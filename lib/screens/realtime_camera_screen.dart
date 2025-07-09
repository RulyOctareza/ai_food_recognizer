import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../services/tflite_service.dart';

class RealTimeCameraScreen extends StatefulWidget {
  const RealTimeCameraScreen({super.key});

  @override
  State<RealTimeCameraScreen> createState() => _RealTimeCameraScreenState();
}

class _RealTimeCameraScreenState extends State<RealTimeCameraScreen> {
  CameraController? _cameraController;
  bool _isDetecting = false;
  String? _label;
  double? _confidence;
  Timer? _timer;
  TfliteService? _tfliteService;

  @override
  void initState() {
    super.initState();
    _tfliteService = TfliteService();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.first;
    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _cameraController!.initialize();
    if (mounted) setState(() {});
    _startImageStream();
  }

  void _startImageStream() {
    _timer = Timer.periodic(const Duration(milliseconds: 400), (_) async {
      if (_cameraController == null ||
          !_cameraController!.value.isInitialized ||
          _isDetecting) {
        return;
      }
      _isDetecting = true;
      try {
        final image = await _cameraController!.takePicture();
        if (_tfliteService != null) {
          final result =
              await _tfliteService!.predictImageWithIsolate(File(image.path));
          if (result.status == PredictionStatus.success &&
              result.prediction != null) {
            setState(() {
              _label = result.prediction!.label;
              _confidence = result.prediction!.confidence;
            });
          } else {
            setState(() {
              _label = 'Tidak dikenali';
              _confidence = null;
            });
          }
        }
        // Hapus file sementara agar storage tidak penuh
        try {
          File(image.path).delete();
        } catch (_) {}
      } catch (e) {
        // ignore error
      } finally {
        _isDetecting = false;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Real-Time Food Detection')),
      body: _cameraController == null || !_cameraController!.value.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                CameraPreview(_cameraController!),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    color: Colors.black.withValues(alpha: .7),
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _label ?? '-',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _confidence != null
                              ? '${(_confidence! * 100).toStringAsFixed(2)}%'
                              : '',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
