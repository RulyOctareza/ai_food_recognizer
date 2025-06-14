import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ai_food_recognizer_app/services/image_picker_service.dart';
import 'package:ai_food_recognizer_app/services/tflite_service.dart';
import 'package:ai_food_recognizer_app/models/prediction_model.dart';
import 'result_screen.dart';
import 'camera_screen.dart';

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
    setState(() {
      _isLoading = true;
    });

    File? pickedImage = await _imagePickerService.pickImageFromGallery(context);
    if (pickedImage == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    File? croppedImage = await _imagePickerService.cropImage(pickedImage, context);
    if (croppedImage == null) {
      // Jika cropping dibatalkan atau gagal, gunakan gambar asli
      // Atau bisa juga hentikan proses jika crop wajib
      // croppedImage = pickedImage; 
       setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pemotongan gambar dibatalkan atau gagal.')),
      );
      return;
    }

    PredictionModel? prediction = await _tfliteService.predictImage(croppedImage);

    setState(() {
      _isLoading = false;
    });

    if (prediction != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            imageFile: croppedImage,
            prediction: prediction,
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mendapatkan prediksi makanan.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Food Recognizer'),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CameraScreen(),
                        ),
                      );
                    },
                    child: const Text('Buka Kamera'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _pickAndProcessImage,
                    child: const Text('Pilih dari Galeri'),
                  ),
                ],
              ),
      ),
    );
  }
}
