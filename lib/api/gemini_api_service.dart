import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:ai_food_recognizer_app/models/nutrition_model.dart';

class GeminiApiService {
  static const String _apiKey = 'AIzaSyCTM3uyTyCFvlNTVwC-MT4ftrqHVu4_OyI';
  late final GenerativeModel _model;

  GeminiApiService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash', // Ganti ke model yang tersedia
      apiKey: _apiKey,
    );
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
      final response = await _model.generateContent(content);

      if (response.text != null && response.text!.isNotEmpty) {
        print('Respons Gemini API berhasil diterima');
        return NutritionModel.fromGeminiResponse(response.text!, foodName);
      } else {
        print('Respons Gemini API kosong');
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
      final response = await _model.generateContent(content);

      return response.text;
    } catch (e) {
      print('Error saat mendapatkan deskripsi makanan: $e');
      return null;
    }
  }
}
