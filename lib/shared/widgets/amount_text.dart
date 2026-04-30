import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';

class AmountText extends StatelessWidget {
  final double amount;
  final bool isIncome;
  final TextStyle? style;
  final bool compact;

  const AmountText({
    super.key,
    required this.amount,
    this.isIncome = true,
    this.style,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = amount == 0
        ? AppColors.textSecondary
        : isIncome
            ? AppColors.secondary
            : AppColors.danger;

    final text = compact
        ? CurrencyFormatter.formatCompact(amount)
        : CurrencyFormatter.format(amount);

    return Text(
      text,
      style: (style ?? AppTypography.bodyL).copyWith(color: color),
    );
  }
}
