import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';

class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;

  Future<void> initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        print('Tidak ada kamera yang tersedia');
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
      print('Kamera berhasil diinisialisasi');
    } catch (e) {
      print('Error saat inisialisasi kamera: $e');
      _isInitialized = false;
    }
  }

  Future<File?> takePicture() async {
    if (!_isInitialized || _controller == null) {
      print('Kamera belum diinisialisasi');
      return null;
    }

    try {
      final XFile image = await _controller!.takePicture();
      
      // Simpan ke direktori temporary
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName = 'camera_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = '${tempDir.path}/$fileName';
      
      final File imageFile = File(image.path);
      final File savedFile = await imageFile.copy(filePath);
      
      print('Gambar berhasil disimpan: $filePath');
      return savedFile;
    } catch (e) {
      print('Error saat mengambil gambar: $e');
      return null;
    }
  }

  void dispose() {
    _controller?.dispose();
    _isInitialized = false;
    print('Camera service disposed');
  }
}
