import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ai_food_recognizer_app/services/image_picker_service.dart';
import 'package:ai_food_recognizer_app/services/tflite_service.dart';
import 'package:ai_food_recognizer_app/models/prediction_model.dart';
import 'result_screen.dart';
import 'camera_screen.dart';
import 'dart:developer';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePickerService _imagePickerService = ImagePickerService();
  final TfliteService _tfliteService = TfliteService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tfliteService.loadModel(); // Muat model saat halaman diinisialisasi
  }

  @override
  void dispose() {
    _tfliteService.dispose();
    super.dispose();
  }

  Future<void> _pickAndProcessImage() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    File? pickedImage = await _imagePickerService.pickImageFromGallery(context);
    if (pickedImage == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      return;
    }

    if (!mounted) return;
    File? croppedImage =
        await _imagePickerService.cropImage(pickedImage, context);
    if (croppedImage == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Pemotongan gambar dibatalkan atau gagal.')),
      );
      return;
    }

    PredictionModel? prediction;
    try {
      prediction = await _tfliteService
          .predictImage(croppedImage)
          .timeout(const Duration(seconds: 15), onTimeout: () {
        log('Timeout saat melakukan prediksi gambar');
        return null;
      });
    } catch (e) {
      log('Error saat melakukan prediksi: $e');
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    if (prediction != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            imageFile: croppedImage,
            prediction: prediction!,
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Gagal mendapatkan prediksi makanan. Coba lagi atau restart aplikasi.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: .3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color.withValues(alpha: .8),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: color.withValues(alpha: .7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.green[200]!, Colors.green[600]!],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Logo dan judul
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .2),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.restaurant_menu,
                          size: 60,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'AI Food Recognizer',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Kenali makanan favoritmu dengan AI',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Card untuk opsi pengambilan gambar
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .1),
                      blurRadius: 10,
                      spreadRadius: 5,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pilih Cara Pengambilan Gambar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ambil gambar makanan untuk dikenali oleh AI',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Tombol
                    Row(
                      children: [
                        Expanded(
                          child: _buildOptionButton(
                            icon: Icons.photo_library,
                            title: 'Galeri',
                            description: 'Pilih foto dari galeri',
                            color: Colors.blue,
                            onTap: _isLoading ? null : _pickAndProcessImage,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildOptionButton(
                            icon: Icons.camera_alt,
                            title: 'Kamera',
                            description: 'Ambil foto baru',
                            color: Colors.orange,
                            onTap: _isLoading
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const CameraScreen(),
                                      ),
                                    );
                                  },
                          ),
                        ),
                      ],
                    ),
                    if (_isLoading)
                      Container(
                        margin: const EdgeInsets.only(top: 20),
                        child: const Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 10),
                              Text('Memproses gambar...'),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
