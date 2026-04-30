import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/providers/wallet_provider.dart';
import '../../shared/models/wallet.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/amount_text.dart';

class WalletsScreen extends ConsumerWidget {
  const WalletsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Wallets', style: AppTypography.headingL),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
      ),
      body: walletsAsync.when(
        data: (wallets) => _buildContent(context, ref, wallets),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Iconsax.warning_2, color: AppColors.danger, size: 48),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Failed to load wallets',
                style: AppTypography.bodyL.copyWith(
                  color: AppColors.danger,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                error.toString(),
                style: AppTypography.bodyS,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddWalletDialog(context, ref),
        backgroundColor: AppColors.primary,
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, List<Wallet> wallets) {
    if (wallets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Iconsax.wallet,
              color: AppColors.textMuted,
              size: 64,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No wallets yet',
              style: AppTypography.headingM.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Add your first wallet to get started',
              style: AppTypography.bodyS,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.6,
              ),
              itemCount: wallets.length,
              itemBuilder: (context, index) {
                return _WalletCard(
                  wallet: wallets[index],
                  onTransfer: () => _showTransferDialog(context, ref, wallets),
                  onEdit: () => _showEditWalletDialog(context, ref, wallets[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddWalletDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    String selectedIcon = 'wallet';
    String selectedColor = '#7C6FF7';

    final iconOptions = [
      'wallet', 'bank', 'mobile', 'card', 'save', 'money',
    ];
    final colorOptions = [
      '#7C6FF7', '#4ECDC4', '#FF6B6B', '#FFD93D', '#4A4A60', '#8A8AA0',
    ];

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
              title: Text(
                'New Wallet',
                style: AppTypography.headingM,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      style: AppTypography.bodyL,
                      decoration: InputDecoration(
                        hintText: 'Wallet name',
                        hintStyle: AppTypography.bodyL.copyWith(
                          color: AppColors.textMuted,
                        ),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.borderSubtle),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: balanceController,
                      style: AppTypography.bodyL,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Initial balance',
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
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Icon',
                      style: AppTypography.headingS.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: iconOptions.map((icon) {
                        final isSelected = selectedIcon == icon;
                        return GestureDetector(
                          onTap: () =>
                              setDialogState(() => selectedIcon = icon),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.2)
                                  : AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.borderSubtle,
                              ),
                            ),
                            child: Icon(
                              _getWalletIcon(icon),
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              size: 20,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Color',
                      style: AppTypography.headingS.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: colorOptions.map((hex) {
                        final isSelected = selectedColor == hex;
                        return GestureDetector(
                          onTap: () =>
                              setDialogState(() => selectedColor = hex),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _parseColor(hex),
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: Colors.white, width: 3)
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: AppTypography.labelBold.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    final balance =
                        double.tryParse(balanceController.text) ?? 0.0;

                    final wallet = Wallet()
                      ..name = name
                      ..iconName = selectedIcon
                      ..colorHex = selectedColor
                      ..balance = balance
                      ..currency = 'IDR'
                      ..createdAt = DateTime.now();

                    ref.read(walletsProvider.notifier).addWallet(wallet);
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Create',
                    style: AppTypography.labelBold.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditWalletDialog(
    BuildContext context,
    WidgetRef ref,
    Wallet wallet,
  ) {
    final nameController = TextEditingController(text: wallet.name);
    final balanceController = TextEditingController(text: wallet.balance.toString());
    String selectedIcon = wallet.iconName;
    String selectedColor = wallet.colorHex;
    bool isDefault = wallet.isDefault;

    final iconOptions = [
      'wallet', 'bank', 'mobile', 'card', 'save', 'money',
    ];
    final colorOptions = [
      '#7C6FF7', '#4ECDC4', '#FF6B6B', '#FFD93D', '#4A4A60', '#8A8AA0',
    ];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.modal),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Edit Wallet', style: AppTypography.headingM),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.of(dialogContext).pop(),
                          child: Icon(
                            Iconsax.close_circle,
                            color: AppColors.textMuted,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: nameController,
                              style: AppTypography.bodyL,
                              decoration: InputDecoration(
                                hintText: 'Wallet name',
                                hintStyle: AppTypography.bodyL.copyWith(
                                  color: AppColors.textMuted,
                                ),
                                enabledBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: AppColors.borderSubtle),
                                ),
                                focusedBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: AppColors.primary),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextField(
                              controller: balanceController,
                              style: AppTypography.bodyL,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Balance',
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
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                Text(
                                  'Default Wallet',
                                  style: AppTypography.headingS.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const Spacer(),
                                Switch(
                                  value: isDefault,
                                  activeColor: AppColors.primary,
                                  onChanged: (val) {
                                    setDialogState(() => isDefault = val);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Icon',
                              style: AppTypography.headingS.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: iconOptions.map((icon) {
                                final isSelected = selectedIcon == icon;
                                return GestureDetector(
                                  onTap: () => setDialogState(() => selectedIcon = icon),
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? _parseColor(selectedColor).withValues(alpha: 0.2)
                                          : AppColors.surfaceElevated,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? _parseColor(selectedColor)
                                            : AppColors.borderSubtle,
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Icon(
                                      _getWalletIcon(icon),
                                      color: isSelected
                                          ? _parseColor(selectedColor)
                                          : AppColors.textMuted,
                                      size: 20,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Color',
                              style: AppTypography.headingS.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: colorOptions.map((color) {
                                final isSelected = selectedColor == color;
                                return GestureDetector(
                                  onTap: () => setDialogState(() => selectedColor = color),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _parseColor(color),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected ? Colors.white : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(Iconsax.tick_circle, color: Colors.white, size: 16)
                                        : null,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.of(dialogContext).pop();
                            ref.read(walletsProvider.notifier).deleteWallet(wallet.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${wallet.name} deleted'),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                          },
                          child: Text(
                            'Delete',
                            style: AppTypography.labelBold.copyWith(
                              color: AppColors.danger,
                            ),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.of(dialogContext).pop(),
                          child: Text(
                            'Cancel',
                            style: AppTypography.labelBold.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        GestureDetector(
                          onTap: () {
                            final name = nameController.text.trim();
                            if (name.isEmpty) return;
                            final balance =
                                double.tryParse(balanceController.text) ?? 0.0;

                            final updated = Wallet()
                              ..id = wallet.id
                              ..name = name
                              ..iconName = selectedIcon
                              ..colorHex = selectedColor
                              ..balance = balance
                              ..currency = wallet.currency
                              ..isDefault = isDefault
                              ..createdAt = wallet.createdAt;

                            ref.read(walletsProvider.notifier).updateWallet(updated);
                            if (isDefault) {
                              ref.read(walletsProvider.notifier).setDefaultWallet(wallet.id);
                            }
                            Navigator.of(dialogContext).pop();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, Color(0xFF9B8FF8)],
                              ),
                              borderRadius: BorderRadius.circular(AppRadius.button),
                            ),
                            child: Text(
                              'Save',
                              style: AppTypography.labelBold.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showTransferDialog(
    BuildContext context,
    WidgetRef ref,
    List<Wallet> wallets,
  ) {
    if (wallets.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need at least 2 wallets to transfer'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    int? fromWalletId = wallets.first.id;
    int? toWalletId = wallets.last.id;
    final amountController = TextEditingController();

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
              title: Text('Transfer', style: AppTypography.headingM),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'From',
                      style: AppTypography.headingS.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        isExpanded: true,
                        value: fromWalletId,
                        dropdownColor: AppColors.surfaceElevated,
                        style: AppTypography.bodyM,
                        items: wallets.map((w) {
                          return DropdownMenuItem<int>(
                            value: w.id,
                            child: Row(
                              children: [
                                Icon(
                                  _getWalletIcon(w.iconName),
                                  color: _parseColor(w.colorHex),
                                  size: 16,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(w.name),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (id) {
                          if (id != null && id != toWalletId) {
                            setDialogState(() => fromWalletId = id);
                          }
                        },
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'To',
                          style: AppTypography.headingS.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: fromWalletId != null && toWalletId != null
                              ? () => setDialogState(() {
                                    final tmp = fromWalletId;
                                    fromWalletId = toWalletId;
                                    toWalletId = tmp;
                                  })
                              : null,
                          icon: Icon(
                            Iconsax.arrow_swap,
                            color: fromWalletId != null && toWalletId != null
                                ? AppColors.primary
                                : AppColors.textMuted,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        isExpanded: true,
                        value: toWalletId,
                        dropdownColor: AppColors.surfaceElevated,
                        style: AppTypography.bodyM,
                        items: wallets.map((w) {
                          return DropdownMenuItem<int>(
                            value: w.id,
                            child: Row(
                              children: [
                                Icon(
                                  _getWalletIcon(w.iconName),
                                  color: _parseColor(w.colorHex),
                                  size: 16,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(w.name),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (id) {
                          if (id != null && id != fromWalletId) {
                            setDialogState(() => toWalletId = id);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
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
                          final amount =
                              double.tryParse(amountController.text) ?? 0.0;
                          if (amount <= 0 ||
                              fromWalletId == null ||
                              toWalletId == null) {
                          return;
                        }

                          final fromWallet = wallets.firstWhere(
                            (w) => w.id == fromWalletId,
                          );
                          final toWallet = wallets.firstWhere(
                            (w) => w.id == toWalletId,
                          );

                          ref.read(walletsProvider.notifier).updateBalance(
                                fromWalletId!,
                                fromWallet.balance - amount,
                              );
                          ref.read(walletsProvider.notifier).updateBalance(
                                toWalletId!,
                                toWallet.balance + amount,
                              );

                          Navigator.of(dialogContext).pop();
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Transferred ${CurrencyFormatter.format(amount)}',
                              ),
                              backgroundColor: AppColors.secondary,
                            ),
                          );
                        },
                        child: Text(
                          'Transfer',
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

  Color _parseColor(String hex) {
    final hexStr = hex.replaceFirst('#', '');
    return Color(int.parse('FF$hexStr', radix: 16));
  }

  IconData _getWalletIcon(String iconName) {
    const iconMap = {
      'wallet': Iconsax.wallet,
      'bank': Iconsax.bank,
      'mobile': Iconsax.mobile,
      'card': Iconsax.card,
      'save': Iconsax.save_2,
      'money': Iconsax.money,
    };
    return iconMap[iconName] ?? Iconsax.wallet;
  }
}

class _WalletCard extends StatelessWidget {
  final Wallet wallet;
  final VoidCallback onTransfer;
  final VoidCallback onEdit;

  const _WalletCard({
    required this.wallet,
    required this.onTransfer,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final walletColor = _parseColor(wallet.colorHex);

    return GlassCard(
      hasGlow: false,
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: walletColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getWalletIcon(wallet.iconName),
                  color: walletColor,
                  size: 20,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppSpacing.xs),
                ),
                child: Text(
                  wallet.currency,
                  style: AppTypography.bodyS.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  wallet.name,
                  style: AppTypography.headingS,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                AmountText(
                  amount: wallet.balance,
                  isIncome: true,
                  style: AppTypography.headingM.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: 'Transfer',
                    isOutlined: true,
                    isFullWidth: true,
                    onPressed: onTransfer,
                    icon: const Icon(
                      Iconsax.arrow_swap,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    final hexStr = hex.replaceFirst('#', '');
    return Color(int.parse('FF$hexStr', radix: 16));
  }

  IconData _getWalletIcon(String iconName) {
    const iconMap = {
      'wallet': Iconsax.wallet,
      'bank': Iconsax.bank,
      'mobile': Iconsax.mobile,
      'card': Iconsax.card,
      'save': Iconsax.save_2,
      'money': Iconsax.money,
    };
    return iconMap[iconName] ?? Iconsax.wallet;
  }
}
