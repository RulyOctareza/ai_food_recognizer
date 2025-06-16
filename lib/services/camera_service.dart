import 'dart:developer';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/material.dart';

class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  final ImageCropper _cropper = ImageCropper();

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;

  Future<void> initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        log('Tidak ada kamera yang tersedia');
        return;
      }

      // Pilih kamera belakang (biasanya index 0)
      final camera = _cameras!.first;

      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();
      _isInitialized = true;
      log('Kamera berhasil diinisialisasi');
    } catch (e) {
      log('Error saat inisialisasi kamera: $e');
      _isInitialized = false;
    }
  }

  Future<File?> takePicture() async {
    try {
      if (!_isInitialized || _controller == null) {
        log('Kamera belum diinisialisasi');
        return null;
      }

      final XFile image = await _controller!.takePicture();
      return File(image.path);
    } catch (e) {
      log('Error saat mengambil gambar: $e');
      return null;
    }
  }

  Future<File?> cropImage(File imageFile, BuildContext context) async {
    try {
      final CroppedFile? croppedFile = await _cropper.cropImage(
        sourcePath: imageFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Potong Gambar',
            toolbarColor: Colors.green,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Potong Gambar',
            aspectRatioLockEnabled: true,
            minimumAspectRatio: 1.0,
            aspectRatioPickerButtonHidden: true,
          ),
        ],
      );

      if (croppedFile != null) {
        return File(croppedFile.path);
      }
    } catch (e) {
      log('Error cropping image: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memotong gambar: $e')),
        );
      }
    }
    return null;
  }

  void dispose() {
    _controller?.dispose();
    _isInitialized = false;
  }
}
