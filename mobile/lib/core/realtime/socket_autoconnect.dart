import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_controller.dart';
import 'socket_service.dart';

/// Автоматически подключает и отключает [SocketService] в зависимости от
/// состояния [authControllerProvider]. Должен быть «включён» в bootstrap
/// через `ref.read(socketAutoconnectProvider)` или `ref.listen`.
final socketAutoconnectProvider = Provider<void>((ref) {
  void apply(AuthState s) {
    final service = ref.read(socketServiceProvider);
    if (s.status == AuthStatus.authenticated) {
      service.connect();
    } else {
      service.disconnect();
    }
  }

  // Реакция на все изменения AuthState, включая первый build.
  apply(ref.read(authControllerProvider));
  ref.listen<AuthState>(authControllerProvider, (prev, next) {
    final wasAuth = prev?.status == AuthStatus.authenticated;
    final isAuth = next.status == AuthStatus.authenticated;
    if (wasAuth == isAuth) return;
    apply(next);
  });
});
