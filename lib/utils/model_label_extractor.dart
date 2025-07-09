import 'dart:developer';
import 'package:flutter/services.dart';

class ModelLabelExtractor {
  /// Constant paths for label files
  static const String _labelPath1 = 'assets/ML/labels_1.txt';
  static const String _labelPathEn = 'assets/ML/labels-en.txt';

  static Future<List<String>?> extractLabelsFromTflite(String modelPath) async {
    try {
      log('Mencoba mengekstrak label dari file-file label yang tersedia...');

      // First try to load the English human-readable labels
      try {
        log('Mencoba memuat label dari file labels-en.txt');
        final labelsContent = await rootBundle.loadString(_labelPathEn);
        if (labelsContent.isNotEmpty) {
          final List<String> extractedLabels = labelsContent
              .split('\n')
              .where((label) => label.trim().isNotEmpty)
              .toList();

          if (extractedLabels.isNotEmpty) {
            log('Berhasil mengekstrak ${extractedLabels.length} label dari labels-en.txt');
            return extractedLabels;
          }
        }
      } catch (e) {
        log('Gagal memuat labels-en.txt: $e');
      }

      // If English labels failed, try the second label file
      try {
        log('Mencoba memuat label dari file labels_1.txt');
        final labelsContent = await rootBundle.loadString(_labelPath1);
        if (labelsContent.isNotEmpty) {
          final List<String> extractedLabels = labelsContent
              .split('\n')
              .where((label) => label.trim().isNotEmpty)
              .toList();

          if (extractedLabels.isNotEmpty) {
            log('Berhasil mengekstrak ${extractedLabels.length} label dari labels_1.txt');
            return extractedLabels;
          }
        }
      } catch (e) {
        log('Gagal memuat labels_1.txt: $e');
      }

      log('Tidak ada file label yang dapat dimuat.');
      return null;
    } catch (e) {
      log('Error saat mengekstrak label: $e');
      return null;
    }
  }
}
