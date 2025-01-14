import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:super_editor_note_app/Objects/note_handler.dart';
import 'package:super_editor_note_app/Objects/themeProvider.dart';
import 'package:super_editor_note_app/Widgets/custom_tile_for_note_folder.dart';
import 'package:super_editor_note_app/hive_models/settings_model.dart';
import 'package:super_editor_note_app/service.dart';

class SettingsScreen extends StatefulWidget {
  SettingsScreen({required noteHandler}) {
    _noteHandler = noteHandler;

  }
  late NoteHandler _noteHandler;

  @override
  State<StatefulWidget> createState() => SettingsScreenState(_noteHandler);
}

class SettingsScreenState extends State {
  late bool _isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
  late StorageService storageService;
  String? root;
  bool rootChanged = false;
  late NoteHandler _noteHandler;
  late ThemeProvider _themeProvider;

  SettingsScreenState(NoteHandler noteHandler){
    _noteHandler = noteHandler;
  }

  @override
  void initState() {
    storageService = StorageService();
    _setDarkMode();
    _setRoot();
    super.initState();
  }
  Future<void> _setDarkMode()async{
    bool? isDarkMode = await storageService.isDarkMode();
    isDarkMode ??= true;
    setState(() {
      _isDarkMode = isDarkMode!;
    });
    await storageService.turnOnDarkMode(isDarkMode);
  }

  Future<void> _setRoot() async {
    var temp = await storageService.getRootFolder();
    setState(() {
      root = temp;
    });
  }

  @override
  Widget build(BuildContext context) {
    return (root == null)
        ? const CircularProgressIndicator()
        : Scaffold(
            appBar: AppBar(
              leading: IconButton(onPressed: (){
                Navigator.pop(context);
              }, icon: const Icon(Icons.arrow_back_rounded),),
              title: const Text("Settings"),
            ),
            body: Center(
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text("Dark Mode"),
                      trailing: Switch.adaptive(
                          value: _isDarkMode,
                          onChanged: (newValue) {
                            setState(() {
                              _isDarkMode = newValue; // JAG BEHÖVS!
                            });
                            storageService.turnOnDarkMode(newValue);
                            var provider = Provider.of<ThemeProvider>(context, listen: false);
                            provider.toggleMode();

                          }),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text("Root folder"),
                      trailing: OutlinedButton(
                          onPressed: () async {
                            print(await storageService.getRootFolder());
                            String? dir = await FilePicker.platform.getDirectoryPath();
                            storageService.saveRootFolderPath(dir!);
                            //var temp = await storageService.getRootFolder();
                            _setRoot();
                            setState(() {
                              //root = temp;
                              _noteHandler.initialize();
                              rootChanged = true;
                            });
                            print(await storageService.getRootFolder());
                          }, child: const Text("Change")),
                      subtitle: Text("Root: ${root!}"),
                    )
                  ],
                ),
              ),
            ),
          );
  }
}
