import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_env.dart';
import 'auth_service.dart';
import 'auth_shell.dart';
import 'verify_identity_args.dart';

class VerifyIdentityScreen extends StatefulWidget {
  const VerifyIdentityScreen({super.key, required this.args});

  static const routeName = '/verify-identity';

  final VerifyIdentityArgs args;

  @override
  State<VerifyIdentityScreen> createState() => _VerifyIdentityScreenState();
}

class _VerifyIdentityScreenState extends State<VerifyIdentityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _authService = AuthService();
  bool _submitting = false;
  bool _resending = false;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _verifyPhone() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      await _authService.verifyPhoneOtp(
        phone: widget.args.identifier,
        token: _tokenController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Telefono verificado correctamente.')),
      );
      Navigator.popUntil(context, ModalRoute.withName('/'));
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _resendPhoneCode() async {
    setState(() => _resending = true);
    try {
      await _authService.resendPhoneOtp(widget.args.identifier);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Codigo reenviado.')),
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmail = widget.args.method == VerificationMethod.email;
    final testPhone = dotenv.maybeGet(AppEnv.supabaseTestPhone);
    final testOtp = dotenv.maybeGet(AppEnv.supabaseTestOtp);

    return AuthShell(
      title: 'Verifica tu identidad',
      subtitle: isEmail
          ? 'Tu cuenta se activara cuando confirmes el enlace enviado al correo registrado.'
          : 'Ingresa el codigo OTP enviado a tu telefono para activar la cuenta.',
      child: isEmail
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
                  'Cuando ya hayas confirmado tu correo, vuelve e inicia sesion normalmente.',
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.popUntil(context, ModalRoute.withName('/')),
                  child: const Text('Ya confirme mi correo'),
                ),
              ],
            )
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.args.identifier == testPhone && testOtp != null)
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
                    onPressed: _submitting ? null : _verifyPhone,
                    child: Text(_submitting ? 'Verificando...' : 'Verificar telefono'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _resending ? null : _resendPhoneCode,
                    child: Text(_resending ? 'Reenviando...' : 'Reenviar codigo'),
                  ),
                ],
              ),
            ),
    );
  }
}
