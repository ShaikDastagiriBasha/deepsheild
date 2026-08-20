import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Show the app UI immediately without blocking on heavy initializations.
  // Initialization is handled asynchronously inside the SplashScreen.
  runApp(const DeepShieldApp());
}

class DeepShieldApp extends StatelessWidget {
  const DeepShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DeepShield AI KYC',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}