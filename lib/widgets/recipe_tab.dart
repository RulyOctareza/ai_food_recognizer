import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/mealdb_api_service.dart';
import '../models/recipe_model.dart';

class RecipeTab extends StatefulWidget {
  final String foodName;

  const RecipeTab({super.key, required this.foodName});

  @override
  State<RecipeTab> createState() => _RecipeTabState();
}

class _RecipeTabState extends State<RecipeTab> {
  late Future<List<RecipeModel>?> _recipeFuture;
  final MealDbApiService _mealDbApiService = MealDbApiService();

  @override
  void initState() {
    super.initState();
    _recipeFuture = _mealDbApiService.searchRecipes(widget.foodName);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RecipeModel>?>(
      future: _recipeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('Tidak ada resep yang tersedia.'),
          );
        }

        final recipes = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: recipes.length,
          itemBuilder: (context, index) {
            final recipe = recipes[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                leading: recipe.image.isNotEmpty
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(recipe.image),
                      )
                    : CircleAvatar(
                        backgroundColor: Colors.orange[100],
                        child: Icon(
                          Icons.receipt_long,
                          color: Colors.orange[800],
                        ),
                      ),
                title: Text(
                  recipe.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  recipe.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  if (recipe.sourceUrl != null &&
                      recipe.sourceUrl!.isNotEmpty) {
                    _launchURL(recipe.sourceUrl!);
                  } else if (recipe.youtubeUrl != null &&
                      recipe.youtubeUrl!.isNotEmpty) {
                    _launchURL(recipe.youtubeUrl!);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tidak ada link sumber yang tersedia.'),
                      ),
                    );
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw 'Could not launch $url';
    }
  }
}
