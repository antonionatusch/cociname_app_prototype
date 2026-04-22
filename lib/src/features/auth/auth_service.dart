import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<void> signUpWithEmail({
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
  }

  Future<void> signUpWithPhone({
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
    await _client.auth.verifyOTP(
      type: OtpType.sms,
      phone: phone,
      token: token,
    );
  }

  Future<void> resendPhoneOtp(String phone) async {
    await _client.auth.signInWithOtp(phone: phone);
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }
}
