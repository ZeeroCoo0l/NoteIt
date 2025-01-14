import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:super_editor/super_editor.dart';

class CustomConvertTaskToParagraph extends EditorCommand{
  CustomConvertTaskToParagraph(this._composer);

  final DocumentComposer _composer;
  @override
  void execute(Document document, DocumentEditorTransaction transaction) {
    var selection = _composer.selection;

    if (selection == null || !selection.isCollapsed) {
      return;
    }

    // We only care about TaskNodes.
    final node = document.getNodeById(selection.extent.nodeId);
    if (node is! TaskNode) {
      return;
    }


    var newParagraphNode = ParagraphNode(id: DocumentEditor.createNodeId(), text: node.text);
    transaction.replaceNode(oldNode: node, newNode: newParagraphNode);

    //var nodeAfter = document.getNodeAfter(node);
    //if(nodeAfter is! ParagraphNode){return;}

    int offset = node.beginningPosition.offset;

    _composer.selectionNotifier.value = DocumentSelection.collapsed(
      position: DocumentPosition(
        nodeId: newParagraphNode.id,
        nodePosition: TextNodePosition(offset: offset),
      ),
    );
  }
}