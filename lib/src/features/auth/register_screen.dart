import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';
import 'auth_shell.dart';
import 'verify_identity_args.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  static const routeName = '/register';

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  VerificationMethod _method = VerificationMethod.email;
  bool _submitting = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      if (_method == VerificationMethod.email) {
        await _authService.signUpWithEmail(
          email: _identifierController.text.trim(),
          password: _passwordController.text,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
        );
      } else {
        await _authService.signUpWithPhone(
          phone: _identifierController.text.trim(),
          password: _passwordController.text,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
        );
      }

      if (!mounted) return;
      Navigator.pushNamed(
        context,
        '/verify-identity',
        arguments: VerifyIdentityArgs(
          method: _method,
          identifier: _identifierController.text.trim(),
        ),
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmail = _method == VerificationMethod.email;

    return AuthShell(
      title: 'Crea tu cuenta',
      subtitle:
          'Empieza con correo o telefono y luego verifica tu identidad para activar tu acceso.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<VerificationMethod>(
              segments: const [
                ButtonSegment(
                  value: VerificationMethod.email,
                  label: Text('Correo'),
                  icon: Icon(Icons.alternate_email_rounded),
                ),
                ButtonSegment(
                  value: VerificationMethod.phone,
                  label: Text('Telefono'),
                  icon: Icon(Icons.sms_rounded),
                ),
              ],
              selected: {_method},
              onSelectionChanged: (value) {
                setState(() {
                  _method = value.first;
                  _identifierController.clear();
                });
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _firstNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nombres'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa tus nombres.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lastNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Apellidos'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa tus apellidos.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _identifierController,
              keyboardType:
                  isEmail ? TextInputType.emailAddress : TextInputType.phone,
              decoration: InputDecoration(
                labelText: isEmail ? 'Correo' : 'Telefono',
                hintText: isEmail ? 'nombre@correo.com' : '+59170000001',
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) {
                  return isEmail ? 'Ingresa tu correo.' : 'Ingresa tu telefono.';
                }
                if (isEmail && !text.contains('@')) {
                  return 'Ingresa un correo valido.';
                }
                if (!isEmail && !text.startsWith('+')) {
                  return 'Usa formato internacional, por ejemplo +59170000001.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contrasena'),
              validator: (value) {
                if (value == null || value.length < 6) {
                  return 'La contrasena debe tener al menos 6 caracteres.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirmar contrasena'),
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'Las contrasenas no coinciden.';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: Text(_submitting ? 'Creando cuenta...' : 'Crear cuenta'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ya tengo una cuenta'),
            ),
          ],
        ),
      ),
    );
  }
}
