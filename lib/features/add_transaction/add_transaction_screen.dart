import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/providers/transaction_provider.dart';
import '../../core/providers/category_provider.dart';
import '../../core/providers/wallet_provider.dart';
import '../../shared/models/transaction.dart';
import '../../shared/models/category.dart';
import '../../shared/models/wallet.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/category_chip.dart';
import '../../shared/widgets/app_button.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  TransactionType _type = TransactionType.expense;
  String _amountText = '0';
  bool _numpadActive = false;
  int? _selectedCategoryId;
  int? _selectedWalletId;
  DateTime _selectedDate = DateTime.now();
  final _noteController = TextEditingController();
  bool _defaultSet = false;

  // Numpad keys layout: 4 rows of 4
  static const _numpadKeys = [
    ['1', '2', '3', '⌫'],
    ['4', '5', '6', 'C'],
    ['7', '8', '9', '000'],
    ['.', '0', '✓'],
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _onNumpadPress(String key) {
    setState(() {
      switch (key) {
        case '⌫':
          if (_amountText.isNotEmpty) {
            _amountText = _amountText.substring(0, _amountText.length - 1);
          }
          if (_amountText.isEmpty) _amountText = '0';
        case 'C':
          _amountText = '0';
        case '✓':
          _numpadActive = false;
        case '000':
          if (_amountText != '0') {
            _amountText += '000';
          }
        case '.':
          if (!_amountText.contains('.')) {
            _amountText += '.';
          }
        default:
          if (_amountText == '0' && key != '.') {
            _amountText = key;
          } else {
            _amountText += key;
          }
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.sf(context),
              onSurface: AppColors.txt(context),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _saveTransaction() {
    final amount = double.tryParse(_amountText) ?? 0.0;
    if (amount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an amount'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final transaction = Transaction()
      ..amount = amount
      ..type = _type
      ..categoryId = _selectedCategoryId ?? 0
      ..walletId = _selectedWalletId ?? 0
      ..note = _noteController.text
      ..date = _selectedDate
      ..createdAt = DateTime.now();

    ref.read(transactionsProvider.notifier).addTransaction(transaction);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_type == TransactionType.income ? 'Income' : 'Expense'} saved: ${CurrencyFormatter.format(amount)}',
        ),
        backgroundColor: AppColors.secondary,
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final walletsAsync = ref.watch(walletsProvider);

    if (!_defaultSet && _selectedWalletId == null) {
      walletsAsync.whenData((wallets) {
        for (final w in wallets) {
          if (w.isDefault) {
            _selectedWalletId = w.id;
            _defaultSet = true;
            break;
          }
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildDragHandle(),
            _buildTypeToggle(),
            _buildAmountDisplay(),
            Expanded(
              child: _numpadActive
                  ? _buildNumpad()
                  : _buildFormContent(categoriesAsync, walletsAsync),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.txtMut(context),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.sf(context),
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        child: Row(
          children: [
            _buildToggleOption(
              label: 'INCOME',
              isSelected: _type == TransactionType.income,
              selectedColor: AppColors.secondary,
              onTap: () => setState(() => _type = TransactionType.income),
            ),
            _buildToggleOption(
              label: 'EXPENSE',
              isSelected: _type == TransactionType.expense,
              selectedColor: AppColors.danger,
              onTap: () => setState(() => _type = TransactionType.expense),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleOption({
    required String label,
    required bool isSelected,
    required Color selectedColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: isSelected ? selectedColor : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.chip - 3),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTypography.labelBold(context).copyWith(
                color: isSelected ? Colors.white : AppColors.txtMut(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountDisplay() {
    final displayAmount = _amountText == '0' ? 'Rp 0' : 'Rp $_amountText';
    final isActive = _type == TransactionType.income
        ? AppColors.secondary
        : AppColors.danger;

    return GestureDetector(
      onTap: () => setState(() => _numpadActive = true),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Column(
          children: [
            Text(
              _type == TransactionType.income ? 'Income' : 'Expense',
              style: AppTypography.bodyS(context).copyWith(
                color: isActive,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              displayAmount,
              style: AppTypography.displayLarge(context).copyWith(
                color: _amountText == '0'
                    ? AppColors.txtMut(context)
                    : AppColors.txt(context),
              ),
            ),
            if (!_numpadActive)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  'Tap to enter amount',
                  style: AppTypography.bodyS(context).copyWith(
                    color: AppColors.txtMut(context),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              children: _numpadKeys.map((row) {
                return Expanded(
                  child: Row(
                    children: row.map((key) {
                      return Expanded(
                        child: _buildNumpadKey(key),
                      );
                    }).toList(),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        _buildCategoryChips(),
      ],
    );
  }

  Widget _buildNumpadKey(String key) {
    final isSpecial = key == '⌫' || key == 'C' || key == '✓';
    final isConfirm = key == '✓';

    Color bgColor = AppColors.sf(context);
    Color textColor = AppColors.txt(context);
    if (key == '⌫') {
      bgColor = AppColors.sfElevated(context);
      textColor = AppColors.danger;
    } else if (key == 'C') {
      bgColor = AppColors.sfElevated(context);
      textColor = AppColors.warning;
    } else if (isConfirm) {
      bgColor = AppColors.primary;
      textColor = Colors.white;
    }

    return Padding(
      padding: const EdgeInsets.all(4),
      child: GestureDetector(
        onTap: () => _onNumpadPress(key),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: isConfirm
                ? null
                : Border.all(color: AppColors.bdr(context)),
          ),
          child: Center(
            child: isConfirm
                ? const Icon(Iconsax.tick_circle, color: Colors.white, size: 24)
                : Text(
                    key,
                    style: AppTypography.headingM(context).copyWith(
                      color: textColor,
                      fontWeight: isSpecial ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Consumer(
      builder: (context, ref, _) {
        return ref.watch(categoriesProvider).when(
              data: (categories) {
                final filtered = categories
                    .where((c) =>
                        c.type == (_type == TransactionType.income
                            ? CategoryType.income
                            : CategoryType.expense))
                    .toList();
                return SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final cat = filtered[index];
                      return CategoryChip(
                        label: cat.name,
                        color: _parseColor(cat.colorHex),
                        isSelected: _selectedCategoryId == cat.id,
                        onTap: () =>
                            setState(() => _selectedCategoryId = cat.id),
                      );
                    },
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            );
      },
    );
  }

  Widget _buildFormContent(
    AsyncValue<List<Category>> categoriesAsync,
    AsyncValue<List<Wallet>> walletsAsync,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          _buildCategorySelector(categoriesAsync),
          const SizedBox(height: AppSpacing.md),
          _buildWalletAndDateRow(walletsAsync),
          const SizedBox(height: AppSpacing.md),
          _buildNoteField(),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Save Transaction',
            onPressed: _saveTransaction,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildCategorySelector(AsyncValue<List<Category>> categoriesAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: AppTypography.headingS(context).copyWith(
            color: AppColors.txtSec(context),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 40,
          child: categoriesAsync.when(
            data: (categories) {
              final filtered = categories
                  .where((c) =>
                      c.type == (_type == TransactionType.income
                          ? CategoryType.income
                          : CategoryType.expense))
                  .toList();
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: filtered.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final cat = filtered[index];
                  return CategoryChip(
                    label: cat.name,
                    color: _parseColor(cat.colorHex),
                    isSelected: _selectedCategoryId == cat.id,
                    onTap: () => setState(() => _selectedCategoryId = cat.id),
                  );
                },
              );
            },
            loading: () => const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, __) => Text(
              'Failed to load categories',
              style: AppTypography.bodyS(context).copyWith(color: AppColors.danger),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWalletAndDateRow(AsyncValue<List<Wallet>> walletsAsync) {
    return Row(
      children: [
        Expanded(child: _buildWalletSelector(walletsAsync)),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: _buildDatePicker()),
      ],
    );
  }

  Widget _buildWalletSelector(AsyncValue<List<Wallet>> walletsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wallet',
          style: AppTypography.headingS(context).copyWith(
            color: AppColors.txtSec(context),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        GlassCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: walletsAsync.when(
            data: (wallets) {
              return DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  isDense: true,
                  isExpanded: true,
                  value: _selectedWalletId,
                  hint: Text(
                    'Select wallet',
                    style: AppTypography.bodyS(context),
                  ),
                  icon: Icon(
                    Iconsax.arrow_down_1,
                    color: AppColors.txtSec(context),
                    size: 18,
                  ),
                  dropdownColor: AppColors.sfElevated(context),
                  style: AppTypography.bodyM(context),
                  items: wallets.map((wallet) {
                    return DropdownMenuItem<int>(
                      value: wallet.id,
                      child: Row(
                        children: [
                          Icon(
                            _getWalletIcon(wallet.iconName),
                            color: _parseColor(wallet.colorHex),
                            size: 16,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(wallet.name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (id) {
                    if (id != null) {
                      setState(() => _selectedWalletId = id);
                    }
                  },
                ),
              );
            },
            loading: () => const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, __) => Text(
              'Error',
              style: AppTypography.bodyS(context).copyWith(color: AppColors.danger),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date',
          style: AppTypography.headingS(context).copyWith(
            color: AppColors.txtSec(context),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: _pickDate,
          child: GlassCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateHelper.formatDateShort(_selectedDate),
                  style: AppTypography.bodyM(context),
                ),
                Icon(
                  Iconsax.calendar,
                  color: AppColors.txtSec(context),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Note',
          style: AppTypography.headingS(context).copyWith(
            color: AppColors.txtSec(context),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _noteController,
          style: AppTypography.bodyL(context),
          maxLines: 1,
          decoration: InputDecoration(
            hintText: 'Add a note...',
            hintStyle: AppTypography.bodyL(context).copyWith(
              color: AppColors.txtMut(context),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.bdr(context)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
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