import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

import '../services/biometric_service.dart';

/// Keys for SharedPreferences persistence
const _biometricEnabledKey = 'biometric_enabled';
const _pinEnabledKey = 'pin_enabled';
const _hashedPinKey = 'hashed_pin';

/// Immutable data class for security settings
class SecuritySettings {
  final bool biometricEnabled;
  final bool pinEnabled;
  final String? hashedPin;

  const SecuritySettings({
    this.biometricEnabled = false,
    this.pinEnabled = false,
    this.hashedPin,
  });

  bool get hasPinSet => hashedPin != null && hashedPin!.isNotEmpty;

  SecuritySettings copyWith({
    bool? biometricEnabled,
    bool? pinEnabled,
    String? hashedPin,
    bool clearHashedPin = false,
  }) {
    return SecuritySettings(
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      pinEnabled: pinEnabled ?? this.pinEnabled,
      hashedPin: clearHashedPin ? null : (hashedPin ?? this.hashedPin),
    );
  }
}

/// Notifier managing security settings with SharedPreferences persistence.
/// Uses SHA-256 hashing for PIN storage.
class SecuritySettingsNotifier extends AsyncNotifier<SecuritySettings> {
  late SharedPreferences _prefs;

  @override
  Future<SecuritySettings> build() async {
    _prefs = await SharedPreferences.getInstance();
    final biometricEnabled = _prefs.getBool(_biometricEnabledKey) ?? false;
    final pinEnabled = _prefs.getBool(_pinEnabledKey) ?? false;
    final hashedPin = _prefs.getString(_hashedPinKey);
    return SecuritySettings(
      biometricEnabled: biometricEnabled,
      pinEnabled: pinEnabled,
      hashedPin: hashedPin,
    );
  }

  /// Toggle biometric lock on/off
  Future<void> toggleBiometric(bool value) async {
    await _prefs.setBool(_biometricEnabledKey, value);
    final current = state.valueOrNull ?? const SecuritySettings();
    state = AsyncValue.data(current.copyWith(biometricEnabled: value));
  }

  /// Toggle PIN lock on/off
  Future<void> togglePin(bool value) async {
    await _prefs.setBool(_pinEnabledKey, value);
    final current = state.valueOrNull ?? const SecuritySettings();
    state = AsyncValue.data(current.copyWith(pinEnabled: value));
  }

  /// Set a new PIN. Hashes with SHA-256 before storing.
  /// [pin] must be a 6-digit string.
  Future<void> setPin(String pin) async {
    final hash = sha256.convert(utf8.encode(pin)).toString();
    await _prefs.setString(_hashedPinKey, hash);
    final current = state.valueOrNull ?? const SecuritySettings();
    state = AsyncValue.data(current.copyWith(hashedPin: hash));
  }

  /// Verify a PIN against the stored hash. Returns true if match.
  bool verifyPin(String pin) {
    final current = state.valueOrNull;
    if (current == null || current.hashedPin == null) return false;
    final hash = sha256.convert(utf8.encode(pin)).toString();
    return hash == current.hashedPin;
  }

  /// Clear the stored PIN (disable PIN lock)
  Future<void> clearPin() async {
    await _prefs.remove(_hashedPinKey);
    await _prefs.setBool(_pinEnabledKey, false);
    final current = state.valueOrNull ?? const SecuritySettings();
    state = AsyncValue.data(current.copyWith(clearHashedPin: true, pinEnabled: false));
  }

  /// Clear ALL security settings (used when user clears all app data)
  Future<void> clearAll() async {
    await _prefs.remove(_biometricEnabledKey);
    await _prefs.remove(_pinEnabledKey);
    await _prefs.remove(_hashedPinKey);
    state = const AsyncValue.data(SecuritySettings());
  }
}

/// Provider for security settings with SharedPreferences persistence.
final securitySettingsProvider =
    AsyncNotifierProvider<SecuritySettingsNotifier, SecuritySettings>(
  () => SecuritySettingsNotifier(),
);

/// Whether biometric hardware is available on this device.
final biometricAvailableProvider = FutureProvider<bool>((ref) {
  return BiometricService().isAvailable();
});