import 'dart:io';
import 'package:firebase_ml_model_downloader/firebase_ml_model_downloader.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class FirebaseMlService {
  static const String _modelName = 'food-recognizer';
  static const String _localModelPath = 'assets/ML/food-reconizer.tflite';
  
  // Download model dari Firebase ML
  Future<String?> downloadModel() async {
    try {
      print('Mencoba mendownload model dari Firebase ML...');
      
      final model = await FirebaseModelDownloader.instance.getModel(
        _modelName,
        FirebaseModelDownloadType.latestModel,
        FirebaseModelDownloadConditions(
          androidChargingRequired: false,
          androidWifiRequired: false,
          androidDeviceIdleRequired: false,
        ),
      );
      
      if (model != null) {
        print('Model berhasil didownload: ${model.file.path}');
        return model.file.path;
      } else {
        print('Gagal mendownload model dari Firebase ML');
        return null;
      }
    } catch (e) {
      print('Error saat mendownload model dari Firebase ML: $e');
      return null;
    }
  }
  
  // Cek apakah model sudah ada di cache lokal
  Future<String?> getCachedModel() async {
    try {
      final model = await FirebaseModelDownloader.instance.getModel(
        _modelName,
        FirebaseModelDownloadType.localModelUpdateInBackground,
        FirebaseModelDownloadConditions(
          androidChargingRequired: false,
          androidWifiRequired: false,
          androidDeviceIdleRequired: false,
        ),
      );
      
      if (model != null && await model.file.exists()) {
        print('Model ditemukan di cache: ${model.file.path}');
        return model.file.path;
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
      
      // Copy dari assets ke directory aplikasi
      final byteData = await rootBundle.load(_localModelPath);
      final bytes = byteData.buffer.asUint8List();
      
      await localModelFile.writeAsBytes(bytes);
      print('Model lokal berhasil dicopy: ${localModelFile.path}');
      
      return localModelFile.path;
    } catch (e) {
      print('Error saat mengakses model lokal: $e');
      return null;
    }
  }
  
  // Method utama untuk mendapatkan path model
  Future<String?> getModelPath() async {
    // 1. Coba cek cache terlebih dahulu
    String? modelPath = await getCachedModel();
    if (modelPath != null) {
      return modelPath;
    }
    
    // 2. Coba download dari Firebase ML
    modelPath = await downloadModel();
    if (modelPath != null) {
      return modelPath;
    }
    
    // 3. Fallback ke model lokal
    modelPath = await getLocalModel();
    if (modelPath != null) {
      return modelPath;
    }
    
    print('Tidak dapat mendapatkan model dari manapun!');
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
