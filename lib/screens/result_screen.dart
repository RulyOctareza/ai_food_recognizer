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
    final bool isFood = prediction.label != 'Bukan makanan';

    return DefaultTabController(
      length: isFood ? 2 : 0,
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
                                        borderRadius:
                                            BorderRadius.circular(8),
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
                                                  fontWeight:
                                                      FontWeight.w500),
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
              if (isFood)
                SliverPersistentHeader(
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      tabs: const [
                        Tab(icon: Icon(Icons.food_bank), text: 'Nutrisi'),
                        Tab(icon: Icon(Icons.receipt), text: 'Resep'),
                      ],
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
              ? TabBarView(
                  children: [
                    // Nutrition Tab
                    NutritionTab(nutrition: prediction.nutrition ?? const {}),

                    // Recipe Tab
                    RecipeTab(recipes: prediction.recipes ?? const []),
                  ],
                )
              : const Center(
                  child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'Tidak ada detail nutrisi atau resep untuk item ini.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )),
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
    if (widget.foodName != 'Bukan makanan') {
      _loadDescription();
    } else {
      setState(() {
        _isLoading = false;
        _description = 'Objek ini tidak dikenali sebagai makanan.';
      });
    }
  }

  Future<void> _loadDescription() async {
    try {
      final description =
          await _geminiService.getFoodDescription(widget.foodName);
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

    if (widget.foodName == 'Bukan makanan') {
      return Container(); // Jangan tampilkan kartu deskripsi
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
