// ignore_for_file: use_build_context_synchronously

library utils;

import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pet_widget/pet_class.dart';

import 'globals.dart';

/// calculates the age to show in the trailing text of the list
String ageCalc(Pet petToCalcAge) {
  if (petToCalcAge.birthDate.year == 0) {
    return '';
  }

  DateTime endDate = petToCalcAge.deathDate.year == 0
      ? DateTime.now()
      : petToCalcAge.deathDate;

  int years = endDate.year - petToCalcAge.birthDate.year;
  int months = endDate.month - petToCalcAge.birthDate.month;
  int days = endDate.day - petToCalcAge.birthDate.day;

  // Adjust months and years if necessary
  if (days < 0) {
    months -= 1;
    days += DateTime(endDate.year, endDate.month, 0).day;
  }

  if (months < 0) {
    years -= 1;
    months += 12;
  }

  // Construct the result string
  String ageText = '';
  if (years > 0) {
    ageText += '$years years';
  }
  if (months > 0) {
    ageText += '\n$months months';
  }
  if (days > 0) {
    ageText += '\n$days days';
  }
  if (ageText.isEmpty) {
    ageText = 'Today';
  }

  return ageText;
}

/// generate a Unique ID based on the IDs already in the pet list so +1 of max
int generateUniqueId() {
  int maxID = allPets.isNotEmpty
      ? allPets.map((e) => e.id).reduce((max, id) => id > max ? id : max)
      : 0;
  int newID = maxID + 1;
  return newID;
}

/// saves an image from base64 to a file and returns the path
Future<String> saveImage(String base64Image, String name) async {
  // Decode the base64 image to bytes
  List<int> imageBytes = base64.decode(base64Image);

  // Get the app directory
  Directory appDocDir = await getApplicationDocumentsDirectory();
  String appDocPath = appDocDir.path;

  // Create a unique filename for the image
  String imageName =
      '${name}_${DateTime.now().millisecondsSinceEpoch.toString()}.png';

  // Write the image to the file
  File imageFile = File('$appDocPath/$imageName');
  await imageFile.writeAsBytes(imageBytes);

  // Return the image path
  return imageFile.path;
}

/// shows a prompt to where to save the export to.
Future<void> saveJsonToFilePrompt(BuildContext context) async {
  // encode all pets in list to a json string
  String jsonString =
      json.encode(allPets.map((pet) => pet.toJsonForExport()).toList());

  // Get directory path from user using file_picker
  String? directoryPath = await FilePicker.platform.getDirectoryPath();

  if (directoryPath != null) {
    // Create the directory if it doesn't exist
    Directory directory = Directory(directoryPath);
    if (!(await directory.exists())) {
      await directory.create(recursive: true);
    }

    DateTime currentDate = DateTime.now();
    String filename =
        '/pets_${currentDate.year}_${currentDate.month}_${currentDate.day}.json';

    // Save JSON file to the selected directory
    await saveJsonToFile(jsonString, directoryPath, filename, context);

    // Show a confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('File Saved'),
          content: Text(
              'Exported your pets successfully to: $directoryPath$filename'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

/// Saves the json string file to the provided directory
Future<void> saveJsonToFile(String jsonString, String directoryPath,
    String filename, BuildContext context) async {
  try {
    // Create the directory if it doesn't exist
    Directory directory = Directory(directoryPath);
    if (!(await directory.exists())) {
      await directory.create(recursive: true);
    }

    // Create and write JSON file
    File file = File('${directory.path}$filename');
    await file.writeAsString(jsonString);
  } catch (e) {
    // Show an error dialog if something goes wrong
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to save JSON file: $e'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

/// import petlist from Json provided by user
Future<void> importJsonFromFile(
    BuildContext context, Function() callback) async {
  // Get file path from user using file_picker
  FilePickerResult? selectedJsonFile = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'],
  );

  List<Pet> originalList = allPets;

  if (selectedJsonFile != null) {
    String filePath = selectedJsonFile.files.single.path!;

    try {
      // Read the contents of the JSON file
      String jsonContent = await File(filePath).readAsString();

      // Parse the JSON data and add to the list of pets
      List<dynamic> jsonData = json.decode(jsonContent);
      List<Pet> importedPets =
          jsonData.map((json) => Pet.fromJson(json)).toList();

      for (Pet importedPet in importedPets) {
        // Check if there is a pet with the same ID already in the list
        bool idConflict =
            allPets.any((existingPet) => existingPet.equals(importedPet));

        // If there is a conflict, assign a new ID to the imported pet
        if (idConflict) {
          int newId = generateUniqueId();
          importedPet.id = newId;
        }

        // convert image from base64 to file and save path
        String imagePath = await saveImage(importedPet.image, importedPet.name);
        importedPet.image = imagePath;

        // Add the imported pet to the list
        allPets.add(importedPet);
      }
      // Save the updated list of pets
      // reload page after import
      callback();

      // Show a confirmation dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('JSON Imported'),
            content: Text('Successfully imported ${importedPets.length} pets.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      // make sure pet list is not altered by faulty import
      allPets = originalList;

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to import JSON file: $e'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }
}

/// dialog to select what pic you want to save
Future<String?> selectImage(BuildContext context) async {
  final result = await showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Select Image'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () async {
                final image = await _getImage(ImageSource.camera);
                Navigator.pop(
                    context, image.path); // Return the selected image path
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () async {
                final image = await _getImage(ImageSource.gallery);
                Navigator.pop(
                    context, image.path); // Return the selected image path
              },
            ),
          ],
        ),
      );
    },
  );

  return result;
}

/// handle saving image to phone storage either from phone or new pic
Future<File> _getImage(ImageSource source) async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: source);

  if (pickedFile != null) {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = DateTime.now().toIso8601String();
    final savedImagePath = '${appDir.path}/$fileName.png';

    final pickedFileTemporary = File(pickedFile.path);

    final savedImage = await pickedFileTemporary.copy(savedImagePath);

    return savedImage;
  }

  throw Exception('Image selection was canceled.');
}
