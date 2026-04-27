import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../config/app_env.dart';
import '../models/verification_method.dart';
import '../models/verify_identity_args.dart';
import '../repositories/auth_repository.dart';
import '../viewmodels/verify_identity_viewmodel.dart';
import 'widgets/auth_shell.dart';

class VerifyIdentityScreen extends StatefulWidget {
  const VerifyIdentityScreen({
    super.key,
    required this.authRepository,
    required this.args,
  });

  final AuthRepository authRepository;
  final VerifyIdentityArgs args;

  @override
  State<VerifyIdentityScreen> createState() => _VerifyIdentityScreenState();
}

class _VerifyIdentityScreenState extends State<VerifyIdentityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  late final VerifyIdentityViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = VerifyIdentityViewModel(widget.authRepository);
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _verifyPhone() async {
    if (!_formKey.currentState!.validate()) return;

    final error = await _viewModel.verifyPhone(
      phone: widget.args.identifier,
      token: _tokenController.text.trim(),
    );

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Telefono verificado correctamente.')),
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _resendPhoneCode() async {
    final error = await _viewModel.resendPhoneOtp(widget.args.identifier);
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error ?? 'Codigo reenviado.')));
  }

  @override
  Widget build(BuildContext context) {
    final isEmail = widget.args.method == VerificationMethod.email;
    final testPhone = dotenv.maybeGet(AppEnv.supabaseTestPhone);
    final testOtp = dotenv.maybeGet(AppEnv.supabaseTestOtp);

    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return AuthShell(
          title: 'Verifica tu identidad',
          subtitle:
              isEmail
                  ? 'Tu cuenta se activara cuando confirmes el enlace enviado al correo registrado.'
                  : 'Ingresa el codigo OTP enviado a tu telefono para activar la cuenta.',
          child:
              isEmail
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Revisa la bandeja local de correo en Mailpit/Inbucket y abre el mensaje enviado a ${widget.args.identifier}.',
                      ),
                      const SizedBox(height: 16),
                      const ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.mail_outline_rounded),
                        title: Text('Studio Mailpit'),
                        subtitle: Text('http://127.0.0.1:42694'),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Cuando ya hayas confirmado tu correo, vuelve e inicia sesion normalmente para continuar con el onboarding.',
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed:
                            () => Navigator.of(
                              context,
                            ).popUntil((route) => route.isFirst),
                        child: const Text('Volver al inicio'),
                      ),
                    ],
                  )
                  : Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.args.identifier == testPhone &&
                            testOtp != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD7B5),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text('OTP de prueba local: $testOtp'),
                          ),
                        TextFormField(
                          key: const ValueKey('phoneOtpField'),
                          controller: _tokenController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Codigo OTP',
                            hintText: '123456',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().length != 6) {
                              return 'Ingresa el codigo de 6 digitos.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed:
                              _viewModel.submitting ? null : _verifyPhone,
                          child: Text(
                            _viewModel.submitting
                                ? 'Verificando...'
                                : 'Verificar telefono',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed:
                              _viewModel.resending ? null : _resendPhoneCode,
                          child: Text(
                            _viewModel.resending
                                ? 'Reenviando...'
                                : 'Reenviar codigo',
                          ),
                        ),
                      ],
                    ),
                  ),
        );
      },
    );
  }
}
