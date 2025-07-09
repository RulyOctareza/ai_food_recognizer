class NutritionInfo {
  final String? calories;
  final String? carbs;
  final String? fat;
  final String? protein;
  final String? sugar;
  final String? sodium;
  final String? description;

  NutritionInfo({
    this.calories,
    this.carbs,
    this.fat,
    this.protein,
    this.sugar,
    this.sodium,
    this.description,
  });

  factory NutritionInfo.fromText(String text) {
    final Map<String, String> nutritionMap = {};
    final lines = text.toLowerCase().split('\n');

    final keywords = {
      'calories': ['kalori', 'calories'],
      'carbs': ['karbohidrat', 'carbohydrates', 'carbs'],
      'fat': ['lemak', 'fat'],
      'protein': ['protein'],
      'sugar': ['gula', 'sugar'],
      'sodium': ['natrium', 'sodium'],
    };

    for (var line in lines) {
      // Hapus karakter-karakter yang tidak perlu seperti '*' atau '-' di awal baris
      line = line.replaceAll(RegExp(r'^\s*[\*\-]\s*'), '').trim();

      final parts = line.split(':');
      if (parts.length >= 2) {
        final key = parts[0].replaceAll(RegExp(r'[\*]'), '').trim();
        final value = parts.sublist(1).join(':').trim();

        // Ambil bagian sebelum tanda kurung untuk mendapatkan nilai bersih
        final cleanValue = value.split('(').first.trim();

        keywords.forEach((mapKey, keywordList) {
          // Gunakan .any() untuk memeriksa apakah salah satu kata kunci ada di dalam `key`
          if (keywordList.any((k) => key.contains(k))) {
            nutritionMap[mapKey] = cleanValue;
          }
        });
      }
    }

    return NutritionInfo(
      calories: nutritionMap['calories'],
      carbs: nutritionMap['carbs'],
      fat: nutritionMap['fat'],
      protein: nutritionMap['protein'],
      sugar: nutritionMap['sugar'],
      sodium: nutritionMap['sodium'],
      description: text, // Simpan teks asli sebagai deskripsi
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'calories': calories,
      'carbs': carbs,
      'fat': fat,
      'protein': protein,
      'sugar': sugar,
      'sodium': sodium,
    };
  }
}
