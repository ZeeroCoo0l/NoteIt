import 'package:flutter/material.dart';
import 'package:super_editor_note_app/Screens/EditorScreen.dart';

import '../Objects/note.dart';
import '../Objects/note_handler.dart';

class CustomSearchBar extends StatelessWidget {
  CustomSearchBar({super.key, required NoteHandler inputedNoteHandler}){
    noteHandler = inputedNoteHandler;
    for(Note note in noteHandler!.notes){
      noteTitles.add(note.name);
    }

  }
  NoteHandler? noteHandler;
  List<String> noteTitles = [];

  @override
  Widget build(BuildContext context) {
    var controller = TextEditingController();
    controller.addListener(()=>_updateSearch());


    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: IconButton(
        onPressed: () {
          showSearch(context: context, delegate: CustomSearchDelegate(noteTitles: noteTitles, noteHandler: noteHandler!));
        },
          icon: const Icon(Icons.search_rounded)),
    );
  }

  void _updateSearch() {
    List<Note> notes = noteHandler!.notes;

  }
}


class CustomSearchDelegate extends SearchDelegate<String> {

  CustomSearchDelegate({required this.noteTitles, required this.noteHandler});
  List<String> noteTitles;
  NoteHandler noteHandler;

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
          // When pressed here the query will be cleared from the search bar.
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => Navigator.of(context).pop(),
      // Exit from the search screen.
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final List<String> searchResults = noteTitles
        .where((item) => item.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return ListView.builder(
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(searchResults[index]),
          onTap: () {
            // Handle the selected search result.
            close(context, searchResults[index]);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final List<String> suggestionList = query.isEmpty
        ? noteTitles
        : noteTitles
        .where((item) => item.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: suggestionList.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(suggestionList[index]),
          onTap: () {
            query = suggestionList[index];
            Note? note = noteHandler.getNodeByName(suggestionList[index]);
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => EditorScreen(note: note!, noteHandler: noteHandler)));
          },
        );
      },
    );
  }

}
