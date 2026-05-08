import 'package:test/test.dart';
import 'package:repair_control_api/repair_control_api.dart';


/// tests for MeApi
void main() {
  final instance = RepairControlApi().getMeApi();

  group(MeApi, () {
    //Future usersControllerAddDevice(RegisterDeviceDto registerDeviceDto) async
    test('test usersControllerAddDevice', () async {
      // TODO
    });

    //Future usersControllerAddRole(AddRoleDto addRoleDto) async
    test('test usersControllerAddRole', () async {
      // TODO
    });

    //Future usersControllerMe() async
    test('test usersControllerMe', () async {
      // TODO
    });

    //Future usersControllerRemoveRole(String role) async
    test('test usersControllerRemoveRole', () async {
      // TODO
    });

    //Future usersControllerRoles() async
    test('test usersControllerRoles', () async {
      // TODO
    });

    //Future usersControllerSetActive(SetActiveRoleDto setActiveRoleDto) async
    test('test usersControllerSetActive', () async {
      // TODO
    });

    //Future usersControllerUpdateMe(UpdateProfileDto updateProfileDto) async
    test('test usersControllerUpdateMe', () async {
      // TODO
    });

  });
}
