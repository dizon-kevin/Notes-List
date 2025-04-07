import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:intl/intl.dart';
import 'edit_note_page.dart';
import 'add_note_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Hive.initFlutter();
    await Hive.openBox('notesBox');
    print("Hive initialized successfully.");
  } catch (e) {
    print("Error initializing Hive: $e");
    return;
  }

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
  List<int> lockedIndices = [];
  TextEditingController searchController = TextEditingController();
  late Box notesBox;
  bool isPinnedExpanded = true;

  @override
  void initState() {
    super.initState();
    try {
      notesBox = Hive.box('notesBox');
      loadNotes();
      updateRelativeDates();
      print("NotesApp initState successful.");
    } catch (e) {
      print("Error in NotesApp initState: $e");
    }
  }

  void loadNotes() {
    setState(() {
      try {
        if (notesBox.isOpen) {
          List<dynamic> rawNotes = notesBox.get('notes', defaultValue: []);
          notes = rawNotes.map((item) => Map<String, dynamic>.from(item)).toList();
          pinnedIndices = List<int>.from(notesBox.get('pinned', defaultValue: []));
          lockedIndices = List<int>.from(notesBox.get('locked', defaultValue: []));
          print("Notes loaded successfully.");
        } else {
          print("Error: NotesBox is not open.");
        }
      } catch (e) {
        print("Error loading notes: $e");
      }
    });
  }

  void saveNotes() {
    try {
      if (notesBox.isOpen) {
        notesBox.put('notes', notes);
        notesBox.put('pinned', pinnedIndices);
        notesBox.put('locked', lockedIndices);
        print("notes box content: ${notesBox.get('notes')}");
        print("pinned box content: ${notesBox.get('pinned')}");
        print("locked box content: ${notesBox.get('locked')}");
        print("Notes saved successfully.");
      } else {
        print("Error: NotesBox is not open.");
      }
    } catch (e) {
      print("Error saving notes: $e");
    }
  }

  void addNote(String title, String tag) {
    setState(() {
      notes.add({
        'title': title,
        'tag': tag,
        'date': DateTime.now(),
      });
      saveNotes();
      updateRelativeDates();
    });
  }

  void updateNote(int index, String title, String tag) {
    if (lockedIndices.contains(index)) {
      print("Note is locked, and cannot be edited");
      return;
    }
    setState(() {
      notes[index]['title'] = title;
      notes[index]['tag'] = tag;
      notes[index]['date'] = DateTime.now();
      saveNotes();
      updateRelativeDates();
    });
  }

  void deleteNote(int index) {
    setState(() {
      notes.removeAt(index);
      pinnedIndices.remove(index);
      lockedIndices.remove(index);
      saveNotes();
      updateRelativeDates();
    });
  }

  void togglePin(int index) {
    setState(() {
      if (pinnedIndices.contains(index)) {
        pinnedIndices.remove(index);
      } else {
        pinnedIndices.add(index);
      }
      saveNotes();
      updateRelativeDates();
    });
  }

  void toggleLock(int index) {
    setState(() {
      if (lockedIndices.contains(index)) {
        lockedIndices.remove(index);
      } else {
        lockedIndices.add(index);
      }
      saveNotes();
      updateRelativeDates();
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

  void updateRelativeDates() {
    setState(() {
      for (var note in notes) {
        note['relativeDate'] = getRelativeDate(note['date']);
      }
    });
    saveNotes();
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
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            showCupertinoModalPopup(
              context: context,
              builder: (BuildContext context) => CupertinoActionSheet(
                title: const Text('Team Members', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                message: const Text('Developed by:', style: TextStyle(color: Colors.grey)),
                actions: <CupertinoActionSheetAction>[
                  _buildTeamMemberAction('Cruz, John Eric'),
                  _buildTeamMemberAction('Dizon, Kevin'),
                  _buildTeamMemberAction('Juanatas Cris, Luriz Jenzelle'),
                  _buildTeamMemberAction('Macapagal Marc, Lawrence'),
                  _buildTeamMemberAction('Venasquez, Charles'),
                ],
                cancelButton: CupertinoActionSheetAction(
                  child: const Text('Cancel', style: TextStyle(color: CupertinoColors.destructiveRed)),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            );
          },
          child: const Icon(CupertinoIcons.profile_circled, color: Colors.yellow, size: 30,),
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
                    controller: searchController, itemColor: Colors.black,
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

                      final String relativeDate = note['relativeDate'];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (index == 0 ||
                              unpinnedNotes[index]['relativeDate'] !=
                                  (index > 0 ? unpinnedNotes[index - 1]['relativeDate'] : null))
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
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => AddNotePage(addNote: addNote),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  CupertinoActionSheetAction _buildTeamMemberAction(String name) {
    return CupertinoActionSheetAction(
      child: Text(name, style: TextStyle(fontWeight: FontWeight.w500)),
      onPressed: () => Navigator.pop(context),
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
          if (!lockedIndices.contains(index)) {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => EditNotePage(
                  note: note,
                  index: index,
                  updateNote: updateNote,
                ),
              ),
            );
          } else {
            print("Note is locked, and cannot be edited");
          }
        },
        onLongPress: () {
          showCupertinoModalPopup(
            context: context,
            builder: (BuildContext context) => CupertinoActionSheet(
              actions: <Widget>[
                CupertinoActionSheetAction(
                  child: Text(pinnedIndices.contains(index) ? 'Unpin Note' : 'Pin Note'),
                  onPressed: () {
                    togglePin(index);
                    Navigator.pop(context);
                  },
                ),
                CupertinoActionSheetAction(
                  child: Text(lockedIndices.contains(index) ? 'Unlock Note' : 'Lock Note'),
                  onPressed: () {
                    toggleLock(index);
                    Navigator.pop(context);
                  },
                ),
              ],
              cancelButton: CupertinoActionSheetAction(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          );
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
              if (lockedIndices.contains(index))
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.lock_fill,
                      color: Colors.black,
                      size: 20,
                    ),
                    SizedBox(width: 3),
                  ],
                ),
              if (!lockedIndices.contains(index)) SizedBox(width: 23),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          note['title'],
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        if (lockedIndices.contains(index))
                          Row(children: [
                            SizedBox(width: 3),
                            Text(
                              "Locked",
                              style: TextStyle(color: Colors.black, fontSize: 12),
                            ),
                          ])
                      ],
                    ),
                    if (note['tag'].isNotEmpty)
                      Text(
                        note['tag'],
                        style: TextStyle(color: Colors.black, fontSize: 14),
                      ),
                    Text(
                      formattedDate,
                      style: TextStyle(color: Colors.black, fontSize: 12),
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