// Denna triggas när jag trycker på "enter" i editorn.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:super_editor/super_editor.dart';
import 'package:super_editor_note_app/Objects/editor_text_converter.dart';
import 'package:super_editor_note_app/historyManager.dart';

class EditorIMEOverride extends DeltaTextInputClientDecorator {
  final DocumentEditor editor;
  final DocumentComposer composer;
  final AttributedText _latestDeletion = AttributedText();
  Historymanager historyManager;
  final ScrollController scrollController;

  AttributedText get latestDeletion => _latestDeletion;

  EditorIMEOverride({
    required this.editor,
    required this.composer,
    required this.historyManager,
    required this.scrollController
  });

  @override
  void performAction(TextInputAction action) {
    if (action == TextInputAction.newline) {
      // Get the current node the caret is in
      final currentNode = editor.document.getNodeById(composer.selection!.base.nodeId) as TextNode;

      //final previousNode = editor.document.getNodeBefore(currentNode);
      var words = currentNode.text.text.split(" ");
      int start = 0;
      for(String word in words){
        start += word.length;
        /*if(word.startsWith("https://")){
          int end = start + word.length;
          Uri url = Uri.parse(word);
          SpanRange range = SpanRange(start, end);
          previousNode.text.addAttribution(LinkAttribution(url: url), range);
          print(currentNode.text.toString());
        }*/
      }


      _savePreviousNodesAttributes(currentNode);

      if (currentNode is ListItemNode) {
        _insertNewListItem(currentNode);
      } else if (currentNode is ParagraphNode) {
        //editor.executeCommand(SplitParagraphCommand(nodeId: currentNode.id, splitPosition: currentNode.endPosition, newNodeId: DocumentEditor.createNodeId(), replicateExistingMetadata: true));
      } else if (currentNode is TaskNode) {
        _handleTaskNodeWhenPressingEnter(currentNode);
      } else if (currentNode == null) {
        throw Exception('No node found at the current selection.');
      } else {
        throw Exception('Current node is not a ListItemNode.');
      }
    }
    // If not handling Enter, delegate to the super method
    super.performAction(action);
  }

  void _handleTaskNodeWhenPressingEnter(TaskNode currentNode) {
    if (currentNode.text.text.isEmpty) {
      //TODO: Justera så man omvandlar task till paragraphNode om den är tom. (OBS! Problem med "LateInitializationError: Local 'oldImeToDoc' has not been initialized."
      return;
    }
    editor.executeCommand(InsertNewTaskOrSplitExistingTaskCommand(composer));
    //historyManager.saveToHistory(DeleteNodeCommand(nodeId: editor.document.getNodeAfter(currentNode)!.id));
  }

  void _savePreviousNodesAttributes(DocumentNode? currentNode) {
    //Set attributions = {};
    var previousNode = editor.document.getNodeAfter(currentNode!);
    if (currentNode is TextNode) {
      var text = currentNode.text;
      for (var span in text.computeAttributionSpans()) {
        if (span.attributions.isEmpty) {
          continue;
        }
        var attributions = span.attributions;

        /*historyManager.saveToHistory(ToggleTextAttributionsCommand(
            documentSelection: DocumentSelection(
                base: DocumentPosition(
                    nodeId: currentNode.id,
                    nodePosition: TextNodePosition(offset: span.start)),
                extent: DocumentPosition(
                    nodeId: currentNode.id,
                    nodePosition: TextNodePosition(offset: span.end))),
            attributions: attributions));

         */
      }
    }
  }

  @override
  void updateEditingValueWithDeltas(
    List<TextEditingDelta> textEditingDeltas,
  ) {
    final selection = composer.selection;
    final currentNode = editor.document.getNodeById(
        selection!.base.nodeId); // Noden som du är på när du triggar metoden.

    if (currentNode == null) {
      return;
    }

    if (currentNode is ParagraphNode) {
      _fallSaveForListConversion(currentNode);
      _autoConvertParagraphToOrderedList(currentNode);
    }

    for (final delta in textEditingDeltas) {
      if (delta is TextEditingDeltaDeletion) {
        if (!composer.selection!.isCollapsed) {
          // SPARA DELETE AV SELECTION TILL PLAIN TEXT, FÖR UNDO
          var command = InsertAttributedTextCommand(
              documentPosition: DocumentPosition(
                  nodeId: currentNode.id,
                  nodePosition: currentNode.beginningPosition),
              textToInsert: AttributedText(delta.oldText));
          //historyManager.saveToHistory(command);
        }
        _backSpaceConvertListToParagraph(currentNode);
        //_backSpaceConvertTaskToParagraph(currentNode);
        _saveDeletionForUndo(delta, currentNode);
      }
      if (delta is TextEditingDeltaInsertion) {
        //_saveInsertionForUndo(delta, currentNode);
      }
    }
    super.updateEditingValueWithDeltas(textEditingDeltas);
  }

  void _autoConvertParagraphToOrderedList(ParagraphNode currentNode) {
    var text = currentNode.text.text;

    if (text.startsWith("1.")) {
      var newText = text.substring(2);
      currentNode.text = AttributedText(newText);
      var newNode = ListItemNode.ordered(
          id: DocumentEditor.createNodeId(), text: AttributedText(""));
      editor.executeCommand(ConvertParagraphToListItemCommand(
          nodeId: currentNode.id, type: ListItemType.ordered));

      //historyManager.saveToHistory(DeleteNodeCommand(nodeId: currentNode.id));
      _setNewSelection(currentNode, true);
    } else if (text.startsWith("-")) {
      var newText = text.substring(1);
      currentNode.text = AttributedText(newText);
      var newNode = ListItemNode.ordered(
          id: DocumentEditor.createNodeId(), text: AttributedText(" "));
      editor.executeCommand(ConvertParagraphToListItemCommand(
          nodeId: currentNode.id, type: ListItemType.unordered));

      //historyManager.saveToHistory(DeleteNodeCommand(nodeId: currentNode.id));
      _setNewSelection(currentNode, true);
    }
  }

  void _setNewSelection(DocumentNode currentNode, bool setOnEndOfLine) {
    var nodePosition = currentNode.endPosition;
    if(!setOnEndOfLine){
      nodePosition = currentNode.beginningPosition;
    }
    // Ändrade från ParagraphNode
    var position = DocumentPosition(
        nodeId: currentNode.id, nodePosition: nodePosition);
    var newSelection = DocumentSelection.collapsed(position: position);
    composer.setSelectionWithReason(newSelection);
  }

  void _backSpaceConvertListToParagraph(DocumentNode currentNode) {
    if (currentNode is ListItemNode) {
      if (currentNode.text.text.isEmpty) {
        var previousNode = editor.document.getNodeBefore(currentNode);
        if (previousNode is ListItemNode) {
          var newNode = ParagraphNode(
              id: DocumentEditor.createNodeId(), text: AttributedText());
          editor.executeCommand(SplitListItemCommand(
              nodeId: previousNode.id,
              newNodeId: newNode.id,
              splitPosition: previousNode.endPosition));
          editor.executeCommand(
              ConvertListItemToParagraphCommand(nodeId: newNode.id));
        }
      }
    }
  }

  void _insertNewListItem(ListItemNode currentNode) {
    if (currentNode.text.text.isEmpty) {
      var type = currentNode.type;
      editor.executeCommand(
          ConvertListItemToParagraphCommand(nodeId: currentNode.id));
      //historyManager.saveToHistory(ConvertParagraphToListItemCommand(nodeId: currentNode.id, type: type));
      _setNewSelection(currentNode, true);
      return;
    } else {
      var selection = composer.selection;
      if (selection != null) {
        var pos = selection.extent;
        if (pos.nodePosition is TextNodePosition) {
          int textLength = currentNode.text.length;
          final cursorOffset = (pos.nodePosition as TextNodePosition).offset;

          // if cursor is in beginning of line, convert to paragraph
          if(cursorOffset == 0){
            editor.executeCommand(
                ConvertListItemToParagraphCommand(nodeId: currentNode.id));
            _setNewSelection(currentNode, false);
          }

          if (cursorOffset < textLength) {
            AttributedText textToNewLine =
                currentNode.text.copyText(cursorOffset);
            currentNode.text = currentNode.text
                .removeRegion(startOffset: cursorOffset, endOffset: textLength);

            // Create a new ListItemNode
            final newListNode = ListItemNode(
              id: DocumentEditor.createNodeId(),
              itemType: currentNode
                  .type, // Maintain the type of list (bullet, number, etc.)
              text: textToNewLine,
            );

            editor.executeCommand(
              SplitListItemCommand(
                nodeId: currentNode.id,
                newNodeId: newListNode.id,
                splitPosition: currentNode.endPosition,
              ),
            );
            editor.executeCommand(InsertAttributedTextCommand(
                documentPosition: DocumentPosition(
                    nodeId: newListNode.id,
                    nodePosition: newListNode.beginningPosition),
                textToInsert: textToNewLine));
            _setNewSelection(newListNode, false);

            return;
          }
          else{
            // Create a new ListItemNode
            final newListNode = ListItemNode(
              id: DocumentEditor.createNodeId(),
              itemType: currentNode
                  .type, // Maintain the type of list (bullet, number, etc.)
              text: AttributedText(),
            );

            editor.executeCommand(
              SplitListItemCommand(
                nodeId: currentNode.id,
                newNodeId: newListNode.id,
                splitPosition: currentNode.endPosition,
              ),
            );
            _setNewSelection(newListNode, true);
          }
        }
      }

      //_setNewSelection(newListNode);
      //historyManager.saveToHistory(DeleteNodeCommand(nodeId: newListNode.id));
    }

    return;
  }

  void _fallSaveForListConversion(ParagraphNode currentNode) {
    if (editor.document.nodes.first.id == currentNode.id) {
      var text = currentNode.text.text;
      if (text.startsWith("- ") || text.startsWith("1.")) {
        var newNode = ParagraphNode(
            id: DocumentEditor.createNodeId(), text: AttributedText(" \n"));
        editor.executeCommand(SplitParagraphCommand(
            nodeId: currentNode.id,
            splitPosition: currentNode.beginningPosition,
            newNodeId: newNode.id,
            replicateExistingMetadata: true));

        //historyManager.saveToHistory(DeleteNodeCommand(nodeId: currentNode.id));

        _setNewSelection(newNode, true);
      }
    }
  }

  void _saveDeletionForUndo(
      TextEditingDeltaDeletion delta, DocumentNode currentNode) {
    if (currentNode is! TextNode) {
      return;
    }

    var textDeleted = delta.textDeleted;
    var textLeft = delta.oldText;
    int startOffset = textLeft.length - textDeleted.length;

    /*historyManager.saveToHistory(EditorCommandFunction((document, transaction) {
      editor.executeCommand(InsertTextCommand(
          documentPosition: DocumentPosition(
              nodeId: currentNode.id,
              nodePosition: TextNodePosition(offset: startOffset)),
          textToInsert: textDeleted,
          attributions: <Attribution>{}));
      _setNewSelection(currentNode, true);
      //currentNode.text.insert(textToInsert: AttributedText(textDeleted), startOffset: startOffset);
    }));*/
  }

  /*void _saveInsertionForUndo(
      TextEditingDeltaInsertion delta, DocumentNode currentNode) {
    if (currentNode is! TextNode) {
      return;
    }

    var textInserted = delta.textInserted;
    if(textInserted.isEmpty){return;}

    var textBefore = delta.oldText;
    var startOffset = textBefore.length;
    print(textInserted);
    print(startOffset);
    var endOffset = delta.insertionOffset + (textInserted.length);
    print(endOffset);

    if(endOffset < 0){ return;}
    if(startOffset == endOffset){print("SAME");return;}
    if(startOffset < 2)(print("startOffset < 2"));

    historymanager.saveToHistory(EditorCommandFunction((document, transaction) {
      editor.executeCommand(DeleteSelectionCommand(documentSelection: DocumentSelection(
          base: DocumentPosition(
              nodeId: currentNode.id,
              nodePosition: TextNodePosition(offset: startOffset)),
          extent: DocumentPosition(
              nodeId: currentNode.id,
              nodePosition: TextNodePosition(offset: endOffset)))));

      //currentNode.text.removeRegion(startOffset: startOffset, endOffset: endOffset);
      _setNewSelection(currentNode);
      //currentNode.text.insert(textToInsert: AttributedText(textDeleted), startOffset: startOffset);
    }));
  }*/
}
