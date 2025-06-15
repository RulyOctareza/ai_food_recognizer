import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:ai_food_recognizer_app/models/nutrition_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiApiService {
  late final GenerativeModel _model;

  GeminiApiService() {
    try {
      // Get API key from .env file
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      
      // Validate API key
      if (apiKey == null || apiKey.isEmpty || apiKey == 'your_gemini_api_key_here') {
        print('WARNING: Gemini API key is missing or invalid in .env file');
        throw Exception('Invalid Gemini API key configuration');
      }
      
      _model = GenerativeModel(
        model: 'gemini-2.0-flash', // Ganti ke model yang tersedia
        apiKey: apiKey,
      );
    } catch (e) {
      print('ERROR: Failed to initialize Gemini API service: $e');
      rethrow; // Re-throw to allow proper error handling upstream
    }
  }

  Future<NutritionModel?> getNutritionInfo(String foodName) async {
    try {
      // Buat prompt yang spesifik untuk mendapatkan informasi nutrisi
      final prompt = '''
Berikan informasi nutrisi lengkap untuk makanan "$foodName" dalam bahasa Indonesia. 
Format jawaban sebagai berikut:

MAKANAN: $foodName

INFORMASI NUTRISI (per 100 gram):
- Kalori: [jumlah] kkal
- Protein: [jumlah] gram
- Karbohidrat: [jumlah] gram
- Lemak: [jumlah] gram
- Serat: [jumlah] gram
- Gula: [jumlah] gram
- Natrium: [jumlah] mg

VITAMIN DAN MINERAL:
- [daftar vitamin dan mineral yang terkandung]

MANFAAT KESEHATAN:
- [manfaat kesehatan dari makanan ini]

TIPS KONSUMSI:
- [saran cara konsumsi yang sehat]

Berikan jawaban yang akurat dan berdasarkan data nutrisi yang valid.
''';

      print('Mengirim permintaan ke Gemini API untuk: $foodName');

      final content = [Content.text(prompt)];
      
      try {
        final response = await _model.generateContent(content)
            .timeout(const Duration(seconds: 30), onTimeout: () {
          print('TIMEOUT: Gemini API request timed out after 30 seconds');
          throw Exception('Gemini API request timed out');
        });

        if (response.text != null && response.text!.isNotEmpty) {
          print('Respons Gemini API berhasil diterima');
          return NutritionModel.fromGeminiResponse(response.text!, foodName);
        } else {
          print('Respons Gemini API kosong');
          return null;
        }
      } catch (apiError) {
        if (apiError.toString().contains('API key')) {
          print('ERROR: Invalid API key configuration. Check your .env file.');
        } else {
          print('API Error: $apiError');
        }
        return null;
      }
    } catch (e) {
      print('Error saat mengakses Gemini API: $e');
      return null;
    }
  }

  Future<String?> getFoodDescription(String foodName) async {
    try {
      final prompt = '''
Berikan deskripsi singkat tentang makanan "$foodName" dalam bahasa Indonesia. 
Sertakan asal daerah, bahan utama, dan karakteristik unik dari makanan ini.
Maksimal 3 paragraf.
''';

      final content = [Content.text(prompt)];
      
      try {
        final response = await _model.generateContent(content)
            .timeout(const Duration(seconds: 20), onTimeout: () {
          print('TIMEOUT: Food description request timed out after 20 seconds');
          throw Exception('Food description request timed out');
        });

        return response.text;
      } catch (apiError) {
        if (apiError.toString().contains('API key')) {
          print('ERROR: Invalid API key configuration for food description');
        } else {
          print('API Error in food description: $apiError');
        }
        return null;
      }
    } catch (e) {
      print('Error saat mendapatkan deskripsi makanan: $e');
      return null;
    }
  }

  Future<String?> getEnhancedFoodNameForRecipe(String foodName) async {
    try {
      // Jika foodName adalah Knowledge Graph ID atau label khusus, gunakan prompt khusus
      String prompt;
      
      if (foodName.startsWith('/g/')) {
        prompt = '''
Ubah ID Knowledge Graph "$foodName" menjadi nama makanan yang standar dan internasional untuk pencarian resep dalam bahasa Inggris.

Aturan:
1. Knowledge Graph ID dimulai dengan /g/ dan diikuti dengan identifier
2. ID ini mewakili jenis makanan tertentu dalam database makanan
3. Berikan nama makanan yang umumnya dikenal secara internasional
4. Fokus pada nama makanan utama, bukan deskripsi panjang
5. Maksimal 2-3 kata

Jawab HANYA nama makanan yang diminta, tanpa penjelasan tambahan.

ID: "$foodName"
Nama makanan:''';
      } 
      else if (foodName.startsWith('__')) {
        prompt = '''
Ubah label khusus model AI "$foodName" menjadi nama makanan yang standar untuk pencarian resep dalam bahasa Inggris.

Aturan:
1. Jika ini adalah __background__ atau label non-makanan, berikan kategori makanan umum
2. Jika ini adalah label makanan khusus, ubah ke nama makanan standar
3. Gunakan nama yang paling umum digunakan dalam resep internasional
4. Maksimal 2-3 kata

Jawab HANYA nama makanan yang diminta, tanpa penjelasan tambahan.

Label: "$foodName" 
Nama makanan:''';
      }
      else {
        prompt = '''
Berikan nama makanan yang lebih standar dan internasional untuk "$foodName" yang cocok untuk pencarian resep dalam bahasa Inggris.

Aturan:
1. Jika makanan Indonesia, berikan nama dalam bahasa Inggris yang umum digunakan
2. Jika sudah dalam bahasa Inggris, perbaiki ejaan dan standarisasi
3. Gunakan nama yang paling umum digunakan dalam resep internasional
4. Fokus pada nama makanan utama, bukan deskripsi panjang
5. Maksimal 2-3 kata

Contoh:
- "Nasi Goreng" → "Fried Rice"
- "Rendang" → "Beef Rendang" 
- "Gado-gado" → "Indonesian Salad"
- "Chicken curry" → "Chicken Curry"
- "Pizza margherita" → "Margherita Pizza"

Jawab HANYA nama makanan yang diminta, tanpa penjelasan tambahan.

Makanan: "$foodName"
Jawaban:''';
      }

      final content = [Content.text(prompt)];
      
      try {
        final response = await _model.generateContent(content)
            .timeout(const Duration(seconds: 15), onTimeout: () {
          print('TIMEOUT: Enhanced food name request timed out');
          throw Exception('Food name enhancement request timed out');
        });

        if (response.text != null && response.text!.isNotEmpty) {
          // Bersihkan respons dari whitespace dan karakter yang tidak perlu
          String cleanedName = response.text!.trim();

          // Hapus tanda petik jika ada
          cleanedName = cleanedName.replaceAll('"', '').replaceAll("'", '');

          // Pastikan tidak terlalu panjang
          if (cleanedName.split(' ').length <= 4 && cleanedName.length <= 50) {
            print('Nama makanan yang ditingkatkan: "$foodName" → "$cleanedName"');
            return cleanedName;
          } else {
            print('Nama makanan terlalu panjang, gunakan nama asli');
            return foodName; // Return original food name as fallback
          }
        }

        return foodName; // Return original food name if response is empty
        
      } catch (apiError) {
        print('API Error in enhanced food name: $apiError');
        // Fall back to original food name
        return foodName;
      }
    } catch (e) {
      print('Error saat mendapatkan nama makanan yang ditingkatkan: $e');
      return foodName; // Return original name as fallback
    }
  }
}
