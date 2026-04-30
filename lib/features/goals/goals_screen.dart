import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/providers/goal_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../shared/models/saving_goal.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/glass_card.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),
              Text('Goals', style: AppTypography.headingL),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: goalsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  ),
                  error: (error, _) => Center(
                    child: Text(
                      'Failed to load goals',
                      style: AppTypography.bodyM.copyWith(
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                  data: (goals) => _GoalsList(goals: goals),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalsList extends StatelessWidget {
  final List<SavingGoal> goals;

  const _GoalsList({required this.goals});

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Iconsax.chart,
              size: 80,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Set your first goal',
              style: AppTypography.headingM.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Start saving towards something\nthat matters to you',
              textAlign: TextAlign.center,
              style: AppTypography.bodyS,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      itemCount: goals.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        return _GoalCard(goal: goals[index]);
      },
    );
  }
}

class _GoalCard extends ConsumerWidget {
  final SavingGoal goal;

  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final percentage = goal.targetAmount > 0
        ? goal.savedAmount / goal.targetAmount
        : 0.0;
    final clampedPercentage = percentage.clamp(0.0, 1.0);
    final isCompleted = percentage >= 1.0;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GoalEmoji(emoji: goal.iconEmoji),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: AppTypography.headingS,
                    ),
                    if (goal.deadline != null) ...[
                      const SizedBox(height: 4),
                      _DeadlineChip(deadline: goal.deadline!),
                    ],
                  ],
                ),
              ),
              _PercentageBadge(percentage: clampedPercentage),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _GoalProgressBar(percentage: clampedPercentage),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${CurrencyFormatter.format(goal.savedAmount)} of ${CurrencyFormatter.format(goal.targetAmount)}',
                style: AppTypography.bodyS,
              ),
              if (isCompleted)
                Text(
                  'Completed!',
                  style: AppTypography.bodyS.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          if (!isCompleted) ...[
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Add Funds',
              isOutlined: true,
              isFullWidth: true,
              icon: const Icon(
                Iconsax.add,
                size: 16,
                color: AppColors.primary,
              ),
              onPressed: () => _showAddFundsDialog(context, ref),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddFundsDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.modal),
          ),
          title: Text(
            'Add Funds to ${goal.name}',
            style: AppTypography.headingS,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current: ${CurrencyFormatter.format(goal.savedAmount)} / ${CurrencyFormatter.format(goal.targetAmount)}',
                style: AppTypography.bodyM.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: AppTypography.bodyL,
                decoration: InputDecoration(
                  hintText: 'Enter amount',
                  hintStyle: AppTypography.bodyL.copyWith(
                    color: AppColors.textMuted,
                  ),
                  prefixText: 'Rp ',
                  prefixStyle: AppTypography.bodyL.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
          actions: [
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
                final amount = double.tryParse(controller.text);
                if (amount != null && amount > 0) {
                  ref
                      .read(goalsProvider.notifier)
                      .addFunds(goal.id, amount);
                  Navigator.of(dialogContext).pop();
                }
              },
              child: Text(
                'Add',
                style: AppTypography.labelBold.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GoalEmoji extends StatelessWidget {
  final String emoji;

  const _GoalEmoji({required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}

class _DeadlineChip extends StatelessWidget {
  final DateTime deadline;

  const _DeadlineChip({required this.deadline});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Iconsax.calendar,
            size: 12,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            DateHelper.formatDateShort(deadline),
            style: AppTypography.bodyS.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PercentageBadge extends StatelessWidget {
  final double percentage;

  const _PercentageBadge({required this.percentage});

  @override
  Widget build(BuildContext context) {
    final isCompleted = percentage >= 1.0;
    final color = isCompleted ? AppColors.secondary : AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        '${(percentage * 100).toStringAsFixed(0)}%',
        style: AppTypography.labelBold.copyWith(
          color: color,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _GoalProgressBar extends StatefulWidget {
  final double percentage;

  const _GoalProgressBar({required this.percentage});

  @override
  State<_GoalProgressBar> createState() => _GoalProgressBarState();
}

class _GoalProgressBarState extends State<_GoalProgressBar>
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
  void didUpdateWidget(covariant _GoalProgressBar oldWidget) {
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
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF9B8FF8)],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        );
      },
    );
  }
}