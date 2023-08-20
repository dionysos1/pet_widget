library globals;

import 'dart:io';
import 'package:pet_widget/pet_class.dart';

List<Pet> items = [];
File? selectedImage;

extension StringExtension on String {
  String capitalizeWords() {
    if (isEmpty) {
      return this;
    }

    final List<String> words = toLowerCase().split(' ');
    final List<String> capitalizedWords = words.map((word) {
      if (word.isNotEmpty) {
        return word[0].toUpperCase() + word.substring(1);
      }
      return word;
    }).toList();

    return capitalizedWords.join(' ');
  }
}