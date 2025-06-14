import 'package:flutter/material.dart';
import 'package:ai_food_recognizer_app/models/recipe_model.dart';
import 'package:ai_food_recognizer_app/api/mealdb_api_service.dart';
import 'package:ai_food_recognizer_app/api/gemini_api_service.dart';

class RecipeTab extends StatefulWidget {
  final String foodName;

  const RecipeTab({super.key, required this.foodName});

  @override
  State<RecipeTab> createState() => _RecipeTabState();
}

class _RecipeTabState extends State<RecipeTab> {
  final MealDbApiService _mealDbService = MealDbApiService();
  final GeminiApiService _geminiService = GeminiApiService();
  List<RecipeModel>? _recipes;
  bool _isLoading = true;
  String? _errorMessage;
  String? _enhancedFoodName;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Pertama, coba dapatkan nama makanan yang lebih baik dari Gemini
      String searchQuery = widget.foodName;
      
      try {
        // Gunakan Gemini untuk mendapatkan nama makanan yang lebih standar untuk pencarian resep
        final enhancedName = await _geminiService.getEnhancedFoodNameForRecipe(widget.foodName);
        if (enhancedName != null && enhancedName.isNotEmpty) {
          searchQuery = enhancedName;
          _enhancedFoodName = enhancedName;
        }
      } catch (e) {
        print('Gagal mendapatkan nama makanan yang ditingkatkan: $e');
        // Lanjutkan dengan nama asli
      }

      // Cari resep menggunakan MealDB API
      List<RecipeModel>? recipes;
      
      // Gunakan method yang lebih baik untuk pencarian resep
      if (_enhancedFoodName != null) {
        recipes = await _mealDbService.searchRecipesByGeminiFoodName(_enhancedFoodName!);
      } else {
        recipes = await _mealDbService.searchRecipesByName(searchQuery);
      }
      
      setState(() {
        _recipes = recipes;
        _isLoading = false;
        if (recipes == null || recipes.isEmpty) {
          _errorMessage = 'Tidak ada resep ditemukan untuk "$searchQuery"';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Terjadi kesalahan: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Mencari resep...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRecipes,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_recipes == null || _recipes!.isEmpty) {
      return const Center(
        child: Text('Resep tidak tersedia'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _recipes!.length,
      itemBuilder: (context, index) {
        final recipe = _recipes![index];
        return _buildRecipeCard(recipe);
      },
    );
  }

  Widget _buildRecipeCard(RecipeModel recipe) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recipe Image
          if (recipe.image.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              child: Image.network(
                recipe.image,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported, size: 50),
                  );
                },
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recipe Title
                Text(
                  recipe.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Category and Area
                Row(
                  children: [
                    Icon(Icons.category, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(recipe.category, style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(width: 16),
                    Icon(Icons.public, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(recipe.area, style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Ingredients
                Text(
                  'Bahan-bahan:',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...recipe.ingredients.asMap().entries.map((entry) {
                  int idx = entry.key;
                  String ingredient = entry.value;
                  String measurement = idx < recipe.measurements.length 
                      ? recipe.measurements[idx] 
                      : '';
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Text('• '),
                        Expanded(
                          child: Text('$measurement $ingredient'.trim()),
                        ),
                      ],
                    ),
                  );
                }).take(8), // Tampilkan maksimal 8 bahan
                
                if (recipe.ingredients.length > 8)
                  Text(
                    '... dan ${recipe.ingredients.length - 8} bahan lainnya',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Instructions
                Text(
                  'Cara Memasak:',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  recipe.instructions.length > 300 
                      ? '${recipe.instructions.substring(0, 300)}...'
                      : recipe.instructions,
                  style: const TextStyle(height: 1.5),
                ),
                
                const SizedBox(height: 16),
                
                // Action Buttons
                Row(
                  children: [
                    if (recipe.youtubeUrl != null && recipe.youtubeUrl!.isNotEmpty)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _showUrlDialog(context, 'YouTube Video', recipe.youtubeUrl!);
                          },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Video'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    
                    if (recipe.youtubeUrl != null && recipe.youtubeUrl!.isNotEmpty &&
                        recipe.sourceUrl != null && recipe.sourceUrl!.isNotEmpty)
                      const SizedBox(width: 8),
                    
                    if (recipe.sourceUrl != null && recipe.sourceUrl!.isNotEmpty)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _showUrlDialog(context, 'Sumber Resep', recipe.sourceUrl!);
                          },
                          icon: const Icon(Icons.link),
                          label: const Text('Sumber'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    
                    if ((recipe.youtubeUrl == null || recipe.youtubeUrl!.isEmpty) &&
                        (recipe.sourceUrl == null || recipe.sourceUrl!.isEmpty))
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _showFullInstructions(context, recipe);
                          },
                          icon: const Icon(Icons.visibility),
                          label: const Text('Lihat Detail'),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showUrlDialog(BuildContext context, String title, String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('URL: $url'),
            const SizedBox(height: 16),
            const Text(
              'Maaf, fitur buka link eksternal belum diimplementasikan. '
              'Anda dapat menyalin URL ini untuk dibuka di browser.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showFullInstructions(BuildContext context, RecipeModel recipe) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(recipe.name),
        content: SingleChildScrollView(
          child: Text(recipe.instructions),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}
