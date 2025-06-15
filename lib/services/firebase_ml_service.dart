import 'dart:io';
import 'package:firebase_ml_model_downloader/firebase_ml_model_downloader.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class FirebaseMlService {
  static const String _modelName = 'food-recognizer';
  static const String _localModelPath = 'assets/ML/food-reconizer.tflite'; // Matches the actual filename
  
  // Download model dari Firebase ML
  Future<String?> downloadModel() async {
    try {
      print('Mencoba mendownload model dari Firebase ML...');
      
      FirebaseCustomModel? model;
      try {
        model = await FirebaseModelDownloader.instance.getModel(
          _modelName,
          FirebaseModelDownloadType.latestModel,
          FirebaseModelDownloadConditions(
            androidChargingRequired: false,
            androidWifiRequired: false,
            androidDeviceIdleRequired: false,
          ),
        ).timeout(const Duration(seconds: 10));
      } catch (e) {
        print('Timeout atau error saat mendownload model: $e');
        return null;
      }
      
      if (model != null) {
        final file = model.file;
        if (await file.exists()) {
          print('Model berhasil didownload: ${file.path}');
          return file.path;
        } else {
          print('File model tidak ditemukan setelah download');
        }
      }
      
      return null;
    } catch (e) {
      print('Error saat mendownload model dari Firebase ML: $e');
      return null;
    }
  }
  
  // Cek apakah model sudah ada di cache lokal
  Future<String?> getCachedModel() async {
    try {
      print('Memeriksa model di cache...');
      FirebaseCustomModel? model;
      
      try {
        model = await FirebaseModelDownloader.instance.getModel(
          _modelName,
          FirebaseModelDownloadType.localModelUpdateInBackground,
          FirebaseModelDownloadConditions(
            androidChargingRequired: false,
            androidWifiRequired: false,
            androidDeviceIdleRequired: false,
          ),
        ).timeout(const Duration(seconds: 5));
      } catch (e) {
        print('Timeout atau error saat memeriksa cache: $e');
        return null;
      }
      
      if (model != null) {
        final file = model.file;
        if (await file.exists()) {
          print('Model ditemukan di cache: ${file.path}');
          return file.path;
        } else {
          print('File model cache tidak ditemukan');
        }
      }
      
      return null;
    } catch (e) {
      print('Error saat mengecek cached model: $e');
      return null;
    }
  }
  
  // Fallback ke model lokal jika Firebase ML tidak tersedia
  Future<String?> getLocalModel() async {
    try {
      print('Menggunakan model lokal dari assets...');
      
      // Cek apakah file sudah dicopy ke directory aplikasi
      final appDir = await getApplicationDocumentsDirectory();
      final localModelFile = File('${appDir.path}/food-recognizer.tflite');
      
      if (await localModelFile.exists()) {
        print('Model lokal ditemukan: ${localModelFile.path}');
        return localModelFile.path;
      }
      
      try {
        // Copy dari assets ke directory aplikasi
        final byteData = await rootBundle.load(_localModelPath);
        final bytes = byteData.buffer.asUint8List();
        
        await localModelFile.writeAsBytes(bytes);
        print('Model lokal berhasil dicopy: ${localModelFile.path}');
        
        return localModelFile.path;
      } catch (e) {
        print('Error saat menyalin model dari assets: $e');
        // Jika gagal menyalin, coba langsung gunakan path assets
        return _localModelPath;
      }
    } catch (e) {
      print('Error saat mengakses model lokal: $e');
      // Fallback ke direct assets path sebagai last resort
      return _localModelPath;
    }
  }
  
  // Method utama untuk mendapatkan path model
  Future<String?> getModelPath() async {
    print('Memulai proses mendapatkan model path...');
    
    // 1. Coba cek cache terlebih dahulu
    String? modelPath = await getCachedModel();
    if (modelPath != null) {
      print('Menggunakan model dari cache');
      return modelPath;
    }
    
    // 2. Coba download dari Firebase ML
    modelPath = await downloadModel();
    if (modelPath != null) {
      print('Menggunakan model yang baru didownload');
      return modelPath;
    }
    
    // 3. Fallback ke model lokal
    print('Fallback ke model lokal');
    modelPath = await getLocalModel();
    if (modelPath != null) {
      print('Menggunakan model lokal: $modelPath');
      return modelPath;
    }
    
    print('KRITIS: Tidak dapat mendapatkan model dari manapun!');
    return null;
  }
  
  // Hapus model yang di-cache
  Future<bool> deleteModel() async {
    try {
      await FirebaseModelDownloader.instance.deleteDownloadedModel(_modelName);
      print('Model berhasil dihapus dari cache');
      return true;
    } catch (e) {
      print('Error saat menghapus model: $e');
      return false;
    }
  }
  
  // Cek informasi model
  Future<void> listDownloadedModels() async {
    try {
      final models = await FirebaseModelDownloader.instance.listDownloadedModels();
      print('Downloaded models:');
      for (final model in models) {
        print('- ${model.name}: ${model.file}, size: ${model.size}');
      }
    } catch (e) {
      print('Error saat listing models: $e');
    }
  }
}
