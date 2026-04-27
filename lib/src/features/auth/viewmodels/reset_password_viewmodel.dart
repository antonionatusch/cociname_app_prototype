import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/auth_repository.dart';

class ResetPasswordViewModel extends ChangeNotifier {
  ResetPasswordViewModel(this._authRepository);

  final AuthRepository _authRepository;

  bool _submitting = false;

  bool get submitting => _submitting;

  Future<String?> submit(String email) async {
    _submitting = true;
    notifyListeners();

    try {
      await _authRepository.resetPassword(email);
      return null;
    } on AuthException catch (error) {
      return error.message;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }
}
