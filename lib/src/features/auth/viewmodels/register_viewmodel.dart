import 'package:flutter/foundation.dart';

import '../models/verification_method.dart';
import '../models/verify_identity_args.dart';
import '../repositories/auth_repository.dart';

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
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }
}
