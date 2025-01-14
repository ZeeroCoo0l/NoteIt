import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:super_editor/super_editor.dart';
import 'package:super_editor_note_app/Objects/converter_of_document.dart';
import 'package:super_editor_note_app/Objects/editor_text_converter.dart';
import 'package:super_editor_note_app/Objects/note_handler.dart';
import 'package:super_editor_note_app/Screens/NoteFolderScreen.dart';
import 'package:super_editor_note_app/Widgets/customIconButton.dart';
import 'package:super_editor_note_app/historyManager.dart';

import '../EditorIMEOverride.dart';
import '../Objects/note.dart';
import '../constants.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen(
      {super.key, required this.note, required this.noteHandler});
  final Note note;
  final NoteHandler noteHandler;

  @override
  State<EditorScreen> createState() => _EditorScreenState(note, noteHandler);
}

class _EditorScreenState extends State<EditorScreen> with WidgetsBindingObserver{
  late final Note _note;
  late final NoteHandler _noteHandler;
  late final MutableDocument _document;
  late final DocumentComposer _composer;
  late final DocumentEditor _editor;
  late CommonEditorOperations _editorOperations;
  late Historymanager _historymanager;
  bool _isBoldActivated = false;
  bool _isItalicActivated = false;
  bool _isStrikeThroughActivated = false;
  bool _isHeader1Activated = false;
  final TextEditingController _titleController = TextEditingController();
  late DocumentNode previouslySelectedNode;
  late DocumentNode currentlySelectedNode;
  bool scrollsImplemented = false;
  Timer? _autosaveTimer;

  late FocusNode keyBoardFocusNode = FocusNode();
  SoftwareKeyboardController softwareKeyboardController =
      SoftwareKeyboardController();
  ScrollController scrollController = ScrollController();

  _EditorScreenState(Note note, NoteHandler noteHandler) {
    _note = note;
    _noteHandler = noteHandler;
  }

  @override
  void initState() {
    super.initState();

    // Ladda in notes text till editorn
    _document = _note.toEditor();

    _composer = DocumentComposer();
    _editor = DocumentEditor(document: _document);
    _historymanager = Historymanager(editor: _editor, composer: _composer);
    _composer.addListener(_onComposerChanged);
    _editorOperations = CommonEditorOperations(
      editor: _editor,
      composer: _composer,
      documentLayoutResolver: () => documentLayout as DocumentLayout,
    );

    currentlySelectedNode = _document.nodes.first;
    previouslySelectedNode = _document.nodes.first;
    _titleController.text = _note.name;

    scrollController.addListener(_scrollListener);
    _startAutosaveTimer(); // Starts saving automatically
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    keyBoardFocusNode.dispose();
    _composer.dispose();
    _document.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  DocumentLayout? get documentLayout =>
      context.findRenderObject() as DocumentLayout?;

  void _scrollListener() {
    if (scrollsImplemented) {
      scrollController.animateTo(scrollController.offset+50, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    }
  }

  void _startAutosaveTimer() {
    _autosaveTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _note.saveWithDocument(_document);
      //_showSnackbar(context, "saved");
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _note.saveWithDocument(_document); // Save when the app is paused or inactive
      print("SAVED");
    }
  }

  void _onComposerChanged() {
    if (previouslySelectedNode != currentlySelectedNode) {
      previouslySelectedNode = currentlySelectedNode;
      currentlySelectedNode =
          _document.getNodeById(_composer.selection!.base.nodeId)!;
    }
    final selection = _composer.selection;
    if (selection == null) {
      return;
    }
    final currentNode = _editor.document.getNodeById(selection.base.nodeId);
    final currentOffset =
        (selection.base.nodePosition as TextNodePosition).offset;

    //selection.isCollapsed ? "" : _showSelectionMenu(selection, null);

    if (currentNode is TextNode) {
      if ((currentNode is ParagraphNode || currentNode is ListItemNode)) {
        _showCurrentAttributionOnButtons(currentNode, currentOffset);
      }
    }

    if (_editor.document.nodes.isEmpty) {
      var node = ParagraphNode(
          id: DocumentEditor.createNodeId(), text: AttributedText(""));
      _document.insertNodeAt(0, node);
      _composer.selection = DocumentSelection.collapsed(
          position: DocumentPosition(
              nodeId: node.id, nodePosition: node.endPosition));
    }
  }

  void _showCurrentAttributionOnButtons(
      TextNode currentNode, int currentOffset) {
    var text = currentNode.text;
    if (_composer.selection!.isCollapsed) {
      currentOffset -= 1;
    }
    var attributions =
        text.getAllAttributionsAt(currentOffset); // LADE TILL AS....

    final currentBlockType = currentNode.getMetadataValue('blockType')?.id;
    if (currentNode is ParagraphNode) {
      if (currentBlockType.toString() == 'header1') {
        setState(() {
          _isHeader1Activated = true;
        });
      } else {
        _isHeader1Activated = false;
      }
    }

    if (attributions.isEmpty) {
      setState(() {
        _isBoldActivated = false;
        _isStrikeThroughActivated = false;
        _isItalicActivated = false;
      });
    } else {
      setState(() {
        _isBoldActivated = false;
        _isItalicActivated = false;
        _isStrikeThroughActivated = false;
      });

      for (var attr in attributions) {
        if (attr is NamedAttribution) {
          switch (attr) {
            case boldAttribution:
              setState(() {
                _isBoldActivated = true;
              });
              break;
            case italicsAttribution:
              setState(() {
                _isItalicActivated = true;
              });
              break;
            case strikethroughAttribution:
              setState(() {
                _isStrikeThroughActivated = true;
              });
              break;
            default:
              break;
          }
        }
      }
    }
  }

  void _toggleBold() {
    Set<Attribution> attributions = <Attribution>{};
    attributions.add(boldAttribution);
    bool isSelected =
        _editorOperations.toggleAttributionsOnSelection(attributions);
    if (!isSelected) {
      _historymanager.saveToHistory(ToggleTextAttributionsCommand(
          documentSelection: _composer.selection!,
          attributions: attributions)); // Addera kommando till history.
      setState(() {
        _isBoldActivated = !_isBoldActivated;
      });

      bool isActivated =
          _editorOperations.toggleComposerAttributions(attributions);
      //_historymanager.saveToHistory(ToggleTextAttributionsCommand(documentSelection: _composer.selection!, attributions: attributions)); // Addera kommando till history.
      if (isActivated) {
        setState(() {
          _isBoldActivated = true;
        });
      } else {
        setState(() {
          _isBoldActivated = false;
        });
      }
    }
  }

  void _toggleItalic() {
    Set<Attribution> attributions = <Attribution>{};
    attributions.add(italicsAttribution);
    bool isSelected =
        _editorOperations.toggleAttributionsOnSelection(attributions);
    if (!isSelected) {
      setState(() {
        _isItalicActivated = !_isItalicActivated;
      });

      bool isActivated =
          _editorOperations.toggleComposerAttributions(attributions);
      _historymanager.saveToHistory(ToggleTextAttributionsCommand(
          documentSelection: _composer.selection!,
          attributions: attributions)); // Addera kommando till history.
      if (isActivated) {
        setState(() {
          _isItalicActivated = true;
        });
      } else {
        setState(() {
          _isItalicActivated = false;
        });
      }
    }
  }

  void _toggleStrikethrough() {
    Set<Attribution> attributions = <Attribution>{};
    attributions.add(strikethroughAttribution);
    bool isSelected =
        _editorOperations.toggleAttributionsOnSelection(attributions);
    if (!isSelected) {
      setState(() {
        _isStrikeThroughActivated = !_isStrikeThroughActivated;
      });

      bool isActivated =
          _editorOperations.toggleComposerAttributions(attributions);
      _historymanager.saveToHistory(ToggleTextAttributionsCommand(
          documentSelection: _composer.selection!,
          attributions: attributions)); // Addera kommando till history.

      if (isActivated) {
        //_historymanager.saveToHistory(AddTextAttributionsCommand(documentSelection: _composer.selection!, attributions: attributions));
        setState(() {
          _isStrikeThroughActivated = true;
        });
      } else {
        //_historymanager.saveToHistory(RemoveTextAttributionsCommand(documentSelection: _composer.selection!, attributions: attributions));
        setState(() {
          _isStrikeThroughActivated = false;
        });
      }
    }
  }

  void _toggleHeader1() {
    var selection = _composer.selection;
    final baseNode = _editor.document.getNodeById(selection!.base.nodeId);

    if (baseNode is! ParagraphNode) {
      return;
    }

    setState(() {
      _isHeader1Activated = !_isHeader1Activated;
    });

    final currentBlockType = baseNode.getMetadataValue('blockType')?.id;
    if (currentBlockType == 'header1') {
      // Currently a header, switch to a paragraph
      baseNode.putMetadataValue(
          'blockType', const NamedAttribution('paragraph'));
      //_historymanager.saveToHistory(ToggleTextAttributionsCommand(documentSelection: _composer.selection!, attributions: <Attribution>{const NamedAttribution('paragraph')})); // Addera kommando till history.

      //_historymanager.saveToHistory(AddTextAttributionsCommand(documentSelection: _composer.selection!, attributions: <Attribution>{const NamedAttribution('header1')})); // Addera kommando till history.
    } else {
      // Currently a paragraph (or anything else), switch to a header
      baseNode.putMetadataValue('blockType', const NamedAttribution('header1'));
      //_historymanager.saveToHistory(AddTextAttributionsCommand(documentSelection: _composer.selection!, attributions: <Attribution>{const NamedAttribution('paragraph')})); // Addera kommando till history.
    }
  }

  void _toogleList(ListItemType type) {
    var selection = _composer.selection;
    //_document.doesSelectedTextContainAttributions(selection!, <Attribution>{header1Attribution});
    if (selection == null) {
      throw Exception("_toogleListBulleted: SELECTION IS NULL");
    }

    final baseNode = _editor.document.getNodeById(selection.base.nodeId);
    if (baseNode == null) {
      throw Exception("ERROR: BaseNode is null in _toggleListBulleted()");
    }

    if (baseNode is ParagraphNode) {
      _editor.executeCommand(
          ConvertParagraphToListItemCommand(nodeId: baseNode.id, type: type));
      _historymanager.saveToHistory(ConvertParagraphToListItemCommand(
          nodeId: baseNode.id, type: type)); // Addera command till history
    } else {
      _editor.executeCommand(
          ConvertListItemToParagraphCommand(nodeId: baseNode.id));
      _historymanager.saveToHistory(ConvertListItemToParagraphCommand(
          nodeId: baseNode.id)); // Addera command till history
    }
  }

  void _toggleTask() {
    var selection = _composer.selection;
    if (selection == null) {
      throw Exception("ERROR: Selection is null in _toggleTask()");
    }

    final baseNode = _editor.document.getNodeById(selection.base.nodeId);
    if (baseNode == null) {
      throw Exception("ERROR: BaseNode is null in _toggleTask()");
    }

    if (_editor.document.nodes.first.id == baseNode.id) {
      var newFirstLine = ParagraphNode(
          id: DocumentEditor.createNodeId(), text: AttributedText(""));
      _document.insertNodeBefore(existingNode: baseNode, newNode: newFirstLine);
    }

    if (baseNode is ParagraphNode) {
      _editor
          .executeCommand(ConvertParagraphToTaskCommand(nodeId: baseNode.id));

      //_historymanager.saveToHistory(CustomConvertTaskToParagraph(_composer));
      _historymanager
          .saveToHistory(EditorCommandFunction((document, transcation) {
        _editor.executeCommand(CustomConvertTaskToParagraph(_composer));
        var currentNode = document.getNode(_composer.selection!.extent);
        if (currentNode is TextNode) {
          currentNode.text = AttributedText("");
        }
      }));
    } else if (baseNode is ListItemNode) {
      var type = baseNode.type;
      _editor.executeCommand(
          ConvertListItemToParagraphCommand(nodeId: baseNode.id));
      _editor
          .executeCommand(ConvertParagraphToTaskCommand(nodeId: baseNode.id));

      _historymanager
          .saveToHistory(EditorCommandFunction((document, transcation) {
        _editor.executeCommand(CustomConvertTaskToParagraph(_composer));
        var currentNode = document.getNode(_composer.selection!.extent);
        if (currentNode != null) {
          _editor.executeCommand(ConvertParagraphToListItemCommand(
              nodeId: currentNode.id, type: type));
          _composer.selection = DocumentSelection.collapsed(
              position: DocumentPosition(
                  nodePosition: currentNode.endPosition,
                  nodeId: currentNode.id));
        }
      }));
    } else if (baseNode is TaskNode) {
      var previousNode = _editor.document.getNodeBefore(baseNode);
      _editor.executeCommand(CustomConvertTaskToParagraph(_composer));
    }
  }

  void _copyToClipboard() {
    if (!_composer.selection!.isCollapsed) {
      _editorOperations.copy();
    }
  }

  void _cutToClipboard() {
    if (!_composer.selection!.isCollapsed) {
      _editorOperations.cut();
    }
  }

  void _pasteFromClipboard() {
    // TODO: Fånga upp tidigare text för att kunna använda undo!
    _editorOperations.paste();
  }

  List<StyleRule> rulesEditor() {
    return [
      StyleRule(
        BlockSelector.all,
        (doc, docNode) {
          return {
            "maxWidth": 640.0,
            "padding": const CascadingPadding.symmetric(horizontal: 24),
            "textStyle": TextStyle(
              inherit: false,
              fontStyle: GoogleFonts.roboto().fontStyle,
              //fontFamily: "InriaSans",
              color: Theme.of(context).colorScheme.primary,
              fontSize: 18,
              height: 1.4,
            ),
          };
        },
      ),
      StyleRule(
        const BlockSelector("header1"),
        (doc, docNode) {
          return {
            "padding": const CascadingPadding.only(top: 16),
            "textStyle": const TextStyle(
              //color: Color(0xFF333333),
              fontSize: 38,
              fontWeight: FontWeight.bold,
            ),
          };
        },
      ),
      StyleRule(
        const BlockSelector("header2"),
        (doc, docNode) {
          return {
            "padding": const CascadingPadding.only(top: 32),
            "textStyle": const TextStyle(
              //color: Color(0xFF333333),
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          };
        },
      ),
      StyleRule(
        const BlockSelector("header3"),
        (doc, docNode) {
          return {
            "padding": const CascadingPadding.only(top: 28),
            "textStyle": const TextStyle(
              //color: Colors.black87,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          };
        },
      ),
      StyleRule(
        const BlockSelector("paragraph"),
        (doc, docNode) {
          return {
            "padding": const CascadingPadding.only(top: 2),
            "textStyle": const TextStyle(
              //Lade till denna
              //color: Colors.black87,
              fontSize: 20,
              height: 1,
            ),
          };
        },
      ),
      StyleRule(
        const BlockSelector("paragraph").after("header1"),
        (doc, docNode) {
          return {
            "padding": const CascadingPadding.only(top: 0),
          };
        },
      ),
      StyleRule(
        const BlockSelector("paragraph").after("header2"),
        (doc, docNode) {
          return {
            "padding": const CascadingPadding.only(top: 0),
          };
        },
      ),
      StyleRule(
        const BlockSelector("paragraph").after("header3"),
        (doc, docNode) {
          return {
            "padding": const CascadingPadding.only(top: 0),
          };
        },
      ),
      StyleRule(
        const BlockSelector("listItem"),
        (doc, docNode) {
          return {
            "padding": const CascadingPadding.only(top: 0, bottom: 0),
            "textStyle": const TextStyle(
              //color: Colors.black87,
              fontSize: 18,
              height: 1,
            ),
            //"manualVerticalAdjustment": 3.0,
            "indent": 0.0,
          };
        },
      ),
      StyleRule(
        const BlockSelector("task"),
        (doc, docNode) {
          return {
            "padding": const CascadingPadding.only(top: 0, bottom: 0),
            "textStyle": const TextStyle(
              //color: Colors.black87,
              fontSize: 18,
              height: 2,
            ),
            //"manualVerticalAdjustment": 3.0,
          };
        },
      ),
      StyleRule(
        const BlockSelector("blockquote"),
        (doc, docNode) {
          return {
            "textStyle": const TextStyle(
              //color: Colors.grey,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          };
        },
      ),
      StyleRule(
        BlockSelector.all.last(),
        (doc, docNode) {
          return {
            "padding": const CascadingPadding.only(bottom: 12),
            //"textStyle": style,
          };
        },
      ),
    ];
  }

  @override
  Widget build(context) {
    final imeOverride = EditorIMEOverride(
        editor: _editor, composer: _composer, historyManager: _historymanager, scrollController: scrollController);
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          //color: fgDarkMode,
          onPressed: () {
            _note.saveWithDocument(_document);
            //_showSnackbar(context, "saved");
            Navigator.pop(context, true);
          },
        ),
        title: TextField(
          controller: _titleController,
          enabled: true,
          decoration: const InputDecoration(border: InputBorder.none),
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w300,
              color: Theme.of(context).colorScheme.primary),
          onTapOutside: (pointerEvent) {
            if (!_noteHandler.containsNoteWithName(_titleController.text)) {
              String newName = _titleController.text;
              setState(() {
                _note.rename(newName);
              });
            } else {
              _titleController.text = _note.name;
            }
            FocusNode().unfocus();
            _showSnackbar(context, "Title already exists...");
          },
          onSubmitted: (string) {
            if (!_noteHandler.containsNoteWithName(_titleController.text)) {
              String newName = _titleController.text;
              setState(() {
                _note.rename(newName);
              });
            } else if (_titleController.text.isEmpty) {
              _titleController.text = _note.name;
              _showSnackbar(context, "Title can't be empty...");
            } else {
              _titleController.text = _note.name;
              _showSnackbar(context, "Title already exists...");
            }
            FocusNode().unfocus();
          },
        ),
        actions: [
          /*IconButton(
            onPressed: _historymanager.undo,
            icon: const Icon(Icons.undo_rounded),
            tooltip: "Undo",
          ),*/
          IconButton(
              onPressed: () {
                //String content = MarkdownHandler().convertDocumentToMarkdown(_document);
                //_note.save(content);
                _note.saveWithDocument(_document);
                _showSnackbar(context, "saved");
              },
              icon: const Icon(Icons.save)),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          //keyBoardFocusNode.requestFocus();
          setState(() {
            scrollsImplemented = true;
          });
        },
        child: Container(
          decoration: const BoxDecoration(),
          child: Column(
            children: [
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8.00),
                  child: SuperEditor(
                    /*contentTapDelegateFactory: (context){
                      var tapHandler = SuperEditorLaunchLinkTapHandler(_document, _composer);
                      return tapHandler;
                    },*/
                    androidHandleColor:
                        Theme.of(context).colorScheme.inversePrimary,
                    iOSHandleColor: Theme.of(context).colorScheme.inversePrimary,
                    softwareKeyboardController: softwareKeyboardController,
                    imePolicies: const SuperEditorImePolicies(
                        openKeyboardOnSelectionChange: true,
                        openKeyboardOnGainPrimaryFocus: true,
                        closeKeyboardOnLosePrimaryFocus: true,
                        closeKeyboardOnSelectionLost: true),
                    autofocus: false,
                    imeOverrides: imeOverride,
                    focusNode: keyBoardFocusNode,
                    composer: _composer,
                    editor: _editor,
                    stylesheet: defaultStylesheet.copyWith(
                        documentPadding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
                        rules: rulesEditor(),
                        inlineTextStyler: _setInlineTextStyle),
                    componentBuilders: [
                      TaskComponentBuilder(_editor),
                      ...defaultComponentBuilders
                    ],
                    scrollController: scrollController,
                  ),
                ),
              ),
              Expanded(child: buildButtonBar(), flex: 1),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackbar(BuildContext context, String text) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Padding(
        padding: const EdgeInsets.only(bottom: 48.0),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          width: 32,
          decoration: ShapeDecoration(
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8))),
            color: Theme.of(context).colorScheme.primary,
          ),
          child: Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18)),
        ),
      ),
      backgroundColor: Colors.transparent,
      duration: const Duration(seconds: 2),
      elevation: 0,
      //padding: EdgeInsets.all(16),
    ));
  }

  TextStyle _setInlineTextStyle(attributions, textStyle) {
    TextStyle style = textStyle;
    for (var attr in attributions) {
      if (attr == boldAttribution) {
        style = style.copyWith(
            color: Theme.of(context).colorScheme.tertiary,
            fontWeight: FontWeight.w800);
      } else if (attr == italicsAttribution) {
        style = style.apply(fontStyle: FontStyle.italic);
      } else if (attr == strikethroughAttribution) {
        style = style.apply(
          decoration: style.decoration == null
              ? TextDecoration.lineThrough
              : TextDecoration.combine(
                  [TextDecoration.lineThrough, style.decoration!]),
        );
      }
    }
    return style;
  }

  Widget buildButtonBar() {
    Size size = MediaQuery.of(context).size;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: ButtonBar(
          mainAxisSize: MainAxisSize.min,
          buttonMinWidth: defaultPadding,
          buttonPadding: const EdgeInsets.symmetric(
              vertical: defaultPadding / 8, horizontal: defaultPadding / 16),
          alignment: MainAxisAlignment.center,
          children: [
            Customiconbutton(
                onPressed: _copyToClipboard,
                icon: Icon(
                  //color: fgDarkMode,
                  color: Theme.of(context).colorScheme.primary,
                  Icons.copy_rounded,
                ),
                isButtonSelected: false),
            Customiconbutton(
                onPressed: _cutToClipboard,
                icon: Icon(
                  //color: fgDarkMode,
                  color: Theme.of(context).colorScheme.primary,
                  Icons.cut_rounded,
                ),
                isButtonSelected: false),
            Customiconbutton(
                onPressed: _pasteFromClipboard,
                icon: Icon(
                  //color: fgDarkMode,
                  color: Theme.of(context).colorScheme.primary,
                  Icons.paste_rounded,
                ),
                isButtonSelected: false),
            SizedBox(
              height: defaultPadding,
              width: defaultPadding * 2,
              child: VerticalDivider(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Customiconbutton(
                onPressed: _toggleBold,
                icon: Icon(
                  //color: fgDarkMode,
                  color: Theme.of(context).colorScheme.primary,
                  Icons.format_bold_rounded,
                ),
                isButtonSelected: _isBoldActivated),
            Customiconbutton(
                onPressed: _toggleItalic,
                icon: Icon(
                  //color: fgDarkMode,
                  color: Theme.of(context).colorScheme.primary,
                  Icons.format_italic_rounded,
                ),
                isButtonSelected: _isItalicActivated),
            Customiconbutton(
                onPressed: _toggleStrikethrough,
                icon: Icon(
                  //color: fgDarkMode,
                  color: Theme.of(context).colorScheme.primary,
                  Icons.format_strikethrough_rounded,
                ),
                isButtonSelected: _isStrikeThroughActivated),
            Customiconbutton(
                onPressed: _toggleHeader1,
                icon: Icon(
                  //color: fgDarkMode,
                  color: Theme.of(context).colorScheme.primary,
                  Icons.h_mobiledata_rounded,
                  size: 38,
                ),
                isButtonSelected: _isHeader1Activated),
            Customiconbutton(
                onPressed: _toggleTask,
                icon: Icon(
                  //color: fgDarkMode,
                  color: Theme.of(context).colorScheme.primary,
                  Icons.checklist_rounded,
                ),
                isButtonSelected: false),
          ],
        ),
      ),
    );
  }
}
