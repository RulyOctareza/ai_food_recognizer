class NutritionModel {
  final String foodName;
  final String calories;
  final String protein;
  final String carbohydrates;
  final String fat;
  final String fiber;
  final String sugar;
  final String sodium;
  final List<String> vitamins;
  final List<String> minerals;
  final String servingSize;
  final String description;

  NutritionModel({
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.carbohydrates,
    required this.fat,
    required this.fiber,
    required this.sugar,
    required this.sodium,
    required this.vitamins,
    required this.minerals,
    required this.servingSize,
    required this.description,
  });

  factory NutritionModel.fromGeminiResponse(String response, String foodName) {
    // Parse response dari Gemini API dan ekstrak informasi nutrisi
    // Ini adalah implementasi sederhana, bisa diperbaiki dengan regex yang lebih baik
    return NutritionModel(
      foodName: foodName,
      calories: _extractValue(response, 'kalori') ?? 'Data tidak tersedia',
      protein: _extractValue(response, 'protein') ?? 'Data tidak tersedia',
      carbohydrates: _extractValue(response, 'karbohidrat') ?? 'Data tidak tersedia',
      fat: _extractValue(response, 'lemak') ?? 'Data tidak tersedia',
      fiber: _extractValue(response, 'serat') ?? 'Data tidak tersedia',
      sugar: _extractValue(response, 'gula') ?? 'Data tidak tersedia',
      sodium: _extractValue(response, 'natrium') ?? 'Data tidak tersedia',
      vitamins: _extractList(response, 'vitamin') ?? [],
      minerals: _extractList(response, 'mineral') ?? [],
      servingSize: '100g',
      description: response,
    );
  }

  static String? _extractValue(String text, String nutrient) {
    // Sederhana ekstraksi - bisa diperbaiki dengan regex yang lebih baik
    final patterns = [
      RegExp('$nutrient[:\\s]*([0-9]+[.,]?[0-9]*\\s*[a-zA-Z]*)', caseSensitive: false),
      RegExp('([0-9]+[.,]?[0-9]*\\s*[a-zA-Z]*)\\s*$nutrient', caseSensitive: false),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1)?.trim();
      }
    }
    return null;
  }

  static List<String>? _extractList(String text, String category) {
    // Implementasi sederhana untuk ekstraksi list vitamin/mineral
    // Bisa diperbaiki sesuai kebutuhan
    return [];
  }
}
