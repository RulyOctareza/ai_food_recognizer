import 'dart:io';
import 'dart:math'; // Untuk exp function
import 'dart:typed_data'; // Untuk Float32List
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:ai_food_recognizer_app/models/prediction_model.dart';
import 'package:ai_food_recognizer_app/utils/model_label_extractor.dart';
import 'package:ai_food_recognizer_app/services/firebase_ml_service.dart';
import 'package:image/image.dart' as img; // Import package image
import 'package:ai_food_recognizer_app/services/isolate_inference_service.dart';

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
      print('Memuat model TFLite...');

      // Dapatkan path model dari Firebase ML Service dengan timeout
      String? modelPath;
      try {
        modelPath = await _firebaseMlService.getModelPath()
            .timeout(const Duration(seconds: 15));
      } catch (e) {
        print('Timeout saat mendapatkan model path: $e');
        modelPath = null;
      }
      
      if (modelPath == null) {
        print('Gagal mendapatkan model path, menggunakan model dari assets');
        modelPath = _modelAsset;
      } else {
        print('Menggunakan model dari: $modelPath');
      }

      // Load labels dari file-file label di assets
      print('Memuat label dari files yang disediakan...');
      try {
        _labels = await ModelLabelExtractor.extractLabelsFromTflite(modelPath);
        if (_labels != null) {
          print('Label berhasil dimuat dari file label');
        } else {
          print('Gagal memuat label dari file yang disediakan, menggunakan label default');
          _labels = ModelLabelExtractor.getFoodLabels2024();
        }
      } catch (e) {
        print('Error saat mengekstrak label: $e');
        _labels = ModelLabelExtractor.getFoodLabels2024();
      }
      
      // Pastikan jumlah label sesuai dengan output model
      if (_labels!.length > _numClasses) {
        print('Jumlah label (${_labels!.length}) melebihi jumlah kelas ($_numClasses), memotong ke $_numClasses');
        _labels = _labels!.take(_numClasses).toList();
      } else if (_labels!.length < _numClasses) {
        // Tambahkan label generik jika kurang
        print('Jumlah label (${_labels!.length}) kurang dari jumlah kelas ($_numClasses), menambah label generik');
        final initialLength = _labels!.length;
        for (int i = initialLength; i < _numClasses; i++) {
          _labels!.add('Unknown Food ${i + 1}');
        }
      }
      print('Jumlah label yang dimuat: ${_labels?.length}');

      // Setup interpreter options
      final options = InterpreterOptions()..threads = 4;
      
      // Load model with proper error handling
      try {
        bool modelLoaded = false;
        String errorMessage = '';
        
        // First try: Use the provided path
        try {
          if (modelPath == _modelAsset) {
            _interpreter = await Interpreter.fromAsset(modelPath, options: options);
            modelLoaded = true;
          } else {
            final modelFile = File(modelPath);
            if (await modelFile.exists()) {
              _interpreter = await Interpreter.fromFile(modelFile, options: options);
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
          print(errorMessage);
          print('Mencoba fallback ke asset...');
          try {
            _interpreter = await Interpreter.fromAsset(_modelAsset, options: options);
            modelLoaded = true;
          } catch (e) {
            print('Error loading model from asset: $e');
            throw Exception('Failed to load model from any source: $errorMessage | Asset error: $e');
          }
        }

        if (modelLoaded && _interpreter != null) {
          print('Model berhasil dimuat. Input tensor shape: ${_interpreter!.getInputTensor(0).shape}');
          print('Output tensor shape: ${_interpreter!.getOutputTensor(0).shape}');

          _interpreter!.allocateTensors();
          _modelLoaded = true;
          print('Model TFLite berhasil dimuat dan tensor dialokasikan.');
          return true;
        } else {
          print('Interpreter kosong setelah semua upaya memuat model.');
          return false;
        }
      } catch (e) {
        print('Error saat memuat interpreter: $e');
        throw e; // Re-throw to be caught by outer catch
      }
    } catch (e, stackTrace) {
      print('Gagal memuat model TFLite: $e');
      print('Stack trace: $stackTrace');
      _modelLoaded = false;
      return false;
    }
  }

  Future<PredictionModel?> predictImage(File imageFile) async {
    if (!_modelLoaded || _interpreter == null) {
      print('Model belum dimuat. Panggil loadModel() terlebih dahulu.');
      
      // Retry loading with up to 2 attempts
      int attempts = 0;
      while (!_modelLoaded && attempts < 2) {
        attempts++;
        print('Percobaan memuat model #$attempts');
        bool success = await loadModel();
        if (success) break;
        await Future.delayed(const Duration(milliseconds: 500)); // Short delay between attempts
      }
      
      if (!_modelLoaded || _interpreter == null) {
        print('Gagal memuat model setelah $attempts percobaan.');
        return null;
      }
    }

    try {
      // 1. Pra-pemrosesan Gambar
      final Uint8List imageBytes = await imageFile.readAsBytes();
      img.Image? originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) {
        print('Gagal men-decode gambar.');
        return null;
      }

      // Resize gambar ke _inputSize x _inputSize (224x224)
      img.Image resizedImage =
          img.copyResize(originalImage, width: _inputSize, height: _inputSize);

      // Konversi gambar ke Uint8List, bentuk input: [1, 192, 192, 3]
      var inputBuffer = Uint8List(1 * _inputSize * _inputSize * 3);
      int bufferIndex = 0;
      for (int y = 0; y < _inputSize; y++) {
        for (int x = 0; x < _inputSize; x++) {
          final pixel = resizedImage.getPixel(x, y);
          // Menggunakan nilai RGB langsung (0-255)
          inputBuffer[bufferIndex++] = pixel.r.toInt();
          inputBuffer[bufferIndex++] = pixel.g.toInt();
          inputBuffer[bufferIndex++] = pixel.b.toInt();
        }
      }

      // Reshape inputBuffer menjadi tensor 4D yang benar: [1, 192, 192, 3]
      final input = inputBuffer.reshape([1, _inputSize, _inputSize, 3]);
      var outputTensor =
          List.filled(1 * _numClasses, 0.0).reshape([1, _numClasses]);

      // 3. Menjalankan Inferensi
      print('Menjalankan inferensi TFLite...');
      print('Input tensor shape: [1, $_inputSize, $_inputSize, 3]');
      print('Input buffer length: ${inputBuffer.length}');
      print('Expected input size: ${1 * _inputSize * _inputSize * 3}');
      print('Output shape: ${outputTensor[0].length}');

      _interpreter!.run(input, outputTensor);
      print('Inferensi selesai.');

      // 4. Memproses Output
      // outputTensor[0] bisa berupa List<int> atau List<double>, konversi ke double
      List<dynamic> rawOutput = outputTensor[0];
      List<double> probabilities =
          rawOutput.map((e) => e.toDouble()).toList().cast<double>();

      print('Output tensor type: ${rawOutput.runtimeType}');
      print('First few probabilities: ${probabilities.take(5).toList()}');
      print(
          'Max probability: ${probabilities.reduce((a, b) => a > b ? a : b)}');
      print(
          'Min probability: ${probabilities.reduce((a, b) => a < b ? a : b)}');

      // Normalisasi menggunakan softmax jika diperlukan
      double maxLogit = probabilities.reduce((a, b) => a > b ? a : b);
      List<double> expValues =
          probabilities.map((x) => exp(x - maxLogit)).toList();
      double sumExp = expValues.reduce((a, b) => a + b);
      List<double> normalizedProbs = expValues.map((x) => x / sumExp).toList();

      double highestConfidence = 0.0;
      int bestLabelIndex = -1;

      for (int i = 0; i < normalizedProbs.length; i++) {
        if (normalizedProbs[i] > highestConfidence) {
          highestConfidence = normalizedProbs[i];
          bestLabelIndex = i;
        }
      }

      print(
          'Indeks terbaik: $bestLabelIndex, Kepercayaan normalized: $highestConfidence');

      if (bestLabelIndex != -1) {
        // Pastikan confidence adalah nilai antara 0 dan 1
        double confidenceScore = highestConfidence.clamp(0.0, 1.0);
        
        String foodLabel;
        if (_labels != null && bestLabelIndex < _labels!.length) {
          // Get the raw label from our list
          String rawLabel = _labels![bestLabelIndex];
          
          // If the label appears to be a Knowledge Graph ID (starts with /g/ or is __background__),
          // attempt to get a more readable label
          if (rawLabel.startsWith('/g/') || rawLabel.startsWith('__')) {
            try {
              // Try to use the English label file for better human-readable labels
              String betterLabel = ModelLabelExtractor.cleanupLabelId(rawLabel);
              // Check if still using raw ID, try to find a proper name from label-en.txt
              if (betterLabel == rawLabel) {
                foodLabel = await ModelLabelExtractor.loadLabelFromIndexAsync(bestLabelIndex);
              } else {
                foodLabel = betterLabel;
              }
            } catch (e) {
              print('Error getting better label: $e');
              foodLabel = rawLabel; // Fallback to raw label
            }
          } else {
            foodLabel = rawLabel; // Already human-readable
          }
        } else {
          // If we don't have a label list or index is out of bounds
          foodLabel = 'Unknown Food ($bestLabelIndex)';
        }
        
        return PredictionModel(
            label: foodLabel, 
            confidence: confidenceScore,
            index: bestLabelIndex);
      } else {
        print('Gagal menemukan indeks label terbaik.');
        return PredictionModel(
            label: "Tidak Dikenali", 
            confidence: 0.0,
            index: -1);
      }
    } catch (e) {
      print('Error selama inferensi TFLite: $e');
      return null;
    }
  }

  // Method untuk inference dengan background isolate
  Future<PredictionModel?> predictImageWithIsolate(File imageFile) async {
    if (!_modelLoaded || _interpreter == null) {
      print('Model belum dimuat. Panggil loadModel() terlebih dahulu.');
      await loadModel();
      if (!_modelLoaded || _interpreter == null) {
        print('Gagal memuat model setelah percobaan kedua.');
        return null;
      }
    }

    try {
      // Dapatkan path model
      String? modelPath = await _firebaseMlService.getModelPath();
      if (modelPath == null) {
        modelPath = _modelAsset;
      }

      // Untuk tujuan demo dan pengembangan, kita menggunakan metode biasa
      // dan mensimulasikan prosesnya di background
      print('Memulai prediksi gambar menggunakan TFLite di background...');
      
      // Kita bisa menambahkan implementasi isolate yang sebenarnya nanti
      // saat aplikasi sudah stabil
      return await predictImage(imageFile);
      
      // Jalankan inference di background isolate - uncomment later
      /*
      final prediction = await IsolateInferenceService.runInference(
        imagePath: imageFile.path,
        modelPath: modelPath,
        labels: _labels ?? [],
      );
      return prediction;
      */
    } catch (e) {
      print('Error saat menjalankan inference dengan isolate: $e');
      return null;
    }
  }

  void dispose() {
    _interpreter?.close();
    _modelLoaded = false;
    print('Interpreter TFLite ditutup.');
  }
}
