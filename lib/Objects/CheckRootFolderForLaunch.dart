import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:super_editor_note_app/Screens/NoteFolderScreen.dart';
import 'package:super_editor_note_app/service.dart';

Widget checkrootfolderforlaunch() {
  return FutureBuilder<bool>(
    future: _checkRootAndIsDarkMode(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        // While the future is being resolved, show a loading indicator
        return const Center(child: CircularProgressIndicator());
      } else if (snapshot.hasError) {
        // If there was an error, you can handle it here
        return const Center(child: Text("No Root found when launching app"));
      } else if (snapshot.hasData && snapshot.data == true) {
        // If root folder is found, navigate to NoteFolderScreen
        return const NoteFolderScreen();
      } else {
        // If root folder is not found, navigate to SetRootFolder
        return SetRootFolder();
      }
    },
  );
}

Future<bool> _checkRootAndIsDarkMode() async {
  StorageService storageService = StorageService();

  await _setDarkMode(storageService);

  var path = await storageService.getRootFolder();
  if (path == null) {
    //print("NULL");
    return false;
  }
  if (path.isEmpty) { // TODO: Hantera att man kan välja root_folder
    //print("NoPath");
    return false;
  } else {
    //print("FOUND PATH");
    return true;
  }
}

Future<void> _setDarkMode(StorageService service)async{
  bool? isDarkMode = await service.isDarkMode();
  if(isDarkMode != null){
    await service.turnOnDarkMode(isDarkMode);
  }
  else{
    await service.turnOnDarkMode(true);
  }
}

class SetRootFolder extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => SetRootFolderState();
}

class SetRootFolderState extends State<SetRootFolder> {
  StorageService storageService = StorageService();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.inversePrimary,
      child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Choose Root-folder"),
              const SizedBox(height: 8,),
              OutlinedButton(
                  onPressed: () async {
                String? dir = await FilePicker.platform.getDirectoryPath();
                storageService.saveRootFolderPath(dir!);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const NoteFolderScreen()));
                //TODO: ADD NAVIGATOR

              }, child: const Text("Choose folder"))
            ],
          )),
    );
  }
}