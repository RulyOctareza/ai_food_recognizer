import 'package:flutter/material.dart';

class NutritionTab extends StatelessWidget {
  final Map<String, dynamic> nutrition;

  const NutritionTab({super.key, required this.nutrition});

  @override
  Widget build(BuildContext context) {
    if (nutrition.isEmpty) {
      return const Center(
        child: Text('Tidak ada data nutrisi yang tersedia.'),
      );
    }

    final entries = nutrition.entries.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
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
              entry.value.toString(),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatNutrientName(String key) {
    return key.replaceAll('_', ' ').split(' ').map((str) {
      if (str.isEmpty) return '';
      return str[0].toUpperCase() + str.substring(1);
    }).join(' ');
  }

  IconData _getIconForNutrient(String key) {
    switch (key.toLowerCase()) {
      case 'calories':
        return Icons.local_fire_department;
      case 'fat':
        return Icons.opacity;
      case 'carbs':
      case 'carbohydrates':
        return Icons.grain;
      case 'protein':
        return Icons.fitness_center;
      case 'sugar':
        return Icons.cake;
      case 'fiber':
        return Icons.eco;
      default:
        return Icons.adjust;
    }
  }
}
