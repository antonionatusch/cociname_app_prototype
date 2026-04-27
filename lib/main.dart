import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/app/auth_gate_screen.dart';
import 'src/config/app_env.dart';
import 'src/core/theme/app_theme.dart';
import 'src/features/auth/repositories/auth_repository.dart';
import 'src/features/onboarding/repositories/onboarding_repository.dart';

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
    final authRepository = AuthRepository();
    final onboardingRepository = OnboardingRepository();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CocinaME',
      theme: AppTheme.light(),
      home: AuthGateScreen(
        authRepository: authRepository,
        onboardingRepository: onboardingRepository,
      ),
    );
  }
}
