import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class RecipeTab extends StatelessWidget {
  final List<String> recipes;

  const RecipeTab({super.key, required this.recipes});

  @override
  Widget build(BuildContext context) {
    if (recipes.isEmpty) {
      return const Center(
        child: Text('Tidak ada resep yang tersedia.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        // Simple check if the recipe is a URL
        final bool isUrl = recipe.startsWith('http');

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange[100],
              child: Icon(
                isUrl ? Icons.link : Icons.receipt_long,
                color: Colors.orange[800],
              ),
            ),
            title: Text(
              isUrl ? 'Lihat Resep Online' : 'Resep ${index + 1}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: isUrl ? null : Text(recipe, maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              if (isUrl) {
                _launchURL(recipe);
              } else {
                // Show full recipe in a dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Resep Lengkap'),
                    content: SingleChildScrollView(child: Text(recipe)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Tutup'),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      // Could show a snackbar here if needed
    }
  }
}
