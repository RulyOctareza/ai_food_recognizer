import 'package:ai_food_recognizer_app/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:ai_food_recognizer_app/screens/home_screen.dart'; // Import HomeScreen
// Import for DefaultFirebaseOptions

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Pastikan binding diinisialisasi
  await Firebase.initializeApp(
    options:
        DefaultFirebaseOptions.currentPlatform, // Gunakan firebase_options.dart
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'AI Food Recognizer', // Tambahkan title yang lebih deskriptif
      home: HomeScreen(), // Ubah home ke HomeScreen
    );
  }
}
