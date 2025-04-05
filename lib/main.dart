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
      pinnedIndices = List<int>.from(notesBox.get('pinned', defaultValue: []));
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

  void updateNote(int index, String title, String tag) {
    setState(() {
      notes[index]['title'] = title;
      notes[index]['tag'] = tag;
      notes[index]['date'] = DateTime.now();
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
    List<Map<String, dynamic>> pinnedNotes = notes
        .asMap()
        .entries
        .where((entry) => pinnedIndices.contains(entry.key))
        .map((entry) => entry.value)
        .toList();
    List<Map<String, dynamic>> unpinnedNotes = notes
        .asMap()
        .entries
        .where((entry) => !pinnedIndices.contains(entry.key))
        .map((entry) => entry.value)
        .toList();
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
                if (pinnedNotes.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              isPinnedExpanded = !isPinnedExpanded;
                            });
                          },
                          child: Row(
                            children: [
                              Text(
                                'Pinned',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                              Spacer(),
                              Icon(
                                isPinnedExpanded
                                    ? CupertinoIcons.chevron_down
                                    : CupertinoIcons.chevron_up,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isPinnedExpanded)
                        ...pinnedNotes.map((note) {
                          final int index = notes.indexOf(note);
                          return buildNoteItem(note, index);
                        }).toList(),
                    ],
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: unpinnedNotes.length,
                    itemBuilder: (context, index) {
                      final note = unpinnedNotes[index];
                      final int originalIndex = notes.indexOf(note);
                      if (searchController.text.isNotEmpty &&
                          !note['title']
                              .toLowerCase()
                              .contains(searchController.text.toLowerCase())) {
                        return Container();
                      }

                      final DateTime noteDate = note['date'];
                      final String _ = DateFormat('MMM d, y, h:mm a').format(noteDate);
                      final String relativeDate = getRelativeDate(noteDate);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (index == 0 ||
                              getRelativeDate(unpinnedNotes[index - 1]['date']) != relativeDate)
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(
                                relativeDate,
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                            ),
                          buildNoteItem(note, originalIndex),
                        ],
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Text(
                    '${notes.length} Notes',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: CupertinoButton(
                padding: EdgeInsets.all(15),
                color: Colors.transparent,
                child: Icon(
                  CupertinoIcons.square_pencil,
                  color: CupertinoColors.systemYellow,
                  size: 25,
                ),
                onPressed: () {
                  showNoteDialog(context, addNote, null, null, null);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildNoteItem(Map<String, dynamic> note, int index) {
    final DateTime noteDate = note['date'];
    final String formattedDate = DateFormat('MMM d, y, h:mm a').format(noteDate);

    return Dismissible(
      key: Key(note['date'].toString()),
      background: Container(
        color: CupertinoColors.destructiveRed,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.0),
        child: Icon(CupertinoIcons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        deleteNote(index);
      },
      child: GestureDetector(
        onTap: () {
          showNoteDialog(context, updateNote, index, note['title'], note['tag']);
        },
        child: Container(
          padding: EdgeInsets.all(12),
          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (pinnedIndices.contains(index))
                Icon(
                  CupertinoIcons.lock_fill,
                  color: Colors.grey,
                  size: 20,
                ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note['title'],
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    if (note['tag'].isNotEmpty)
                      Text(
                        note['tag'],
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    Text(
                      formattedDate,
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  pinnedIndices.contains(index) ? CupertinoIcons.pin_fill : CupertinoIcons.pin,
                  color: pinnedIndices.contains(index) ? Colors.blue : Colors.grey,
                ),
                onPressed: () => togglePin(index),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showNoteDialog(BuildContext context, Function action, int? index, String? initialTitle, String? initialTag) {
    TextEditingController titleController = TextEditingController(text: initialTitle ?? '');
    TextEditingController tagController = TextEditingController(text: initialTag ?? '');

    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text(index == null ? 'New Note' : 'Edit Note', style: TextStyle(color: Colors.black)),
          content: Column(
            children: [
              CupertinoTextField(
                placeholder: 'Title',
                controller: titleController,
                style: TextStyle(color: Colors.black),
                decoration: BoxDecoration(color: Colors.white),
              ),
              SizedBox(height: 10),
              CupertinoTextField(
                placeholder: 'Tag (e.g., #work, #travel)',
                controller: tagController,
                style: TextStyle(color: Colors.black),
                decoration: BoxDecoration(color: Colors.white),
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              child: Text('Cancel', style: TextStyle(color: CupertinoColors.destructiveRed)),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              child: Text('Save', style: TextStyle(color: Colors.black)),
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  if (index == null) {
                    action(titleController.text, tagController.text);
                  } else {
                    action(index, titleController.text, tagController.text);
                  }
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }
}