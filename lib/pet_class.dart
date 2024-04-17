import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path_provider/path_provider.dart';

class Pet {
  Pet({
    required this.id,
    required this.name,
    required this.birthDate,
    required this.deathDate,
    required this.image,
  });

  int id;
  String name;
  DateTime birthDate;
  DateTime deathDate;
  String image;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'birthDate': birthDate.toIso8601String(),
      'deathDate': deathDate.toIso8601String(),
      'image': image,
    };
  }

  Map<String, dynamic> toJsonForExport() {
    String base64Image = '';
    if (image.isNotEmpty) {
      File imageFile = File(image);
      List<int> imageBytes = imageFile.readAsBytesSync();
      base64Image = base64Encode(imageBytes);
    }

    return {
      'id': id,
      'name': name,
      'birthDate': birthDate.toIso8601String(),
      'deathDate': deathDate.toIso8601String(),
      'image': base64Image,
    };
  }

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      birthDate: json['birthDate'] != null
          ? DateTime.parse(json['birthDate'])
          : DateTime(0000),
      deathDate: json['deathDate'] != null
          ? DateTime.parse(json['deathDate'])
          : DateTime(0000),
      image: json['image'] ?? '', // Store the base64 string directly
    );
  }

  /// Decode base64 image string and save it as a file
  Future<Pet> decodeBase64Image(Pet pet) async {
    String imagePath = '';
    if (pet.image.isNotEmpty) {
      List<int> imageBytes = base64Decode(pet.image);
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
      final savedImagePath = '${appDir.path}/$fileName';
      await File(savedImagePath).writeAsBytes(imageBytes);
      imagePath = savedImagePath;
    }

    return Pet(
      id: pet.id,
      name: pet.name,
      birthDate: pet.birthDate,
      deathDate: pet.deathDate,
      image: imagePath,
    );
  }

  bool equals(Pet other) {
    return id == other.id;
  }

  static empty() {
    return Pet(
        id: 0,
        name: '',
        birthDate: DateTime(0000, 1, 1),
        deathDate: DateTime(0000, 1, 1),
        image: '');
  }

  static random() {
    return Pet(
        id: Random().nextInt(3000),
        name: 'Random name ${Random().nextInt(100)}',
        birthDate: DateTime(
            Random().nextInt(3000), Random().nextInt(12), Random().nextInt(30)),
        deathDate: DateTime(
            Random().nextInt(3000), Random().nextInt(12), Random().nextInt(30)),
        image: '');
  }
}
