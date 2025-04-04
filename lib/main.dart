import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('notesBox');

  runApp(CupertinoApp(
    debugShowCheckedModeBanner: false,
    home: NotesApp(),
  ));
}


class NotesApp extends StatefulWidget {

  @override
  State<NotesApp> createState() => _NotesAppState();
}

class _NotesAppState extends State<NotesApp> {
  List<Map<String, dynamic>> notes = [];
  List<int> pinnedIndices = [];
  TextEditingController searchController = TextEditingController();
  late Box notesBox;
  bool isPinnedExpanded = true;


  @override
  void initState() {
    super.initState();
    notesBox = Hive.box('notesBox');
    loadNotes();
  }

     void loadNotes() {
    setState(() {
      List<dynamic> rawNotes = notesBox.get('notes', defaultValue: []);
      notes = rawNotes.map((item) => Map<String, dynamic>.from(item)).toList();
      pinnedIndices = List<int>.from(notesBox.get('pinned', defaultValue: [])); /
    });
  }

  void addNote(String title, String tag) {
    setState(() {
      notes.add({
        'title': title,
        'tag': tag,
        'date': DateTime.now(),
      });
      notesBox.put('notes', notes);
    });
  }

  void deleteNote(int index) {
    setState(() {
      notes.removeAt(index);
      pinnedIndices.remove(index);
      notesBox.put('notes', notes);
      notesBox.put('pinned', pinnedIndices);
    });
  }

  void togglePin(int index) {
    setState(() {
      if (pinnedIndices.contains(index)) {
        pinnedIndices.remove(index);
      } else {
        pinnedIndices.add(index);
      }
      notesBox.put('pinned', pinnedIndices);
    });
  }

  String getRelativeDate(DateTime date) {
    DateTime now = DateTime.now();
    DateTime yesterday = now.subtract(Duration(days: 1));
    DateTime sevenDaysAgo = now.subtract(Duration(days: 7));

    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return 'Yesterday';
    } else if (date.isAfter(sevenDaysAgo)) {
      return 'Previous 7 Days';
    } else {
      return 'Older';
    }
  }

    @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> pinnedNotes =
        notes.asMap().entries.where((entry) => pinnedIndices.contains(entry.key)).map((entry) => entry.value).toList();
    List<Map<String, dynamic>> unpinnedNotes =
        notes.asMap().entries.where((entry) => !pinnedIndices.contains(entry.key)).map((entry) => entry.value).toList();
    return CupertinoPageScaffold(
      backgroundColor: Colors.white,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          'Notes',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
       child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(10),
                  child: CupertinoSearchTextField(
                    controller: searchController,
                    placeholder: 'Search Notes',
                    style: TextStyle(color: Colors.black),
                    onChanged: (value) => setState(() {}),
                  ),
                ),
            Expanded(
              child: ListView.builder(
                itemCount: todoList.length,
                itemBuilder: (context, int index) {
                  final item = todoList;
                  return GestureDetector(
                    onLongPress: () {
                      showCupertinoDialog(
                        context: context,
                        builder: (context) {
                          return CupertinoAlertDialog(
                            title: Text('Delete'),
                            content: Text('Remove ${item[index]['task']}?'),
                            actions: [
                              CupertinoButton(
                                child: Text(
                                  'Yes',
                                  style: TextStyle(
                                      color: CupertinoColors.destructiveRed),
                                ),
                                onPressed: () {
                                  setState(() {
                                    item.removeAt(index);
                                    box.put('todo', item);
                                  });
                                  Navigator.pop(context);
                                },
                              ),
                              CupertinoButton(
                                child: Text('No'),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                    onTap: () {
                      setState(() {
                        item[index]['status'] = !item[index]['status'];
                        box.put('todo', item);
                      });
                    },
                    child: Container(
                      child: CupertinoListTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item[index]['task'],
                              style: TextStyle(
                                  decoration: item[index]['status']
                                      ? TextDecoration.lineThrough
                                      : null),
                            ),
                            Icon(
                              CupertinoIcons.circle_fill,
                              size: 15,
                              color: item[index]['status']
                                  ? CupertinoColors.activeGreen
                                  : CupertinoColors.destructiveRed,
                            )
                          ],
                        ),
                        subtitle: Divider(
                            color: CupertinoColors.systemFill.withOpacity(0.5)),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              color: CupertinoColors.systemFill.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('               '),
                  Text('${(box.get('todo') ?? []).length} ToDo'),
                  CupertinoButton(
                    child: Icon(
                      CupertinoIcons.square_pencil,
                      color: CupertinoColors.systemYellow,
                    ),
                    onPressed: () {
                      showCupertinoDialog(
                        context: context,
                        builder: (context) {
                          return CupertinoAlertDialog(
                            title: Text('Add Task'),
                            content: CupertinoTextField(
                              placeholder: 'Add To-Do',
                              controller: _addTask,
                            ),
                            actions: [
                              CupertinoButton(
                                child: Text(
                                  'Close',
                                  style: TextStyle(
                                      color: CupertinoColors.destructiveRed),
                                ),
                                onPressed: () {
                                  _addTask.text = "";
                                  Navigator.pop(context);
                                },
                              ),
                              CupertinoButton(
                                child: Text('Save'),
                                onPressed: () {
                                  setState(() {
                                    todoList.add({
                                      "task": _addTask.text,
                                      "status": false
                                    });
                                    box.put('todo', todoList);
                                  });

                                  _addTask.text = "";
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
