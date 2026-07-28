import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

/// Thin wrapper over `local_auth` for the optional app lock. Every call is
/// guarded so a device without biometrics (or a widget test) simply reports
/// "not available / not authenticated" instead of throwing.
class AuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Whether the device can do any local authentication (biometric or PIN).
  Future<bool> canAuthenticate() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (e) {
      debugPrint('AuthService.canAuthenticate failed: $e');
      return false;
    }
  }

  /// Prompts the user. Returns true only on success. Allows the device
  /// passcode as a fallback (biometricOnly: false).
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(stickyAuth: true),
      );
    } catch (e) {
      debugPrint('AuthService.authenticate failed: $e');
      return false;
    }
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
