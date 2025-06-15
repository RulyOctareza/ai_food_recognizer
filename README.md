# AI Food Recognizer App

A Flutter application that recognizes food from images using TensorFlow Lite and provides recipe and nutrition information.

## Features

- **Food Recognition**: Uses a TFLite model to identify food items from user photos
- **Realistic Confidence Scores**: Provides meaningful confidence levels for predictions
- **Recipe Suggestions**: Shows recipes based on recognized food items
- **Nutrition Information**: Displays nutritional information for identified foods
- **Multi-source Label Support**: Uses multiple label files for better food identification
- **Knowledge Graph ID Support**: Handles specialized food IDs for better matching

## Recent Updates

### Improved Confidence Score Display
- Added a more realistic confidence score calculation that avoids always showing 100%
- Implemented a visual confidence bar with color indicators
- Added descriptive confidence level texts
- See [confidence score implementation documentation](docs/confidence_score_implementation.md) for details

### Enhanced Model Label Extraction
- Now supports both primary and fallback label files
- Better handling for Knowledge Graph IDs and special labels

## Technical Implementation

The app uses:
- TensorFlow Lite for on-device inference
- Firebase ML for model management
- Gemini API for enhanced recipe and nutrition information
- Flutter for cross-platform UI
- Environment variables for secure API key storage

## Getting Started

1. Clone the repository
2. Copy `.env.example` to `.env` and add your API keys:
   ```
   cp .env.example .env
   ```
3. Add your Gemini API key to the `.env` file:
   ```
   GEMINI_API_KEY=your_api_key_here
   ```
4. Install dependencies: `flutter pub get`
5. Run the app: `flutter run`

## Testing

Run tests with: `flutter test`

## Environment Setup

This application uses environment variables for secure configuration. For detailed setup instructions, see the [Environment Variables Setup](docs/environment_variables_setup.md) documentation.

Key environment variables:
- `GEMINI_API_KEY`: Required for food description, nutrition information, and recipe enhancement features
