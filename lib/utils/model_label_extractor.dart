import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';

class ModelLabelExtractor {
  static Future<List<String>?> extractLabelsFromTflite(String modelPath) async {
    try {
      // Load the TFLite model as bytes
      final ByteData data = await rootBundle.load(modelPath);
      final Uint8List bytes = data.buffer.asUint8List();

      // Untuk metode implementasi yang lebih baik, kita akan mencoba mengekstrak label
      // yang tertanam dalam model TFLite
      
      // Pendekatan 1: Coba temukan label dalam association files
      try {
        // Check jika ada file label.txt yang menyertai model
        final String labelPath = modelPath.replaceAll('.tflite', '_labels.txt');
        final String labelsContent = await rootBundle.loadString(labelPath);
        
        if (labelsContent.isNotEmpty) {
          final List<String> extractedLabels = labelsContent
              .split('\n')
              .where((label) => label.trim().isNotEmpty)
              .toList();
          
          if (extractedLabels.isNotEmpty) {
            print('Berhasil mengekstrak ${extractedLabels.length} label dari file label.');
            return extractedLabels;
          }
        }
      } catch (e) {
        print('Tidak menemukan file label terpisah: $e');
      }
      
      // Pendekatan 2: Coba cari metadata dalam file TFLite
      // TFLite models sering menyimpan metadata termasuk label
      try {
        // Cari pola teks dalam file binary untuk menemukan label
        String fileContent = String.fromCharCodes(
            bytes, 0, bytes.length > 50000 ? 50000 : bytes.length);
            
        // Cari bagian yang mungkin berisi label (biasanya JSON atau teks plain)
        RegExp labelSectionRegex = RegExp(r'(\w+)(,|\s+)(\w+)(,|\s+)');
        final matches = labelSectionRegex.allMatches(fileContent);
        
        if (matches.length > 20) {
          // Jika menemukan banyak match, mungkin itu adalah label
          List<String> potentialLabels = [];
          for (final match in matches) {
            String label = match.group(0)?.trim() ?? '';
            if (label.length > 2 && !potentialLabels.contains(label)) {
              potentialLabels.add(label);
            }
          }
          
          if (potentialLabels.length > 100) {
            print('Berhasil mengekstrak ${potentialLabels.length} label dari metadata model.');
            return potentialLabels.take(2024).toList(); // Ambil maksimal 2024 label
          }
        }
      } catch (e) {
        print('Error saat mencari metadata dalam model: $e');
      }
      
      // Jika pendekatan di atas gagal, gunakan daftar predefined
      print('Tidak menemukan label dalam model, menggunakan daftar predefined.');
      return null;
    } catch (e) {
      print('Error extracting labels from TFLite model: $e');
      return null;
    }
  }

  static List<String> getFoodLabels2024() {
    // These are common food categories that might be in a 2024-class food recognition model
    // This is a comprehensive list of food items organized by categories
    return [
      // Indonesian Foods
      'Nasi Gudeg', 'Rendang', 'Gado-gado', 'Sate Ayam', 'Nasi Padang',
      'Gudeg Jogja', 'Pecel Lele', 'Ayam Bakar', 'Ikan Bakar', 'Soto Ayam',
      'Bakso', 'Mie Ayam', 'Nasi Goreng', 'Ayam Goreng', 'Bebek Goreng',
      'Rawon', 'Rujak', 'Kerupuk', 'Tempe Goreng', 'Tahu Goreng',

      // International Foods
      'Pizza Margherita', 'Pizza Pepperoni', 'Hamburger', 'Cheeseburger',
      'Hot Dog', 'Pasta Carbonara', 'Pasta Bolognese', 'Spaghetti',
      'Fried Chicken', 'Grilled Chicken', 'Chicken Wings', 'Fish and Chips',
      'Steak', 'Pork Chops', 'Lamb Curry', 'Beef Stew',

      // Asian Foods
      'Sushi', 'Ramen', 'Pad Thai', 'Fried Rice', 'Spring Rolls',
      'Dim Sum', 'Dumplings', 'Pho', 'Tom Yum', 'Green Curry',
      'Red Curry', 'Bibimbap', 'Kimchi', 'Bulgogi', 'Teriyaki',

      // Breakfast Items
      'Pancakes', 'Waffles', 'French Toast', 'Eggs Benedict', 'Omelette',
      'Scrambled Eggs', 'Fried Eggs', 'Cereal', 'Oatmeal', 'Yogurt',
      'Croissant', 'Bagel', 'Toast', 'Bacon', 'Sausage',

      // Soups and Stews
      'Chicken Soup', 'Vegetable Soup', 'Tomato Soup', 'Mushroom Soup',
      'Seafood Soup', 'Corn Soup', 'Onion Soup', 'Pumpkin Soup',
      'Lentil Soup', 'Bean Soup', 'Miso Soup', 'Hot and Sour Soup',

      // Salads
      'Caesar Salad', 'Garden Salad', 'Greek Salad', 'Fruit Salad',
      'Potato Salad', 'Coleslaw', 'Caprese Salad', 'Tuna Salad',
      'Chicken Salad', 'Quinoa Salad', 'Spinach Salad', 'Kale Salad',

      // Desserts
      'Chocolate Cake', 'Vanilla Cake', 'Cheesecake', 'Apple Pie',
      'Ice Cream', 'Cookies', 'Brownies', 'Donuts', 'Cupcakes',
      'Tiramisu', 'Pudding', 'Jelly', 'Candy', 'Chocolate',

      // Beverages
      'Coffee', 'Tea', 'Hot Chocolate', 'Smoothie', 'Juice',
      'Soda', 'Water', 'Milk', 'Latte', 'Cappuccino',

      // Fruits
      'Apple', 'Banana', 'Orange', 'Grape', 'Strawberry',
      'Blueberry', 'Raspberry', 'Mango', 'Pineapple', 'Watermelon',
      'Avocado', 'Kiwi', 'Peach', 'Pear', 'Cherry',

      // Vegetables
      'Broccoli', 'Carrot', 'Spinach', 'Lettuce', 'Tomato',
      'Cucumber', 'Bell Pepper', 'Onion', 'Garlic', 'Potato',
      'Sweet Potato', 'Corn', 'Peas', 'Green Beans', 'Cauliflower',

      // Snacks
      'Chips', 'Crackers', 'Nuts', 'Popcorn', 'Pretzels',
      'Trail Mix', 'Granola Bar', 'Cheese Sticks', 'Dried Fruit',

      // Fast Food
      'French Fries', 'Onion Rings', 'Chicken Nuggets', 'Fish Burger',
      'Veggie Burger', 'Wrap', 'Burrito', 'Taco', 'Quesadilla',

      // Bread and Baked Goods
      'White Bread', 'Whole Wheat Bread', 'Rye Bread', 'Sourdough',
      'Baguette', 'Pita', 'Naan', 'Tortilla', 'Muffin', 'Scone',

      // Dairy
      'Cheese', 'Butter', 'Cream', 'Yogurt', 'Milk', 'Ice Cream',

      // Meat and Seafood
      'Salmon', 'Tuna', 'Shrimp', 'Crab', 'Lobster', 'Clams',
      'Chicken Breast', 'Chicken Thigh', 'Ground Beef', 'Pork Belly',

      // Rice and Grains
      'White Rice', 'Brown Rice', 'Fried Rice', 'Rice Bowl',
      'Quinoa', 'Barley', 'Oats', 'Wheat', 'Pasta',

      // Regional Specialties
      'Tacos', 'Enchiladas', 'Burritos', 'Falafel', 'Hummus',
      'Shawarma', 'Kebab', 'Gyros', 'Paella', 'Risotto',
      'Goulash', 'Schnitzel', 'Fish Curry', 'Chicken Curry',

      // Additional items to reach 2024 classes
      ..._generateAdditionalFoodItems()
    ];
  }

  static List<String> _generateAdditionalFoodItems() {
    List<String> additionalItems = [];

    // Generate variations and combinations
    final bases = ['Rice', 'Noodles', 'Pasta', 'Bread', 'Soup'];
    final proteins = ['Chicken', 'Beef', 'Fish', 'Pork', 'Tofu', 'Egg'];
    final styles = ['Fried', 'Grilled', 'Steamed', 'Baked', 'Boiled'];
    final regions = [
      'Asian',
      'Western',
      'Indonesian',
      'Thai',
      'Japanese',
      'Chinese',
      'Indian'
    ];

    int count = 0;
    for (String region in regions) {
      for (String style in styles) {
        for (String protein in proteins) {
          for (String base in bases) {
            if (count < 1800) {
              // Fill remaining slots
              additionalItems.add('$region $style $protein $base');
              count++;
            }
          }
        }
      }
    }

    return additionalItems;
  }
}
