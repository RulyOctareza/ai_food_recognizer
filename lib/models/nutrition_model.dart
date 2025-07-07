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
    return NutritionModel(
      foodName: foodName,
      calories: _extractValue(response, 'kalori') ?? 'Data tidak tersedia',
      protein: _extractValue(response, 'protein') ?? 'Data tidak tersedia',
      carbohydrates:
          _extractValue(response, 'karbohidrat') ?? 'Data tidak tersedia',
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
    // Lebih robust: support format key-value, bullet, tabel, dan satuan
    final patterns = [
      // Format: kalori: 120 kkal
      RegExp('$nutrient[:s]*([0-9]+[.,]?[0-9]*s*[a-zA-Z]*)',
          caseSensitive: false),
      // Format: 120 kkal kalori
      RegExp('([0-9]+[.,]?[0-9]*s*[a-zA-Z]*)s*$nutrient', caseSensitive: false),
      // Format: - kalori 120 kkal
      RegExp('-s*$nutrient[:s]*([0-9]+[.,]?[0-9]*s*[a-zA-Z]*)',
          caseSensitive: false),
      // Format tabel: | kalori | 120 kkal |
      RegExp('|s*${nutrient}s*|s*([0-9]+[.,]?[0-9]*s*[a-zA-Z]*)s*|',
          caseSensitive: false),
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
    // Ekstraksi list vitamin/mineral dari bullet, koma, atau baris
    // Contoh: "Vitamin: A, B1, B2, C" atau "- Vitamin: A\n- Vitamin: B1"
    final bulletPattern = RegExp('-s*$category[:s]*([ws,]+)',
        caseSensitive: false, multiLine: true);
    final linePattern = RegExp('$category[:s]*([ws,]+)', caseSensitive: false);
    final tablePattern =
        RegExp('|s*${category}s*|s*([ws,]+)s*|', caseSensitive: false);
    final patterns = [bulletPattern, linePattern, tablePattern];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final raw = match.group(1);
        if (raw != null) {
          // Split by comma or new line, trim each
          return raw
              .split(RegExp('[,\n]'))
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      }
    }
    return [];
  }
}
