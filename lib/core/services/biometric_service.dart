import 'dart:async';

import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

/// Result of a biometric authentication attempt.
enum BiometricResult {
  /// Authentication succeeded.
  success,

  /// Authentication failed (e.g., wrong fingerprint).
  failure,

  /// Biometrics are not available on this device.
  notAvailable,

  /// No biometrics are enrolled on this device.
  notEnrolled,

  /// Biometrics are locked out (too many failed attempts).
  lockedOut,

  /// An unexpected error occurred.
  error,
}

/// Service that wraps [LocalAuthentication] for biometric and device
/// credential authentication.
///
/// Uses a singleton pattern — call [BiometricService()] to access the shared
/// instance.
class BiometricService {
  static final BiometricService _instance = BiometricService._();
  factory BiometricService() => _instance;

  final LocalAuthentication _auth = LocalAuthentication();

  BiometricService._();

  /// Returns `true` if the device supports biometric authentication *and*
  /// biometrics are enrolled.
  Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } on PlatformException {
      return false;
    }
  }

  /// Returns the list of [BiometricType]s the device has enrolled.
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  /// Prompts the user to authenticate with biometrics or device credentials
  /// (PIN/pattern/password).
  ///
  /// [reason] is shown in the system authentication dialog.
  ///
  /// Returns a [BiometricResult] indicating the outcome.
  Future<BiometricResult> authenticate({required String reason}) async {
    try {
      final success = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(biometricOnly: false),
      );
      return success ? BiometricResult.success : BiometricResult.failure;
    } on PlatformException catch (e) {
      switch (e.code) {
        case auth_error.notAvailable:
          return BiometricResult.notAvailable;
        case auth_error.notEnrolled:
          return BiometricResult.notEnrolled;
        case auth_error.lockedOut:
          return BiometricResult.lockedOut;
        default:
          return BiometricResult.error;
      }
    }
  }
}
