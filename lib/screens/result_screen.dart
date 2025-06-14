import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ai_food_recognizer_app/models/prediction_model.dart';
import 'package:ai_food_recognizer_app/widgets/nutrition_tab.dart';
import 'package:ai_food_recognizer_app/widgets/recipe_tab.dart';

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
      length: 2,
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                              color: Colors.black.withOpacity(0.1),
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
                                  Icon(Icons.restaurant, color: Colors.green[600]),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Prediksi Makanan:',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                prediction.label,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.verified, color: Colors.blue[600], size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Tingkat Kepercayaan: ${(prediction.confidence * 100).toStringAsFixed(1)}%',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                delegate: _SliverTabBarDelegate(
                  TabBar(
                    labelColor: Colors.green[700],
                    unselectedLabelColor: Colors.grey[600],
                    indicatorColor: Colors.green[700],
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.food_bank_outlined),
                        text: 'Nutrisi',
                      ),
                      Tab(
                        icon: Icon(Icons.receipt_long_outlined),
                        text: 'Resep',
                      ),
                    ],
                  ),
                ),
                pinned: true,
              ),
            ];
          },
          body: TabBarView(
            children: [
              NutritionTab(foodName: prediction.label),
              RecipeTab(foodName: prediction.label),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
