import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService extends ChangeNotifier {
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> authenticate({
    String localizedReason = 'Please authenticate to proceed',
  }) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }
}
