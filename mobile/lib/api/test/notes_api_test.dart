import 'package:test/test.dart';
import 'package:repair_control_api/repair_control_api.dart';

/// tests for NotesApi
void main() {
  final instance = RepairControlApi().getNotesApi();

  group(NotesApi, () {
    //Future notesControllerCreate(String projectId, CreateNoteDto createNoteDto) async
    test('test notesControllerCreate', () async {
      // TODO
    });

    //Future notesControllerDelete(String noteId) async
    test('test notesControllerDelete', () async {
      // TODO
    });

    //Future notesControllerList(String projectId, String scope, String stageId, String search) async
    test('test notesControllerList', () async {
      // TODO
    });

    //Future notesControllerUpdate(String noteId, UpdateNoteDto updateNoteDto) async
    test('test notesControllerUpdate', () async {
      // TODO
    });
  });
}
