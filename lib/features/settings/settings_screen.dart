import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/transaction_provider.dart';
import '../../core/providers/wallet_provider.dart';
import '../../core/providers/category_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../shared/models/transaction.dart';
import '../../shared/models/category.dart';
import '../../shared/models/wallet.dart';
import '../../shared/widgets/glass_card.dart';
import '../../core/providers/security_settings_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../security/pin_setup_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isNavigatingToPinSetup = false;

  void _showClearDataConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.sf(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.modal),
        ),
        title: Text(
          'Clear All Data?',
          style: AppTypography.headingM(context),
        ),
        content: Text(
          'This will permanently delete all your transactions, wallets, and categories. This action cannot be undone.',
          style: AppTypography.bodyM(context).copyWith(
            color: AppColors.txtSec(context),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: AppTypography.labelBold(context).copyWith(
                color: AppColors.txtSec(context),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearAllData();
            },
            child: Text(
              'Clear Data',
              style: AppTypography.labelBold(context).copyWith(
                color: AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData() async {
    try {
      final isar = await ref.read(databaseProvider.future);
      await isar.writeTxn(() async {
        await isar.transactions.clear();
        await isar.categorys.clear();
        await isar.wallets.clear();
      });
      ref.invalidate(transactionsProvider);
      ref.invalidate(walletsProvider);
      ref.read(securitySettingsProvider.notifier).clearAll();
      ref.invalidate(securitySettingsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.sf(context),
            content: Text(
              'All data cleared',
              style: AppTypography.bodyM(context).copyWith(
                color: AppColors.txt(context),
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text(
              'Failed to clear data: $e',
              style: AppTypography.bodyM(context),
            ),
          ),
        );
      }
    }
  }

  Future<void> _exportToCsv() async {
    try {
      final transactions = await ref.read(transactionsProvider.future);
      final categories = await ref.read(categoriesProvider.future);

      final categoryMap = <int, String>{};
      for (final cat in categories) {
        categoryMap[cat.id] = cat.name;
      }

      final buffer = StringBuffer();
      buffer.writeln('Date,Type,Category,Amount,Note');

      for (final t in transactions) {
        final type = t.type == TransactionType.income ? 'Income' : 'Expense';
        final category = categoryMap[t.categoryId] ?? 'Unknown';
        final note = t.note.replaceAll(',', ';');
        buffer.writeln(
          '${t.date.toIso8601String().split('T').first},'
          '$type,'
          '$category,'
          '${t.amount},'
          '$note',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.sf(context),
            content: Text(
              'Export ready (${transactions.length} transactions)',
              style: AppTypography.bodyM(context).copyWith(
                color: AppColors.txt(context),
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text(
              'Export failed: $e',
              style: AppTypography.bodyM(context),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        elevation: 0,
        title: Text('Settings', style: AppTypography.headingL(context)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PreferencesSection(
              isDarkTheme: ref.watch(themeModeProvider).valueOrNull != ThemeMode.light,
              onThemeChanged: (value) {
                ref.read(themeModeProvider.notifier).setThemeMode(
                  value ? ThemeMode.dark : ThemeMode.light,
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _SecuritySection(
              isBiometricEnabled: ref.watch(securitySettingsProvider).valueOrNull?.biometricEnabled ?? false,
              onBiometricChanged: (value) {
                ref.read(securitySettingsProvider.notifier).toggleBiometric(value);
              },
              pinEnabled: ref.watch(securitySettingsProvider).valueOrNull?.pinEnabled ?? false,
              onPinChanged: (value) async {
                if (value) {
                  final hasPinSet = ref.read(securitySettingsProvider).valueOrNull?.hasPinSet ?? false;
                  if (!hasPinSet) {
                    if (_isNavigatingToPinSetup) return;
                    _isNavigatingToPinSetup = true;
                    try {
                      final result = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => const PinSetupScreen(),
                        ),
                      );
                      if (result != true) return;
                    } finally {
                      _isNavigatingToPinSetup = false;
                    }
                  }
                  await ref.read(securitySettingsProvider.notifier).togglePin(true);
                } else {
                  await ref.read(securitySettingsProvider.notifier).togglePin(false);
                }
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _DataSection(
              onExport: _exportToCsv,
              onClearData: _showClearDataConfirmation,
            ),
            const SizedBox(height: AppSpacing.md),
            const _AboutSection(),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _PreferencesSection extends StatelessWidget {
  final bool isDarkTheme;
  final ValueChanged<bool> onThemeChanged;

  const _PreferencesSection({
    required this.isDarkTheme,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Preferences', style: AppTypography.headingM(context)),
          const SizedBox(height: AppSpacing.sm),
          _SettingsRow(
            icon: Iconsax.money,
            title: 'Currency',
            trailing: Text(
              'IDR',
              style: AppTypography.bodyM(context).copyWith(
                color: AppColors.txtSec(context),
              ),
            ),
          ),
          _SettingsToggleRow(
            icon: Iconsax.moon,
            title: 'Dark Theme',
            subtitle: isDarkTheme ? 'Dark mode active' : 'Light mode active',
            value: isDarkTheme,
            onChanged: onThemeChanged,
          ),
        ],
      ),
    );
  }
}

class _SecuritySection extends ConsumerWidget {
  final bool isBiometricEnabled;
  final ValueChanged<bool> onBiometricChanged;
  final bool pinEnabled;
  final ValueChanged<bool> onPinChanged;

  const _SecuritySection({
    required this.isBiometricEnabled,
    required this.onBiometricChanged,
    required this.pinEnabled,
    required this.onPinChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final biometricAvailable = ref.watch(biometricAvailableProvider);

    final biometricSubtitle = biometricAvailable.value == true
        ? 'Use fingerprint or face ID to open app'
        : 'Not available on this device';

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Security', style: AppTypography.headingM(context)),
          const SizedBox(height: AppSpacing.sm),
          _SettingsToggleRow(
            icon: Iconsax.finger_scan,
            title: 'Biometric Lock',
            subtitle: biometricSubtitle,
            value: isBiometricEnabled,
            onChanged: biometricAvailable.value == true
                ? onBiometricChanged
                : null,
          ),
          _SettingsToggleRow(
            icon: Iconsax.lock,
            title: 'PIN Lock',
            subtitle: 'Require PIN on app launch',
            value: pinEnabled,
            onChanged: onPinChanged,
          ),
        ],
      ),
    );
  }
}

class _DataSection extends StatelessWidget {
  final VoidCallback onExport;
  final VoidCallback onClearData;

  const _DataSection({
    required this.onExport,
    required this.onClearData,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Data', style: AppTypography.headingM(context)),
          const SizedBox(height: AppSpacing.sm),
          _SettingsRow(
            icon: Iconsax.export_1,
            title: 'Export to CSV',
            onTap: onExport,
          ),
          _SettingsRow(
            icon: Iconsax.trash,
            title: 'Clear All Data',
            titleColor: AppColors.danger,
            onTap: onClearData,
          ),
        ],
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About', style: AppTypography.headingM(context)),
          const SizedBox(height: AppSpacing.sm),
          _SettingsRow(
            icon: Iconsax.information,
            title: 'App Version',
            trailing: Text(
              '1.0.0',
              style: AppTypography.bodyM(context).copyWith(
                color: AppColors.txtSec(context),
              ),
            ),
          ),
          _SettingsRow(
            icon: Iconsax.star,
            title: 'Rate App',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.title,
    this.titleColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: titleColor ?? AppColors.txtSec(context)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                style: AppTypography.bodyM(context).copyWith(
                  color: titleColor ?? AppColors.txt(context),
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _SettingsToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _SettingsToggleRow({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.txtSec(context)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyM(context)),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: AppTypography.bodyS(context).copyWith(
                      color: AppColors.txtMut(context),
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }
}