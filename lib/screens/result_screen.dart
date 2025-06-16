import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ai_food_recognizer_app/models/prediction_model.dart';
import 'package:ai_food_recognizer_app/widgets/nutrition_tab.dart';
import 'package:ai_food_recognizer_app/widgets/recipe_tab.dart';
import 'package:ai_food_recognizer_app/api/gemini_api_service.dart';

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
                              color: Colors.black.withValues(alpha:0.1),
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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
                                  const SizedBox(height: 8),
                                  // Confidence bar visualization
                                  Container(
                                    width: double.infinity,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: prediction.confidence,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              if (prediction.confidence < 0.5)
                                                Colors.orange
                                              else if (prediction.confidence < 0.7)
                                                Colors.yellow
                                              else
                                                Colors.green[300]!,
                                              if (prediction.confidence < 0.5)
                                                Colors.red
                                              else if (prediction.confidence < 0.7)
                                                Colors.orange
                                              else
                                                Colors.green,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // Confidence level description
                                  Text(
                                    _getConfidenceDescription(prediction.confidence),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: prediction.confidence > 0.7 ? Colors.green[700] : 
                                             prediction.confidence > 0.5 ? Colors.orange[700] : Colors.red[700],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Tambahkan deskripsi makanan dari Gemini
                      FoodDescription(foodName: prediction.label),
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

// FoodDescription Widget yang menggunakan Gemini API
class FoodDescription extends StatefulWidget {
  final String foodName;

  const FoodDescription({super.key, required this.foodName});

  @override
  State<FoodDescription> createState() => _FoodDescriptionState();
}

class _FoodDescriptionState extends State<FoodDescription> {
  final GeminiApiService _geminiService = GeminiApiService();
  String? _description;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadDescription();
  }
  
  Future<void> _loadDescription() async {
    try {
      final description = await _geminiService.getFoodDescription(widget.foodName);
      setState(() {
        _description = description;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _description = 'Tidak dapat memuat deskripsi makanan.';
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
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
              _description ?? 'Deskripsi tidak tersedia.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.justify,
            ),
          ],
        ),
      ),
    );
  }
}
