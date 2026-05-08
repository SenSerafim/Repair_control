// Cross-session-leak fix: список user-scoped провайдеров и хелпер,
// который при logout (authenticated → unauthenticated) инвалидирует их все.
//
// Зачем это нужно
// ----------------
// До этого фикса `AuthController.logout()` чистил только токены в
// secure storage. Riverpod-провайдеры с пользовательскими данными
// (мои инструменты, чаты, команды, инструменты проекта, материалы и т.д.)
// были созданы без `.autoDispose` — после logout их state продолжал жить
// в RAM. При login/регистрации нового пользователя UI успевал показать
// закешированные данные предыдущего юзера до того, как свежий ответ от
// API приходил и переписывал state.
//
// Это и есть root cause багов из QA-документа «Контроль ремонта.docx»:
//   #11 — «Инструмент другого пользователя из совместного проекта виден
//          на экране Мои инструменты, при открытии — ошибка» (getTool на
//          бэке проверяет ownerId и возвращает 403, отсюда ошибка).
//   #12 — «У нового пользователя отображаются участники команды/чаты/
//          инструменты другого пользователя».
//
// Поэтому на logout мы явно инвалидируем все провайдеры из списка ниже,
// и при новом логине build() каждого вернёт свежий ответ для текущего
// userId. Подключается через `userScopedInvalidationProvider` в
// `app.dart` `_initServices`.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/approvals/application/approvals_controller.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/chat/application/chats_controller.dart';
import '../../features/finance/application/budget_controller.dart';
import '../../features/finance/application/payments_controller.dart';
import '../../features/materials/application/materials_controller.dart';
import '../../features/notes/application/notes_controller.dart';
import '../../features/profile/application/notification_settings_controller.dart';
import '../../features/profile/application/profile_controller.dart';
import '../../features/projects/application/projects_list_controller.dart';
import '../../features/selfpurchase/application/selfpurchase_controller.dart';
import '../../features/stages/application/stages_controller.dart';
import '../../features/stages/application/templates_controller.dart';
import '../../features/steps/application/step_detail_controller.dart';
import '../../features/steps/application/steps_controller.dart';
import '../../features/team/application/team_controller.dart';
import '../../features/tools/application/tools_controller.dart';

/// User-scoped провайдеры, которые держат данные текущего пользователя в
/// памяти. При logout они должны быть инвалидированы, чтобы новый юзер не
/// видел кеш предыдущего.
///
/// Если добавляешь новый AsyncNotifier/FutureProvider, который тянет
/// что-то связанное с конкретным пользователем (его проекты, чаты,
/// инструменты, права в проекте и т.п.) — добавь его сюда. Если данные
/// глобальные (методология, FAQ, knowledge base, support-контакты) —
/// сюда не нужно.
final userScopedProviders = <ProviderOrFamily>[
  // tools
  myToolsProvider,
  toolDetailProvider,
  toolIssuancesProvider,
  projectToolRegistryProvider,
  // team
  teamControllerProvider,
  // materials
  materialsControllerProvider,
  materialDetailProvider,
  // approvals
  approvalsControllerProvider,
  approvalDetailProvider,
  // notes
  notesControllerProvider,
  // stages / templates / steps
  stagesControllerProvider,
  templateDetailProvider,
  stepsControllerProvider,
  stepDetailProvider,
  // chats
  projectChatsProvider,
  myChatsProvider,
  messagesProvider,
  // projects
  activeProjectsProvider,
  archivedProjectsProvider,
  projectsFilterProvider,
  projectsSearchQueryProvider,
  // selfpurchase
  selfpurchasesControllerProvider,
  // finance
  paymentsControllerProvider,
  paymentDetailProvider,
  projectBudgetProvider,
  stageBudgetProvider,
  moneyFlowFilteredProvider,
  // profile / notifications
  profileControllerProvider,
  notificationSettingsProvider,
];

/// Подписывается на `authControllerProvider` и при переходе в
/// `unauthenticated` (как обычный logout, так и `onSessionExpired` после
/// провала refresh) инвалидирует все провайдеры из `providers`.
///
/// Отдельно вынесено в функцию, чтобы её можно было дёргать из теста с
/// произвольным списком провайдеров без привязки к продакшн-списку.
void watchAuthAndInvalidate(Ref ref, List<ProviderOrFamily> providers) {
  ref.listen<AuthState>(authControllerProvider, (prev, next) {
    final wasAuthenticated = prev?.status == AuthStatus.authenticated;
    final nowUnauthenticated = next.status == AuthStatus.unauthenticated;
    if (!wasAuthenticated || !nowUnauthenticated) return;
    for (final p in providers) {
      ref.invalidate(p);
    }
  });
}

/// Корневой listener-провайдер. Подключается в `app.dart` через
/// `ref.read(userScopedInvalidationProvider)` — после этого глобально
/// слушает изменения auth-состояния и автоматически инвалидирует все
/// `userScopedProviders` при logout.
final userScopedInvalidationProvider = Provider<void>((ref) {
  watchAuthAndInvalidate(ref, userScopedProviders);
});
