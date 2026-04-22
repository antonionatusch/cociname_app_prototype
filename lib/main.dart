import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/config/app_env.dart';
import 'src/core/theme/app_theme.dart';
import 'src/features/auth/login_screen.dart';
import 'src/features/auth/register_screen.dart';
import 'src/features/auth/reset_password_screen.dart';
import 'src/features/auth/verify_identity_args.dart';
import 'src/features/auth/verify_identity_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Supabase.initialize(
    url: dotenv.get(AppEnv.supabaseUrl),
    anonKey: dotenv.get(AppEnv.supabaseAnonKey),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CocinaME',
      theme: AppTheme.light(),
      initialRoute: LoginScreen.routeName,
      routes: {
        LoginScreen.routeName: (_) => const LoginScreen(),
        RegisterScreen.routeName: (_) => const RegisterScreen(),
        ResetPasswordScreen.routeName: (_) => const ResetPasswordScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == VerifyIdentityScreen.routeName) {
          final args = settings.arguments as VerifyIdentityArgs;
          return MaterialPageRoute(
            builder: (_) => VerifyIdentityScreen(args: args),
          );
        }
        return null;
      },
    );
  }
}
