import 'dart:math';

import 'package:flutter/material.dart';

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

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      birthDate: json['birthDate'] != null ? DateTime.parse(json['birthDate']) : DateTime(0000),
      deathDate: json['deathDate'] != null ? DateTime.parse(json['deathDate']) : DateTime(0000),
      image: json['image'] ?? '',
    );
  }

  printout() {
    debugPrint("$name : $birthDate - $deathDate");
  }
  static empty(){
    return Pet(id: 0, name: '', birthDate: DateTime(0000, 1, 1), deathDate: DateTime(0000, 1, 1), image: '');
  }
  static random(){
    return Pet(
        id: Random().nextInt(3000),
        name: 'Random name ${Random().nextInt(100)}',
        birthDate: DateTime(Random().nextInt(3000), Random().nextInt(12), Random().nextInt(30)),
        deathDate: DateTime(Random().nextInt(3000), Random().nextInt(12), Random().nextInt(30)),
        image: ''
    );
  }


}