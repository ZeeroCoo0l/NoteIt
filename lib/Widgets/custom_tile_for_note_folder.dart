


import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';
import 'package:super_editor_note_app/Objects/note.dart';
import 'package:super_editor_note_app/Objects/note_handler.dart';
import 'package:super_editor_note_app/Screens/EditorScreen.dart';

class customTileForNoteFolder extends StatelessWidget {
  String? title;
  //MutableDocument document;
  //Note note;

  customTileForNoteFolder({
    super.key,
    //required this.note,
  }){
    //title = note.name;
    //document = note.loadDocument()!;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      //onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EditorScreen(document: note.loadDocument()!,))),
        title: Text(
          title!,
          style: TextStyle(
              fontSize: Theme.of(context)
                  .textTheme
                  .headlineSmall!
                  .fontSize,
              color: Theme.of(context).colorScheme.primary),
        ),
        //subtitle: Text(firstLineInNote!),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_horiz_rounded),
          elevation: 0,
            onSelected: (value){
            // TODO: Lägg till funktionen för knapparna
            },

            itemBuilder: (context) {
          return [
            const PopupMenuItem(
                child: Text("Delete"), value: "Delete",),
            const PopupMenuItem(
                child: Text("Rename"), value: "Rename",),
            const PopupMenuItem(
                child: Text("Share"), value: "Share"),
          ];
        }));
  }
}
