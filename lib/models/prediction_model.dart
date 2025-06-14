class PredictionModel {
  final String label;
  final double confidence;
  final int index;

  PredictionModel({
    required this.label, 
    required this.confidence,
    required this.index,
  });

  @override
  String toString() {
    return 'Prediction: $label, Confidence: ${(confidence * 100).toStringAsFixed(2)}%';
  }
}
