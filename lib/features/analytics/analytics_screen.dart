import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/transaction_provider.dart';
import '../../core/providers/category_provider.dart';
import '../../core/utils/formatters.dart';
import '../../shared/models/transaction.dart';
import '../../shared/models/category.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/amount_text.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  DateTime _selectedMonth = DateTime.now();

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  List<Transaction> _filterByMonth(List<Transaction> transactions) {
    return transactions.where((t) {
      return t.date.year == _selectedMonth.year &&
          t.date.month == _selectedMonth.month;
    }).toList();
  }

  double _totalIncome(List<Transaction> transactions) {
    return transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double _totalExpense(List<Transaction> transactions) {
    return transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Map<Category, double> _expenseByCategory(
    List<Transaction> transactions,
    List<Category> categories,
  ) {
    final expenseTransactions =
        transactions.where((t) => t.type == TransactionType.expense).toList();
    final categoryMap = <int, double>{};

    for (final t in expenseTransactions) {
      categoryMap[t.categoryId] =
          (categoryMap[t.categoryId] ?? 0) + t.amount;
    }

    final result = <Category, double>{};
    for (final entry in categoryMap.entries) {
      final category = categories.cast<Category?>().firstWhere(
            (c) => c?.id == entry.key,
            orElse: () => null,
          );
      if (category != null) {
        result[category] = entry.value;
      }
    }

    final sorted = result.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted);
  }

  List<_MonthlyData> _last6MonthsData(List<Transaction> transactions) {
    final now = DateTime.now();
    final data = <_MonthlyData>[];

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthTransactions = transactions.where((t) {
        return t.date.year == month.year && t.date.month == month.month;
      }).toList();

      data.add(_MonthlyData(
        month: month,
        income: monthTransactions
            .where((t) => t.type == TransactionType.income)
            .fold(0.0, (sum, t) => sum + t.amount),
        expense: monthTransactions
            .where((t) => t.type == TransactionType.expense)
            .fold(0.0, (sum, t) => sum + t.amount),
      ));
    }

    return data;
  }

  Color _parseColor(String hex) {
    final hexStr = hex.replaceFirst('#', '');
    return Color(int.parse('FF$hexStr', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Analytics', style: AppTypography.headingL),
        centerTitle: true,
      ),
      body: transactionsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => Center(
          child: Text('Error: $error', style: AppTypography.bodyM),
        ),
        data: (transactions) {
          return categoriesAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (error, _) => Center(
              child: Text('Error: $error', style: AppTypography.bodyM),
            ),
            data: (categories) {
              final filtered = _filterByMonth(transactions);
              final income = _totalIncome(filtered);
              final expense = _totalExpense(filtered);
              final net = income - expense;
              final categoryBreakdown =
                  _expenseByCategory(filtered, categories);
              final monthlyData = _last6MonthsData(transactions);

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MonthPicker(
                      selectedMonth: _selectedMonth,
                      onPrevious: _previousMonth,
                      onNext: _nextMonth,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _SummaryRow(
                      income: income,
                      expense: expense,
                      net: net,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _ExpenseDonutSection(
                      categoryBreakdown: categoryBreakdown,
                      totalExpense: expense,
                      parseColor: _parseColor,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _MonthlyBarChart(
                      monthlyData: monthlyData,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _MonthlyData {
  final DateTime month;
  final double income;
  final double expense;

  _MonthlyData({
    required this.month,
    required this.income,
    required this.expense,
  });
}

class _MonthPicker extends StatelessWidget {
  final DateTime selectedMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _MonthPicker({
    required this.selectedMonth,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Iconsax.arrow_left_2, color: AppColors.textPrimary),
            onPressed: onPrevious,
            splashRadius: 20,
          ),
          Text(
            DateHelper.formatMonthYear(selectedMonth),
            style: AppTypography.headingM,
          ),
          IconButton(
            icon: const Icon(Iconsax.arrow_right_2, color: AppColors.textPrimary),
            onPressed: onNext,
            splashRadius: 20,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final double income;
  final double expense;
  final double net;

  const _SummaryRow({
    required this.income,
    required this.expense,
    required this.net,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Income',
            amount: income,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _SummaryCard(
            label: 'Expense',
            amount: expense,
            color: AppColors.danger,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _SummaryCard(
            label: 'Net',
            amount: net,
            color: net >= 0 ? AppColors.secondary : AppColors.danger,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.bodyS),
          const SizedBox(height: AppSpacing.xs),
          AmountText(
            amount: amount.abs(),
            isIncome: amount >= 0,
            compact: true,
            style: AppTypography.headingS,
          ),
        ],
      ),
    );
  }
}

class _ExpenseDonutSection extends StatelessWidget {
  final Map<Category, double> categoryBreakdown;
  final double totalExpense;
  final Color Function(String) parseColor;

  const _ExpenseDonutSection({
    required this.categoryBreakdown,
    required this.totalExpense,
    required this.parseColor,
  });

  @override
  Widget build(BuildContext context) {
    if (categoryBreakdown.isEmpty) {
      return GlassCard(
        child: SizedBox(
          width: double.infinity,
          height: 200,
          child: Center(
            child: Text(
              'No expenses this month',
              style: AppTypography.bodyM.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
        ),
      );
    }

    final sections = categoryBreakdown.entries.map((entry) {
      final category = entry.key;
      final amount = entry.value;
      final percentage =
          totalExpense > 0 ? (amount / totalExpense) * 100 : 0.0;
      final color = parseColor(category.colorHex);

      return PieChartSectionData(
        color: color,
        value: amount,
        title: percentage >= 5 ? '${percentage.toStringAsFixed(0)}%' : '',
        radius: 50,
        titleStyle: AppTypography.bodyS.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
        titlePositionPercentageOffset: 0.6,
      );
    }).toList();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Expense Breakdown', style: AppTypography.headingM),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 60,
                    sectionsSpace: 2,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total',
                      style: AppTypography.bodyS.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatCompact(totalExpense),
                      style: AppTypography.headingS.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _CategoryLegend(
            categoryBreakdown: categoryBreakdown,
            totalExpense: totalExpense,
            parseColor: parseColor,
          ),
        ],
      ),
    );
  }
}

class _CategoryLegend extends StatelessWidget {
  final Map<Category, double> categoryBreakdown;
  final double totalExpense;
  final Color Function(String) parseColor;

  const _CategoryLegend({
    required this.categoryBreakdown,
    required this.totalExpense,
    required this.parseColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: categoryBreakdown.entries.map((entry) {
        final category = entry.key;
        final amount = entry.value;
        final percentage =
            totalExpense > 0 ? (amount / totalExpense) * 100 : 0.0;
        final color = parseColor(category.colorHex);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  category.name,
                  style: AppTypography.bodyM,
                ),
              ),
              Text(
                CurrencyFormatter.formatCompact(amount),
                style: AppTypography.bodyM.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: 48,
                child: Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: AppTypography.bodyS.copyWith(
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _MonthlyBarChart extends StatelessWidget {
  final List<_MonthlyData> monthlyData;

  const _MonthlyBarChart({required this.monthlyData});

  @override
  Widget build(BuildContext context) {
    if (monthlyData.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxY = monthlyData.fold<double>(
      0,
      (max, d) {
        final localMax = d.income > d.expense ? d.income : d.expense;
        return localMax > max ? localMax : max;
      },
    );

    final adjustedMaxY = maxY == 0 ? 1000000.0 : maxY * 1.2;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Monthly Overview', style: AppTypography.headingM),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: adjustedMaxY,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final label = rodIndex == 0 ? 'Income' : 'Expense';
                      return BarTooltipItem(
                        '$label\n${CurrencyFormatter.formatCompact(rod.toY)}',
                        AppTypography.bodyS.copyWith(color: Colors.white),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= monthlyData.length) {
                          return const SizedBox.shrink();
                        }
                        final month = monthlyData[index].month;
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            _monthShort(month),
                            style: AppTypography.bodyS.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        );
                      },
                      reservedSize: 28,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            CurrencyFormatter.formatCompact(value),
                            style: AppTypography.bodyS.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                      reservedSize: 52,
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: adjustedMaxY / 5,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.borderSubtle,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: monthlyData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: data.income,
                        color: AppColors.secondary,
                        width: 12,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                      BarChartRodData(
                        toY: data.expense,
                        color: AppColors.danger,
                        width: 12,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                    barsSpace: 4,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ChartLegendDot(color: AppColors.secondary, label: 'Income'),
              const SizedBox(width: AppSpacing.lg),
              _ChartLegendDot(color: AppColors.danger, label: 'Expense'),
            ],
          ),
        ],
      ),
    );
  }

  String _monthShort(DateTime date) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[date.month];
  }
}

class _ChartLegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: AppTypography.bodyS),
      ],
    );
  }
}