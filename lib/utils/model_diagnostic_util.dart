import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ai_food_recognizer_app/services/firebase_ml_service.dart';

/// Utility class to diagnose model loading issues
class ModelDiagnosticUtil {
  /// Checks all possible model locations and returns a diagnostic report
  static Future<Map<String, dynamic>> diagnoseModelAvailability() async {
    final Map<String, dynamic> report = {};
    final FirebaseMlService firebaseMlService = FirebaseMlService();
    
    // Check Firebase ML model cache
    try {
      String? cachedPath = await firebaseMlService.getCachedModel();
      report['firebase_cached'] = cachedPath != null;
      if (cachedPath != null) {
        report['firebase_cached_path'] = cachedPath;
        final file = File(cachedPath);
        report['firebase_cached_exists'] = await file.exists();
        report['firebase_cached_size'] = await file.exists() ? await file.length() : 0;
      }
    } catch (e) {
      report['firebase_cached_error'] = e.toString();
    }
    
    // Check local asset
    try {
      const assetPath = 'assets/ML/food-reconizer.tflite';
      report['asset_path'] = assetPath;
      
      try {
        final ByteData data = await rootBundle.load(assetPath);
        report['asset_exists'] = true;
        report['asset_size'] = data.lengthInBytes;
      } catch (e) {
        report['asset_exists'] = false;
        report['asset_error'] = e.toString();
      }
    } catch (e) {
      report['asset_check_error'] = e.toString();
    }
    
    // Check app directory
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final localModelFile = File('${appDir.path}/food-recognizer.tflite');
      
      report['local_path'] = localModelFile.path;
      report['local_exists'] = await localModelFile.exists();
      report['local_size'] = await localModelFile.exists() ? await localModelFile.length() : 0;
    } catch (e) {
      report['local_check_error'] = e.toString();
    }
    
    // Get device info
    report['free_space'] = await _getFreeDiskSpace();
    
    return report;
  }
  
  /// Attempts to get free disk space on the device
  static Future<String> _getFreeDiskSpace() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      
      // This will only work on Android/iOS with limitations
      final statSync = FileStat.statSync(appDir.path);
      return '${appDir.path} space info: ${statSync.toString()}';
    } catch (e) {
      return 'Could not determine free space: $e';
    }
  }
  
  /// Runs a complete model loading diagnostic
  static Future<String> runDiagnostics() async {
    final report = await diagnoseModelAvailability();
    final StringBuffer buffer = StringBuffer();
    
    buffer.writeln('===== MODEL DIAGNOSTIC REPORT =====');
    report.forEach((key, value) {
      buffer.writeln('$key: $value');
    });
    buffer.writeln('==================================');
    
    return buffer.toString();
  }
}
