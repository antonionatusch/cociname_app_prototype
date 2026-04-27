import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/verification_method.dart';
import '../models/verify_identity_args.dart';

class AuthRepository {
  AuthRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<VerifyIdentityArgs> signUpWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'first_name': firstName,
        'last_name': lastName,
        'full_name': '$firstName $lastName',
      },
    );

    return VerifyIdentityArgs(
      method: VerificationMethod.email,
      identifier: email,
    );
  }

  Future<VerifyIdentityArgs> signUpWithPhone({
    required String phone,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    await _client.auth.signUp(
      phone: phone,
      password: password,
      data: {
        'first_name': firstName,
        'last_name': lastName,
        'full_name': '$firstName $lastName',
      },
    );

    return VerifyIdentityArgs(
      method: VerificationMethod.phone,
      identifier: phone,
    );
  }

  Future<void> signIn({
    required String identifier,
    required String password,
  }) async {
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (emailPattern.hasMatch(identifier)) {
      await _client.auth.signInWithPassword(
        email: identifier,
        password: password,
      );
      return;
    }

    await _client.auth.signInWithPassword(
      phone: identifier,
      password: password,
    );
  }

  Future<void> verifyPhoneOtp({
    required String phone,
    required String token,
  }) async {
    await _client.auth.verifyOTP(type: OtpType.sms, phone: phone, token: token);
  }

  Future<void> resendPhoneOtp(String phone) async {
    await _client.auth.signInWithOtp(phone: phone);
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
