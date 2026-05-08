import 'package:test/test.dart';
import 'package:repair_control_api/repair_control_api.dart';


/// tests for HealthApi
void main() {
  final instance = RepairControlApi().getHealthApi();

  group(HealthApi, () {
    //Future healthControllerHealth() async
    test('test healthControllerHealth', () async {
      // TODO
    });

  });
}
