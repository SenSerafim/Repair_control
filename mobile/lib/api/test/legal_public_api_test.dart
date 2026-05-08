import 'package:test/test.dart';
import 'package:repair_control_api/repair_control_api.dart';


/// tests for LegalPublicApi
void main() {
  final instance = RepairControlApi().getLegalPublicApi();

  group(LegalPublicApi, () {
    //Future legalPublicControllerListVersions(String kind) async
    test('test legalPublicControllerListVersions', () async {
      // TODO
    });

    //Future legalPublicControllerRender(String kind) async
    test('test legalPublicControllerRender', () async {
      // TODO
    });

  });
}
