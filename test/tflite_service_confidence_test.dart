import 'package:flutter_test/flutter_test.dart';
import 'package:ai_food_recognizer_app/services/tflite_service.dart';
import 'dart:math';

void main() {
  group('Confidence Score Calculation Tests', () {
    test('Test with realistic TFLite output values', () {
      // This test simulates more realistic output values from a TFLite model
      // Values based on typical softmax outputs from food recognition model
      
      // Create mock output where one class has significantly higher confidence
      List<double> mockOutputTensor = List.filled(2024, 0.0001); // Simulate 2024 classes with low baseline values
      
      // Set a few stronger predictions
      mockOutputTensor[305] = 0.85;  // Strong first prediction
      mockOutputTensor[721] = 0.45;  // Moderate second prediction
      mockOutputTensor[128] = 0.30;  // Lower third prediction
      
      // We'll manually perform the same calculations as in tflite_service.dart
      
      // Apply softmax
      double maxLogit = mockOutputTensor.reduce((a, b) => a > b ? a : b);
      List<double> expValues = mockOutputTensor.map((x) => exp(x - maxLogit)).toList();
      double sumExp = expValues.reduce((a, b) => a + b);
      List<double> normalizedProbs = expValues.map((x) => x / sumExp).toList();
      
      // Find top values
      List<MapEntry<int, double>> indexedProbs = [];
      for (int i = 0; i < normalizedProbs.length; i++) {
        indexedProbs.add(MapEntry(i, normalizedProbs[i]));
      }
      indexedProbs.sort((a, b) => b.value.compareTo(a.value));
      
      List<int> topIndices = [];
      List<double> topConfidences = [];
      for (int i = 0; i < min(3, indexedProbs.length); i++) {
        topIndices.add(indexedProbs[i].key);
        topConfidences.add(indexedProbs[i].value);
      }
      
      int bestLabelIndex = topIndices[0];
      double confidenceScore = topConfidences[0];
      
      // Calculate relative confidence
      if (topConfidences.length > 1 && topConfidences[1] > 0) {
        double diff = topConfidences[0] - topConfidences[1];
        confidenceScore = 0.5 + (diff * 0.5);
        
        // No random factor for test determinism
      }
      
      confidenceScore = confidenceScore.clamp(0.0, 0.97);
      
      // Verify calculations
      expect(bestLabelIndex, equals(305), reason: "Best label index should be 305");
      expect(confidenceScore, lessThan(0.97), reason: "Confidence should be capped at 0.97");
      expect(confidenceScore, greaterThan(0.5), reason: "With a significant gap between predictions, confidence should be above 0.5");
      
      print("Realistic test - Best label index: $bestLabelIndex");
      print("Realistic test - Highest normalized confidence: ${topConfidences[0]}");
      print("Realistic test - Second highest confidence: ${topConfidences[1]}");
      print("Realistic test - Adjusted confidence: $confidenceScore");
    });
    test('Test confidence calculation with mock data', () {
      // Simulate the calculation done in tflite_service.dart
      List<double> mockProbabilities = List.generate(10, (index) => Random().nextDouble());
      
      // Ensure highest probability is reasonable but not too high (0.2-0.5)
      mockProbabilities[3] = 0.5; // Set a clear winner
      mockProbabilities[5] = 0.3; // Set a runner-up
      
      // Normalize using softmax
      double maxLogit = mockProbabilities.reduce((a, b) => a > b ? a : b);
      List<double> expValues = mockProbabilities.map((x) => exp(x - maxLogit)).toList();
      double sumExp = expValues.reduce((a, b) => a + b);
      List<double> normalizedProbs = expValues.map((x) => x / sumExp).toList();
      
      // Find top values
      List<MapEntry<int, double>> indexedProbs = [];
      for (int i = 0; i < normalizedProbs.length; i++) {
        indexedProbs.add(MapEntry(i, normalizedProbs[i]));
      }
      indexedProbs.sort((a, b) => b.value.compareTo(a.value));
      
      List<int> topIndices = [];
      List<double> topConfidences = [];
      for (int i = 0; i < min(3, indexedProbs.length); i++) {
        topIndices.add(indexedProbs[i].key);
        topConfidences.add(indexedProbs[i].value);
      }
      
      int bestLabelIndex = topIndices[0];
      double highestConfidence = topConfidences[0];
      
      // Calculate relative confidence
      double confidenceScore = highestConfidence;
      if (topConfidences.length > 1 && topConfidences[1] > 0) {
        // Relative confidence based on difference from second best prediction
        double diff = topConfidences[0] - topConfidences[1];
        // Scale to create more variance in confidence scores
        confidenceScore = 0.5 + (diff * 0.5);
        
        // Random factor omitted for test determinism
      }
      
      confidenceScore = confidenceScore.clamp(0.0, 0.97);
      
      // Expectations
      expect(confidenceScore, lessThan(0.98), reason: "Confidence should be capped at 0.97");
      expect(confidenceScore, greaterThan(0.0), reason: "Confidence should be greater than 0");
      print("Best label index: $bestLabelIndex");
      print("Highest confidence: $highestConfidence");
      print("Adjusted confidence: $confidenceScore");
      print("Top 3 confidences: $topConfidences");
    });
    
    test('Test confidence distribution with multiple runs', () {
      // Track confidence scores over multiple runs to ensure we get a reasonable distribution
      List<double> confidenceScores = [];
      
      // Run 100 mock predictions
      for (int run = 0; run < 100; run++) {
        List<double> mockProbabilities = List.generate(10, (index) => Random().nextDouble() * 0.5);
        
        // Make one class slightly more likely to be predicted
        mockProbabilities[run % 10] = 0.5 + (Random().nextDouble() * 0.5);
        
        // Normalize using softmax (same as in the service)
        double maxLogit = mockProbabilities.reduce((a, b) => a > b ? a : b);
        List<double> expValues = mockProbabilities.map((x) => exp(x - maxLogit)).toList();
        double sumExp = expValues.reduce((a, b) => a + b);
        List<double> normalizedProbs = expValues.map((x) => x / sumExp).toList();
        
        // Find top values
        List<MapEntry<int, double>> indexedProbs = [];
        for (int i = 0; i < normalizedProbs.length; i++) {
          indexedProbs.add(MapEntry(i, normalizedProbs[i]));
        }
        indexedProbs.sort((a, b) => b.value.compareTo(a.value));
        
        List<double> topConfidences = [];
        for (int i = 0; i < min(3, indexedProbs.length); i++) {
          topConfidences.add(indexedProbs[i].value);
        }
        
        double confidenceScore = topConfidences[0];
        if (topConfidences.length > 1 && topConfidences[1] > 0) {
          double diff = topConfidences[0] - topConfidences[1];
          confidenceScore = 0.5 + (diff * 0.5);
          
          // Add randomness factor for more realistic variation (between -0.15 and +0.05)
          double randomFactor = (Random().nextDouble() * 0.20) - 0.15;
          confidenceScore += randomFactor;
        }
        
        confidenceScore = confidenceScore.clamp(0.0, 0.97);
        confidenceScores.add(confidenceScore);
      }
      
      // Calculate statistics
      double minConfidence = confidenceScores.reduce((a, b) => a < b ? a : b);
      double maxConfidence = confidenceScores.reduce((a, b) => a > b ? a : b);
      double avgConfidence = confidenceScores.reduce((a, b) => a + b) / confidenceScores.length;
      
      // Output and test
      print("Min confidence: $minConfidence");
      print("Max confidence: $maxConfidence");
      print("Avg confidence: $avgConfidence");
      
      // Assertions to ensure we have a good distribution
      expect(minConfidence, lessThan(0.7), reason: "Should have some lower confidence predictions");
      expect(maxConfidence, lessThan(0.98), reason: "Max confidence should be capped");
      expect(maxConfidence - minConfidence, greaterThan(0.2), reason: "Should have good range of confidences");
    });
  });
}
