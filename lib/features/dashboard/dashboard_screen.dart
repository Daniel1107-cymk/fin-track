import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/transaction_provider.dart';
import '../../core/providers/wallet_provider.dart';
import '../../core/providers/category_provider.dart';
import '../../core/providers/budget_provider.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/animated_number.dart';
import '../../shared/widgets/amount_text.dart';
import '../../shared/models/transaction.dart';
import '../../shared/models/wallet.dart';
import '../../shared/models/category.dart';
import '../../shared/models/budget.dart';

// ── Icon & Color helpers ────────────────────────────────────────────────────

IconData _iconData(String iconName) {
  final map = <String, IconData>{
    'wallet': Iconsax.wallet,
    'bank': Iconsax.bank,
    'mobile': Iconsax.mobile,
    'moneys': Iconsax.moneys,
    'briefcase': Iconsax.briefcase,
    'chart': Iconsax.chart,
    'add-circle': Iconsax.add_circle,
    'coffee': Iconsax.coffee,
    'car': Iconsax.car,
    'bag': Iconsax.bag_2,
    'heart': Iconsax.heart,
    'music': Iconsax.music,
    'receipt': Iconsax.receipt,
    'book': Iconsax.book,
    'more': Iconsax.more,
    'home': Iconsax.home,
    'send': Iconsax.send,
    'receive': Iconsax.arrow_down,
  };
  return map[iconName] ?? Iconsax.wallet;
}

Color _parseColor(String hex) {
  final hexStr = hex.replaceFirst('#', '');
  return Color(int.parse('FF$hexStr', radix: 16));
}

Category? _findCategory(List<Category> categories, int categoryId) {
  for (final c in categories) {
    if (c.id == categoryId) return c;
  }
  return null;
}

// ── Dashboard Screen ────────────────────────────────────────────────────────

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletsProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final budgetsAsync = ref.watch(budgetsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Greeting ──────────────────────────────────────────────
              Text(
                '${DateHelper.getGreeting()} 👋',
                style: AppTypography.bodyL.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              // ── Net Worth ─────────────────────────────────────────────
              _buildNetWorth(walletsAsync),
              const SizedBox(height: AppSpacing.lg),

              // ── Toggle Pill ────────────────────────────────────────────
              const _TogglePill(),
              const SizedBox(height: AppSpacing.md),

              // ── Stat Cards ────────────────────────────────────────────
              _buildStatCards(transactionsAsync),
              const SizedBox(height: AppSpacing.lg),

              // ── Wallet Cards ──────────────────────────────────────────
              _buildSectionTitle(
                'My Wallets',
                onTap: () => context.push('/wallets'),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildWalletCards(walletsAsync),
              const SizedBox(height: AppSpacing.lg),

              // ── Budget Progress ───────────────────────────────────────
              _buildBudgetProgress(context, budgetsAsync, categoriesAsync),
              const SizedBox(height: AppSpacing.lg),

              // ── Recent Transactions ───────────────────────────────────
              _buildRecentTransactions(context, transactionsAsync, categoriesAsync),
            ],
          ),
        ),
      ),
    );
  }

  // ── Net Worth ────────────────────────────────────────────────────────────

  Widget _buildNetWorth(AsyncValue<List<Wallet>> walletsAsync) {
    return walletsAsync.when(
      data: (wallets) {
        final total = wallets.fold(0.0, (sum, w) => sum + w.balance);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Net Worth',
              style: AppTypography.bodyS.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.xs),
            AnimatedNumber(
              value: total,
              style: AppTypography.displayLarge.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Text(
        'Error loading wallets',
        style: AppTypography.bodyM.copyWith(color: AppColors.danger),
      ),
    );
  }

  // ── Stat Cards ──────────────────────────────────────────────────────────

  Widget _buildStatCards(AsyncValue<List<Transaction>> transactionsAsync) {
    return transactionsAsync.when(
      data: (transactions) {
        final now = DateTime.now();
        final monthTx = transactions.where(
          (t) => t.date.month == now.month && t.date.year == now.year,
        );
        final income = monthTx
            .where((t) => t.type == TransactionType.income)
            .fold(0.0, (sum, t) => sum + t.amount);
        final expense = monthTx
            .where((t) => t.type == TransactionType.expense)
            .fold(0.0, (sum, t) => sum + t.amount);

        return Row(
          children: [
            Expanded(child: _statCard('Income', income, AppColors.secondary)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _statCard('Expense', expense, AppColors.danger)),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Text(
        'Error loading stats',
        style: AppTypography.bodyM.copyWith(color: AppColors.danger),
      ),
    );
  }

  Widget _statCard(String label, double amount, Color accent) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGlow,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 40,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.bodyS.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  CurrencyFormatter.formatCompact(amount),
                  style: AppTypography.headingS.copyWith(color: accent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Wallet Cards ────────────────────────────────────────────────────────

  Widget _buildWalletCards(AsyncValue<List<Wallet>> walletsAsync) {
    return walletsAsync.when(
      data: (wallets) {
        if (wallets.isEmpty) {
          return Text(
            'No wallets yet',
            style: AppTypography.bodyS.copyWith(color: AppColors.textMuted),
          );
        }
        return SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: wallets.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final wallet = wallets[index];
              return _walletCard(context, wallet);
            },
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Text(
        'Error loading wallets',
        style: AppTypography.bodyM.copyWith(color: AppColors.danger),
      ),
    );
  }

  Widget _walletCard(BuildContext context, Wallet wallet) {
    final color = _parseColor(wallet.colorHex);
    return GestureDetector(
      onTap: () => context.push('/wallets'),
      child: GlassCard(
        width: 180,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_iconData(wallet.iconName), color: color, size: 22),
            ),
            const Spacer(),
            Text(
              wallet.name,
              style: AppTypography.bodyS.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              CurrencyFormatter.formatCompact(wallet.balance),
              style: AppTypography.headingS,
            ),
          ],
        ),
      ),
    );
  }

  // ── Budget Progress ──────────────────────────────────────────────────────

  Widget _buildBudgetProgress(
    BuildContext context,
    AsyncValue<List<Budget>> budgetsAsync,
    AsyncValue<List<Category>> categoriesAsync,
  ) {
    return budgetsAsync.when(
      data: (budgets) => categoriesAsync.when(
        data: (categories) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(
                'Budget',
                onTap: () => context.push('/budgets'),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (budgets.isEmpty)
                Text(
                  'No budgets set',
                  style: AppTypography.bodyS.copyWith(color: AppColors.textMuted),
                )
              else
                ...budgets.take(3).map((b) => _budgetBar(b, categories)),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Text(
          'Error loading categories',
          style: AppTypography.bodyM.copyWith(color: AppColors.danger),
        ),
      ),
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Text(
        'Error loading budgets',
        style: AppTypography.bodyM.copyWith(color: AppColors.danger),
      ),
    );
  }

  Widget _budgetBar(Budget budget, List<Category> categories) {
    final category = _findCategory(categories, budget.categoryId);
    final progress =
        budget.limitAmount > 0 ? budget.spentAmount / budget.limitAmount : 0.0;
    final clampedProgress = progress.clamp(0.0, 1.0);
    final color = category != null
        ? _parseColor(category.colorHex)
        : AppColors.textMuted;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                category != null ? _iconData(category.iconName) : Iconsax.more,
                size: 16,
                color: color,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  category?.name ?? 'Unknown',
                  style: AppTypography.labelBold,
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: AppTypography.bodyS.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: clampedProgress,
              backgroundColor: AppColors.surfaceElevated,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  // ── Recent Transactions ─────────────────────────────────────────────────

  Widget _buildRecentTransactions(
    BuildContext context,
    AsyncValue<List<Transaction>> transactionsAsync,
    AsyncValue<List<Category>> categoriesAsync,
  ) {
    return transactionsAsync.when(
      data: (transactions) => categoriesAsync.when(
        data: (categories) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(
                'Recent Transactions',
                onTap: () => context.go('/transactions'),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (transactions.isEmpty)
                Text(
                  'No transactions yet',
                  style: AppTypography.bodyS.copyWith(color: AppColors.textMuted),
                )
              else
                ..._groupByDate(transactions.take(5).toList()).entries.expand(
                      (entry) => [
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.sm,
                            top: AppSpacing.sm,
                          ),
                          child: Text(
                            entry.key,
                            style: AppTypography.bodyS.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                        ...entry.value.map(
                          (t) => _transactionRow(t, categories),
                        ),
                      ],
                    ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Text(
          'Error loading categories',
          style: AppTypography.bodyM.copyWith(color: AppColors.danger),
        ),
      ),
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Text(
        'Error loading transactions',
        style: AppTypography.bodyM.copyWith(color: AppColors.danger),
      ),
    );
  }

  Widget _transactionRow(Transaction tx, List<Category> categories) {
    final category = _findCategory(categories, tx.categoryId);
    final color = category != null
        ? _parseColor(category.colorHex)
        : AppColors.textMuted;
    final isIncome = tx.type == TransactionType.income;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              category != null ? _iconData(category.iconName) : Iconsax.more,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category?.name ?? 'Unknown',
                  style: AppTypography.labelBold,
                ),
                if (tx.note.isNotEmpty)
                  Text(
                    tx.note,
                    style: AppTypography.bodyS.copyWith(
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          AmountText(amount: tx.amount, isIncome: isIncome),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title, {VoidCallback? onTap}) {
    return Row(
      children: [
        Text(title, style: AppTypography.headingM),
        const Spacer(),
        GestureDetector(
          onTap: onTap,
          child: Text(
            'See all',
            style: AppTypography.bodyS.copyWith(color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Map<String, List<Transaction>> _groupByDate(List<Transaction> txs) {
    final groups = <String, List<Transaction>>{};
    for (final t in txs) {
      final key = DateHelper.getRelativeDate(t.date);
      groups.putIfAbsent(key, () => []).add(t);
    }
    return groups;
  }
}

// ── Toggle Pill (stateful) ──────────────────────────────────────────────────

class _TogglePill extends StatefulWidget {
  const _TogglePill();

  @override
  State<_TogglePill> createState() => _TogglePillState();
}

class _TogglePillState extends State<_TogglePill> {
  bool _showIncome = true;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('This Month', style: AppTypography.headingS),
        const Spacer(),
        GestureDetector(
          onTap: () => setState(() => _showIncome = true),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: _showIncome
                  ? AppColors.secondary
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.chip),
              border: Border.all(
                color: _showIncome
                    ? AppColors.secondary
                    : AppColors.borderSubtle,
              ),
            ),
            child: Text(
              'Income',
              style: AppTypography.labelBold.copyWith(
                color: _showIncome ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        GestureDetector(
          onTap: () => setState(() => _showIncome = false),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: !_showIncome
                  ? AppColors.danger
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.chip),
              border: Border.all(
                color: !_showIncome
                    ? AppColors.danger
                    : AppColors.borderSubtle,
              ),
            ),
            child: Text(
              'Expense',
              style: AppTypography.labelBold.copyWith(
                color: !_showIncome ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}