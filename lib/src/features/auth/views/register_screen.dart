import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/verification_method.dart';
import '../repositories/auth_repository.dart';
import '../viewmodels/register_viewmodel.dart';
import 'verify_identity_screen.dart';
import 'widgets/auth_shell.dart';

const _signUpTimeoutMessage =
    'El sistema esta tardando más de lo esperado. Intenta mas tarde.';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.authRepository});

  final AuthRepository authRepository;

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
  late final RegisterViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = RegisterViewModel(widget.authRepository);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final args = await _viewModel.signUp(
        identifier: _identifierController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
      );

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (_) => VerifyIdentityScreen(
                authRepository: widget.authRepository,
                args: args,
              ),
        ),
      );
    } on IdentifierAlreadyTakenException catch (error) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..removeCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(error.message),
            action: SnackBarAction(
              label: 'INICIAR SESION',
              onPressed: () => Navigator.of(context).pop(),
            ),
            duration: Duration(seconds: 5),
            persist: false,
          ),
        );
    } on SignUpTimeoutException catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(_signUpTimeoutMessage),
          duration: Duration(seconds: 7),
        ),
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..removeCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final isEmail = _viewModel.method == VerificationMethod.email;

        return AuthShell(
          title: 'Crea tu cuenta',
          subtitle:
              'Empieza con correo o telefono y luego completa tu perfil gastronomico segun el rol que elijas.',
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
                  selected: {_viewModel.method},
                  onSelectionChanged: (value) {
                    _viewModel.selectMethod(value.first);
                    _identifierController.clear();
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
                      isEmail
                          ? TextInputType.emailAddress
                          : TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: isEmail ? 'Correo' : 'Telefono',
                    hintText: isEmail ? 'nombre@correo.com' : '+59170000001',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return isEmail
                          ? 'Ingresa tu correo.'
                          : 'Ingresa tu telefono.';
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
                  decoration: const InputDecoration(
                    labelText: 'Confirmar contrasena',
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Las contrasenas no coinciden.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _viewModel.submitting ? null : _submit,
                  child: Text(
                    _viewModel.submitting
                        ? 'Creando cuenta...'
                        : 'Crear cuenta',
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Ya tengo una cuenta'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
