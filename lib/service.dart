import 'package:hive_flutter/hive_flutter.dart';
import 'package:super_editor_note_app/Objects/themeProvider.dart';

class StorageService{
  final String _boxName = "settings";

  // HANDLE ROOT
  Future<void> saveRootFolderPath(String path) async {
    var box = Hive.box('settings'); // Access the box named 'settings'
    await box.put('root_folder', path);
  }

  Future<String?> getRootFolder() async {
    var box = Hive.box('settings');
    return box.get('root_folder');
  }


  // DARK MODE
  Future<void> turnOnDarkMode(bool turnOn )async{ // TODO: IMPLEMENTERA DENNA
    var box = Hive.box('settings');
    await box.put('darkMode', turnOn);
  }

  Future<bool?> isDarkMode() async{
    var box = Hive.box('settings');
    return box.get('darkMode');
  }


  // SORT
  Future<String?> getSortType() async {// TODO: IMPLEMENTERA DENNA
    var box = Hive.box('settings');
    return box.get('sortType');
  }

  Future<void> setSortType(String type)async{ // TODO: IMPLEMENTERA DENNA
    var box = Hive.box('settings');
    await box.put('sortType', type);
  }

}