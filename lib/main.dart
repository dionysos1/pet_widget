import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:pet_widget/pet_class.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

List<Pet> items = [];
Pet newPet = Pet.empty();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pet Widgets',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Pet Widgets'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  bool isDead = false;

  @override
  void initState() {
    super.initState();
    loadPets();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: ReorderableListView.builder(
        key: const Key('petlist'),
        itemCount: items.length,
        itemBuilder: (BuildContext context, int index) {
          Pet currPet = items[index];
          return InkWell(
            key: Key(currPet.id.toString()),
            onTap: () => editPetDialog(items[index]),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Color.fromRGBO(Random().nextInt(255),
                    Random().nextInt(255), Random().nextInt(255), 100),
                child: currPet.image != '' // Check if the pet has an image
                    ? Image.file(File(currPet.image!)) // Display the pet's image
                    : Icon(MdiIcons.cat), // Display the default icon
              ),
              title: Text(currPet.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if(currPet.birthDate != DateTime(0000))
                    Text("Birthday: ${currPet.birthDate.day.toString()} - ${currPet.birthDate.month.toString()} - ${currPet.birthDate.year.toString()}", style: const TextStyle(fontSize: 10),),
                  if(currPet.deathDate != DateTime(0000))
                    Text("Date of death: ${currPet.deathDate.day.toString()} - ${currPet.deathDate.month.toString()} - ${currPet.deathDate.year.toString()}", style: const TextStyle(fontSize: 10)),
                ],
              ),
              trailing: ageCalc(currPet),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addPetDialog,
        tooltip: 'new pet',
        child: const Icon(Icons.add),
      ),
    );
  }
  
  ageCalc(Pet petToCalcAge){
    if(petToCalcAge.birthDate == DateTime(0000)){
      return Text('');
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

    return Text(ageText, style: TextStyle(fontSize: 10), textAlign: TextAlign.right);
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
      // setState(() {});
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

  /// generate a Unique ID based on the IDs already in the pet list so +1 of max
  int generateUniqueId(List<Pet> items) {
    int maxID = items.isNotEmpty ? items.map((e) => e.id).reduce((max, id) => id > max ? id : max) : 0;
    int newID = maxID + 1;
    return newID;
  }

  /// dialog to add a new Pet
  addPetDialog() {
    newPet = Pet.empty();
    isDead = false;

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text(
          'Add a new pet',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
          ),
        ),
        content: SingleChildScrollView(
            child:
            StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return Column(
                    children: [

                      /// Name field
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Pet Name'),
                        onChanged: (value) {
                          newPet.name = value;
                        },
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      /// picture picker
                      InkWell(
                        onTap: () =>
                            newPet.image = _selectImage(context),
                        child: const Icon(Icons.add_a_photo),
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      /// Birthdate picker
                      OutlinedButton(
                          onPressed: () async {
                            final selectedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(DateTime
                                  .now()
                                  .year - 20),
                              lastDate: DateTime(DateTime
                                  .now()
                                  .year + 1),
                            );

                            if (selectedDate != null) {
                              setState(() {
                                newPet.birthDate = selectedDate;
                              });

                            }
                          },
                          child: const Text('Pick birthdate')),

                      if (newPet.birthDate.year != 0000)
                        Text('Selected birthdate: ${newPet.birthDate
                            .day}/${newPet.birthDate.month}/${newPet.birthDate
                            .year}'),

                      Divider(),
                      /// Death date picker
                      Column(
                            children: [
                              Row(
                                children: [
                                  Text('has your pet passed away? '),
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
                                        initialDate: DateTime.now(),
                                        firstDate: DateTime(DateTime
                                            .now()
                                            .year - 20),
                                        lastDate: DateTime(DateTime
                                            .now()
                                            .year + 1),
                                      );

                                      if (selectedDate != null) {
                                        setState(() {
                                          newPet.deathDate = selectedDate;
                                        });

                                      }
                                    },
                                    child: const Text('Pick date of death')),

                              if (newPet.deathDate.year != 0000)
                                Text('Selected date of death: ${newPet.deathDate
                                    .day}/${newPet.deathDate.month}/${newPet.deathDate
                                    .year}'),
                            ],
                          ),

                      const SizedBox(
                        height: 20,
                      ),
                    ],
                  );
                }),

        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.pop(context, 'Cancel');
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              addPet(newPet);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'New pet added: ${newPet.name}'),
                ),
              );
              Navigator.pop(context, 'Add');
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  /// dialog to add a new Pet
  editPetDialog(Pet editablePet) {
    isDead = editablePet.deathDate != DateTime(0000);
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text(
          'Edit your pet',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
          ),
        ),
        content: SingleChildScrollView(
          child:
          StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Column(
                  children: [

                    /// Name field
                    TextFormField(
                      initialValue: editablePet.name,
                      decoration: const InputDecoration(labelText: 'Pet Name'),
                      onChanged: (value) {
                        editablePet.name = value;
                      },
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    /// picture picker
                    InkWell(
                      onTap: () =>
                          editablePet.image = _selectImage(context),
                      child: const Icon(Icons.add_a_photo),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    /// Birthdate picker
                    OutlinedButton(
                        onPressed: () async {
                          final selectedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(DateTime
                                .now()
                                .year - 20),
                            lastDate: DateTime(DateTime
                                .now()
                                .year + 1),
                          );

                          if (selectedDate != null) {
                            setState(() {
                              editablePet.birthDate = selectedDate;
                            });

                          }
                        },
                        child: const Text('Pick birthdate')),

                    if (editablePet.birthDate.year != 0000)
                      Text('Selected birthdate: ${editablePet.birthDate
                          .day}/${editablePet.birthDate.month}/${editablePet.birthDate
                          .year}'),

                    Divider(),
                    /// Death date picker
                    Column(
                      children: [
                        Row(
                          children: [
                            const Text('has your pet passed away? '),
                            Checkbox(
                              value: isDead,
                              onChanged: (newValue) {
                                setState(() {
                                  isDead = newValue ?? false;
                                  editablePet.deathDate = DateTime(0000);
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
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(DateTime
                                      .now()
                                      .year - 20),
                                  lastDate: DateTime(DateTime
                                      .now()
                                      .year + 1),
                                );

                                if (selectedDate != null) {
                                  setState(() {
                                    editablePet.deathDate = selectedDate;
                                  });

                                }
                              },
                              child: const Text('Pick date of death')),

                        if (editablePet.deathDate.year != 0000)
                          Text('Selected date of death: ${editablePet.deathDate
                              .day}/${editablePet.deathDate.month}/${editablePet.deathDate
                              .year}'),
                      ],
                    ),

                    const SizedBox(
                      height: 20,
                    ),
                  ],
                );
              }),

        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.pop(context, 'Cancel');
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              editPet(editablePet.id, editablePet);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Pet edited: ${editablePet.name}'),
                ),
              );
              Navigator.pop(context, 'Edit');
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  /// return location of filepath of the local storage
  _handleImageSelected(File image) {
    // Handle the selected image here
    // You can save the image path, display the image, etc.
    debugPrint('Selected image: ${image.path}');
    return image.path;
  }

  /// dialog to select what pic you want to save
  Future<File?> _selectImage(BuildContext context) async {
    return showDialog<File?>(
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
                  Navigator.pop(context, image.path);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  final image = await _getImage(ImageSource.gallery);
                  Navigator.pop(context, image.path);
                },
              ),
            ],
          ),
        );
      },
    );
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
