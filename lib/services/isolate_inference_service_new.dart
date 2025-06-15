import 'dart:isolate';
import 'package:flutter_isolate/flutter_isolate.dart';
import 'package:ai_food_recognizer_app/models/prediction_model.dart';

// Data yang akan dikirim ke isolate
class InferenceData {
  final String imagePath;
  final String modelPath;
  final List<String> labels;
  final SendPort responsePort;

  InferenceData({
    required this.imagePath,
    required this.modelPath,
    required this.labels,
    required this.responsePort,
  });

  Map<String, dynamic> toMap() {
    return {
      'imagePath': imagePath,
      'modelPath': modelPath,
      'labels': labels,
      'responsePort': responsePort,
    };
  }
}

// Data hasil inference
class InferenceResult {
  final String? error;
  final PredictionModel? prediction;

  InferenceResult({this.error, this.prediction});

  Map<String, dynamic> toMap() {
    return {
      'error': error,
      'prediction': prediction?.toMap(),
    };
  }

  static InferenceResult fromMap(Map<String, dynamic> map) {
    return InferenceResult(
      error: map['error'],
      prediction: map['prediction'] != null
          ? PredictionModelExtension.fromMap(map['prediction'])
          : null,
    );
  }
}

// Extension untuk PredictionModel
extension PredictionModelExtension on PredictionModel {
  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'confidence': confidence,
      'index': index,
    };
  }

  static PredictionModel fromMap(Map<String, dynamic> map) {
    return PredictionModel(
      label: map['label'],
      confidence: map['confidence'],
      index: map['index'],
    );
  }
}

class IsolateInferenceService {
  static FlutterIsolate? _isolate;
  static bool _isRunning = false;

  // Jalankan inference di background isolate
  static Future<PredictionModel?> runInference({
    required String imagePath,
    required String modelPath,
    required List<String> labels,
  }) async {
    try {
      if (_isRunning) {
        print('Isolate sedang berjalan, menunggu...');
        await Future.delayed(const Duration(milliseconds: 100));
        return await runInference(
          imagePath: imagePath,
          modelPath: modelPath,
          labels: labels,
        );
      }

      _isRunning = true;
      print('Memulai inference di background isolate...');

      // Buat port untuk menerima hasil
      final receivePort = ReceivePort();
      final sendPort = receivePort.sendPort;

      // Data untuk dikirim ke isolate
      final inferenceData = InferenceData(
        imagePath: imagePath,
        modelPath: modelPath,
        labels: labels,
        responsePort: sendPort,
      );

      // Jalankan isolate
      _isolate = await FlutterIsolate.spawn(
        _inferenceEntryPoint,
        inferenceData.toMap(),
      );

      // Tunggu hasil
      final result = await receivePort.first;
      final inferenceResult = InferenceResult.fromMap(result);

      if (inferenceResult.error != null) {
        print('Error dalam inference: ${inferenceResult.error}');
        return null;
      }

      print('Inference selesai di background isolate');
      return inferenceResult.prediction;
    } catch (e) {
      print('Error saat menjalankan inference di isolate: $e');
      return null;
    } finally {
      _isRunning = false;
      await stopIsolate();
    }
  }

  // Entry point untuk isolate
  static void _inferenceEntryPoint(Map<String, dynamic> data) async {
    try {
      final labels = List<String>.from(data['labels']);
      final responsePort = data['responsePort'] as SendPort;

      // Simulasi inference (akan diganti dengan TFLite sebenarnya)
      await Future.delayed(const Duration(seconds: 1));

      // Buat hasil prediction dummy untuk testing
      // Nanti bisa diganti dengan inference TFLite yang sebenarnya
      final prediction = PredictionModel(
        label: labels.isNotEmpty ? labels[0] : 'Unknown Food',
        confidence: 0.85,
        index: 0,
      );

      final result = InferenceResult(prediction: prediction);
      responsePort.send(result.toMap());
    } catch (e) {
      final errorResult = InferenceResult(error: e.toString());
      final responsePort = data['responsePort'] as SendPort;
      responsePort.send(errorResult.toMap());
    }
  }

  // Hentikan isolate
  static Future<void> stopIsolate() async {
    if (_isolate != null) {
      _isolate!.kill();
      _isolate = null;
    }
  }

  // Cek apakah isolate sedang berjalan
  static bool get isRunning => _isRunning;
}
