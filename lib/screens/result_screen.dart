import 'dart:io';
import 'package:flutter/material.dart';
import '../api/gemini_api_service.dart';
import '../models/prediction_model.dart';
import '../widgets/nutrition_tab.dart';
import '../widgets/recipe_tab.dart';

class ResultScreen extends StatelessWidget {
  final File imageFile;
  final PredictionModel prediction;

  const ResultScreen({
    super.key,
    required this.imageFile,
    required this.prediction,
  });

  // Helper method to get a description based on confidence level
  String _getConfidenceDescription(double confidence) {
    if (confidence > 0.85) {
      return 'Sangat yakin dengan prediksi ini';
    } else if (confidence > 0.7) {
      return 'Yakin dengan prediksi ini';
    } else if (confidence > 0.5) {
      return 'Cukup yakin dengan prediksi ini';
    } else if (confidence > 0.3) {
      return 'Kurang yakin dengan prediksi ini';
    } else {
      return 'Tidak yakin dengan prediksi ini';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isFood = prediction.label != 'Bukan makanan';
    final foodName = prediction.label;

    final List<Widget> tabs = [];
    final List<Widget> tabViews = [];

    if (isFood) {
      tabs.add(const Tab(icon: Icon(Icons.food_bank), text: 'Nutrisi'));
      tabViews.add(NutritionTab(foodName: foodName));
      tabs.add(const Tab(icon: Icon(Icons.receipt), text: 'Resep'));
      tabViews.add(RecipeTab(foodName: foodName));
    }

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Hasil Prediksi'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.grey[50],
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Gambar Asli:',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            imageFile,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Prediksi Card
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.restaurant,
                                      color: Colors.green[600]),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Prediksi Makanan:',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                prediction.label,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700],
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.verified,
                                          color: Colors.blue[600], size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Tingkat Kepercayaan: ${(prediction.confidence * 100).toStringAsFixed(1)}%',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: Colors.blue[700],
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Confidence bar visualization
                                  if (isFood)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        LinearProgressIndicator(
                                          value: prediction.confidence,
                                          backgroundColor: Colors.grey[300],
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            _getConfidenceColor(
                                                prediction.confidence),
                                          ),
                                          minHeight: 8,
                                        ),
                                        const SizedBox(height: 4),
                                        // Confidence level description
                                        Text(
                                          _getConfidenceDescription(
                                              prediction.confidence),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                            color: prediction.confidence > 0.7
                                                ? Colors.grey[700]
                                                : Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    // Pesan untuk item "Bukan Makanan"
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blueGrey[50],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.info_outline,
                                              color: Colors.blueGrey[700]),
                                          const SizedBox(width: 10),
                                          const Expanded(
                                            child: Text(
                                              'Gambar ini tidak terdeteksi sebagai makanan.',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Food Description (Gemini)
                      if (isFood)
                        FoodDescription(
                          foodName: prediction.label,
                        ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              if (isFood && tabs.isNotEmpty)
                SliverPersistentHeader(
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      tabs: tabs,
                      labelColor: Colors.green[700],
                      unselectedLabelColor: Colors.grey[600],
                      indicatorColor: Colors.green,
                    ),
                  ),
                  pinned: true,
                ),
            ];
          },
          body: isFood
              ? TabBarView(children: tabViews)
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            size: 60, color: Colors.orange),
                        const SizedBox(height: 20),
                        const Text(
                          'Objek yang dideteksi sepertinya bukan makanan.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _getConfidenceDescription(prediction.confidence),
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence > 0.85) return Colors.green;
    if (confidence > 0.7) return Colors.lightGreen;
    if (confidence > 0.5) return Colors.amber;
    return Colors.red;
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

// FoodDescription Widget yang menggunakan Gemini API
class FoodDescription extends StatelessWidget {
  final String foodName;
  final GeminiApiService _geminiService = GeminiApiService();

  FoodDescription({super.key, required this.foodName});

  @override
  Widget build(BuildContext context) {
    if (foodName == 'Bukan makanan') {
      return Container(); // Jangan tampilkan kartu deskripsi
    }

    return FutureBuilder<String?>(
      future: _geminiService.getFoodDescription(foodName),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(top: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Tidak dapat memuat deskripsi makanan.'),
            ),
          );
        }

        final description = snapshot.data!;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(top: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.description, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Tentang Makanan Ini:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
