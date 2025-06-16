import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:developer';

class EnvValidator {
  /// Validates that all required environment variables are set
  static bool validateEnv(BuildContext? context) {
    final requiredEnvVars = {
      'GEMINI_API_KEY': 'Gemini API key for AI features',
      // Add more required env vars here as needed
    };

    bool isValid = true;
    List<String> missingVars = [];

    for (var entry in requiredEnvVars.entries) {
      final value = dotenv.env[entry.key];
      if (value == null ||
          value.isEmpty ||
          value == 'your_gemini_api_key_here') {
        isValid = false;
        missingVars.add('${entry.key} (${entry.value})');
      }
    }

    if (!isValid && context != null) {
      // Show a helpful error message if any required variables are missing
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Configuration Error'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                const Text(
                  'The application is missing required environment variables:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ...missingVars.map((varName) => Text('• $varName')),
                const SizedBox(height: 10),
                const Text(
                  'Please check your .env file and make sure all required variables are set.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }

    return isValid;
  }

  /// Logs the status of all environment variables (for debugging only)
  static void logEnvStatus() {
    log('Environment Variables Status:');
    final envVars = dotenv.env.entries.toList();

    if (envVars.isEmpty) {
      log('No environment variables found. Check that .env file exists and is properly loaded.');
      return;
    }

    for (var entry in envVars) {
      final key = entry.key;
      final value = entry.value;
      final maskedValue = key.contains('KEY') || key.contains('SECRET')
          ? '${value.substring(0, 3)}...${value.substring(value.length - 3)}'
          : value;

      log('$key: $maskedValue');
    }
  }
}
