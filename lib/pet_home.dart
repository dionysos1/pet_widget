// dart
import 'dart:convert';
import 'dart:io';

/// material
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

/// plugins
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_widget/home_widget.dart';

/// classes
import 'package:pet_widget/globals.dart';
import 'package:pet_widget/utils.dart';
import 'package:pet_widget/pet_class.dart';

const String appGroupId = 'group.petwidget';
const String iOSWidgetName = 'pet_widget';
const String androidWidgetName = 'PetHomeScreenWidget';

class PetHome extends StatefulWidget {
  const PetHome({super.key});

  @override
  State<PetHome> createState() => _PetHomeState();
}

void updateHeadline(Pet petToShow) async {
    HomeWidget.saveWidgetData<String>('headline_title', petToShow.name);
    HomeWidget.saveWidgetData<String>('headline_image', petToShow.image);
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
        title: const Text('Pets'),
        actions: [
          TextButton.icon(
              onPressed: () => showImportExportDialog(context),
              icon: const Icon(Icons.import_export_rounded),
              label: const Text('Import | Export')),
          TextButton.icon(
              onPressed: () =>
                  allPets.isNotEmpty ? updateHeadline(allPets[0]) : null,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh widget')),
        ],
      ),
      body: petsLoaded
          ? Stack(
              children: [
                ReorderableListView.builder(
                  key: const Key('petlist'),
                  itemCount: allPets.length,
                  itemBuilder: (BuildContext context, int index) {
                    Pet currPet = allPets[index];
                    return InkWell(
                        key: Key(currPet.id.toString()),
                        onTap: () => showPetDialog(editablePet: allPets[index]),
                        child: petListTile(currPet));
                  },
                  onReorder: (int oldIndex, int newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) {
                        newIndex -= 1;
                      }
                      final Pet movedPet = allPets.removeAt(oldIndex);
                      allPets.insert(newIndex, movedPet);
                      savePets(); // Save the updated list after reordering
                    });
                  },
                ),

                /// to debug a button to delete all pets from list
                if (kDebugMode)
                  Positioned(
                    bottom: 15,
                    left: 15,
                    child: TextButton(
                      onPressed: () {
                        allPets = [];
                        setState(() {
                          savePets();
                        });
                      },
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all<Color>(
                            Colors.orangeAccent),
                        foregroundColor:
                            WidgetStateProperty.all<Color>(Colors.black),
                        elevation: WidgetStateProperty.all<double>(10),
                        shape: WidgetStateProperty.all<OutlinedBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13.0),
                          ),
                        ),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.delete),
                          Text('Debug: empty list')
                        ],
                      ),
                    ),
                  )
              ],
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orangeAccent,
        onPressed: showPetDialog,
        tooltip: 'new pet',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// save pet list to local storage
  Future<void> savePets() async {
    final prefs = await _prefs;
    final petList = allPets.map((pet) => pet.toJson()).toList();
    await prefs.setStringList(
        'petList', petList.map((petJson) => json.encode(petJson)).toList());
  }

  /// load all pets from the local storage
  Future<void> loadPets() async {
    final prefs = await _prefs;
    final petListJson = prefs.getStringList('petList');
    if (petListJson != null) {
      allPets = petListJson
          .map((petJson) => Pet.fromJson(json.decode(petJson)))
          .toList();
      setState(() {
        petsLoaded = true;
      });
    } else {
      setState(() {
        petsLoaded = true;
      });
    }
  }

  /// add a new pet to the list
  void addPet(Pet newPet) async {
    newPet.id = generateUniqueId();

    allPets.add(newPet);

    savePets();

    setState(() {});
  }

  /// Method to edit a Pet object based on its ID
  void editPet(int id, Pet editedPet) {
    final int index = allPets.indexWhere((pet) => pet.id == id);

    if (index != -1) {
      setState(() {
        allPets[index] = editedPet;
        savePets();
      });
    } else {
      // Handle the case where the specified ID is not found
      debugPrint('Pet with ID $id not found.');
    }
  }

  /// delete pet from list
  void deletePet(int id) {
    final int index = allPets.indexWhere((pet) => pet.id == id);

    if (index != -1) {
      setState(() {
        allPets.removeAt(index);
        savePets();
      });
    } else {
      // Handle the case where the specified ID is not found
      debugPrint('Pet with ID $id not found.');
    }
  }

  /// add or edit a pet
  showPetDialog({Pet? editablePet}) {
    bool isDead = false;
    if (editablePet != null) {
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
                      final imagePath = await selectImage(context);
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
                          child: newPet.image != '' &&
                                  File(newPet.image).existsSync()
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
                        initialDate: newPet.birthDate == DateTime(0000)
                            ? DateTime.now()
                            : newPet.birthDate,
                        firstDate: DateTime.now()
                            .subtract(const Duration(days: 365 * 20)),
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
                    Text(
                        'Selected birthdate: ${newPet.birthDate.day}/${newPet.birthDate.month}/${newPet.birthDate.year}'),

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
                              initialDate: newPet.deathDate == DateTime(0000)
                                  ? DateTime.now()
                                  : newPet.deathDate,
                              firstDate: DateTime.now()
                                  .subtract(const Duration(days: 365 * 20)),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
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
                        Text(
                            'Selected date of death: ${newPet.deathDate.day}/${newPet.deathDate.month}/${newPet.deathDate.year}'),
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
                      title: const Text('Confirm Delete'),
                      content: Text(
                          'Are you sure you want to delete the pet ${editablePet.name}?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            deletePet(editablePet.id);
                            Navigator.popUntil(
                                context, ModalRoute.withName('/'));
                          },
                          child: const Text('Delete',
                              style: TextStyle(color: Colors.red)),
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

  /// shows the dialog where the user can select the import or export option
  Future<void> showImportExportDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Text('Import & Export'),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.close),
              )
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Import button with icon
              ElevatedButton.icon(
                onPressed: () {
                  void importCallback() {
                    setState(() {
                      savePets();
                    });
                  }

                  importJsonFromFile(context, importCallback);
                },
                icon: const Icon(Icons.file_download),
                label: const Text('Import Pets'),
              ),
              const SizedBox(height: 16),
              // Export button with icon
              ElevatedButton.icon(
                onPressed: () {
                  saveJsonToFilePrompt(context);
                },
                icon: const Icon(Icons.file_upload),
                label: const Text('Export Pets'),
              ),
            ],
          ),
        );
      },
    );
  }

  /// pet tiles in the list
  petListTile(Pet currPet) {
    return ListTile(
      leading: Container(
        width: 52,
        height: 52,
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
        child: CircleAvatar(
          radius: 26,
          backgroundColor: Colors.white,
          child: ClipOval(
            child: SizedBox(
              width: 50,
              height: 50,
              child:
                  currPet.image.isNotEmpty && File(currPet.image).existsSync()
                      ? Image.file(
                          File(currPet.image),
                          fit: BoxFit.cover,
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
          if (currPet.birthDate != DateTime(0000))
            Text(
              "Birthday: ${currPet.birthDate.day.toString()} - ${currPet.birthDate.month.toString()} - ${currPet.birthDate.year.toString()}",
              style: const TextStyle(fontSize: 11),
            ),
          if (currPet.deathDate != DateTime(0000))
            Text(
                "Date of death: ${currPet.deathDate.day.toString()} - ${currPet.deathDate.month.toString()} - ${currPet.deathDate.year.toString()}",
                style: const TextStyle(fontSize: 11)),
        ],
      ),
      trailing: Text(ageCalc(currPet),
          style: const TextStyle(fontSize: 10), textAlign: TextAlign.right),
    );
  }
}
