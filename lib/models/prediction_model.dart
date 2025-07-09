class PredictionModel {
  final String label;
  final double confidence;
  final int index;
  final String rawLabel;
  final Map<String, dynamic>? nutrition;
  final List<String>? recipes;

  PredictionModel({
    required this.label,
    required this.confidence,
    required this.index,
    required this.rawLabel,
    this.nutrition,
    this.recipes,
  });

  @override
  String toString() {
    return 'Prediction: $label, Confidence: ${(confidence * 100).toStringAsFixed(2)}%';
  }
}
