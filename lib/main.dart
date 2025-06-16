import 'package:ai_food_recognizer_app/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:ai_food_recognizer_app/screens/splash_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ai_food_recognizer_app/utils/env_validator.dart';
import 'dart:developer';
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Pastikan binding diinisialisasi

  // Load .env file
  try {
    await dotenv.load(fileName: ".env");
    // Log environment status in debug mode (masked for security)
    assert(() {
      EnvValidator.logEnvStatus();
      return true;
    }());
  } catch (e) {
    log('ERROR: Failed to load .env file: $e');
    // Continue execution - EnvValidator will show warning dialogs later
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Food Recognizer',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true, // Gunakan Material Design 3
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false, // Hapus banner debug
    );
  }
}
