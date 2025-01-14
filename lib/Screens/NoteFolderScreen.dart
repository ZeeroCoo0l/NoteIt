import 'package:flutter/material.dart';
import 'package:super_editor_note_app/Objects/note_handler.dart';
import 'package:super_editor_note_app/Screens/EditorScreen.dart';
import 'package:super_editor_note_app/Screens/SettingsScreen.dart';
import 'package:super_editor_note_app/Widgets/seachbar.dart';
import 'package:super_editor_note_app/constants.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:super_editor_note_app/service.dart';

import '../Objects/note.dart';

class NoteFolderScreen extends StatefulWidget {
  const NoteFolderScreen({super.key});

  @override
  State<StatefulWidget> createState() => _NoteFolderScreenState();
}

class _NoteFolderScreenState extends State<NoteFolderScreen> {
  late NoteHandler _noteHandler;
  bool _loading = true;
  //String sortingType = "alfa";

  @override
  void initState() {
    _initNoteHandler();
    StorageService storageService = StorageService();
    super.initState();
  }

  Future<void> _initNoteHandler() async {
    bool havePermission = await checkManageExternalStoragePermission();
    if (havePermission) {
      _noteHandler = NoteHandler();
      await _noteHandler.initialize();
      await _noteHandler.loadFiles();
      _noteHandler.sortHandler.sort(_noteHandler.notes);
    }
    //_noteHandler.sortNotesByName();
    //_noteHandler.sortNotesByLastModified();
    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return _loading
        ? const Center(child: CircularProgressIndicator.adaptive())
        : Scaffold(
            appBar: AppBar(
              elevation: 0,
              actions: [
                sortButton(),
                CustomSearchBar(
                  inputedNoteHandler: _noteHandler,
                ),
              ],
            ),
            floatingActionButton: Padding(
              padding: const EdgeInsets.all(8.0),
              child: FloatingActionButton(
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                foregroundColor: Theme.of(context).colorScheme.primary,
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) {
                            Note newNote = _noteHandler.createNote();
                            //_update();
                            return EditorScreen(note: newNote, noteHandler: _noteHandler,);})
                  );
                },
                child: const Icon(Icons.add_rounded),
              ),
            ),
            drawer: Drawer(
              elevation: 0,
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    /*const Text(
                      "Drawer",
                      style: TextStyle(fontSize: 38),
                    ),*/
                    const Spacer(
                      flex: 1,
                    ),
                    SizedBox(
                      height: 250,
                      child: ListView(
                        children: [
                          ListTile(
                            title: const Text("Notes"),
                            onTap: () {
                              Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            title: const Text("Settings"),
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => SettingsScreen(noteHandler: _noteHandler,))),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(
                      flex: 3,
                    ),
                  ],
                ),
              ),
            ),
            body: RefreshIndicator(
              onRefresh: () => _update(),
              child: SafeArea(
                child: Center(
                  child: SizedBox(
                    height: size.height,
                    child: Column(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(
                                top: defaultPadding,
                                bottom: defaultPadding / 4,
                                left: defaultPadding / 2,
                                right: defaultPadding / 2),
                            child: ListView.separated(
                                itemBuilder: (context, index) {
                                  Note note =
                                      _noteHandler.notes.elementAt(index);
                                  return ListTile(
                                    onLongPress: () {
                                      showDialog(
                                          context: context,
                                          builder: (context) {
                                            MenuController menuController =
                                                MenuController();
                                            return AlertDialog.adaptive(
                                                title: Text(note.name),
                                                content: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children:
                                                      _getButtonsForNoteMenu(
                                                          menuController,
                                                          index,
                                                          note),
                                                ));
                                          });
                                    },
                                    onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    EditorScreen(note: note, noteHandler: _noteHandler,)))
                                        /*.then((value) {
                                          if(value is bool && value){
                                            setState(() {
                                              //_noteHandler.loadFiles();
                                              _update();
                                            });
                                          }
                                    })*/,
                                    title: Text(note.name),
                                    trailing: SizedBox(
                                      width: 50,
                                      child: _noteListMenuButton(
                                          index, context, note),
                                    ),
                                    subtitle:
                                        _getNoteLastModifiedDateWidget(note),
                                  );
                                },
                                separatorBuilder: (_, __) => const Divider(),
                                itemCount: _noteHandler.notes.length),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
  }

  IconButton sortButton() {
    Icon icon = const Icon(Icons.sort_rounded);
    return IconButton(
        onPressed: () {
          String sortType = "";
          setState(() {
            sortType = _noteHandler.sortHandler.toggleSortType();

            _noteHandler.sortHandler.sort(_noteHandler.notes);
            //_update();
          });

          _showSnackbar(context, sortType);
        },
        icon: icon);
  }

  void _showSnackbar(BuildContext context, String text) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Padding(
        padding: const EdgeInsets.only(bottom: 48.0),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          width: 32,
          decoration: ShapeDecoration(
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8))),
            color: Theme.of(context).colorScheme.primary,
          ),
          child: Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18)),
        ),
      ),
      backgroundColor: Colors.transparent,
      duration: const Duration(seconds: 2),
      elevation: 0,
      //padding: EdgeInsets.all(16),
    ));
  }


    List<TextButton> _getButtonsForNoteMenu(
      MenuController menuController, int index, Note note) {
    return [
      TextButton(
        onPressed: () {
          setState(() {
            menuController.close();
            _noteHandler.deleteNote(_noteHandler.notes.elementAt(index));
          });
        },
        child: const Text("Delete"),
      ),
      TextButton(
        child: const Text("Rename"),
        onPressed: () {
          menuController.close();
          GlobalKey<FormState> formKey = GlobalKey<FormState>();
          TextEditingController textController = TextEditingController();
          textController.text = note.name;
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog.adaptive(
                  title: const Text("Rename"),
                  content: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: textController,
                            autofocus: true,
                            validator: (value) {
                              for (Note note in _noteHandler.notes) {
                                if (note.name == value) {
                                  return "Name is already in use!";
                                }
                              }
                              return null;
                            },
                          ),
                          ButtonBar(
                            children: [
                              TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    textController.clear();
                                  },
                                  child: const Text("Cancel")),
                              TextButton(
                                  onPressed: () {
                                    if (formKey.currentState!.validate()) {
                                      String newName = textController.text;
                                      setState(() {
                                        _noteHandler.renameNote(note, newName);
                                        //_noteHandler.loadFiles();
                                        _update();
                                      });
                                      Navigator.pop(context);
                                    }
                                  },
                                  child: const Text("Rename")),
                            ],
                          )
                        ],
                      )),
                );
              });
        },
      ),
      TextButton(
        onPressed: () {
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog.adaptive(
                  title: const Text(
                    "I N F O R M A T I O N",
                    textAlign: TextAlign.center,
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Name: ${note.name}",
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        "\nLast Modified:\n ${note.lastModified}\n",
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        "Extension:\n ${note.extension}",
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              });
        },
        child: const Text("Information"),
      )
    ];
  }

  SubmenuButton _noteListMenuButton(
      int index, BuildContext context, Note note) {
    MenuController menuController = MenuController();
    return SubmenuButton(
      controller: menuController,
      menuChildren: _getButtonsForNoteMenu(menuController, index, note),
      child: const Icon(Icons.more_horiz_rounded),
    );
  }

  Row _getNoteLastModifiedDateWidget(Note note) {
    String time = "";
    String date = "";
    DateTime dateTime = note.lastModified;
    if (dateTime.minute.toString().length < 2) {
      time = "${dateTime.hour}:0${dateTime.minute} ";
    } else {
      time = "${dateTime.hour}:${dateTime.minute} ";
    }
    date = "${dateTime.year}-${dateTime.month}-${dateTime.day}";
    Row row = Row(
      children: [
        Text(time, style: const TextStyle(fontWeight: FontWeight.w900)),
        Text(
          date,
        )
      ],
    );

    return row;
  }

  Future<void> _update() async {
    //_noteHandler.initialize();
    setState(() {
      _noteHandler.loadFiles();
      _noteHandler.sortHandler.sort(_noteHandler.notes);
    });

  }
}

Future<bool> checkManageExternalStoragePermission() async {
  if (await Permission.manageExternalStorage.isGranted) {
    print("MANAGE_EXTERNAL_STORAGE permission is already granted");
    return true;
  } else {
    // Open the settings page for the user to manually grant the permission
    if (await Permission.manageExternalStorage.request().isGranted) {
      print("MANAGE_EXTERNAL_STORAGE permission granted");
      return true;
    } else {
      print("MANAGE_EXTERNAL_STORAGE permission denied");
      throw Exception("Didn't have permission for managing external storage.");
    }
  }
}
