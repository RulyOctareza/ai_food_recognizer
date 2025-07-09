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

  /// Extracts food name, nutrition, and recipes from a raw label string.
  static Map<String, dynamic> extractNutritionAndRecipes(String rawLabel) {
    // Example rawLabel: "0 Apple pie~calories: 237, fat: 11g, carbs: 34g, protein: 2g~recipe: Bake at 350F for 40 mins."
    try {
      final parts = rawLabel.split('~');
      final foodNamePart = parts[0];
      final foodName =
          foodNamePart.replaceAll(RegExp(r'^\d+\s*'), '').trim(); // Remove leading number and trim

      Map<String, dynamic> nutrition = {};
      if (parts.length > 1 && parts[1].isNotEmpty) {
        final nutritionParts = parts[1].split(',');
        for (var part in nutritionParts) {
          final keyValue = part.split(':');
          if (keyValue.length == 2) {
            nutrition[keyValue[0].trim()] = keyValue[1].trim();
          }
        }
      }

      List<String> recipes = [];
      if (parts.length > 2 && parts[2].isNotEmpty) {
        recipes = parts[2]
            .split(';')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }

      return {
        'foodName': foodName,
        'nutrition': nutrition.isNotEmpty ? nutrition : null,
        'recipes': recipes.isNotEmpty ? recipes : null,
      };
    } catch (e) {
      log('Error parsing raw label "$rawLabel": $e');
      // Return the raw label as the food name if parsing fails
      return {
        'foodName': rawLabel.replaceAll(RegExp(r'^\d+\s*'), '').trim(),
        'nutrition': null,
        'recipes': null,
      };
    }
  }
}
