import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/security_settings_provider.dart';
import '../../core/services/biometric_service.dart';
import '../../core/theme/app_colors.dart';
import 'app_lifecycle_observer.dart';
import 'biometric_lock_screen.dart';
import 'pin_lock_screen.dart';

/// Gate widget that conditionally shows the appropriate lock screen
/// or the app content below.
///
/// Decision logic:
/// - If no lock is enabled (`!biometricEnabled && !pinEnabled`) → show child.
/// - If any lock is enabled AND auth is required → show lock screen on top
///   via [Stack] overlay (not Navigator push).
/// - Biometric is primary; PIN is fallback (manual via
///   [BiometricLockResult.usePin]).
/// - On successful unlock → [AppLifecycleNotifier.resetAuth] is called so the
///   gate removes the lock and reveals the child.
class LockGate extends ConsumerStatefulWidget {
  const LockGate({super.key, required this.child});

  /// The app content shown when the lock is disabled or already passed.
  final Widget child;

  @override
  ConsumerState<LockGate> createState() => _LockGateState();
}

class _LockGateState extends ConsumerState<LockGate> {
  /// Prevents concurrent lock-screen pushes.
  bool _isShowingLock = false;

  /// Semaphore so we don't re-lock after the user has authenticated during
  /// the current foreground session.
  bool _hasAuthenticatedThisSession = false;

  /// Which lock screen to show: biometric or PIN.
  _LockScreen _activeLockScreen = _LockScreen.none;

  @override
  void initState() {
    super.initState();
    // Schedule after first frame so the Navigator is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryShowLock();
    });
  }

  // ── Gate trigger ──────────────────────────────────────────────────────────

  /// Attempts to show the lock screen if conditions are met.
  ///
  /// Checks biometric availability BEFORE setting any state so we know
  /// synchronously which screen to display.
  Future<void> _tryShowLock() async {
    if (kDebugMode) return;
    if (_isShowingLock || _hasAuthenticatedThisSession) return;

    final settings = ref.read(securitySettingsProvider).valueOrNull;
    if (settings == null) return;

    final needsAuth = ref.read(appLifecycleProvider);
    if (!needsAuth) return;
    if (!settings.biometricEnabled && !settings.pinEnabled) return;

    // Check biometric availability before deciding which screen to push.
    bool biometricAvailable = false;
    if (settings.biometricEnabled) {
      try {
        biometricAvailable = await BiometricService().isAvailable();
      } catch (_) {
        biometricAvailable = false;
      }
    }

    if (!mounted) return;

    _isShowingLock = true;
    if (settings.biometricEnabled && biometricAvailable) {
      setState(() => _activeLockScreen = _LockScreen.biometric);
    } else {
      setState(() => _activeLockScreen = _LockScreen.pin);
    }
  }

  /// Called after any successful authentication step.
  void _onUnlocked() {
    setState(() {
      _hasAuthenticatedThisSession = true;
      _isShowingLock = false;
      _activeLockScreen = _LockScreen.none;
    });
    ref.read(appLifecycleProvider.notifier).resetAuth();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) return widget.child;

    // Listen for lifecycle resume events to re-trigger the lock.
    ref.listen(appLifecycleProvider, (previous, next) {
      if (next && !(previous ?? false)) {
        _hasAuthenticatedThisSession = false;
        _tryShowLock();
      }
    });

    // Also re-trigger when security settings finish loading (cold start).
    // The initial _tryShowLock may have run while settings was null.
    ref.listen(securitySettingsProvider, (previous, next) {
      if (!next.isLoading && next.valueOrNull != null) {
        final loaded = next.valueOrNull!;
        if (loaded.biometricEnabled || loaded.pinEnabled) {
          final needsAuth = ref.read(appLifecycleProvider);
          if (needsAuth && !_hasAuthenticatedThisSession) {
            _tryShowLock();
          }
        }
      }
    });

    // Show lock screen via Stack overlay — no Navigator push needed.
    return Stack(
      children: [
        widget.child,
        if (_activeLockScreen == _LockScreen.biometric)
          Positioned.fill(
            child: Material(
              color: AppColors.bg(context),
              child: BiometricLockWidget(onUnlocked: _onUnlocked),
            ),
          ),
        if (_activeLockScreen == _LockScreen.pin)
          Positioned.fill(
            child: Material(
              color: AppColors.bg(context),
              child: PinLockWidget(onUnlocked: _onUnlocked),
            ),
          ),
      ],
    );
  }
}

enum _LockScreen { none, biometric, pin }

// ── Inline lock widgets (no route push needed) ────────────────────────────

class BiometricLockWidget extends ConsumerStatefulWidget {
  const BiometricLockWidget({super.key, required this.onUnlocked});
  final VoidCallback onUnlocked;
  @override
  ConsumerState<BiometricLockWidget> createState() =>
      _BiometricLockWidgetState();
}

class _BiometricLockWidgetState extends ConsumerState<BiometricLockWidget> {
  _AuthState _state = _AuthState.authenticating;
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
        await Future.delayed(const Duration(milliseconds: 400));
        if (mounted) widget.onUnlocked();
      case BiometricResult.failure:
        setState(() {
          _state = _AuthState.failure;
          _message = 'Authentication failed';
        });
      case BiometricResult.notAvailable:
      case BiometricResult.notEnrolled:
      case BiometricResult.lockedOut:
        setState(() {
          _state = _AuthState.lockedOut;
          _message = 'Biometric locked out. Use PIN';
        });
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) widget.onUnlocked();
      case BiometricResult.error:
        setState(() {
          _state = _AuthState.error;
          _message = 'Authentication error';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.bg(context),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 80),
                  _buildLogo(),
                  const SizedBox(height: 40),
                  _buildStatusIcon(),
                  const SizedBox(height: 24),
                  Text(
                    _message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _stateTextColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_state == _AuthState.failure || _state == _AuthState.error)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _authenticate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Try Again'),
                      ),
                    ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.lock,
          size: 40,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    return switch (_state) {
      _AuthState.authenticating => const SizedBox(
          width: 64,
          height: 64,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      _AuthState.success => Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.secondary.withValues(alpha: 0.15),
          ),
          child: const Icon(Icons.check_circle, size: 36, color: AppColors.secondary),
        ),
      _AuthState.failure || _AuthState.error => Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.danger.withValues(alpha: 0.15),
          ),
          child: const Icon(Icons.error, size: 36, color: AppColors.danger),
        ),
      _AuthState.lockedOut => Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.warning.withValues(alpha: 0.15),
          ),
          child: const Icon(Icons.lock, size: 36, color: AppColors.warning),
        ),
      _ => const SizedBox(width: 64, height: 64),
    };
  }

  Color get _stateTextColor {
    return switch (_state) {
      _AuthState.success => AppColors.secondary,
      _AuthState.failure || _AuthState.error => AppColors.danger,
      _AuthState.lockedOut => AppColors.warning,
      _ => AppColors.txt(context),
    };
  }
}

class PinLockWidget extends ConsumerStatefulWidget {
  const PinLockWidget({super.key, required this.onUnlocked});
  final VoidCallback onUnlocked;
  @override
  ConsumerState<PinLockWidget> createState() => _PinLockWidgetState();
}

class _PinLockWidgetState extends ConsumerState<PinLockWidget>
    with TickerProviderStateMixin {
  final List<String> _pinDigits = [];
  int _failedAttempts = 0;
  bool _isLocked = false;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;
  String? _errorMessage;

  late final AnimationController _shakeController;
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
    _shakeAnimation = Tween<double>(begin: 0, end: 12)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _onDigit(String digit) {
    if (_isLocked || !mounted) return;
    if (_pinDigits.length >= _pinLength) return;

    setState(() {
      _pinDigits.add(digit);
      _errorMessage = null;
    });

    if (_pinDigits.length == _pinLength) {
      _verifyPin();
    }
  }

  void _onBackspace() {
    if (_isLocked || !mounted) return;
    if (_pinDigits.isEmpty) return;
    setState(() {
      _pinDigits.removeLast();
      _errorMessage = null;
    });
  }

  void _verifyPin() {
    final pin = _pinDigits.join();
    final isValid = ref.read(securitySettingsProvider.notifier).verifyPin(pin);

    if (isValid) {
      widget.onUnlocked();
    } else {
      _failedAttempts++;
      if (_failedAttempts >= _maxFailedAttempts) {
        _startCooldown();
      } else {
        setState(() {
          _pinDigits.clear();
          _errorMessage = 'Wrong PIN. ${_maxFailedAttempts - _failedAttempts} attempts left.';
        });
        _shakeController.forward(from: 0);
      }
    }
  }

  void _startCooldown() {
    setState(() {
      _isLocked = true;
      _cooldownSeconds = _cooldownDuration;
      _pinDigits.clear();
      _errorMessage = 'Too many attempts. Wait $_cooldownSeconds seconds.';
    });
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _cooldownSeconds--;
        _errorMessage = 'Too many attempts. Wait $_cooldownSeconds seconds.';
      });
      if (_cooldownSeconds <= 0) {
        timer.cancel();
        setState(() {
          _isLocked = false;
          _failedAttempts = 0;
          _errorMessage = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.bg(context),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 80),
              // Logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                ),
                child: const Icon(Icons.lock, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 24),
              Text(
                'Enter PIN',
                style: TextStyle(
                  color: AppColors.txt(context),
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 32),
              // PIN dots
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shakeAnimation.value * ( _shakeController.status == AnimationStatus.forward ? 1 : -1), 0),
                    child: child,
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pinLength, (i) {
                    final filled = i < _pinDigits.length;
                    return Container(
                      width: 16,
                      height: 16,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled
                            ? AppColors.primary
                            : AppColors.txtMut(context).withValues(alpha: 0.3),
                      ),
                    );
                  }),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: AppColors.danger, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
              const Spacer(),
              // Keypad
              _buildKeypad(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          Row(children: [_buildKey('1'), _buildKey('2'), _buildKey('3')]),
          Row(children: [_buildKey('4'), _buildKey('5'), _buildKey('6')]),
          Row(children: [_buildKey('7'), _buildKey('8'), _buildKey('9')]),
          Row(children: [_buildKey(''), _buildKey('0'), _buildKey('⌫', isBackspace: true)]),
        ],
      ),
    );
  }

  Widget _buildKey(String label, {bool isBackspace = false}) {
    final isDisabled = _isLocked && !isBackspace;
    return Expanded(
      child: GestureDetector(
        onTap: isDisabled
            ? null
            : () {
                if (isBackspace) {
                  _onBackspace();
                } else if (label.isNotEmpty) {
                  _onDigit(label);
                }
              },
        child: Container(
          height: 72,
          alignment: Alignment.center,
          child: isBackspace
              ? Icon(
                  Icons.backspace_outlined,
                  color: isDisabled
                      ? AppColors.txtMut(context).withValues(alpha: 0.3)
                      : AppColors.txt(context),
                  size: 28,
                )
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                    color: isDisabled
                        ? AppColors.txtMut(context).withValues(alpha: 0.3)
                        : AppColors.txt(context),
                  ),
                ),
        ),
      ),
    );
  }
}

// ── Shared auth state enum (copied from biometric_lock_screen.dart) ─────────

enum _AuthState {
  authenticating,
  success,
  failure,
  notAvailable,
  notEnrolled,
  lockedOut,
  error,
}
