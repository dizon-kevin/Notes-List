import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EditNotePage extends StatefulWidget {
  final Map<String, dynamic> note;
  final int index;
  final Function(int, String, String) updateNote;

  EditNotePage({
    required this.note,
    required this.index,
    required this.updateNote,
  });

  @override
  _EditNotePageState createState() => _EditNotePageState();
}

class _EditNotePageState extends State<EditNotePage> {
  late TextEditingController _titleController;
  late TextEditingController _tagController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note['title']);
    _tagController = TextEditingController(text: widget.note['tag']);
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
      backgroundColor: Colors.white, // Set background to white
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          'Edit Note',
          style: TextStyle(color: Colors.black), // Set text to black
        ),
        previousPageTitle: 'Notes', // Set back button text
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Text('Save'),
          onPressed: () {
            widget.updateNote(
              widget.index,
              _titleController.text,
              _tagController.text,
            );
            Navigator.pop(context);
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
              SizedBox(height: 20),
              Text(
                'Last edited: ${DateFormat('MMM d, y, h:mm a').format(widget.note['date'])}',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}