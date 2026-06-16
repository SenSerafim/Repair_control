import 'package:test/test.dart';
import 'package:repair_control_api/repair_control_api.dart';

/// tests for FilesApi
void main() {
  final instance = RepairControlApi().getFilesApi();

  group(FilesApi, () {
    //Future filesApiControllerPresign(Object body) async
    test('test filesApiControllerPresign', () async {
      // TODO
    });
  });
}
