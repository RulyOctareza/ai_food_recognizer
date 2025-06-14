class RecipeModel {
  final String id;
  final String name;
  final String image;
  final String category;
  final String area;
  final String instructions;
  final List<String> ingredients;
  final List<String> measurements;
  final String? youtubeUrl;
  final String? sourceUrl;

  RecipeModel({
    required this.id,
    required this.name,
    required this.image,
    required this.category,
    required this.area,
    required this.instructions,
    required this.ingredients,
    required this.measurements,
    this.youtubeUrl,
    this.sourceUrl,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    // Ekstraksi ingredients dan measurements dari API MealDB
    List<String> ingredients = [];
    List<String> measurements = [];
    
    for (int i = 1; i <= 20; i++) {
      final ingredient = json['strIngredient$i'];
      final measurement = json['strMeasure$i'];
      
      if (ingredient != null && ingredient.toString().trim().isNotEmpty) {
        ingredients.add(ingredient.toString().trim());
        measurements.add(measurement?.toString().trim() ?? '');
      }
    }

    return RecipeModel(
      id: json['idMeal'] ?? '',
      name: json['strMeal'] ?? '',
      image: json['strMealThumb'] ?? '',
      category: json['strCategory'] ?? '',
      area: json['strArea'] ?? '',
      instructions: json['strInstructions'] ?? '',
      ingredients: ingredients,
      measurements: measurements,
      youtubeUrl: json['strYoutube'],
      sourceUrl: json['strSource'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idMeal': id,
      'strMeal': name,
      'strMealThumb': image,
      'strCategory': category,
      'strArea': area,
      'strInstructions': instructions,
      'strYoutube': youtubeUrl,
      'strSource': sourceUrl,
    };
  }
}
