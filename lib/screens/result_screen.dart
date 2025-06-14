import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ai_food_recognizer_app/models/prediction_model.dart';
// Import widget tab jika sudah siap
// import 'package:ai_food_recognizer_app/widgets/nutrition_tab.dart';
// import 'package:ai_food_recognizer_app/widgets/recipe_tab.dart';

class ResultScreen extends StatelessWidget {
  final File imageFile;
  final PredictionModel prediction;

  const ResultScreen({
    super.key,
    required this.imageFile,
    required this.prediction,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Jumlah tab (Nutrisi, Resep)
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Hasil Prediksi'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.food_bank_outlined), text: 'Nutrisi'),
              Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Resep'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Konten Tab Nutrisi
            _buildPredictionDetails(context),
            // Konten Tab Resep
            // RecipeTab(foodName: prediction.label), // Akan diimplementasikan nanti
            Center(child: Text('Resep untuk ${prediction.label} (Akan datang)')),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionDetails(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Gambar Asli:',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8.0),
          Image.file(
            imageFile,
            height: 250,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 24.0),
          Text(
            'Prediksi Makanan:',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8.0),
          Card(
            elevation: 2.0,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prediction.label,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Tingkat Kepercayaan: ${(prediction.confidence * 100).toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24.0),
          // Placeholder untuk informasi nutrisi dari Gemini API
          Text(
            'Informasi Nutrisi (dari Gemini API - Akan datang):',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8.0),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Data nutrisi akan ditampilkan di sini.'),
            ),
          ),
        ],
      ),
    );
  }
}
