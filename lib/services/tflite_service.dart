import 'dart:io';
import 'dart:math'; // Untuk exp function
import 'dart:typed_data'; // Untuk Float32List
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:ai_food_recognizer_app/models/prediction_model.dart';
import 'package:ai_food_recognizer_app/models/food_labels.dart';
import 'package:image/image.dart' as img; // Import package image

class TfliteService {
  Interpreter? _interpreter;
  List<String>? _labels;
  bool _modelLoaded = false;

  final String _modelAsset = 'assets/ML/food-reconizer.tflite';
  static const int _inputSize = 192; // Ubah sesuai dengan model: 192x192
  static const int _numClasses = 2024; // Ubah sesuai dengan output model: 2024

  Future<void> loadModel() async {
    if (_modelLoaded) return;
    try {
      print('Mencoba memuat model dari: $_modelAsset');

      // Gunakan nama makanan yang sebenarnya
      _labels = FoodLabels.generateAllLabels(_numClasses);
      print('Jumlah label yang di-generate: ${_labels?.length}');

      // Memuat model dengan opsi yang lebih spesifik
      final options = InterpreterOptions()..threads = 4;
      _interpreter = await Interpreter.fromAsset(_modelAsset, options: options);

      print(
          'Model berhasil dimuat. Input tensor shape: ${_interpreter?.getInputTensor(0).shape}');
      print('Output tensor shape: ${_interpreter?.getOutputTensor(0).shape}');

      _interpreter?.allocateTensors();
      _modelLoaded = true;
      print('Model TFLite berhasil dimuat dan tensor dialokasikan.');
    } catch (e, stackTrace) {
      print('Gagal memuat model TFLite: $e');
      print('Stack trace: $stackTrace');
      _modelLoaded = false;
    }
  }

  Future<PredictionModel?> predictImage(File imageFile) async {
    if (!_modelLoaded || _interpreter == null) {
      print('Model belum dimuat. Panggil loadModel() terlebih dahulu.');
      await loadModel();
      if (!_modelLoaded || _interpreter == null) {
        print('Gagal memuat model setelah percobaan kedua.');
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

      if (bestLabelIndex != -1 &&
          _labels != null &&
          bestLabelIndex < _labels!.length) {
        // Pastikan confidence adalah nilai antara 0 dan 1
        double confidenceScore = highestConfidence.clamp(0.0, 1.0);
        return PredictionModel(
            label: _labels![bestLabelIndex], confidence: confidenceScore);
      } else {
        print('Gagal menemukan label yang valid atau _labels null.');
        return PredictionModel(label: "Tidak Dikenali", confidence: 0.0);
      }
    } catch (e) {
      print('Error selama inferensi TFLite: $e');
      return null;
    }
  }

  void dispose() {
    _interpreter?.close();
    _modelLoaded = false;
    print('Interpreter TFLite ditutup.');
  }
}
