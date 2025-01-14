import 'dart:io';
import 'package:super_editor/super_editor.dart';
import 'package:super_editor_note_app/Objects/converter_of_document.dart';
//import 'package:super_editor_markdown/super_editor_markdown.dart';

class Note {
  File file;
  late String name;
  late String extension;
  //late DateTime creationDate;
  late DateTime lastModified;
  final MarkdownHandler _mdHandler = MarkdownHandler();

  // C R E A T E
  Note({required this.file}) {
    name = _getNameFromPath();
    extension = file.path.split((".")).last;
    //creationDate = file.statSync();//DateTime.now();
    lastModified = file.lastModifiedSync();//DateTime.now();
  }

  String _getNameFromPath() {
    // Gives the name WITHOUT the extension.
    String path = file.path;
    String nameWithExtension = path.split("/").last;
    var indexOfDot = nameWithExtension.lastIndexOf(".");
    if (indexOfDot.isNegative) {
      throw Exception("fileName of note does not contain an extension.");
    }
    String nameWithoutExtension = nameWithExtension.substring(0, indexOfDot);

    if (nameWithoutExtension.isEmpty) {
      nameWithoutExtension = "Untitled";
    }
    return nameWithoutExtension;
  }


  MutableDocument toEditor() {
    var lines = file.readAsLinesSync();
    if(lines.isEmpty){
      return MutableDocument(nodes: [
        ParagraphNode(id: DocumentEditor.createNodeId(), text: AttributedText())
      ]);
    }
    MutableDocument document = _mdHandler.convertMarkdownToDocument(lines);

    return document;
  }


  // S A V E    &     U P D A T E

  void saveWithDocument(Document document){
    String content = _mdHandler.convertDocumentToMarkdown(document);
    save(content);
  }

  void save(String content) {
    // TODO: Hämta content från editorn och spara/uppdatera dess fil! + konvertering
    file.writeAsStringSync(content);
    _setLastModified();
  }

  void rename(String newName){
    name = newName;
    String parentPath = file.parent.path;
    file = file.renameSync("$parentPath/$newName.md");
    _setLastModified();
  }

  void _setLastModified() {
    DateTime dateNow = DateTime.now();
    lastModified = dateNow;
    file.setLastModifiedSync(dateNow);
  }

  // D E L E T E
  bool delete() {
    try{
      file.deleteSync();
      return true;
    }
    catch(e){
      throw Exception("Can't delete note:\n $e");
    }
    finally{
      return false;
    }
  }

}
