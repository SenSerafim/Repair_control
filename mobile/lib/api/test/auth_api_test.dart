import 'package:test/test.dart';
import 'package:repair_control_api/repair_control_api.dart';

/// tests for AuthApi
void main() {
  final instance = RepairControlApi().getAuthApi();

  group(AuthApi, () {
    //Future authControllerLogin(LoginDto loginDto) async
    test('test authControllerLogin', () async {
      // TODO
    });

    //Future authControllerLogout(LogoutDto logoutDto) async
    test('test authControllerLogout', () async {
      // TODO
    });

    //Future authControllerRecoveryReset(RecoveryResetDto recoveryResetDto) async
    test('test authControllerRecoveryReset', () async {
      // TODO
    });

    //Future authControllerRecoverySend(RecoverySendDto recoverySendDto) async
    test('test authControllerRecoverySend', () async {
      // TODO
    });

    //Future authControllerRecoveryVerify(RecoveryVerifyDto recoveryVerifyDto) async
    test('test authControllerRecoveryVerify', () async {
      // TODO
    });

    //Future authControllerRefresh(RefreshDto refreshDto) async
    test('test authControllerRefresh', () async {
      // TODO
    });

    //Future authControllerRegister(RegisterDto registerDto) async
    test('test authControllerRegister', () async {
      // TODO
    });
  });
}
