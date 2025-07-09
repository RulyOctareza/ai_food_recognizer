import 'dart:io';
import 'dart:typed_data';
import 'package:ai_food_recognizer_app/utils/app_logger.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:ai_food_recognizer_app/models/prediction_model.dart';
import 'package:ai_food_recognizer_app/utils/model_label_extractor.dart';
import 'package:ai_food_recognizer_app/services/firebase_ml_service.dart';
import 'package:image/image.dart' as img;
import 'package:ai_food_recognizer_app/services/isolate_inference_service.dart';

enum PredictionStatus { success, error }

class PredictionResult {
  final PredictionStatus status;
  final PredictionModel? prediction;
  final String? errorMessage;

  PredictionResult.success(this.prediction)
      : status = PredictionStatus.success,
        errorMessage = null;
  PredictionResult.error(this.errorMessage)
      : status = PredictionStatus.error,
        prediction = null;
}

class TfliteService {
  Interpreter? _interpreter;
  List<String>? _labels;
  bool _modelLoaded = false;
  final FirebaseMlService _firebaseMlService = FirebaseMlService();

  final String _modelAsset = 'assets/ML/food-reconizer.tflite';
  static const int _inputSize = 192; // Ubah sesuai dengan model: 192x192
  static const int _numClasses = 2024; // Ubah sesuai dengan output model: 2024

  Future<bool> loadModel() async {
    if (_modelLoaded) return true;
    try {
      AppLogger.i('Memuat model TFLite...');

      // Dapatkan path model dari Firebase ML Service dengan timeout
      String? modelPath;
      try {
        modelPath = await _firebaseMlService
            .getModelPath()
            .timeout(const Duration(seconds: 15));
      } catch (e) {
        AppLogger.i('Timeout saat mendapatkan model path: $e');
        modelPath = null;
      }

      if (modelPath == null) {
        AppLogger.i(
            'Gagal mendapatkan model path, menggunakan model dari assets');
        modelPath = _modelAsset;
      } else {
        AppLogger.i('Menggunakan model dari: $modelPath');
      }

      // Load labels dari file-file label di assets
      AppLogger.i('Memuat label dari files yang disediakan...');
      try {
        _labels = await ModelLabelExtractor.extractLabelsFromTflite(modelPath);
        if (_labels != null) {
          AppLogger.i('Label berhasil dimuat dari file label');
        } else {
          AppLogger.i(
              'Gagal memuat label dari file yang disediakan, menggunakan label default');
          _labels = ['Bukan makanan']; // Fallback ke label default
        }
      } catch (e) {
        AppLogger.i('Error saat mengekstrak label: $e');
        _labels = ['Bukan makanan']; // Fallback ke label default
      }

      // Validasi jumlah label
      if (_labels == null || _labels!.isEmpty) {
        AppLogger.i('Label tidak ditemukan sama sekali.');
        throw Exception(
            'Label tidak ditemukan sama sekali. Model tidak dapat digunakan.');
      }
      if (_labels!.length != _numClasses) {
        final msg =
            'Jumlah label (${_labels!.length}) tidak sama dengan jumlah kelas model ($_numClasses).';
        AppLogger.i(msg);
        throw Exception(msg);
      }
      AppLogger.i('Jumlah label yang dimuat: ${_labels?.length}');

      // Setup interpreter options
      final options = InterpreterOptions()..threads = 4;

      // Load model with proper error handling
      try {
        bool modelLoaded = false;
        String errorMessage = '';

        // First try: Use the provided path
        try {
          if (modelPath == _modelAsset) {
            _interpreter =
                await Interpreter.fromAsset(modelPath, options: options);
            modelLoaded = true;
          } else {
            final modelFile = File(modelPath);
            if (await modelFile.exists()) {
              _interpreter = Interpreter.fromFile(modelFile, options: options);
              modelLoaded = true;
            } else {
              errorMessage = 'File model tidak ditemukan pada path: $modelPath';
            }
          }
        } catch (e) {
          errorMessage = 'Error loading model from $modelPath: $e';
        }

        // Second try: Fallback to asset if the first attempt failed
        if (!modelLoaded) {
          AppLogger.i(errorMessage);
          AppLogger.i('Mencoba fallback ke asset...');
          try {
            _interpreter =
                await Interpreter.fromAsset(_modelAsset, options: options);
            modelLoaded = true;
          } catch (e) {
            AppLogger.i('Error loading model from asset: $e');
            throw Exception(
                'Failed to load model from any source: $errorMessage | Asset error: $e');
          }
        }

        if (modelLoaded && _interpreter != null) {
          AppLogger.i(
              'Model berhasil dimuat. Input tensor shape: ${_interpreter!.getInputTensor(0).shape}');
          AppLogger.i(
              'Output tensor shape: ${_interpreter!.getOutputTensor(0).shape}');

          _interpreter!.allocateTensors();
          _modelLoaded = true;
          AppLogger.i('Model TFLite berhasil dimuat dan tensor dialokasikan.');
          return true;
        } else {
          AppLogger.i('Interpreter kosong setelah semua upaya memuat model.');
          return false;
        }
      } catch (e) {
        AppLogger.i('Error saat memuat interpreter: $e');
        rethrow; // Re-throw to be caught by outer catch
      }
    } catch (e, stackTrace) {
      AppLogger.i('Gagal memuat model TFLite: $e');
      AppLogger.i('Stack trace: $stackTrace');
      _modelLoaded = false;
      return false;
    }
  }

  // Ubah return type dari Future<PredictionModel?> menjadi Future<PredictionResult>
  Future<PredictionResult> predictImage(File imageFile) async {
    if (!_modelLoaded || _interpreter == null) {
      final msg = 'Model belum dimuat. Panggil loadModel() terlebih dahulu.';
      AppLogger.i(msg);
      // Retry loading with up to 2 attempts
      int attempts = 0;
      while (!_modelLoaded && attempts < 2) {
        attempts++;
        AppLogger.i('Percobaan memuat model #$attempts');
        try {
          bool success = await loadModel();
          if (success) break;
        } catch (e) {
          return PredictionResult.error('Gagal memuat model: $e');
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }
      if (!_modelLoaded || _interpreter == null) {
        final failMsg = 'Gagal memuat model setelah $attempts percobaan.';
        AppLogger.i(failMsg);
        return PredictionResult.error(failMsg);
      }
    }
    try {
      // 1. Pra-pemrosesan Gambar
      final Uint8List imageBytes = await imageFile.readAsBytes();
      img.Image? originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) {
        final msg = 'Gagal men-decode gambar.';
        AppLogger.i(msg);
        return PredictionResult.error(msg);
      }

      // Resize gambar ke _inputSize x _inputSize (224x224)
      img.Image resizedImage =
          img.copyResize(originalImage, width: _inputSize, height: _inputSize);

      // --- PERBAIKAN: Menggunakan Uint8List Sesuai Tipe Data Model ---
      // Model ini mengharapkan input Uint8 [0-255], bukan Float32 [-1, 1].
      var inputBuffer = Uint8List(1 * _inputSize * _inputSize * 3);
      int bufferIndex = 0;
      for (int y = 0; y < _inputSize; y++) {
        for (int x = 0; x < _inputSize; x++) {
          final pixel = resizedImage.getPixel(x, y);
          inputBuffer[bufferIndex++] = pixel.r.toInt();
          inputBuffer[bufferIndex++] = pixel.g.toInt();
          inputBuffer[bufferIndex++] = pixel.b.toInt();
        }
      }

      // Reshape inputBuffer menjadi tensor 4D yang benar: [1, 192, 192, 3]
      final input = inputBuffer.reshape([1, _inputSize, _inputSize, 3]);
      var outputTensor =
          List.filled(1 * _numClasses, 0).reshape([1, _numClasses]);

      // 3. Menjalankan Inferensi
      AppLogger.i('Menjalankan inferensi TFLite...');
      AppLogger.i('Input tensor shape: [1, $_inputSize, $_inputSize, 3]');
      AppLogger.i('Input buffer length: ${inputBuffer.length}');
      AppLogger.i('Expected input size: ${1 * _inputSize * _inputSize * 3}');
      AppLogger.i('Output shape: ${outputTensor[0].length}');

      _interpreter!.run(input, outputTensor);
      AppLogger.i('Inferensi selesai.');

      // 4. Memproses Output
      // Output dari model uint8 biasanya juga uint8, yang perlu dinormalisasi ke double [0,1]
      List<int> rawOutput = outputTensor[0].cast<int>();
      List<double> probabilities = rawOutput.map((e) => e / 255.0).toList();

      AppLogger.i('Output tensor type: ${rawOutput.runtimeType}');
      AppLogger.i('First few probabilities: ${probabilities.take(5).toList()}');
      AppLogger.i(
          'Max probability: ${probabilities.reduce((a, b) => a > b ? a : b)}');
      AppLogger.i(
          'Min probability: ${probabilities.reduce((a, b) => a < b ? a : b)}');

      // HAPUS: Normalisasi manual dengan softmax tidak diperlukan jika output model
      // sudah merupakan probabilitas (umum untuk model klasifikasi uint8).
      // double maxLogit = probabilities.reduce((a, b) => a > b ? a : b);
      // List<double> expValues =
      //     probabilities.map((x) => exp(x - maxLogit)).toList();
      // double sumExp = expValues.reduce((a, b) => a + b);
      // List<double> normalizedProbs = expValues.map((x) => x / sumExp).toList();
      List<double> normalizedProbs =
          probabilities; // Langsung gunakan probabilitas

      // --- LOGIKA DETEKSI BARU BERDASARKAN DISTRIBUSI PROBABILITAS ---

      // 1. Dapatkan 3 prediksi teratas untuk analisis
      List<MapEntry<int, double>> sortedProbs = normalizedProbs
          .asMap()
          .entries
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      double maxProb = sortedProbs[0].value;
      int maxIndex = sortedProbs[0].key;
      double top2Prob = sortedProbs.length > 1 ? sortedProbs[1].value : 0.0;

      // Lakukan null check pada _labels
      if (_labels == null || maxIndex >= _labels!.length) {
        return PredictionResult.error("Label tidak valid atau tidak ada.");
      }
      String rawLabel = _labels![maxIndex];

      // 2. Tentukan ambang batas (threshold)
      const double absoluteThreshold = 0.6;
      const double relativeThreshold = 0.4;
      double confidenceRatio = (maxProb > 0) ? (top2Prob / maxProb) : 1.0;

      AppLogger.i('Max prob: $maxProb ($rawLabel), Top 2 prob: $top2Prob');
      AppLogger.i('Confidence ratio (top2/top1): $confidenceRatio');

      // 3. Logika penentuan "Bukan Makanan"
      if (maxProb < absoluteThreshold || confidenceRatio > relativeThreshold) {
        AppLogger.w(
            'CLASSIFICATION: Not food. Reason: maxProb ($maxProb) < $absoluteThreshold OR ratio ($confidenceRatio) > $relativeThreshold');

        // Buat instance PredictionModel untuk "Bukan makanan"
        final nonFoodPrediction = PredictionModel(
          label: 'Bukan makanan',
          confidence: 1.0, // Confidence 100% untuk UI
          index: -1, // Indeks khusus untuk non-makanan
          rawLabel: 'Bukan makanan',
          nutrition: null,
          recipes: null,
        );
        return PredictionResult.success(nonFoodPrediction);
      }

      // 4. Jika lolos, siapkan hasil seperti biasa
      AppLogger.i(
          'CLASSIFICATION: Food detected. Label: $rawLabel, Confidence: $maxProb');

      // Info nutrisi dan resep tidak lagi diekstrak di sini.
      // Cukup teruskan nama makanan mentah dari label.
      final prediction = PredictionModel(
        label: rawLabel, // Langsung gunakan rawLabel
        confidence: maxProb,
        nutrition: null, // Akan diambil oleh UI
        recipes: null, // Akan diambil oleh UI
        rawLabel: rawLabel,
        index: maxIndex,
      );

      return PredictionResult.success(prediction);
    } catch (e, stackTrace) {
      final msg = 'Error saat prediksi: $e';
      AppLogger.i(msg);
      AppLogger.i('Stack trace: $stackTrace');
      return PredictionResult.error(msg);
    }
  }

  // Ubah return type dari Future<PredictionModel?> menjadi Future<PredictionResult>
  Future<PredictionResult> predictImageWithIsolate(File imageFile) async {
    if (!_modelLoaded || _interpreter == null) {
      final msg = 'Model belum dimuat. Panggil loadModel() terlebih dahulu.';
      AppLogger.i(msg);
      try {
        await loadModel();
      } catch (e) {
        final failMsg = 'Gagal memuat model: $e';
        AppLogger.i(failMsg);
        return PredictionResult.error(failMsg);
      }
      if (!_modelLoaded || _interpreter == null) {
        final failMsg = 'Gagal memuat model setelah percobaan kedua.';
        AppLogger.i(failMsg);
        return PredictionResult.error(failMsg);
      }
    }

    try {
      // Dapatkan path model
      String? modelPath = await _firebaseMlService.getModelPath();
      modelPath ??= _modelAsset;

      AppLogger.i(
          'Memulai prediksi gambar menggunakan TFLite di background...');

      // Siapkan data untuk dikirim ke isolate
      final isolateData = IsolateInferenceData(
        imagePath: imageFile.path,
        modelPath: modelPath,
        labels: _labels ?? [],
        inputSize: _inputSize,
        numClasses: _numClasses,
      );

      // Jalankan inference di background isolate
      final prediction =
          await IsolateInferenceService.runInference(isolateData);

      if (prediction != null) {
        return PredictionResult.success(prediction);
      } else {
        return PredictionResult.error('Inference di isolate gagal.');
      }
    } catch (e) {
      final msg = 'Error saat menjalankan inference dengan isolate: $e';
      AppLogger.i(msg);
      return PredictionResult.error(msg);
    }
  }

  void dispose() {
    if (_interpreter != null) {
      _interpreter!.close();
      _interpreter = null;
      _modelLoaded = false;
      AppLogger.i('Interpreter TFLite ditutup.');
    }
  }
}
