import 'dart:io';

import 'package:ai_food_recognizer_app/models/prediction_model.dart';
import 'package:ai_food_recognizer_app/utils/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Data class untuk membawa parameter ke dalam isolate.
class IsolateInferenceData {
  final String imagePath;
  final String modelPath;
  final List<String> labels;
  final int inputSize;
  final int numClasses;

  IsolateInferenceData({
    required this.imagePath,
    required this.modelPath,
    required this.labels,
    required this.inputSize,
    required this.numClasses,
  });
}

/// Top-level function yang akan dijalankan di dalam isolate.
/// Fungsi ini tidak bisa menjadi bagian dari sebuah class.
Future<PredictionModel?> _inferenceFunction(
    IsolateInferenceData isolateData) async {
  try {
    // 1. Muat model TFLite
    final options = InterpreterOptions()..threads = 2;
    final interpreter =
        Interpreter.fromFile(File(isolateData.modelPath), options: options);
    interpreter.allocateTensors();

    // 2. Pra-pemrosesan Gambar
    final imageBytes = await File(isolateData.imagePath).readAsBytes();
    final originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) return null;

    final resizedImage = img.copyResize(originalImage,
        width: isolateData.inputSize, height: isolateData.inputSize);

    var inputBuffer =
        Uint8List(1 * isolateData.inputSize * isolateData.inputSize * 3);
    int bufferIndex = 0;
    for (int y = 0; y < isolateData.inputSize; y++) {
      for (int x = 0; x < isolateData.inputSize; x++) {
        final pixel = resizedImage.getPixel(x, y);
        inputBuffer[bufferIndex++] = pixel.r.toInt();
        inputBuffer[bufferIndex++] = pixel.g.toInt();
        inputBuffer[bufferIndex++] = pixel.b.toInt();
      }
    }

    final input = inputBuffer
        .reshape([1, isolateData.inputSize, isolateData.inputSize, 3]);
    var output = List.filled(1 * isolateData.numClasses, 0)
        .reshape([1, isolateData.numClasses]);

    // 3. Jalankan Inferensi
    interpreter.run(input, output);

    // 4. Proses Output
    List<int> rawOutput = output[0].cast<int>();
    List<double> probabilities = rawOutput.map((e) => e / 255.0).toList();

    List<MapEntry<int, double>> sortedProbs = probabilities
        .asMap()
        .entries
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    double maxProb = sortedProbs[0].value;
    int maxIndex = sortedProbs[0].key;
    double top2Prob = sortedProbs.length > 1 ? sortedProbs[1].value : 0.0;

    if (maxIndex >= isolateData.labels.length) return null;
    String rawLabel = isolateData.labels[maxIndex];

    const double absoluteThreshold = 0.6;
    const double relativeThreshold = 0.4;
    double confidenceRatio = (maxProb > 0) ? (top2Prob / maxProb) : 1.0;

    if (maxProb < absoluteThreshold || confidenceRatio > relativeThreshold) {
      return PredictionModel(
        label: 'Bukan makanan',
        confidence: 1.0,
        index: -1,
        rawLabel: 'Bukan makanan',
      );
    }

    interpreter.close();

    return PredictionModel(
      label: rawLabel,
      confidence: maxProb,
      index: maxIndex,
      rawLabel: rawLabel,
    );
  } catch (e) {
    AppLogger.i('Error di dalam isolate: $e');
    return null;
  }
}

// Service untuk menjalankan TFLite inference di background isolate
class IsolateInferenceService {
  static final bool _isRunning = false;

  /// Jalankan inference di background isolate menggunakan compute.
  static Future<PredictionModel?> runInference(
      IsolateInferenceData isolateData) async {
    // `compute` adalah cara best-practice untuk menjalankan fungsi di isolate.
    return compute(_inferenceFunction, isolateData);
  }

  // Cek apakah isolate sedang berjalan
  static bool get isRunning => _isRunning;
}
