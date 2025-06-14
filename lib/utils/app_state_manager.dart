import 'package:flutter/material.dart';

enum AppState {
  idle,
  loading,
  success,
  error,
}

enum ProcessingStep {
  none,
  loadingModel,
  processingImage,
  runningInference,
  fetchingNutrition,
  searchingRecipes,
  completed,
}

class AppStateManager {
  AppState _currentState = AppState.idle;
  ProcessingStep _currentStep = ProcessingStep.none;
  String? _errorMessage;
  double _progress = 0.0;

  AppState get currentState => _currentState;
  ProcessingStep get currentStep => _currentStep;
  String? get errorMessage => _errorMessage;
  double get progress => _progress;

  void setState(AppState state, {ProcessingStep? step, String? error, double? progress}) {
    _currentState = state;
    if (step != null) _currentStep = step;
    _errorMessage = error;
    if (progress != null) _progress = progress;
  }

  void setLoading(ProcessingStep step, {double? progress}) {
    setState(AppState.loading, step: step, progress: progress);
  }

  void setSuccess(ProcessingStep step) {
    setState(AppState.success, step: step, progress: 1.0);
  }

  void setError(String error, {ProcessingStep? step}) {
    setState(AppState.error, step: step ?? _currentStep, error: error, progress: 0.0);
  }

  void reset() {
    setState(AppState.idle, step: ProcessingStep.none, progress: 0.0);
    _errorMessage = null;
  }

  String getStepMessage() {
    switch (_currentStep) {
      case ProcessingStep.none:
        return 'Siap memproses';
      case ProcessingStep.loadingModel:
        return 'Memuat model AI...';
      case ProcessingStep.processingImage:
        return 'Memproses gambar...';
      case ProcessingStep.runningInference:
        return 'Menjalankan prediksi...';
      case ProcessingStep.fetchingNutrition:
        return 'Mengambil informasi nutrisi...';
      case ProcessingStep.searchingRecipes:
        return 'Mencari resep...';
      case ProcessingStep.completed:
        return 'Selesai!';
    }
  }
}

// Widget untuk menampilkan progress
class ProgressIndicatorWidget extends StatelessWidget {
  final AppStateManager stateManager;
  final VoidCallback? onRetry;

  const ProgressIndicatorWidget({
    super.key,
    required this.stateManager,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    switch (stateManager.currentState) {
      case AppState.idle:
        return const SizedBox.shrink();
      
      case AppState.loading:
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                value: stateManager.progress > 0 ? stateManager.progress : null,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              const SizedBox(height: 16),
              Text(
                stateManager.getStepMessage(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              if (stateManager.progress > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${(stateManager.progress * 100).toInt()}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
            ],
          ),
        );
      
      case AppState.error:
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red[700],
              ),
              const SizedBox(height: 16),
              Text(
                'Terjadi Kesalahan',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                stateManager.errorMessage ?? 'Kesalahan tidak diketahui',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              if (onRetry != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        );
      
      case AppState.success:
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 48,
                color: Colors.green[700],
              ),
              const SizedBox(height: 16),
              Text(
                stateManager.getStepMessage(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.green[700],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
    }
  }
}
