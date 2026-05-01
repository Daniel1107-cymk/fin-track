import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isOutlined;
  final bool isFullWidth;
  final Widget? icon;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isOutlined = false,
    this.isFullWidth = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final button = Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: isOutlined
            ? null
            : const LinearGradient(
                colors: [AppColors.primary, Color(0xFF9B8FF8)],
              ),
        color: isOutlined ? Colors.transparent : null,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: isOutlined
            ? Border.all(color: AppColors.primary)
            : null,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              icon!,
              const SizedBox(width: AppSpacing.sm),
            ],
            Text(
              label,
              style: AppTypography.labelBold(context).copyWith(
                color: isOutlined ? AppColors.primary : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );

    return GestureDetector(
      onTap: onPressed,
      child: button,
    );
  }
}
