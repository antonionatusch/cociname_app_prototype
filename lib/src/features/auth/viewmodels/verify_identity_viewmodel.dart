import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/auth_repository.dart';

class VerifyIdentityViewModel extends ChangeNotifier {
  VerifyIdentityViewModel(this._authRepository);

  final AuthRepository _authRepository;

  bool _submitting = false;
  bool _resending = false;

  bool get submitting => _submitting;
  bool get resending => _resending;

  Future<String?> verifyPhone({
    required String phone,
    required String token,
  }) async {
    _submitting = true;
    notifyListeners();

    try {
      await _authRepository.verifyPhoneOtp(phone: phone, token: token);
      return null;
    } on AuthException catch (error) {
      return error.message;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  Future<String?> resendPhoneOtp(String phone) async {
    _resending = true;
    notifyListeners();

    try {
      await _authRepository.resendPhoneOtp(phone);
      return null;
    } on AuthException catch (error) {
      return error.message;
    } finally {
      _resending = false;
      notifyListeners();
    }
  }
}
