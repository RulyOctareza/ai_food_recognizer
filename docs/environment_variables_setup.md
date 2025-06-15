# Environment Variables Setup

This document explains how to set up environment variables for the AI Food Recognizer App.

## Overview

The app uses environment variables to securely store sensitive information like API keys. These environment variables are stored in a `.env` file that is not committed to version control.

## Setup Instructions

1. Create a `.env` file in the root of the project:

   ```
   touch .env
   ```

2. Add the following environment variables to your `.env` file:

   ```
   GEMINI_API_KEY=your_gemini_api_key_here
   ```

   Replace `your_gemini_api_key_here` with your actual Gemini API key.

3. Make sure `.env` is listed in your `.gitignore` file to prevent it from being committed to version control.

## Usage in Code

The environment variables are loaded using the `flutter_dotenv` package. Here's how it works:

1. The `.env` file is loaded in `main.dart`:

   ```dart
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await dotenv.load(fileName: ".env");
     // ...
   }
   ```

2. Environment variables are accessed in the code like this:
   ```dart
   final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
   ```

## Troubleshooting

If the app fails to load environment variables:

1. Make sure the `.env` file exists in the root of the project.
2. Make sure the `.env` file has been properly added to the assets in `pubspec.yaml`.
3. Make sure you've run `flutter pub get` after modifying `pubspec.yaml`.
4. Check for typos in environment variable names.

## Security Considerations

- Never commit your `.env` file to version control.
- Don't share your API keys with others.
- Consider using different API keys for development and production environments.
