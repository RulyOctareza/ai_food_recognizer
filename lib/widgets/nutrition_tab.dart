import 'package:flutter/material.dart';

import '../api/gemini_api_service.dart';
import '../models/nutrition_model.dart';

class NutritionTab extends StatefulWidget {
  final String foodName;

  const NutritionTab({super.key, required this.foodName});

  @override
  State<NutritionTab> createState() => _NutritionTabState();
}

class _NutritionTabState extends State<NutritionTab> {
  late Future<NutritionInfo?> _nutritionFuture;
  final GeminiApiService _geminiApiService = GeminiApiService();

  @override
  void initState() {
    super.initState();
    _nutritionFuture = _geminiApiService.getNutritionInfo(widget.foodName);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<NutritionInfo?>(
      future: _nutritionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data == null) {
          return const Center(
            child: Text('Tidak ada data nutrisi yang tersedia.'),
          );
        }

        final nutrition = snapshot.data!;
        final nutritionMap = nutrition.toMap();
        final entries = nutritionMap.entries.toList();

        // Log deskripsi nutrisi ke konsol
        debugPrint('[NUTRITION TAB] Deskripsi: ${nutrition.description}');

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bagian untuk menampilkan nilai nutrisi dalam ListTile
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  if (entry.value == null || entry.value.toString().isEmpty) {
                    return const SizedBox.shrink(); // Lewati entri kosong
                  }
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green[100],
                        child: Icon(
                          _getIconForNutrient(entry.key),
                          color: Colors.green[800],
                        ),
                      ),
                      title: Text(
                        _formatNutrientName(entry.key),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: Text(
                        entry.value.toString().split(' ').first, // Hanya angka
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Bagian untuk menampilkan deskripsi nutrisi
              Text(
                'Penjelasan Nutrisi',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    (nutrition.description != null &&
                            nutrition.description!.isNotEmpty)
                        ? nutrition.description!
                        : 'Deskripsi tidak tersedia.',
                    textAlign: TextAlign.justify,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getIconForNutrient(String nutrient) {
    switch (nutrient.toLowerCase()) {
      case 'calories':
        return Icons.local_fire_department;
      case 'carbs':
        return Icons.rice_bowl;
      case 'fat':
        return Icons.fastfood;
      case 'protein':
        return Icons.fitness_center;
      case 'sugar':
        return Icons.cake;
      case 'sodium':
        return Icons.grain;
      default:
        return Icons.spa;
    }
  }

  String _formatNutrientName(String name) {
    return name[0].toUpperCase() + name.substring(1);
  }
}
