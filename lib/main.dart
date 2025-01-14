import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:super_editor_note_app/Objects/CheckRootFolderForLaunch.dart';
import 'package:super_editor_note_app/Objects/themeProvider.dart';
import 'package:super_editor_note_app/Screens/EditorScreen.dart';
import 'package:super_editor_note_app/Screens/NoteFolderScreen.dart';
import 'package:super_editor_note_app/service.dart';
import 'package:super_editor_note_app/themeAndData//theme.dart';

import 'hive_models/settings_model.dart';

Future<void> main() async {
  await Hive.initFlutter();
  await Hive.openBox('settings');
  Hive.registerAdapter(SettingsModelAdapter());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    StorageService storageService = StorageService();

    return ChangeNotifierProvider(
        create: (context) => ThemeProvider(),
        child:
            Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Notetaking App',
            themeMode: themeProvider.themeMode,
            theme: themeProvider.lightMode,
            darkTheme: themeProvider.darkMode,
            home: checkrootfolderforlaunch(),
          );
        }));
  }
}
