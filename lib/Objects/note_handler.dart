import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:super_editor_note_app/Objects/converter_of_document.dart';
import 'package:super_editor_note_app/Objects/sort_handler.dart';
import 'package:super_editor_note_app/service.dart';

import 'note.dart';

class NoteHandler {
  late Directory root;
  late List<Note> _notes;
  MarkdownHandler mdHandler = MarkdownHandler();
  SortHandler sortHandler = SortHandler();
  StorageService storageService = StorageService();

  List<Note> get notes => _notes;

  set notes(List<Note> value) {
    _notes = value;
  }

  NoteHandler() {
    _notes = <Note>[]; // Initialize _notes
  }

  Future<void> initialize() async {
    await _initialize();
  }

  Future<bool> loadFiles() async {
    if(_notes.isNotEmpty){
      _notes.clear();
    }
    try {
      var files = Directory(root.path).listSync();
      for (var file in files) {
        if (file is File && !file.path.contains(".trashed")) {
          Note note = Note(file: file);
          notes.add(note);
          //_notes.add(Note(file: file));
        }
      }

      //sortHandler.sort(notes);
      return true;
    } catch (e) {
      throw Exception("Error loading files: $e");
    }
  }

  Future<void> _initialize() async {
    try {
      String? path = await storageService.getRootFolder();
      root = Directory(path!);
      //root = Directory("/storage/emulated/0/Documents/notepad_app");
      //root = Directory("/storage/emulated/0/Documents/Synced vault /SEBBES STASH/00 - INBOX");
      if (!(await root.exists())) {
        print("Root directory does not exist.");
        return;
      }
      //await loadFiles();
    } catch (e) {
      print("ERROR: root not initialized... $e");
    }
  }

  void sortNotesByName() {
    _notes.sort((a, b) => a.name.compareTo(b.name));
  }

  void sortNotesByLastModified() {
    _notes.sort((a, b) => b.lastModified.compareTo(a.lastModified));
  }

  String _setUniqueName() {
    int index = 1;
    String baseName = "Untitled";
    String newName = baseName;

    var noteNames = [];
    for (var note in _notes) {
      noteNames.add(note.name.toLowerCase());
    }

    // Check if the current newName exists in the list
    while (noteNames.contains(newName.toLowerCase())) {
      newName = "$baseName $index";  // Append index to the base name
      index++;
    }

    return newName;  // Return the unique name
  }

  Note createNote() {
    String name = _setUniqueName();
    File newFile = File("${root.path}/$name.md");
    newFile.createSync();

    Note note = Note(file: newFile);
    _addNote(note);
    //note.toEditor();
    return note;
  }

  void _addNote(Note note) {
    _notes.add(note);

    // TODO: Lägg till att spara filen i mappen också!
  }

  void deleteNote(Note note){
    _notes.remove(note);
    note.delete();
  }

  void renameNote(Note noteToChange, String newName){
    String oldName = noteToChange.name;
    for(Note note in _notes){
      if(note.name == oldName){
        note.rename(newName);
      }
    }
  }

  bool containsNoteWithName(String text) {
    for(Note note in _notes){
      if(note.name == text){
        return true;
      }
    }
    return false;
  }

  Note? getNodeByName(String searchResult) {
    for(Note note in _notes){
      if(searchResult == note.name){
        return note;
      }
    }
    // Bör aldrig hamna här, då alla notes ska finnas i sökningen.
    return null;
  }
}
