import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/auth_repository.dart';

class LoginViewModel extends ChangeNotifier {
  LoginViewModel(this._authRepository);

  final AuthRepository _authRepository;

  bool _submitting = false;

  bool get submitting => _submitting;

  Future<String?> signIn({
    required String identifier,
    required String password,
  }) async {
    _submitting = true;
    notifyListeners();

    try {
      await _authRepository.signIn(identifier: identifier, password: password);
      return null;
    } on AuthException catch (error) {
      return error.message;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }
}
