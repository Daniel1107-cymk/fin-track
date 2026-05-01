import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/services/biometric_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/security_settings_provider.dart';

/// Result returned when the biometric lock screen is popped.
///
/// Indicates how the user authenticated or whether they chose
/// to fall back to PIN entry.
enum BiometricLockResult {
  /// Biometric authentication succeeded.
  authenticated,

  /// User chose to enter PIN instead.
  usePin,
}

/// Full-screen biometric lock screen.
///
/// On mount, automatically triggers biometric authentication.
/// Handles all [BiometricResult] cases with appropriate UI and
/// offers a PIN fallback when [securitySettingsProvider.pinEnabled]
/// is true.
class BiometricLockScreen extends ConsumerStatefulWidget {
  const BiometricLockScreen({super.key});

  @override
  ConsumerState<BiometricLockScreen> createState() =>
      _BiometricLockScreenState();
}

class _BiometricLockScreenState extends ConsumerState<BiometricLockScreen> {
  /// Current authentication state driving the UI.
  _AuthState _state = _AuthState.authenticating;

  /// Human-readable message shown below the status icon.
  String _message = 'Authenticating...';

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    if (!mounted) return;

    setState(() {
      _state = _AuthState.authenticating;
      _message = 'Authenticating...';
    });

    final result = await BiometricService().authenticate(
      reason: 'Authenticate to access FinTrack',
    );

    if (!mounted) return;

    switch (result) {
      case BiometricResult.success:
        setState(() {
          _state = _AuthState.success;
          _message = 'Authenticated';
        });
        // Brief visual confirmation before popping.
        await Future.delayed(const Duration(milliseconds: 400));
        if (mounted) {
          Navigator.of(context).pop(BiometricLockResult.authenticated);
        }
      case BiometricResult.failure:
        setState(() {
          _state = _AuthState.failure;
          _message = 'Authentication failed';
        });
      case BiometricResult.notAvailable:
        setState(() {
          _state = _AuthState.notAvailable;
          _message = 'No biometrics enrolled. Use PIN instead?';
        });
      case BiometricResult.notEnrolled:
        setState(() {
          _state = _AuthState.notEnrolled;
          _message = 'No biometrics enrolled. Use PIN instead?';
        });
      case BiometricResult.lockedOut:
        setState(() {
          _state = _AuthState.lockedOut;
          _message = 'Biometric locked out. Use PIN instead?';
        });
      case BiometricResult.error:
        setState(() {
          _state = _AuthState.failure;
          _message = 'Authentication error. Please try again.';
        });
    }
  }

  void _usePinInstead() {
    Navigator.of(context).pop(BiometricLockResult.usePin);
  }

  @override
  Widget build(BuildContext context) {
    final securitySettings = ref.watch(securitySettingsProvider).valueOrNull;
    final pinEnabled = securitySettings?.pinEnabled ?? false;
    final isAuthenticating = _state == _AuthState.authenticating;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.bg(context),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: AppSpacing.xxl),
                  // App logo
                  _LogoIcon(),
                  const SizedBox(height: AppSpacing.xl),
                  // Status icon + loading
                  _StatusIcon(state: _state),
                  const SizedBox(height: AppSpacing.lg),
                  // Message
                  Text(
                    _message,
                    textAlign: TextAlign.center,
                    style: AppTypography.headingM(context).copyWith(
                      color: _stateTextColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Retry button (shown on failure / error states)
                  if (!isAuthenticating && _canRetry)
                    _RetryButton(onPressed: _authenticate),
                  const SizedBox(height: AppSpacing.md),
                  // PIN fallback (always shown when pinEnabled and not
                  // already authenticated)
                  if (pinEnabled && !isAuthenticating && _state != _AuthState.success)
                    _PinFallbackButton(onPressed: _usePinInstead),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool get _canRetry {
    return _state == _AuthState.failure ||
        _state == _AuthState.error;
  }

  Color get _stateTextColor {
    switch (_state) {
      case _AuthState.success:
        return AppColors.secondary;
      case _AuthState.failure:
      case _AuthState.error:
        return AppColors.danger;
      case _AuthState.lockedOut:
        return AppColors.warning;
      default:
        return AppColors.txt(context);
    }
  }
}

// ---------------------------------------------------------------------------
// Internal state enum
// ---------------------------------------------------------------------------

enum _AuthState {
  authenticating,
  success,
  failure,
  notAvailable,
  notEnrolled,
  lockedOut,
  error,
}

// ---------------------------------------------------------------------------
// Supporting widgets
// ---------------------------------------------------------------------------

class _LogoIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGlow,
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Iconsax.wallet,
          size: 40,
          color: AppColors.txt(context),
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final _AuthState state;

  const _StatusIcon({required this.state});

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      _AuthState.authenticating => SizedBox(
          width: 64,
          height: 64,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
              const Icon(
                Iconsax.finger_scan,
                size: 32,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      _AuthState.success => Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.secondary.withValues(alpha: 0.15),
          ),
          child: const Icon(
            Iconsax.tick_circle,
            size: 36,
            color: AppColors.secondary,
          ),
        ),
      _AuthState.failure ||
      _AuthState.error =>
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.danger.withValues(alpha: 0.15),
          ),
          child: const Icon(
            Iconsax.close_circle,
            size: 36,
            color: AppColors.danger,
          ),
        ),
      _AuthState.lockedOut => Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.warning.withValues(alpha: 0.15),
          ),
          child: const Icon(
            Iconsax.lock,
            size: 36,
            color: AppColors.warning,
          ),
        ),
      _AuthState.notAvailable ||
      _AuthState.notEnrolled =>
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.txtMut(context).withValues(alpha: 0.15),
          ),
          child: Icon(
            Iconsax.finger_scan,
            size: 36,
            color: AppColors.txtMut(context),
          ),
        ),
    };
  }
}

class _RetryButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _RetryButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.txt(context),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          elevation: 0,
        ),
        child: Text('Try Again', style: AppTypography.labelBold(context)),
      ),
    );
  }
}

class _PinFallbackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _PinFallbackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.txtSec(context),
          side: BorderSide(color: AppColors.bdr(context), width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
        child: Text('Use PIN Instead', style: AppTypography.labelBold(context)),
      ),
    );
  }
}