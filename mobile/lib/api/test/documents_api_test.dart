import 'package:test/test.dart';
import 'package:repair_control_api/repair_control_api.dart';


/// tests for DocumentsApi
void main() {
  final instance = RepairControlApi().getDocumentsApi();

  group(DocumentsApi, () {
    //Future documentsControllerConfirm(String id) async
    test('test documentsControllerConfirm', () async {
      // TODO
    });

    //Future documentsControllerDelete(String id) async
    test('test documentsControllerDelete', () async {
      // TODO
    });

    //Future documentsControllerDownload(String id) async
    test('test documentsControllerDownload', () async {
      // TODO
    });

    //Future documentsControllerGet(String id) async
    test('test documentsControllerGet', () async {
      // TODO
    });

    //Future documentsControllerList(String projectId, { String stageId, String stepId, String category, String q }) async
    test('test documentsControllerList', () async {
      // TODO
    });

    //Future documentsControllerPatch(String id, PatchDocumentDto patchDocumentDto) async
    test('test documentsControllerPatch', () async {
      // TODO
    });

    //Future documentsControllerPresign(String projectId, PresignUploadDto presignUploadDto) async
    test('test documentsControllerPresign', () async {
      // TODO
    });

    //Future documentsControllerThumbnail(String id) async
    test('test documentsControllerThumbnail', () async {
      // TODO
    });

  });
}
