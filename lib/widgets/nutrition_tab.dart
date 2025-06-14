import 'package:flutter/material.dart';
import 'package:ai_food_recognizer_app/models/nutrition_model.dart';
import 'package:ai_food_recognizer_app/api/gemini_api_service.dart';

class NutritionTab extends StatefulWidget {
  final String foodName;

  const NutritionTab({super.key, required this.foodName});

  @override
  State<NutritionTab> createState() => _NutritionTabState();
}

class _NutritionTabState extends State<NutritionTab> {
  final GeminiApiService _geminiService = GeminiApiService();
  NutritionModel? _nutritionData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNutritionData();
  }

  Future<void> _loadNutritionData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final nutrition = await _geminiService.getNutritionInfo(widget.foodName);
      
      setState(() {
        _nutritionData = nutrition;
        _isLoading = false;
        if (nutrition == null) {
          _errorMessage = 'Tidak dapat memuat informasi nutrisi';
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
            Text('Memuat informasi nutrisi...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadNutritionData,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_nutritionData == null) {
      return const Center(
        child: Text('Data nutrisi tidak tersedia'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Informasi Nutrisi',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
          Text(
            _nutritionData!.foodName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),

          // Nutrition Facts Card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fakta Nutrisi (per ${_nutritionData!.servingSize})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(thickness: 2),
                  _buildNutritionRow('Kalori', _nutritionData!.calories, Icons.local_fire_department),
                  _buildNutritionRow('Protein', _nutritionData!.protein, Icons.fitness_center),
                  _buildNutritionRow('Karbohidrat', _nutritionData!.carbohydrates, Icons.grain),
                  _buildNutritionRow('Lemak', _nutritionData!.fat, Icons.opacity),
                  _buildNutritionRow('Serat', _nutritionData!.fiber, Icons.eco),
                  _buildNutritionRow('Gula', _nutritionData!.sugar, Icons.cake),
                  _buildNutritionRow('Natrium', _nutritionData!.sodium, Icons.scatter_plot),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Detailed Description
          if (_nutritionData!.description.isNotEmpty) ...[
            Text(
              'Detail Informasi',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _nutritionData!.description,
                  style: const TextStyle(height: 1.5),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNutritionRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.green[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
