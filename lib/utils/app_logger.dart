// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';

class AppLogger {
  static const String _tag = "AI_FOOD_RECOGNIZER";
  static bool _enableLogging = true;

  /// Enable or disable logging
  static set enableLogging(bool value) {
    _enableLogging = value;
  }

  /// Log debug message
  static void d(String message) {
    if (_enableLogging && kDebugMode) {
      print('[$_tag][DEBUG] $message');
    }
  }

  /// Log info message
  static void i(String message) {
    if (_enableLogging && kDebugMode) {
      print('[$_tag][INFO] $message');
    }
  }

  /// Log error message
  static void e(String message, [Object? error, StackTrace? stackTrace]) {
    if (_enableLogging && kDebugMode) {
      print('[$_tag][ERROR] $message');
      if (error != null) print('Error: $error');
      if (stackTrace != null) print('StackTrace: $stackTrace');
    }
  }

  /// Log warning message
  static void w(String message) {
    if (_enableLogging && kDebugMode) {
      print('[$_tag][WARN] $message');
    }
  }
}
