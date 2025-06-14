// Daftar nama makanan yang sebenarnya untuk model food-reconizer
// Ini adalah contoh mapping - Anda perlu mengganti dengan label yang sebenarnya dari model Anda

class FoodLabels {
  static const List<String> labels = [
    // Index 0-99
    'Nasi Putih', 'Ayam Goreng', 'Rendang', 'Gado-Gado', 'Sate Ayam',
    'Nasi Gudeg', 'Bakso', 'Mie Ayam', 'Soto Ayam', 'Nasi Liwet',
    'Pecel Lele', 'Ayam Bakar', 'Ikan Bakar', 'Sayur Asem', 'Tempe Goreng',
    'Tahu Goreng', 'Capcay', 'Nasi Goreng', 'Mie Goreng', 'Kwetiau Goreng',
    'Bihun Goreng', 'Martabak Manis', 'Martabak Telur', 'Lumpia', 'Siomay',
    'Pempek', 'Kerak Telor', 'Ketoprak', 'Lotek', 'Rujak',
    'Es Campur', 'Es Cendol', 'Es Dawet', 'Klepon', 'Onde-Onde',
    'Kue Lapis', 'Kue Putu', 'Dadar Gulung', 'Pisang Goreng', 'Tempe Mendoan',
    'Perkedel', 'Kroket', 'Risoles', 'Pastel', 'Lemper',
    'Ketupat', 'Lontong', 'Opor Ayam', 'Gulai Kambing', 'Rawon',
    'Sop Buntut', 'Sop Iga', 'Tongseng', 'Semur Daging', 'Dendeng',
    'Abon', 'Sambal Terasi', 'Sambal Matah', 'Lalap', 'Kerupuk',
    'Emping', 'Rempeyek', 'Keripik Tempe', 'Keripik Singkong', 'Keripik Pisang',
    'Dodol', 'Wajik', 'Tape', 'Getuk', 'Cenil',
    'Bubur Ayam', 'Bubur Kacang Hijau', 'Bubur Sumsum', 'Kolak', 'Kompot',
    'Manisan', 'Asinan', 'Pickle', 'Acar', 'Terong Balado',
    'Kangkung Belacan', 'Tumis Kangkung', 'Cap Cay', 'Sayur Lodeh', 'Sayur Bayam',
    'Urap', 'Pecel', 'Karedok', 'Lalapan', 'Sambal Kacang',
    'Bumbu Kacang', 'Saus Kacang', 'Sambal Kecap', 'Kecap Manis', 'Kecap Asin',
    'Petis', 'Terasi', 'Bumbu Base', 'Bumbu Rujak', 'Sirup',
    'Jus Jeruk', 'Jus Alpukat', 'Jus Mangga', 'Es Jeruk', 'Es Teh',
    'Kopi', 'Teh', 'Susu', 'Yogurt', 'Keju',
    
    // Index 100-199 (contoh tambahan)
    'Pizza', 'Burger', 'Hot Dog', 'Sandwich', 'Salad',
    'Pasta', 'Spaghetti', 'Macaroni', 'Lasagna', 'Ravioli',
    'Sushi', 'Ramen', 'Udon', 'Tempura', 'Yakitori',
    'Pad Thai', 'Tom Yum', 'Green Curry', 'Fried Rice', 'Spring Roll',
    'Dimsum', 'Wonton', 'Dumpling', 'Congee', 'Chow Mein',
    // ... tambahkan sampai 2024 items
  ];

  static String getFoodName(int index) {
    if (index >= 0 && index < labels.length) {
      return labels[index];
    }
    
    // Fallback jika indeks tidak ditemukan
    return 'Makanan Tidak Dikenal ($index)';
  }

  // Helper method untuk mencari indeks berdasarkan nama
  static int? findIndexByName(String name) {
    for (int i = 0; i < labels.length; i++) {
      if (labels[i].toLowerCase() == name.toLowerCase()) {
        return i;
      }
    }
    return null;
  }

  // Method untuk generate label lengkap (untuk testing)
  static List<String> generateAllLabels(int totalClasses) {
    List<String> allLabels = [];
    
    for (int i = 0; i < totalClasses; i++) {
      if (i < labels.length) {
        allLabels.add(labels[i]);
      } else {
        // Generate nama makanan generik untuk indeks yang belum didefinisikan
        allLabels.add('Makanan ${_getGenericFoodName(i)}');
      }
    }
    
    return allLabels;
  }

  static String _getGenericFoodName(int index) {
    List<String> genericNames = [
      'Ayam', 'Ikan', 'Daging', 'Sayur', 'Buah', 'Nasi', 'Mie', 'Roti',
      'Sup', 'Salad', 'Kue', 'Minuman', 'Cemilan', 'Gorengan', 'Rebusan',
      'Panggang', 'Kukus', 'Bakar', 'Tumis', 'Kalio'
    ];
    
    String category = genericNames[index % genericNames.length];
    int number = (index ~/ genericNames.length) + 1;
    
    return '$category $number';
  }
}
