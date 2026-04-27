import 'verification_method.dart';

class VerifyIdentityArgs {
  const VerifyIdentityArgs({required this.method, required this.identifier});

  final VerificationMethod method;
  final String identifier;
}
