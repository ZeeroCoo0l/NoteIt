import 'dart:collection';
import 'dart:ffi';

import 'package:flutter/widgets.dart';
import 'package:super_editor/super_editor.dart';

class MarkdownHandler {
  MarkdownHandler();

  // C O N V E R T    M D     TO    D O C U M E N T
  MutableDocument convertMarkdownToDocument(List<String> markdownList) {
    MutableDocument document = MutableDocument();
    TextNode node = TextNode(id: DocumentEditor.createNodeId(), text: AttributedText(""));
    //TextNode node;
    for (var line in markdownList) {
      node = _convertMarkdownAttributes(line);

      if (line.startsWith("# ")) {
        String temp = line.substring(2);
        var attributedTemp = node.text;
        var newText = attributedTemp.copyTextInRange(SpanRange(2, attributedTemp.length));
        node.text = newText;
        node.metadata = {"blockType": const NamedAttribution("header1")};
        document.add(node);

        /*document.add(ParagraphNode(
            id: DocumentEditor.createNodeId(),
            text: AttributedText(temp),
            metadata: {"blockType": const NamedAttribution("header1")}));

         */
      } else {
        document.add(node);
        /*document.add(ParagraphNode(
            id: DocumentEditor.createNodeId(), text: AttributedText(line)));*/
      }
    }


    return document;
  }

  bool _startsWithIntegerAndDot(String input) {
    return RegExp(r'^\d+.').hasMatch(input);
  }

  TextNode _convertMarkdownAttributes(String line) {
    var text = AttributedText(line);
    TextNode node = TextNode(id: DocumentEditor.createNodeId(),text: text);

    // TODO: Hämta attribut och lägg till Spans i node.
    node = _setMdInlineAttributes(line, node);
    text = node.text;
    line = text.text;

    // Initiera node till rätt subklass.
    if (line.startsWith("- ")) {
      var removedDash = text.removeRegion(startOffset: 0, endOffset: 1);
      node = ListItemNode.unordered(id: DocumentEditor.createNodeId(), text: removedDash);
    } else if (line.startsWith("[ ]")) {
      node = TaskNode(
          id: DocumentEditor.createNodeId(), text: text, isComplete: false);
    } else if (line.startsWith("[x]")) {
      node = TaskNode(
          id: DocumentEditor.createNodeId(), text: text, isComplete: true);
    } else if (_startsWithIntegerAndDot(text.text)) {
      //int start = text.text.indexOf(" ");
      text = _removeOrdinalValue(text);
      //var removedOrdinalValue = text.removeRegion(startOffset: 0, endOffset: start);
      node = ListItemNode.ordered(id: DocumentEditor.createNodeId(), text: text);
    } else {
      node = ParagraphNode(id: DocumentEditor.createNodeId(), text: text);
    }

    return node;
  }

  AttributedText _removeOrdinalValue(AttributedText text) {
    String textString = text.text;

    var match = RegExp(r'^\d+. ').firstMatch(textString);
    //print("MatchIndex: "+match!.end.toString());
    if(match != null){
      int index = match.end;
      if(!index.isNegative){
        var temp = text.copyText(index);
        //print(temp.toString());
        text = temp;
      }
    }
    return text;
  }

  // Apply Attributions
  TextNode _setMdInlineAttributes(String line, TextNode nodeToFix) {
    //var boldMatches = _getBoldRangesFromMd(line);
    int offset = 0;
    var nodeAndOffset = _applyBold(nodeToFix, line, offset);
    nodeAndOffset = _applyItalic(nodeToFix, nodeToFix.text.text, offset);
    nodeAndOffset = _applyStrikeThrough(nodeToFix, nodeToFix.text.text, offset);

    return nodeAndOffset.keys.first;
  }

  // APPLY BOLD
  Map<TextNode, int> _applyBold(TextNode nodeToFix,String line, int offset) {
    var boldMatches = _getBoldRangesFromMd(line);
    if(boldMatches.isNotEmpty){
      int start = -1;
      int end = -1;
      //int offset = 0;
      for(var match in boldMatches){
        start = match["start"]! - offset;
        end = match['end']! - offset;

        for(MapEntry<String, int> entry in match.entries){
          if(entry.key == "start"){
            //print("start");
            start = entry.value;
          }
          else if( entry.key == "end"){
            //print("end");
            end = entry.value;
          }
        }

        if(start != -1 && end != -1){
          nodeToFix.text.addAttribution(boldAttribution, SpanRange(start, end));

          nodeToFix.text = nodeToFix.text.removeRegion(startOffset: start-offset, endOffset: start+2-offset);
          offset += 2;

          nodeToFix.text = nodeToFix.text.removeRegion(startOffset: end - 1 - offset, endOffset: end+1-offset);
          offset += 2;

          start = -1;
          end = -1;
        }

      }
    }
    return {nodeToFix:offset};
  }

  List<Map<String, int>> _getBoldRangesFromMd(String input) {
    // RegExp to match words that start and end with **
    RegExp regExp = RegExp(r'\*\*(.+?)\*\*');
    Iterable<RegExpMatch> matches = regExp.allMatches(input);

    // List to store the start and end indices
    List<Map<String, int>> ranges = [];

    // For each match, record the start and end index
    for (RegExpMatch match in matches) {
      //print("MATCH: "+ match.input);
      ranges.add({
        'start': match.start,
        'end': match.end - 1 // Since `match.end` is exclusive, subtract 1 to get the inclusive end index
      });
    }

    return ranges;
  }

  // APPLY ITALIC
  Map<TextNode, int> _applyItalic(TextNode nodeToFix, String line, int offset) {
    var italicMatches = _getItalicRangesFromMd(line);

    if(italicMatches.isNotEmpty){
      int start = -1;
      int end = -1;
      //int offset = 0;
      for(var match in italicMatches){
        start = match["start"]! - offset;
        end = match['end']! - offset;

        for(MapEntry<String, int> entry in match.entries){
          if(entry.key == "start"){
            //print("start");
            start = entry.value;
          }
          else if( entry.key == "end"){
            //print("end");
            end = entry.value;
          }
        }

        if(start != -1 && end != -1){
          nodeToFix.text.addAttribution(italicsAttribution, SpanRange(start, end));

          nodeToFix.text = nodeToFix.text.removeRegion(startOffset: start-offset, endOffset: start+1-offset);
          offset += 1;

          nodeToFix.text = nodeToFix.text.removeRegion(startOffset: end - offset, endOffset: end+1-offset);
          offset += 1;

          start = -1;
          end = -1;
        }

      }
    }
    return {nodeToFix:offset};


  }

  List<Map<String, int>> _getItalicRangesFromMd(String input) {
    // RegExp to match words that start and end with **
    RegExp regExp = RegExp(r'\*(.+?)\*');
    Iterable<RegExpMatch> matches = regExp.allMatches(input);

    // List to store the start and end indices
    List<Map<String, int>> ranges = [];

    // For each match, record the start and end index
    for (RegExpMatch match in matches) {
      if(match.input[1] == "*" && match.input[match.input.length-3] == "*"){
        continue;
      }
      ranges.add({
        'start': match.start,
        'end': match.end - 1 // Since `match.end` is exclusive, subtract 1 to get the inclusive end index
      });
    }

    return ranges;
  }

  // Apply Strikethough
  Map<TextNode, int> _applyStrikeThrough(TextNode nodeToFix, String line, int offset) {
    var strikethroughMatches = _getStrikethroughRangesFromMd(line);

    if(strikethroughMatches.isNotEmpty){
      int start = -1;
      int end = -1;
      //int offset = 0;
      for(var match in strikethroughMatches){
        start = match["start"]! - offset;
        end = match['end']! - offset;

        for(MapEntry<String, int> entry in match.entries){
          if(entry.key == "start"){
            //print("start");
            start = entry.value;
          }
          else if( entry.key == "end"){
            //print("end");
            end = entry.value;
          }
        }

        if(start != -1 && end != -1){
          nodeToFix.text.addAttribution(strikethroughAttribution, SpanRange(start, end));

          nodeToFix.text = nodeToFix.text.removeRegion(startOffset: start-offset, endOffset: start+1-offset);
          offset += 1;
          nodeToFix.text = nodeToFix.text.removeRegion(startOffset: end - offset, endOffset: end+1-offset);
          offset += 1;

          start = -1;
          end = -1;
        }

      }
    }
    return {nodeToFix:offset};
  }

  List<Map<String, int>> _getStrikethroughRangesFromMd(String line) {
    RegExp regExp = RegExp(r'~(.+?)~');
    Iterable<RegExpMatch> matches = regExp.allMatches(line);

    List<Map<String, int>> ranges = [];

    // For each match, record the start and end index
    for (RegExpMatch match in matches) {

      ranges.add({
        'start': match.start,
        'end': match.end - 1
      });
    }

    return ranges;
  }




  // C O N V E R T    D O C U M E N T     TO    M D
  String convertDocumentToMarkdown(Document document) {
    String mdContent = "";
    int indexInOrderedList = 0;
    final nodes = document.nodes;
    for (var node in nodes) {
      if (node is TextNode) {
        if (node is ParagraphNode) {
          indexInOrderedList = 0;
          mdContent += _handleParagraphNode(node);
        } else if (node is ListItemNode) {
          if (node.type == ListItemType.unordered) {
            indexInOrderedList = 0;
            mdContent += _handleListItemNode(node, null);
          } else if (node.type == ListItemType.ordered) {
            indexInOrderedList += 1;
            mdContent += _handleListItemNode(node, indexInOrderedList);
          }
        } else if (node is TaskNode) {
          indexInOrderedList = 0;
          mdContent += _handleTaskNode(node);
        }
      }
    }
    return mdContent;
  }

  String _handleParagraphNode(ParagraphNode node) {
    //String mdContent = "";
    final metadata = node.metadata;

    /*
    Hämta attributes för noden och skriv den i markdown!
     */
    String text = node.text.text;
    final spans = node.text.spans;
    var markers = spans.markers;
    int offset = 0;

    return _convertNodeAttributes(markers, text, offset, metadata);
  }


  String _convertNodeAttributes(Iterable<SpanMarker> markers, String text,
      int offset, Map<String, dynamic> metadata) {
    for (var marker in markers) {
      // Bold
      if (marker.attribution == boldAttribution) {
        if (marker.isStart) {
          int start = marker.offset;
          if (text.characters.elementAt(start + offset) == " ") {
            start += 1;
          }
          text = "${text.substring(0, start + offset)}**${text.substring(start + offset)}";
          offset += 2;
        } else if (marker.isEnd) {
          int end = marker.offset + 1;
          text = "${text.substring(0, end + offset)}**${text.substring(end + offset)}";
          offset += 2;
        }
      }

      // Italics
      else if (marker.attribution == italicsAttribution) {
        if (marker.isStart) {
          int start = marker.offset;
          text = "${text.substring(0, start + offset)}*${text.substring(start + offset)}";
          offset += 1;
        } else if (marker.isEnd) {
          int end = marker.offset + 1;
          text = "${text.substring(0, end + offset)}*${text.substring(end + offset)}";
          offset += 1;
        }
      }

      // StrikeThrough
      else if (marker.attribution == strikethroughAttribution) {
        if (marker.isStart) {
          int start = marker.offset;
          /*if (text.characters.elementAt(start - 1 + offset) == "*") {
            start -= 1;
          }*/

          String subStart =  "";
          String subEnd =  "";

          subStart = text.substring(0, start + offset);
          subEnd = text.substring(start + offset );

          text = "$subStart~$subEnd";
          offset += 1;
        } else if (marker.isEnd) {
          int end = marker.offset + 1;

          String subStart =  "";
          String subEnd =  "";

          subStart = text.substring(0, end + offset);
          subEnd = text.substring(end + offset);

          text = "$subStart~$subEnd";
          offset += 1;
        }
      }
    }
    // Header
    if (metadata.keys.contains("blockType") &&
        metadata.values.contains(NamedAttribution("header1"))) {
      text = "# $text";
    }
    return "$text\n";
  }


  String _handleListItemNode(ListItemNode node, int? indexInOrderedList) {
    var metadata = node.metadata;
    String text = node.text.text;
    final spans = node.text.spans;
    var markers = spans.markers;
    int offset = 0;

    text = _convertNodeAttributes(markers, text, offset, metadata);
    if (node.type == ListItemType.unordered) {
      text = "- $text";
    } else if (node.type == ListItemType.ordered) {
      text = "$indexInOrderedList. $text";
      // TODO: Hur ska du veta vilket nummer som du är i listan? (Type: Ordered)
    }

    return text;
  }

  String _handleTaskNode(TaskNode node) {
    String mdContent = "";

    return mdContent;
  }



}
