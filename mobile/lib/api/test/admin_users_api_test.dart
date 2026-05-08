import 'package:test/test.dart';
import 'package:repair_control_api/repair_control_api.dart';


/// tests for AdminUsersApi
void main() {
  final instance = RepairControlApi().getAdminUsersApi();

  group(AdminUsersApi, () {
    //Future adminUsersControllerAudit(String id) async
    test('test adminUsersControllerAudit', () async {
      // TODO
    });

    //Future adminUsersControllerBan(String id, BanUserDto banUserDto) async
    test('test adminUsersControllerBan', () async {
      // TODO
    });

    //Future adminUsersControllerDetail(String id) async
    test('test adminUsersControllerDetail', () async {
      // TODO
    });

    //Future adminUsersControllerForceLogout(String id) async
    test('test adminUsersControllerForceLogout', () async {
      // TODO
    });

    //Future adminUsersControllerList({ String q, String role, bool banned, num limit, num offset }) async
    test('test adminUsersControllerList', () async {
      // TODO
    });

    //Future adminUsersControllerResetPassword(String id) async
    test('test adminUsersControllerResetPassword', () async {
      // TODO
    });

    //Future adminUsersControllerSetRoles(String id, SetRolesDto setRolesDto) async
    test('test adminUsersControllerSetRoles', () async {
      // TODO
    });

    //Future adminUsersControllerUnban(String id) async
    test('test adminUsersControllerUnban', () async {
      // TODO
    });

  });
}
