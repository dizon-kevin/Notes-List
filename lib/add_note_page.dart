import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AddNotePage extends StatefulWidget {
  final Function(String, String) addNote;

  AddNotePage({required this.addNote});

  @override
  _AddNotePageState createState() => _AddNotePageState();
}

class _AddNotePageState extends State<AddNotePage> {
  late TextEditingController _titleController;
  late TextEditingController _tagController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _tagController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Colors.white,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          'New Note',
          style: TextStyle(color: Colors.black),
        ),
        previousPageTitle: 'Notes',
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Text('Save'),
          onPressed: () {
            if (_titleController.text.isNotEmpty) {
              widget.addNote(_titleController.text, _tagController.text);
              Navigator.pop(context);
            }
          },
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              CupertinoTextField(
                controller: _titleController,
                placeholder: 'Title',
                placeholderStyle: TextStyle(color: Colors.grey),
                style: TextStyle(color: Colors.black),
                decoration: BoxDecoration(color: Colors.white),
              ),
              SizedBox(height: 10),
              CupertinoTextField(
                controller: _tagController,
                placeholder: 'Tag (e.g., #work, #travel)',
                placeholderStyle: TextStyle(color: Colors.grey),
                style: TextStyle(color: Colors.black),
                decoration: BoxDecoration(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}