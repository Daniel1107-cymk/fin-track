import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/providers/budget_provider.dart';
import '../../core/providers/category_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../shared/models/budget.dart';
import '../../shared/models/category.dart';
import '../../shared/widgets/glass_card.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Iconsax.arrow_left, color: AppColors.textPrimary),
        ),
        title: Text('Budgets', style: AppTypography.headingL),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              const _MonthHeader(),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: budgetsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (error, _) => Center(
                    child: Text(
                      'Failed to load budgets',
                      style: AppTypography.bodyM.copyWith(
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                  data: (budgets) => categoriesAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                    error: (error, _) => Center(
                      child: Text(
                        'Failed to load categories',
                        style: AppTypography.bodyM.copyWith(
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                    data: (categories) => Stack(
                      children: [
                        _BudgetList(
                          budgets: budgets,
                          categories: categories,
                        ),
                        Positioned(
                          bottom: AppSpacing.md,
                          right: 0,
                          child: FloatingActionButton(
                            onPressed: () => _showAddBudgetDialog(
                                context, ref, categories),
                            backgroundColor: AppColors.primary,
                            child: const Icon(Iconsax.add, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _parseBudgetColor(String hexColor) {
  final hex = hexColor.replaceAll('#', '');
  return Color(int.parse('FF$hex', radix: 16));
}

void _showAddBudgetDialog(
  BuildContext context,
  WidgetRef ref,
  List<Category> categories,
) {
  int? selectedCategoryId;
  final amountController = TextEditingController();

  // Filter out categories that already have a budget this month
  final now = DateTime.now();
  final existingBudgetCats = ref.read(budgetsProvider).valueOrNull
          ?.where((b) => b.month == now.month && b.year == now.year)
          .map((b) => b.categoryId)
          .toSet() ??
      {};

  final availableCategories = categories
      .where((c) => !existingBudgetCats.contains(c.id))
      .toList();

  if (availableCategories.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All categories already have budgets'),
        backgroundColor: AppColors.warning,
      ),
    );
    return;
  }

  selectedCategoryId = availableCategories.first.id;

  showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.modal),
            ),
            title: Text('Add Budget', style: AppTypography.headingM),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category',
                    style: AppTypography.headingS.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: selectedCategoryId,
                      dropdownColor: AppColors.surfaceElevated,
                      style: AppTypography.bodyM,
                      items: availableCategories.map((c) {
                        return DropdownMenuItem<int>(
                          value: c.id,
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: _parseBudgetColor(c.colorHex).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  _mapIconName(c.iconName),
                                  color: _parseBudgetColor(c.colorHex),
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(c.name),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (id) {
                        if (id != null) {
                          setDialogState(() => selectedCategoryId = id);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Monthly Limit',
                    style: AppTypography.headingS.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: amountController,
                    style: AppTypography.bodyL,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Amount',
                      hintStyle: AppTypography.bodyL.copyWith(
                        color: AppColors.textMuted,
                      ),
                      prefixText: 'Rp ',
                      prefixStyle: AppTypography.bodyL.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.borderSubtle),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: MediaQuery.of(dialogContext).viewInsets.bottom == 0
                ? [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: Text(
                        'Cancel',
                        style: AppTypography.labelBold.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        final amount = double.tryParse(amountController.text) ?? 0.0;
                        if (amount <= 0 || selectedCategoryId == null) return;

                        ref.read(budgetsProvider.notifier).addBudget(
                              selectedCategoryId!,
                              amount,
                            );
                        Navigator.of(dialogContext).pop();
                      },
                      child: Text(
                        'Add',
                        style: AppTypography.labelBold.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ]
                : null,
          );
        },
      );
    },
  );
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Budgets',
          style: AppTypography.headingL,
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Iconsax.calendar,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                DateHelper.formatMonthYear(now),
                style: AppTypography.labelBold.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BudgetList extends ConsumerWidget {
  final List<Budget> budgets;
  final List<Category> categories;

  const _BudgetList({
    required this.budgets,
    required this.categories,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (budgets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Iconsax.wallet,
              size: 80,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No budgets set',
              style: AppTypography.headingM.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Set a budget for each category\nto track your spending',
              textAlign: TextAlign.center,
              style: AppTypography.bodyS,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      itemCount: budgets.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final budget = budgets[index];
        final category = categories.firstWhere(
          (c) => c.id == budget.categoryId,
          orElse: () => Category()
            ..name = 'Unknown'
            ..iconName = 'more'
            ..colorHex = '#8A8AA0'
            ..type = CategoryType.expense,
        );
        return _BudgetCard(budget: budget, category: category);
      },
    );
  }
}

class _BudgetCard extends ConsumerWidget {
  final Budget budget;
  final Category category;

  const _BudgetCard({
    required this.budget,
    required this.category,
  });

  Color _parseColor(String hexColor) {
    final hex = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  Color _progressColor(double percentage) {
    if (percentage >= 0.9) return AppColors.danger;
    if (percentage >= 0.7) return AppColors.warning;
    return AppColors.secondary;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final percentage = budget.limitAmount > 0
        ? budget.spentAmount / budget.limitAmount
        : 0.0;
    final isOverspent = percentage >= 1.0;
    final progressColor = _progressColor(percentage);
    final categoryColor = _parseColor(category.colorHex);

    return Dismissible(
      key: ValueKey(budget.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) {
        ref.read(budgetsProvider.notifier).deleteBudget(budget.id);
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
      child: GlassCard(
        hasGlow: isOverspent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _mapIconName(category.iconName),
                    color: categoryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: AppTypography.headingS,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${CurrencyFormatter.format(budget.spentAmount)} / ${CurrencyFormatter.format(budget.limitAmount)}',
                        style: AppTypography.bodyS.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOverspent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                    child: Text(
                      'Overspent',
                      style: AppTypography.bodyS.copyWith(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  Text(
                    '${(percentage * 100).toStringAsFixed(0)}%',
                    style: AppTypography.headingS.copyWith(
                      color: progressColor,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _AnimatedProgressBar(
              percentage: percentage.clamp(0.0, 1.0),
              color: progressColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedProgressBar extends StatefulWidget {
  final double percentage;
  final Color color;

  const _AnimatedProgressBar({
    required this.percentage,
    required this.color,
  });

  @override
  State<_AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<_AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = Tween<double>(begin: 0, end: widget.percentage).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _AnimatedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percentage != widget.percentage) {
      _animation = Tween<double>(
        begin: oldWidget.percentage,
        end: widget.percentage,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _animation.value,
            child: Container(
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(4),
                boxShadow: widget.color == AppColors.danger
                    ? [
                        BoxShadow(
                          color: AppColors.danger.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }
}

IconData _mapIconName(String iconName) {
  const iconMap = <String, IconData>{
    'moneys': Iconsax.moneys,
    'briefcase': Iconsax.briefcase,
    'chart': Iconsax.chart,
    'add-circle': Iconsax.add_circle,
    'coffee': Iconsax.coffee,
    'car': Iconsax.car,
    'bag': Iconsax.bag,
    'heart': Iconsax.heart,
    'music': Iconsax.music,
    'receipt': Iconsax.receipt,
    'book': Iconsax.book,
    'more': Iconsax.more,
    'wallet': Iconsax.wallet,
    'bank': Iconsax.bank,
    'mobile': Iconsax.mobile,
  };
  return iconMap[iconName] ?? Iconsax.more;
}