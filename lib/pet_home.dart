/// dart
import 'dart:convert';
import 'dart:io';

/// material
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

/// plugins
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:home_widget/home_widget.dart';

/// classes
import 'package:pet_widget/globals.dart';
import 'package:pet_widget/pet_class.dart';

const String appGroupId = 'group.petwidget';
const String iOSWidgetName = 'pet_widget';
const String androidWidgetName = 'PetHomeScreenWidget';

class PetHome extends StatefulWidget {
  const PetHome({super.key});

  @override
  State<PetHome> createState() => _PetHomeState();
}

void updateHeadline(Pet petToShow) {
  HomeWidget.saveWidgetData<String>('headline_title', petToShow.name);
  HomeWidget.saveWidgetData<String>(
      'headline_description', ageCalc(petToShow));
  HomeWidget.updateWidget(
    iOSName: iOSWidgetName,
    androidName: androidWidgetName,
  );
}


class _PetHomeState extends State<PetHome> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  bool isDead = false;
  bool petsLoaded = false;

  @override
  void initState() {
    super.initState();
    loadPets();
    HomeWidget.setAppGroupId(appGroupId);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orangeAccent,
        title: Text('Pets'),
        actions: [TextButton.icon(onPressed: () => updateHeadline(items[0]), icon: Icon(Icons.refresh), label: Text('Refresh widget'))],
      ),

      body: petsLoaded ? ReorderableListView.builder(
        key: const Key('petlist'),
        itemCount: items.length,
        itemBuilder: (BuildContext context, int index) {
          Pet currPet = items[index];
          return InkWell(
            key: Key(currPet.id.toString()),
            onTap: () => showPetDialog(editablePet: items[index]),
            child: ListTile(
              leading: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1), // Shadow color
                      spreadRadius: 1, // Spread radius of the shadow
                      blurRadius: 3, // Blur radius of the shadow
                      offset: Offset(0, 2), // Offset of the shadow
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white, // Set the background color of the circle
                  child: ClipOval(
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: currPet.image != ''
                          ? Image.file(
                        File(currPet.image),
                        fit: BoxFit.cover, // Fit the image to cover the circle
                      )
                          : Icon(MdiIcons.cat),
                    ),
                  ),
                ),
              ),

              title: Text(currPet.name.capitalizeWords()),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if(currPet.birthDate != DateTime(0000))
                    Text("Birthday: ${currPet.birthDate.day.toString()} - ${currPet.birthDate.month.toString()} - ${currPet.birthDate.year.toString()}", style: const TextStyle(fontSize: 11),),
                  if(currPet.deathDate != DateTime(0000))
                    Text("Date of death: ${currPet.deathDate.day.toString()} - ${currPet.deathDate.month.toString()} - ${currPet.deathDate.year.toString()}", style: const TextStyle(fontSize: 11)),
                ],
              ),
              trailing: Text(ageCalc(currPet), style: const TextStyle(fontSize: 10), textAlign: TextAlign.right),
            ),
          );
        }, onReorder: (int oldIndex, int newIndex) {
        setState(() {
          if (newIndex > oldIndex) {
            newIndex -= 1; // Adjust index if moving items down in the list
          }
          final Pet movedPet = items.removeAt(oldIndex);
          items.insert(newIndex, movedPet);
          savePets(); // Save the updated list after reordering
        });
      },
      ) : const Center(
        child: CircularProgressIndicator(), // Loading indicator
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showPetDialog,
        tooltip: 'new pet',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// save pet list to local storage
  Future<void> savePets() async {
    final prefs = await _prefs;
    final petList = items.map((pet) => pet.toJson()).toList();
    await prefs.setStringList('petList', petList.map((petJson) => json.encode(petJson)).toList());
  }

  /// load all pets from the local storage
  Future<void> loadPets() async {
    final prefs = await _prefs;
    final petListJson = prefs.getStringList('petList');
    if (petListJson != null) {
      items = petListJson.map((petJson) => Pet.fromJson(json.decode(petJson))).toList();
      setState(() {
        petsLoaded = true;
      });
    }
  }

  /// add a new pet to the list
  void addPet(Pet newPet) async {
    newPet.id = generateUniqueId(items);

    items.add(newPet);

    savePets();

    setState(() {});
  }

  /// Method to edit a Pet object based on its ID
  void editPet(int id, Pet editedPet) {
    final int index = items.indexWhere((pet) => pet.id == id);

    if (index != -1) {
      setState(() {
        items[index] = editedPet;
        savePets(); // Save the updated list after editing
      });
    } else {
      // Handle the case where the specified ID is not found
      debugPrint('Pet with ID $id not found.');
    }
  }

  /// delete pet from list
  void deletePet(int id) {
    final int index = items.indexWhere((pet) => pet.id == id);

    if (index != -1) {
      setState(() {
        items.removeAt(index);
        savePets(); // Save the updated list after editing
      });
    } else {
      // Handle the case where the specified ID is not found
      debugPrint('Pet with ID $id not found.');
    }
  }

  /// generate a Unique ID based on the IDs already in the pet list so +1 of max
  int generateUniqueId(List<Pet> items) {
    int maxID = items.isNotEmpty ? items.map((e) => e.id).reduce((max, id) => id > max ? id : max) : 0;
    int newID = maxID + 1;
    return newID;
  }

  /// add or edit a pet
  showPetDialog({Pet? editablePet}) {
    bool isDead = false;
    if (editablePet != null){
      isDead = editablePet.deathDate != DateTime(0000);
    }
    Pet newPet = editablePet ?? Pet.empty();

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(
          editablePet == null ? 'Add a new pet' : 'Edit your pet',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
          ),
        ),
        content: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                children: [

                  /// pet name
                  TextFormField(
                    initialValue: newPet.name,
                    decoration: const InputDecoration(labelText: 'Pet Name'),
                    onChanged: (value) {
                      newPet.name = value;
                    },
                  ),

                  const SizedBox(height: 20),

                  /// image picker
                  InkWell(
                    onTap: () async {
                      final imagePath = await _selectImage(context);
                      if (imagePath != null) {
                        setState(() {
                          newPet.image = imagePath;
                        });
                      }
                    },
                    child: Container(
                      width: 101,
                      height: 101,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Container(
                          width: 100,
                          height: 100,
                          color: Colors.white,
                          child: newPet.image != ''
                              ? Image.file(
                            File(newPet.image),
                            fit: BoxFit.cover,
                          )
                              : const Icon(Icons.add_a_photo),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// pet birthdate
                  OutlinedButton(
                    onPressed: () async {
                      final selectedDate = await showDatePicker(
                        context: context,
                        initialDate: newPet.birthDate == DateTime(0000) ? DateTime.now() : newPet.birthDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (selectedDate != null) {
                        setState(() {
                          newPet.birthDate = selectedDate;
                        });
                      }
                    },
                    child: const Text('Pick birthdate'),
                  ),
                  if (newPet.birthDate.year != 0000)
                    Text('Selected birthdate: ${newPet.birthDate.day}/${newPet.birthDate.month}/${newPet.birthDate.year}'),

                  const Divider(),

                  /// pet date of death
                  Column(
                    children: [
                      Row(
                        children: [
                          const Text('Has your pet passed away? '),
                          Checkbox(
                            value: isDead,
                            onChanged: (newValue) {
                              setState(() {
                                isDead = newValue ?? false;
                                newPet.deathDate = DateTime(0000);
                              });
                            },
                          ),
                        ],
                      ),
                      if (isDead)
                        OutlinedButton(
                          onPressed: () async {
                            final selectedDate = await showDatePicker(
                              context: context,
                              initialDate: newPet.deathDate == DateTime(0000) ? DateTime.now() : newPet.deathDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (selectedDate != null) {
                              setState(() {
                                newPet.deathDate = selectedDate;
                              });
                            }
                          },
                          child: const Text('Pick date of death'),
                        ),
                      if (newPet.deathDate.year != 0000)
                        Text('Selected date of death: ${newPet.deathDate.day}/${newPet.deathDate.month}/${newPet.deathDate.year}'),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        ),
        /// dialog options Delete, cancel, edit
        actions: <Widget>[
          if (editablePet != null)
            TextButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Confirm Delete'),
                      content: Text('Are you sure you want to delete the pet ${editablePet.name}?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            deletePet(editablePet.id);
                            Navigator.popUntil(context, ModalRoute.withName('/'));
                          },
                          child: Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    );
                  },
                );
              },
              label: const Text('Delete', style: TextStyle(color: Colors.red)),
              icon: const Icon(Icons.delete, color: Colors.red),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, 'Cancel');
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (editablePet != null) {
                editPet(editablePet.id, newPet);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Pet edited: ${newPet.name}'),
                  ),
                );
                Navigator.pop(context, 'Edit');
              } else {
                addPet(newPet);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('New pet added: ${newPet.name}'),
                  ),
                );
                Navigator.pop(context, 'Add');
              }
            },
            child: Text(editablePet != null ? 'Edit' : 'Add'),
          ),
        ],
        actionsPadding: const EdgeInsets.symmetric(horizontal: 15),
      ),
    );
  }

  /// dialog to select what pic you want to save
  Future<String?> _selectImage(BuildContext context) async {
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
                  Navigator.pop(context, image.path); // Return the selected image path
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  final image = await _getImage(ImageSource.gallery);
                  Navigator.pop(context, image.path); // Return the selected image path
                },
              ),
            ],
          ),
        );
      },
    );

    return result; // Return the result (selected image path or null)
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
}

/// calculates the age to show in the trailing text of the list
String ageCalc(Pet petToCalcAge){
  if(petToCalcAge.birthDate == DateTime(0000)){
    return '';
  }
  Duration ageDuration = const Duration(days: 0);
  if (petToCalcAge.deathDate == DateTime(0000)) {
    ageDuration = DateTime.now().difference(petToCalcAge.birthDate);
  } else {
    ageDuration = petToCalcAge.deathDate.difference(petToCalcAge.birthDate);
  }

  int years = ageDuration.inDays ~/ 365;
  int remainingDays = ageDuration.inDays % 365;
  int months = remainingDays ~/ 30;
  int days = remainingDays % 30;

  String ageText = '';
  if (years > 0) {
    ageText += '${years} years';
  }
  if (months > 0) {
    ageText += '\n${months} months';
  }
  if (days > 0) {
    ageText += '\n${days} days';
  }
  if (ageText.isEmpty){
    ageText = 'Today';
  }
  return ageText;
}