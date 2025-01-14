import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

class Historymanager {
  final _history = <EditorCommand>[];
  final _length = 25;
  final DocumentEditor editor;
  final DocumentComposer composer;

  Historymanager({required this.editor, required this.composer});


  // S A V E    T O     H I S T O R Y
  void saveToHistory(EditorCommand command){
    print("SAVED COMMAND: $command");
    if(_history.length > _length){
      _history.removeAt(0);
    }
    _history.add(command);
  }

  // U N D O
  void undo(){
    if(_history.isEmpty){
      return;
    }
    try{
      var latestCommand = _history.last;
      DocumentNode? nodeToLandOn;
      if(latestCommand is DeleteNodeCommand){
        var node = editor.document.getNodeById(latestCommand.nodeId);
        if(node == null){return;}
        nodeToLandOn = editor.document.getNodeBefore(node);
      }

      // E X E K V E R I N G
      editor.executeCommand(latestCommand);

      if(latestCommand is InsertAttributedTextCommand){
        //_setNewSelection(editor.document.getNode(latestCommand.documentPosition)!);
        nodeToLandOn = editor.document.getNode(latestCommand.documentPosition)!;
      }
      //_setNewSelection(editor.document.getNodeById(composer.selection!.extent.nodeId)!);
      if(nodeToLandOn != null){
        _setNewSelection(nodeToLandOn);
      }
    }
    catch(e){
      throw Exception("ERROR: HistoryManager tried to execute undo without success.\n Message:\n$e");
    }
    finally{
      _history.removeLast();
    }

  }

  void _setNewSelection(DocumentNode currentNode) {
    // Ändrade från ParagraphNode
    var position = DocumentPosition(
        nodeId: currentNode.id, nodePosition: currentNode.endPosition);
    var newSelection = DocumentSelection.collapsed(position: position);
    composer.setSelectionWithReason(newSelection);
  }



  // TODO: R E D O ?


}