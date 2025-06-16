import 'dart:io';
import 'package:firebase_ml_model_downloader/firebase_ml_model_downloader.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:developer';
class FirebaseMlService {
  static const String _modelName = 'food-recognizer';
  static const String _localModelPath =
      'assets/ML/food-reconizer.tflite'; // Matches the actual filename

  // Download model dari Firebase ML
  Future<String?> downloadModel() async {
    try {
      log('Mencoba mendownload model dari Firebase ML...');

      FirebaseCustomModel? model;
      try {
        model = await FirebaseModelDownloader.instance
            .getModel(
              _modelName,
              FirebaseModelDownloadType.latestModel,
              FirebaseModelDownloadConditions(
                androidChargingRequired: false,
                androidWifiRequired: false,
                androidDeviceIdleRequired: false,
              ),
            )
            .timeout(const Duration(seconds: 10));
      } catch (e) {
        log('Timeout atau error saat mendownload model: $e');
        return null;
      }

      final file = model.file;
      if (await file.exists()) {
        log('Model berhasil didownload: ${file.path}');
        return file.path;
      } else {
        log('File model tidak ditemukan setelah download');
      }

      return null;
    } catch (e) {
      log('Error saat mendownload model dari Firebase ML: $e');
      return null;
    }
  }

  // Cek apakah model sudah ada di cache lokal
  Future<String?> getCachedModel() async {
    try {
      log('Memeriksa model di cache...');
      FirebaseCustomModel? model;

      try {
        model = await FirebaseModelDownloader.instance
            .getModel(
              _modelName,
              FirebaseModelDownloadType.localModelUpdateInBackground,
              FirebaseModelDownloadConditions(
                androidChargingRequired: false,
                androidWifiRequired: false,
                androidDeviceIdleRequired: false,
              ),
            )
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        log('Timeout atau error saat memeriksa cache: $e');
        return null;
      }

      final file = model.file;
      if (await file.exists()) {
        log('Model ditemukan di cache: ${file.path}');
        return file.path;
      } else {
        log('File model cache tidak ditemukan');
      }

      return null;
    } catch (e) {
      log('Error saat mengecek cached model: $e');
      return null;
    }
  }

  // Fallback ke model lokal jika Firebase ML tidak tersedia
  Future<String?> getLocalModel() async {
    try {
      log('Menggunakan model lokal dari assets...');

      // Cek apakah file sudah dicopy ke directory aplikasi
      final appDir = await getApplicationDocumentsDirectory();
      final localModelFile = File('${appDir.path}/food-recognizer.tflite');

      if (await localModelFile.exists()) {
        log('Model lokal ditemukan: ${localModelFile.path}');
        return localModelFile.path;
      }

      try {
        // Copy dari assets ke directory aplikasi
        final byteData = await rootBundle.load(_localModelPath);
        final bytes = byteData.buffer.asUint8List();

        await localModelFile.writeAsBytes(bytes);
        log('Model lokal berhasil dicopy: ${localModelFile.path}');

        return localModelFile.path;
      } catch (e) {
        log('Error saat menyalin model dari assets: $e');
        // Jika gagal menyalin, coba langsung gunakan path assets
        return _localModelPath;
      }
    } catch (e) {
      log('Error saat mengakses model lokal: $e');
      // Fallback ke direct assets path sebagai last resort
      return _localModelPath;
    }
  }

  // Method utama untuk mendapatkan path model
  Future<String?> getModelPath() async {
    log('Memulai proses mendapatkan model path...');

    // 1. Coba cek cache terlebih dahulu
    String? modelPath = await getCachedModel();
    if (modelPath != null) {
      log('Menggunakan model dari cache');
      return modelPath;
    }

    // 2. Coba download dari Firebase ML
    modelPath = await downloadModel();
    if (modelPath != null) {
      log('Menggunakan model yang baru didownload');
      return modelPath;
    }

    // 3. Fallback ke model lokal
    log('Fallback ke model lokal');
    modelPath = await getLocalModel();
    if (modelPath != null) {
      log('Menggunakan model lokal: $modelPath');
      return modelPath;
    }

    log('KRITIS: Tidak dapat mendapatkan model dari manapun!');
    return null;
  }

  // Hapus model yang di-cache
  Future<bool> deleteModel() async {
    try {
      await FirebaseModelDownloader.instance.deleteDownloadedModel(_modelName);
      log('Model berhasil dihapus dari cache');
      return true;
    } catch (e) {
      log('Error saat menghapus model: $e');
      return false;
    }
  }

  // Cek informasi model
  Future<void> listDownloadedModels() async {
    try {
      final models =
          await FirebaseModelDownloader.instance.listDownloadedModels();
      log('Downloaded models:');
      for (final model in models) {
        log('- ${model.name}: ${model.file}, size: ${model.size}');
      }
    } catch (e) {
      log('Error saat listing models: $e');
    }
  }
}
