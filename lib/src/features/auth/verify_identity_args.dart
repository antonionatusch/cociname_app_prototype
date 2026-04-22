enum VerificationMethod { email, phone }

class VerifyIdentityArgs {
  const VerifyIdentityArgs({
    required this.method,
    required this.identifier,
  });

  final VerificationMethod method;
  final String identifier;
}
