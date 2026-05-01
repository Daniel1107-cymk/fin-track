import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/security_settings_provider.dart';

/// Two-step PIN creation flow:
/// Step 1 — "Create your 6-digit PIN"
/// Step 2 — "Confirm your PIN"
///
/// On match  → hashes PIN via [SecuritySettingsNotifier.setPin] and pops `true`.
/// On cancel → pops `false` so the caller can revert the toggle.
class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  /// 0 = create, 1 = confirm
  int _step = 0;
  String _pin = '';
  String _confirmPin = '';
  String? _errorMessage;

  static const int _pinLength = 6;

  // ──────────────────────────── lifecycle ────────────────────────────

  void _onDigitPressed(String digit) {
    if (_step == 0) {
      if (_pin.length >= _pinLength) return;
      setState(() {
        _pin += digit;
        _errorMessage = null;
      });
      if (_pin.length == _pinLength) {
        _transitionToConfirm();
      }
    } else {
      if (_confirmPin.length >= _pinLength) return;
      setState(() {
        _confirmPin += digit;
        _errorMessage = null;
      });
      if (_confirmPin.length == _pinLength) {
        _onConfirmComplete();
      }
    }
  }

  void _onBackspace() {
    setState(() {
      if (_step == 0) {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        }
      }
      _errorMessage = null;
    });
  }

  void _transitionToConfirm() {
    // Small delay so the user sees the 6th dot fill before the screen changes.
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _step = 1);
    });
  }

  Future<void> _onConfirmComplete() async {
    if (_confirmPin == _pin) {
      // PINs match — persist and pop success.
      await ref.read(securitySettingsProvider.notifier).setPin(_pin);
      if (mounted) Navigator.of(context).pop(true);
    } else {
      // Mismatch — show error and reset to step 1.
      setState(() {
        _errorMessage = "PINs don't match. Try again.";
        _step = 0;
        _pin = '';
        _confirmPin = '';
      });
    }
  }

  void _onCancel() {
    Navigator.of(context).pop(false);
  }

  // ──────────────────────────── build ────────────────────────────

  @override
  Widget build(BuildContext context) {
    final currentPin = _step == 0 ? _pin : _confirmPin;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const Spacer(),
            _buildDots(currentPin),
            const SizedBox(height: AppSpacing.sm),
            _buildErrorOrHint(),
            const Spacer(),
            _buildKeypad(),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────── header ────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _onCancel,
            icon: Icon(Icons.arrow_back, color: AppColors.txt(context)),
            splashRadius: 20,
          ),
          Expanded(
            child: Text(
              _step == 0 ? 'Create PIN' : 'Confirm PIN',
              style: AppTypography.headingL(context),
              textAlign: TextAlign.center,
            ),
          ),
          // Balance the back button so the title stays centered.
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // ──────────────────────────── dots ────────────────────────────

  Widget _buildDots(String currentPin) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pinLength, (index) {
        final filled = index < currentPin.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? AppColors.primary : Colors.transparent,
            border: Border.all(
              color: filled ? AppColors.primary : AppColors.txtMut(context),
              width: 2,
            ),
          ),
        );
      }),
    );
  }

  // ──────────────────────────── error / hint ────────────────────────────

  Widget _buildErrorOrHint() {
    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Text(
          _errorMessage!,
          style: AppTypography.bodyM(context).copyWith(color: AppColors.danger),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Text(
        _step == 0
            ? 'Create your 6-digit PIN'
            : 'Confirm your 6-digit PIN',
        style: AppTypography.bodyM(context).copyWith(color: AppColors.txtSec(context)),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ──────────────────────────── keypad ────────────────────────────

  Widget _buildKeypad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildKeypadRow(['1', '2', '3']),
          const SizedBox(height: AppSpacing.sm),
          _buildKeypadRow(['4', '5', '6']),
          const SizedBox(height: AppSpacing.sm),
          _buildKeypadRow(['7', '8', '9']),
          const SizedBox(height: AppSpacing.sm),
          _buildBottomRow(),
        ],
      ),
    );
  }

  Widget _buildKeypadRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) => _buildDigitButton(d)).toList(),
    );
  }

  Widget _buildBottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        const SizedBox(width: 72), // spacer for alignment
        _buildDigitButton('0'),
        _buildBackspaceButton(),
      ],
    );
  }

  Widget _buildDigitButton(String digit) {
    return SizedBox(
      width: 72,
      height: 72,
      child: TextButton(
        onPressed: () => _onDigitPressed(digit),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.txt(context),
          backgroundColor: AppColors.sf(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
        child: Text(digit, style: AppTypography.headingM(context)),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return SizedBox(
      width: 72,
      height: 72,
      child: TextButton(
        onPressed: _onBackspace,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.txtSec(context),
          backgroundColor: AppColors.sf(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
        child: const Icon(Icons.backspace_outlined, size: 24),
      ),
    );
  }
}