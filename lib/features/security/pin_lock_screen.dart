import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/security_settings_provider.dart';

class PinLockScreen extends ConsumerStatefulWidget {
  const PinLockScreen({super.key});

  @override
  ConsumerState<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends ConsumerState<PinLockScreen>
    with TickerProviderStateMixin {
  /// Entered PIN digits (never displayed as text — dots only).
  final List<String> _pinDigits = [];

  /// Number of consecutive wrong attempts (local state, not persisted).
  int _failedAttempts = 0;

  /// Whether the keypad is disabled due to cooldown.
  bool _isLocked = false;

  /// Countdown seconds remaining during lockout.
  int _cooldownSeconds = 0;

  /// Timer for the cooldown period.
  Timer? _cooldownTimer;

  /// Error message shown below the dot indicators.
  String? _errorMessage;

  /// Shake animation controller.
  late final AnimationController _shakeController;

  /// Shake offset animation.
  late final Animation<double> _shakeAnimation;

  static const int _pinLength = 6;
  static const int _maxFailedAttempts = 5;
  static const int _cooldownDuration = 30;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 12), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 12, end: -12), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12, end: 10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10, end: 6), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 6, end: 0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  // ── Keypad handlers ──────────────────────────────────────────────────────

  void _onDigitPressed(String digit) {
    if (_isLocked || _pinDigits.length >= _pinLength) return;

    setState(() {
      _pinDigits.add(digit);
      _errorMessage = null;
    });

    if (_pinDigits.length == _pinLength) {
      _validatePin();
    }
  }

  void _onBackspacePressed() {
    if (_isLocked || _pinDigits.isEmpty) return;
    setState(() {
      _pinDigits.removeLast();
      _errorMessage = null;
    });
  }

  // ── PIN validation ───────────────────────────────────────────────────────

  void _validatePin() {
    final pin = _pinDigits.join();
    final isMatch = ref.read(securitySettingsProvider.notifier).verifyPin(pin);

    if (isMatch) {
      _failedAttempts = 0;
      Navigator.of(context).pop(true); // success
    } else {
      _failedAttempts++;
      setState(() {
        _errorMessage = 'Incorrect PIN';
      });
      _shakeController.forward(from: 0);

      if (_failedAttempts >= _maxFailedAttempts) {
        _startCooldown();
      } else {
        // Clear input after shake so user can retry
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _pinDigits.clear();
            });
          }
        });
      }
    }
  }

  // ── Cooldown ─────────────────────────────────────────────────────────────

  void _startCooldown() {
    setState(() {
      _isLocked = true;
      _cooldownSeconds = _cooldownDuration;
      _pinDigits.clear();
    });

    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _cooldownTimer?.cancel();
        return;
      }

      setState(() {
        _cooldownSeconds--;
      });

      if (_cooldownSeconds <= 0) {
        _cooldownTimer?.cancel();
        setState(() {
          _isLocked = false;
          _failedAttempts = 0;
          _errorMessage = null;
          _cooldownSeconds = 0;
        });
      }
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.bg(context),
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 1),
              _buildLogo(),
              const SizedBox(height: AppSpacing.lg),
              _buildTitle(),
              const SizedBox(height: AppSpacing.xl),
              _buildDotIndicators(),
              const SizedBox(height: AppSpacing.sm),
              _buildErrorMessage(),
              const Spacer(flex: 1),
              _buildKeypad(),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  // ── Logo ──────────────────────────────────────────────────────────────────

  Widget _buildLogo() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF9B8FF8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGlow,
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(
        Iconsax.wallet,
        color: Colors.white,
        size: 36,
      ),
    );
  }

  // ── Title ─────────────────────────────────────────────────────────────────

  Widget _buildTitle() {
    return Text(
      'Enter PIN to unlock',
      style: AppTypography.headingL(context).copyWith(
        color: AppColors.txt(context),
      ),
    );
  }

  // ── Dot indicators ───────────────────────────────────────────────────────

  Widget _buildDotIndicators() {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_pinLength, (index) {
          final isFilled = index < _pinDigits.length;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFilled ? AppColors.primary : Colors.transparent,
              border: Border.all(
                color: isFilled ? AppColors.primary : AppColors.txtMut(context),
                width: 2,
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Error / cooldown message ─────────────────────────────────────────────

  Widget _buildErrorMessage() {
    if (_isLocked) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Text(
          'Too many attempts. Try again in $_cooldownSeconds seconds.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyM(context).copyWith(
            color: AppColors.danger,
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Text(
        _errorMessage!,
        style: AppTypography.bodyM(context).copyWith(
          color: AppColors.danger,
        ),
      );
    }

    return const SizedBox(height: 20);
  }

  // ── Numeric keypad ───────────────────────────────────────────────────────

  Widget _buildKeypad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: [
          _buildKeypadRow(['1', '2', '3']),
          const SizedBox(height: AppSpacing.md),
          _buildKeypadRow(['4', '5', '6']),
          const SizedBox(height: AppSpacing.md),
          _buildKeypadRow(['7', '8', '9']),
          const SizedBox(height: AppSpacing.md),
          _buildKeypadRow(['', '0', 'backspace']),
        ],
      ),
    );
  }

  Widget _buildKeypadRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) {
        if (d == 'backspace') {
          return _buildKeypadButton(
            child: Icon(
              Icons.backspace_outlined,
              color: AppColors.txtSec(context),
              size: 24,
            ),
            onTap: _onBackspacePressed,
          );
        }
        if (d.isEmpty) {
          return const SizedBox(width: 72, height: 72);
        }
        return _buildKeypadButton(
          child: Text(
            d,
            style: AppTypography.headingL(context).copyWith(
              color: AppColors.txt(context),
              fontSize: 28,
            ),
          ),
          onTap: () => _onDigitPressed(d),
        );
      }).toList(),
    );
  }

  Widget _buildKeypadButton({
    required Widget child,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isLocked ? null : onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.sfElevated(context),
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(
            color: AppColors.bdr(context),
            width: 1,
          ),
        ),
        child: Center(child: child),
      ),
    );
  }
}