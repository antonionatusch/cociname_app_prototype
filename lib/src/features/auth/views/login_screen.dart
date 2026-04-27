import 'package:flutter/material.dart';

import '../repositories/auth_repository.dart';
import '../viewmodels/login_viewmodel.dart';
import 'register_screen.dart';
import 'reset_password_screen.dart';
import 'widgets/auth_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  late final LoginViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = LoginViewModel(widget.authRepository);
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final error = await _viewModel.signIn(
      identifier: _identifierController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted || error == null) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return AuthShell(
          title: 'Entrar a CocinaME',
          subtitle:
              'Accede con tu correo o telefono para seguir con tus publicaciones, pedidos y perfil gastronomico.',
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _identifierController,
                  decoration: const InputDecoration(
                    labelText: 'Correo o telefono',
                    hintText: 'ejemplo@correo.com o +59170000001',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa tu correo o telefono.';
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
                    if (value == null || value.isEmpty) {
                      return 'Ingresa tu contrasena.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _viewModel.submitting ? null : _submit,
                  child: Text(
                    _viewModel.submitting ? 'Ingresando...' : 'Iniciar sesion',
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (_) => RegisterScreen(
                                  authRepository: widget.authRepository,
                                ),
                          ),
                        );
                      },
                      child: const Text('Crear cuenta'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (_) => ResetPasswordScreen(
                                  authRepository: widget.authRepository,
                                ),
                          ),
                        );
                      },
                      child: const Text('Olvide mi contrasena'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
