import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';



void main () async{
  await Hive.initFlutter();
  var box =await Hive.openBox('test');



  runApp(CupertinoApp(
    debugShowCheckedModeBanner: false,

    home: MyApp(),));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List <dynamic> todoList = [];
  TextEditingController _addTask = TextEditingController();
  var box = Hive.box('test');
  @override
  void initState() {

    try {
      todoList = box.get('todo');
      print(todoList);
    }catch (e) {
      todoList = [];
    }
    super.initState();
  }