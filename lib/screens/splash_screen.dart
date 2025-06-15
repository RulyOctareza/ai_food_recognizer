import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ai_food_recognizer_app/screens/home_screen.dart';
import 'package:ai_food_recognizer_app/services/tflite_service.dart';
import 'package:ai_food_recognizer_app/utils/model_diagnostic_util.dart';
import 'package:ai_food_recognizer_app/utils/env_validator.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  final TfliteService _tfliteService = TfliteService();
  bool _modelLoaded = false;
  bool _timerComplete = false;
  String _loadingStatus = 'Initializing...';
  
  @override
  void initState() {
    super.initState();
    
    // Buat animasi untuk logo
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    // Validasi environment variables
    WidgetsBinding.instance.addPostFrameCallback((_) {
      EnvValidator.validateEnv(context);
    });
    
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _animationController.forward();
    
    // Load TFLite model di background
    _loadModel();
    
    // Pastikan splash screen muncul minimal 2.5 detik
    Timer(const Duration(milliseconds: 2500), () {
      setState(() {
        _timerComplete = true;
        _checkNavigate();
      });
    });
  }
  
  Future<void> _loadModel() async {
    try {
      setState(() {
        _loadingStatus = 'Mempersiapkan model AI...';
      });
      
      // Run diagnostic before attempting to load model
      try {
        final diagnostics = await ModelDiagnosticUtil.runDiagnostics();
        print(diagnostics);
      } catch (e) {
        print('Error running diagnostics: $e');
      }
      
      // Add timeout to prevent hanging indefinitely
      bool success = await _tfliteService.loadModel()
          .timeout(const Duration(seconds: 20), onTimeout: () {
        print('Timeout saat memuat model TFLite');
        return false;
      });
      
      setState(() {
        _loadingStatus = success ? 'Model berhasil dimuat!' : 'Gagal memuat model';
        _modelLoaded = success;
        
        if (!success) {
          // Even if model failed to load, we should proceed after a delay
          print('Model gagal dimuat, tapi aplikasi akan tetap dilanjutkan');
          
          // Show a message that we're continuing anyway
          Future.delayed(const Duration(seconds: 1), () {
            setState(() {
              _loadingStatus = 'Melanjutkan tanpa model...';
            });
            
            // Run diagnostic again to determine the cause of failure
            ModelDiagnosticUtil.runDiagnostics().then((diagnostics) {
              print('Post-failure diagnostics:\n$diagnostics');
            });
            
            Future.delayed(const Duration(seconds: 2), () {
              setState(() {
                _modelLoaded = true; // Force proceed
                _checkNavigate();
              });
            });
          });
        } else {
          _checkNavigate();
        }
      });
    } catch (e) {
      print('Error saat memuat model: $e');
      setState(() {
        _loadingStatus = 'Error: $e';
      });
      
      // Run diagnostic to determine the cause of the error
      ModelDiagnosticUtil.runDiagnostics().then((diagnostics) {
        print('Error diagnostics:\n$diagnostics');
      });
      
      // Proceed anyway after error
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _loadingStatus = 'Melanjutkan tanpa model...';
          _modelLoaded = true; // Force proceed
          _checkNavigate();
        });
      });
    }
  }
  
  void _checkNavigate() {
    if (_modelLoaded && _timerComplete) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green[300]!, Colors.green[700]!],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _animation,
              child: Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.restaurant_menu,
                    size: 80,
                    color: Colors.green[700],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            FadeTransition(
              opacity: _animation,
              child: const Text(
                'AI Food Recognizer',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              _loadingStatus,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
