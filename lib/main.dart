import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // List items = ['test1', 'test2', 'test3'];
    List<Pet> items = [Pet.random(), Pet.random(), Pet.random()];
    items[0].printout();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: ListView.builder(itemCount: items.length, itemBuilder: (BuildContext context, int index) {
        return ListTile(
            leading: CircleAvatar(backgroundColor: Color.fromRGBO(Random().nextInt(255), Random().nextInt(255), Random().nextInt(255), 100),),
            title: Text(items[index].name),
            subtitle: Text("${items[index].birthDate.year.toString()} - ${items[index].deathDate.year.toString()} "),
            trailing: Text((index+1).toString()),
        );
      },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class Pet {
  Pet({
    required this.name,
    required this.birthDate,
    required this.deathDate,
  });

  final String name;
  final DateTime birthDate;
  final DateTime deathDate;

  printout() {
    debugPrint("$name : $birthDate - $deathDate");
  }
  static empty(){
    return Pet(name: '', birthDate: DateTime(2023, 1, 1), deathDate: DateTime(2023, 2, 2));
  }
  static random(){
    return Pet(name: 'Random name ${Random().nextInt(100)}', birthDate: DateTime(Random().nextInt(3000), Random().nextInt(12), Random().nextInt(30)), deathDate: DateTime(Random().nextInt(3000), Random().nextInt(12), Random().nextInt(30)));
  }


}
