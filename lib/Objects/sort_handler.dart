

import 'package:super_editor_note_app/service.dart';

import 'note.dart';

class SortHandler{
  StorageService storageService = StorageService();
  String _currentSortType = "name";

  SortHandler() {
    _initializeSortHandler();
  }

  Future<void> _initializeSortHandler() async {
    var temp = await storageService.getSortType();
    if( temp == null){
      _currentSortType = "name";
    }
    else{
      _currentSortType = temp;
    }
    await storageService.setSortType(_currentSortType);
  }

  void sort(List<Note> notes){
    if(_currentSortType == "name"){
      _sortByName(notes);
    }
    else if(_currentSortType == "mod"){
      _sortByModification(notes);
    }
  }

  void changeSortToMod(){
    _currentSortType = "mod";
  }

  void changeSortToName(){
    _currentSortType = "name";
  }

  String toggleSortType(){
    if(_currentSortType == "name"){
      _currentSortType = "mod";
      storageService.setSortType(_currentSortType);
      return "Sorted by last modification.";
    }
    else{
      print("name");
      _currentSortType = "name";
      storageService.setSortType(_currentSortType);
      return "Sorted by name.";
    }

  }

  void _sortByName(List<Note> notes){
    notes.sort((a,b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  void _sortByModification(List<Note> notes){
    notes.sort((a,b)=>b.lastModified.compareTo(a.lastModified));
  }



}