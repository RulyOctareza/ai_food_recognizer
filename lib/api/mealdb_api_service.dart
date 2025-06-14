import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ai_food_recognizer_app/models/recipe_model.dart';

class MealDbApiService {
  static const String _baseUrl = 'https://www.themealdb.com/api/json/v1/1';
  // Using test API key "1" as mentioned in the documentation

  Future<List<RecipeModel>?> searchRecipesByName(String foodName) async {
    try {
      // Bersihkan nama makanan untuk pencarian
      String cleanFoodName = _cleanFoodName(foodName);
      
      print('Mencari resep untuk: $cleanFoodName');
      
      final url = Uri.parse('$_baseUrl/search.php?s=$cleanFoodName');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['meals'] != null) {
          List<RecipeModel> recipes = [];
          for (var meal in data['meals']) {
            recipes.add(RecipeModel.fromJson(meal));
          }
          print('Ditemukan ${recipes.length} resep');
          return recipes;
        } else {
          print('Tidak ada resep ditemukan untuk: $cleanFoodName');
          // Coba pencarian dengan kata kunci yang lebih umum
          return await _searchWithGenericTerms(cleanFoodName);
        }
      } else {
        print('Error HTTP: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error saat mengakses MealDB API: $e');
      return null;
    }
  }

  Future<List<RecipeModel>?> _searchWithGenericTerms(String foodName) async {
    // Daftar kata kunci umum untuk makanan Indonesia/Asia
    List<String> genericTerms = [
      'chicken', 'beef', 'rice', 'noodle', 'soup', 'curry', 'fried',
      'fish', 'pork', 'vegetable', 'pasta', 'bread', 'egg'
    ];

    String lowerFoodName = foodName.toLowerCase();
    
    for (String term in genericTerms) {
      if (lowerFoodName.contains(term) || 
          _containsIndonesianEquivalent(lowerFoodName, term)) {
        try {
          final url = Uri.parse('$_baseUrl/search.php?s=$term');
          final response = await http.get(url);
          
          if (response.statusCode == 200) {
            final Map<String, dynamic> data = json.decode(response.body);
            
            if (data['meals'] != null) {
              List<RecipeModel> recipes = [];
              // Ambil maksimal 3 resep pertama
              int count = 0;
              for (var meal in data['meals']) {
                if (count >= 3) break;
                recipes.add(RecipeModel.fromJson(meal));
                count++;
              }
              print('Ditemukan ${recipes.length} resep alternatif dengan kata kunci: $term');
              return recipes;
            }
          }
        } catch (e) {
          print('Error saat mencari dengan kata kunci $term: $e');
        }
      }
    }
    
    return await _getRandomRecipes();
  }

  bool _containsIndonesianEquivalent(String foodName, String englishTerm) {
    Map<String, List<String>> equivalents = {
      'chicken': ['ayam', 'unggas'],
      'beef': ['sapi', 'daging'],
      'rice': ['nasi', 'beras'],
      'noodle': ['mie', 'bakmi', 'kwetiau'],
      'fish': ['ikan', 'lele', 'gurame', 'bandeng'],
      'egg': ['telur', 'telor'],
      'soup': ['soto', 'sup', 'kuah'],
      'fried': ['goreng', 'bakar'],
    };

    if (equivalents[englishTerm] != null) {
      for (String equivalent in equivalents[englishTerm]!) {
        if (foodName.contains(equivalent)) {
          return true;
        }
      }
    }
    return false;
  }

  Future<List<RecipeModel>?> _getRandomRecipes() async {
    try {
      print('Mengambil resep acak...');
      List<RecipeModel> randomRecipes = [];
      
      // Ambil 3 resep acak
      for (int i = 0; i < 3; i++) {
        final url = Uri.parse('$_baseUrl/random.php');
        final response = await http.get(url);
        
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          
          if (data['meals'] != null && data['meals'].isNotEmpty) {
            randomRecipes.add(RecipeModel.fromJson(data['meals'][0]));
          }
        }
      }
      
      print('Ditemukan ${randomRecipes.length} resep acak');
      return randomRecipes.isNotEmpty ? randomRecipes : null;
    } catch (e) {
      print('Error saat mengambil resep acak: $e');
      return null;
    }
  }

  String _cleanFoodName(String foodName) {
    // Hapus prefix "Makanan Teridentifikasi" jika ada
    String cleaned = foodName.replaceAll(RegExp(r'^Makanan Teridentifikasi \d+'), '').trim();
    
    // Jika masih kosong atau tidak bermakna, gunakan kata kunci umum
    if (cleaned.isEmpty || cleaned.length < 3) {
      return 'chicken'; // Default fallback
    }
    
    // Translasi beberapa kata umum Indonesia ke English untuk pencarian yang lebih baik
    Map<String, String> translations = {
      'ayam': 'chicken',
      'sapi': 'beef',
      'ikan': 'fish',
      'nasi': 'rice',
      'mie': 'noodle',
      'telur': 'egg',
      'sayur': 'vegetable',
    };
    
    for (String indonesian in translations.keys) {
      if (cleaned.toLowerCase().contains(indonesian)) {
        return translations[indonesian]!;
      }
    }
    
    return cleaned;
  }

  Future<RecipeModel?> getRecipeById(String id) async {
    try {
      final url = Uri.parse('$_baseUrl/lookup.php?i=$id');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['meals'] != null && data['meals'].isNotEmpty) {
          return RecipeModel.fromJson(data['meals'][0]);
        }
      }
      return null;
    } catch (e) {
      print('Error saat mengambil resep berdasarkan ID: $e');
      return null;
    }
  }
}
