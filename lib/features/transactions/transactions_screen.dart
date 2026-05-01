import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/transaction_provider.dart';
import '../../core/providers/category_provider.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/amount_text.dart';
import '../../shared/models/transaction.dart';
import '../../shared/models/category.dart';

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

// ── Transactions Screen ─────────────────────────────────────────────────────

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                0,
              ),
              child: Text(
                'Transactions',
                style: AppTypography.headingL(context),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Content (stateful) ─────────────────────────────────────
            Expanded(
              child: transactionsAsync.when(
                data: (transactions) => categoriesAsync.when(
                  data: (categories) => _TransactionContent(
                    transactions: transactions,
                    categories: categories,
                    onDelete: (tx) => ref
                        .read(transactionsProvider.notifier)
                        .deleteTransaction(tx.id, tx.type, tx.amount, tx.walletId),
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (_, __) => const Center(
                    child: Text('Error loading categories'),
                  ),
                ),
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (_, __) => const Center(
                  child: Text('Error loading transactions'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Transaction Content (stateful for filter + search) ──────────────────────

class _TransactionContent extends StatefulWidget {
  final List<Transaction> transactions;
  final List<Category> categories;
  final void Function(Transaction) onDelete;

  const _TransactionContent({
    required this.transactions,
    required this.categories,
    required this.onDelete,
  });

  @override
  State<_TransactionContent> createState() => _TransactionContentState();
}

class _TransactionContentState extends State<_TransactionContent> {
  String _filter = 'All'; // All | Income | Expense
  String _searchQuery = '';

  List<Transaction> get _filtered {
    var result = widget.transactions;

    // Filter by type
    if (_filter == 'Income') {
      result = result.where((t) => t.type == TransactionType.income).toList();
    } else if (_filter == 'Expense') {
      result =
          result.where((t) => t.type == TransactionType.expense).toList();
    }

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((t) {
        final category = _findCategory(widget.categories, t.categoryId);
        final name = category?.name.toLowerCase() ?? '';
        final note = t.note.toLowerCase();
        return name.contains(query) || note.contains(query);
      }).toList();
    }

    return result;
  }

  Map<String, List<Transaction>> get _grouped {
    final groups = <String, List<Transaction>>{};
    for (final t in _filtered) {
      final key = DateHelper.getRelativeDate(t.date);
      groups.putIfAbsent(key, () => []).add(t);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Pill Tab Filter ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              _filterPill('All'),
              const SizedBox(width: AppSpacing.sm),
              _filterPill('Income'),
              const SizedBox(width: AppSpacing.sm),
              _filterPill('Expense'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Search Bar ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            style: AppTypography.bodyM(context),
            decoration: InputDecoration(
              hintText: 'Search transactions...',
              hintStyle: AppTypography.bodyM(context).copyWith(
                color: AppColors.txtMut(context),
              ),
              prefixIcon: Icon(
                Iconsax.search_normal,
                color: AppColors.txtMut(context),
                size: 20,
              ),
              filled: true,
              fillColor: AppColors.sf(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Transaction List ──────────────────────────────────────────
        Expanded(
          child: _filtered.isEmpty
              ? Center(
                  child: Text(
                    'No transactions found',
                    style: AppTypography.bodyM(context).copyWith(
                      color: AppColors.txtMut(context),
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  children: _grouped.entries.expand((entry) {
                    return [
                      Padding(
                        padding: const EdgeInsets.only(
                          top: AppSpacing.md,
                          bottom: AppSpacing.sm,
                        ),
                        child: Text(
                          entry.key,
                          style: AppTypography.labelBold(context).copyWith(
                            color: AppColors.txtSec(context),
                          ),
                        ),
                      ),
                      ...entry.value.map(
                        (tx) => _dismissibleRow(tx),
                      ),
                    ];
                  }).toList(),
                ),
        ),
      ],
    );
  }

  // ── Filter Pill ──────────────────────────────────────────────────────────

  Widget _filterPill(String label) {
    final isSelected = _filter == label;
    Color activeColor = AppColors.primary;
    if (label == 'Income') activeColor = AppColors.secondary;
    if (label == 'Expense') activeColor = AppColors.danger;

    return GestureDetector(
      onTap: () => setState(() => _filter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.2)
              : AppColors.sf(context),
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.bdr(context),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelBold(context).copyWith(
            color: isSelected ? activeColor : AppColors.txtSec(context),
          ),
        ),
      ),
    );
  }

  // ── Dismissible Row ──────────────────────────────────────────────────────

  Widget _dismissibleRow(Transaction tx) {
    final category = _findCategory(widget.categories, tx.categoryId);
    final color = category != null
        ? _parseColor(category.colorHex)
        : AppColors.txtMut(context);
    final isIncome = tx.type == TransactionType.income;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Dismissible(
        key: ValueKey(tx.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) {
          widget.onDelete(tx);
          return Future.value(true);
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.danger,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: const Icon(Iconsax.trash, color: Colors.white),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.sf(context),
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.bdr(context)),
          ),
          child: Row(
            children: [
              // ── Category Icon ──────────────────────────────────────
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  category != null
                      ? _iconData(category.iconName)
                      : Iconsax.more,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // ── Category + Note ────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category?.name ?? 'Unknown',
                      style: AppTypography.labelBold(context),
                    ),
                    if (tx.note.isNotEmpty)
                      Text(
                        tx.note,
                        style: AppTypography.bodyS(context).copyWith(
                          color: AppColors.txtMut(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // ── Amount ──────────────────────────────────────────────
              AmountText(
                amount: tx.amount,
                isIncome: isIncome,
                style: AppTypography.headingS(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}