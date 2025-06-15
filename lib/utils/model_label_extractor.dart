import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';

class ModelLabelExtractor {
  /// Constant paths for label files
  static const String _labelPath1 = 'assets/ML/labels_1.txt';
  static const String _labelPathEn = 'assets/ML/labels-en.txt';
  
  static Future<List<String>?> extractLabelsFromTflite(String modelPath) async {
    try {
      print('Mencoba mengekstrak label dari file-file label yang tersedia...');
      
      // First try to load the English human-readable labels
      try {
        print('Mencoba memuat label dari file labels-en.txt');
        final labelsContent = await rootBundle.loadString(_labelPathEn);
        if (labelsContent.isNotEmpty) {
          final List<String> extractedLabels = labelsContent
              .split('\n')
              .where((label) => label.trim().isNotEmpty)
              .toList();
          
          if (extractedLabels.isNotEmpty) {
            print('Berhasil mengekstrak ${extractedLabels.length} label dari labels-en.txt');
            return extractedLabels;
          }
        }
      } catch (e) {
        print('Gagal memuat labels-en.txt: $e');
      }
      
      // If English labels failed, try the second label file
      try {
        print('Mencoba memuat label dari file labels_1.txt');
        final labelsContent = await rootBundle.loadString(_labelPath1);
        if (labelsContent.isNotEmpty) {
          final List<String> extractedLabels = labelsContent
              .split('\n')
              .where((label) => label.trim().isNotEmpty)
              .toList();
          
          if (extractedLabels.isNotEmpty) {
            print('Berhasil mengekstrak ${extractedLabels.length} label dari labels_1.txt');
            return extractedLabels;
          }
        }
      } catch (e) {
        print('Gagal memuat labels_1.txt: $e');
      }
      
      // If both dedicated label files failed, try the old approach with model-associated label file
      try {
        // Check jika ada file label.txt yang menyertai model
        String labelPath;
        if (modelPath.startsWith('assets/')) {
          labelPath = modelPath.replaceAll('.tflite', '_labels.txt');
        } else {
          labelPath = '$modelPath.labels.txt'; // For files in device storage
        }
        
        String labelsContent;
        try {
          labelsContent = await rootBundle.loadString(labelPath);
        } catch (e) {
          // If asset loading failed and it's a file path, try to read from file
          if (!modelPath.startsWith('assets/')) {
            final labelFile = File(labelPath);
            if (await labelFile.exists()) {
              labelsContent = await labelFile.readAsString();
            } else {
              throw Exception('Label file not found');
            }
          } else {
            throw e;
          }
        }
        
        if (labelsContent.isNotEmpty) {
          final List<String> extractedLabels = labelsContent
              .split('\n')
              .where((label) => label.trim().isNotEmpty)
              .toList();
          
          if (extractedLabels.isNotEmpty) {
            print('Berhasil mengekstrak ${extractedLabels.length} label dari file label.');
            return extractedLabels;
          }
        }
      } catch (e) {
        print('Tidak menemukan file label terpisah: $e');
      }
      
      // If all approaches failed, use default labels
      print('Semua pendekatan ekstraksi label gagal, menggunakan label default');
      return getFoodLabels2024();
    } catch (e) {
      print('Error pada ekstraksi label: $e');
      return null;
    }
  }
  
  // Fungsi ini mengembalikan label default ketika file label tidak dapat dimuat
  static List<String> getFoodLabels2024() {
    // These are common food categories that might be in a 2024-class food recognition model
    // This is a comprehensive list of food items organized by categories
    return [
      // Indonesian Foods
      'Nasi Gudeg', 'Rendang', 'Gado-gado', 'Sate Ayam', 'Nasi Padang',
      'Gudeg Jogja', 'Pecel Lele', 'Ayam Bakar', 'Ikan Bakar', 'Soto Ayam',
      'Bakso', 'Mie Ayam', 'Nasi Goreng', 'Ayam Goreng', 'Bebek Goreng',
      'Rawon', 'Rujak', 'Kerupuk', 'Tempe Goreng', 'Tahu Goreng',

      // International Foods
      'Pizza Margherita', 'Pizza Pepperoni', 'Hamburger', 'Cheeseburger',
      'Hot Dog', 'Pasta Carbonara', 'Pasta Bolognese', 'Spaghetti',
      'Fried Chicken', 'Grilled Chicken', 'Chicken Wings', 'Fish and Chips',
      'Steak', 'Pork Chops', 'Lamb Curry', 'Beef Stew',

      // Asian Foods
      'Sushi', 'Ramen', 'Pad Thai', 'Fried Rice', 'Spring Rolls',
      'Dim Sum', 'Dumplings', 'Pho', 'Tom Yum', 'Green Curry',
      'Red Curry', 'Bibimbap', 'Kimchi', 'Bulgogi', 'Teriyaki',

      // Breakfast Items
      'Pancakes', 'Waffles', 'French Toast', 'Eggs Benedict', 'Omelette',
      'Scrambled Eggs', 'Fried Eggs', 'Cereal', 'Oatmeal', 'Yogurt',
      'Croissant', 'Bagel', 'Toast', 'Bacon', 'Sausage',

      // Default placeholder untuk sisa kelas
      'Unknown Food', 'Generic Food Item',
    ];
  }
  
  // Mendapatkan nama makanan yang bisa dibaca manusia dari ID label
  static Object getHumanReadableLabel(String labelId, int classIndex) {
    // Jika labelId dimulai dengan /g/, bisa jadi itu adalah Knowledge Graph ID
    if (labelId.startsWith('/g/') || labelId.startsWith('__')) {
      try {
        // Coba ambil label dari file label-en.txt berdasarkan indeks kelas
        return loadLabelFromIndexAsync(classIndex);
      } catch (e) {
        return 'Unknown Food ($classIndex)';
      }
    }
    return labelId; // Jika labelnya sudah dalam bentuk yang bisa dibaca
  }
  
  // Fungsi untuk memuat label berdasarkan indeks dari file label secara asinkron
  static Future<String> loadLabelFromIndexAsync(int index) async {
    try {
      // Coba muat dari label bahasa Inggris
      final labelsContent = await rootBundle.loadString(_labelPathEn);
      final labels = labelsContent
          .split('\n')
          .where((label) => label.trim().isNotEmpty)
          .toList();
      
      if (index >= 0 && index < labels.length) {
        return labels[index];
      }
    } catch (e) {
      print('Error loading label by index: $e');
    }
    
    return 'Unknown Food ($index)';
  }
  
  // Fungsi untuk memuat label berdasarkan indeks dari file label
  static String loadLabelFromIndex(int index, List<String> labels) {
    if (index >= 0 && index < labels.length) {
      return labels[index];
    }
    return 'Unknown Food ($index)';
  }
  
  // Fungsi utilitas untuk mengonversi berbagai format label
  static String cleanupLabelId(String labelId) {
    // Jika label adalah Knowledge Graph ID, hapus prefix
    if (labelId.startsWith('/g/')) {
      return labelId.replaceFirst('/g/', '').replaceAll('_', ' ');
    }
    
    // Jika label adalah background atau placeholder, berikan nama yang lebih deskriptif
    if (labelId == '__background__') {
      return 'Background (Non-food)';
    }
    
    return labelId;
  }
}
