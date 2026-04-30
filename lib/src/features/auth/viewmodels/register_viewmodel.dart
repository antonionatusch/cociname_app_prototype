import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../config/app_env.dart';
import '../models/verification_method.dart';
import '../models/verify_identity_args.dart';
import '../repositories/auth_repository.dart';

class SignUpTimeoutException implements Exception {
  const SignUpTimeoutException(this.message);
  final String message;
}

class RegisterViewModel extends ChangeNotifier {
  RegisterViewModel(this._authRepository);

  final AuthRepository _authRepository;

  VerificationMethod method = VerificationMethod.email;
  bool _submitting = false;

  bool get submitting => _submitting;

  void selectMethod(VerificationMethod value) {
    if (method == value) return;
    method = value;
    notifyListeners();
  }

  Future<VerifyIdentityArgs> signUp({
    required String identifier,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    _submitting = true;
    notifyListeners();

    try {
      final shouldSimulateSlow =
          dotenv.maybeGet(AppEnv.simulateSlowSignup) == 'true';

      Future<VerifyIdentityArgs> performSignup() async {
        if (shouldSimulateSlow) {
          await Future.delayed(const Duration(seconds: 6));
        }

        if (method == VerificationMethod.email) {
          return await _authRepository.signUpWithEmail(
            email: identifier,
            password: password,
            firstName: firstName,
            lastName: lastName,
          );
        }

        return await _authRepository.signUpWithPhone(
          phone: identifier,
          password: password,
          firstName: firstName,
          lastName: lastName,
        );
      }

      return await performSignup().timeout(
        const Duration(seconds: 5),
        onTimeout:
            () =>
                throw const SignUpTimeoutException(
                  'El sistema esta tardando más de lo esperado. Intenta mas tarde.',
                ),
      );
    } on SignUpTimeoutException {
      rethrow;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }
}
