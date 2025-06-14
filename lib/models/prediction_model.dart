class PredictionModel {
  final String label;
  final double confidence;

  PredictionModel({required this.label, required this.confidence});

  @override
  String toString() {
    return 'Prediction: $label, Confidence: ${(confidence * 100).toStringAsFixed(2)}%';
  }
}
