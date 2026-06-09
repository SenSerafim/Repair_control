# NEWFIX Gaps Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close all gaps from the ТЗ NEWFIX audit (10 critical + 15 important pieces of work) in the Flutter mobile client without touching backend (API frozen in 1.0.0) and without git operations until explicitly approved.

**Architecture:** Each phase touches one domain (profile / stage / checklist / project list / tools / etc.) so phases are mostly independent. Domain/data/application/presentation layering is preserved. New backend endpoints are listed but blocked — those tasks ship UI only and are flagged for the backend track.

**Tech Stack:** Flutter 3.35, Dart 3.11, Riverpod 2 (`riverpod_generator`), `freezed`, `go_router` 14, `dio` + `retrofit`, `url_launcher` (already in deps), `flutter_secure_storage`, `printing` for PDF, design tokens from `mobile/lib/core/theme/tokens.dart`.

---

## Open questions — decisions baked into this plan

**Q1: Rename «Материалы» in `finance/_widgets/budget_tabs_bar.dart`, `budget_hero_card.dart`, `approval_detail_screen.dart:1054`, `Expense.materials`?**
**Decision: NO.** These refer to the *expense category* (work vs materials spending), not material *requests*. The TZ §5.1 rename rule targets the requests feature only. Leave finance labels alone.

**Q2: Should hidden `_QuestionsSection` and `_SubstepsSection` in `step_detail_screen.dart` (marked `// ignore: unused_element`) be re-enabled?**
**Decision: KEEP HIDDEN for now.** They were intentionally muted (see surrounding comments). The current TZ scope does not require them. Phase 9 (backlog) tracks re-evaluation.

**Q3: Document hierarchy — project / stage / step?**
**Decision: Two-level for this iteration.**
- Project-level docs: already in `documents_screen.dart` (top-level docs feature).
- Stage-level docs: in `stage_docs_tab.dart` — add `📷 Фото` / `📄 Документы` toggle + group documents by step within stage.
- Step-level standalone screen: deferred to backlog.

---

## File structure overview

### New files

```
mobile/lib/features/stages/presentation/_widgets/
  stage_requests_tab.dart          # P2: stage requests tab body
  stage_quick_actions_row.dart     # P2: dual chat/budget buttons block

mobile/lib/features/steps/presentation/
  reclamation_sheet.dart           # P4: separate from extra_work_sheet

mobile/lib/features/tools/presentation/
  tool_custody_history_screen.dart # P6: history UI
  batch_tool_add_sheet.dart        # P6: multi-tool entry

mobile/lib/shared/widgets/
  app_notifications_bell.dart      # P8: shared bell with badge

mobile/test/features/stages/_widgets/
  stage_requests_tab_test.dart
  stage_quick_actions_row_test.dart
mobile/test/features/steps/
  reclamation_sheet_test.dart
mobile/test/features/tools/
  batch_tool_add_sheet_test.dart
```

### Modified files (canonical list)

```
mobile/lib/features/user_profile/presentation/user_profile_screen.dart
mobile/lib/features/projects/presentation/project_card.dart
mobile/lib/features/projects/presentation/console_screen.dart
mobile/lib/features/projects/presentation/create_project_screen.dart
mobile/lib/features/stages/presentation/stage_detail_screen.dart
mobile/lib/features/stages/presentation/_widgets/stage_tabs_bar.dart
mobile/lib/features/stages/presentation/_widgets/stage_stats_row.dart
mobile/lib/features/stages/presentation/_widgets/stage_checklist_tab.dart
mobile/lib/features/stages/presentation/_widgets/stage_docs_tab.dart
mobile/lib/features/stages/presentation/_widgets/checklist_step_row.dart
mobile/lib/features/steps/presentation/step_detail_screen.dart
mobile/lib/features/finance/presentation/budget_screen.dart
mobile/lib/features/tools/domain/tool.dart
mobile/lib/features/tools/presentation/my_tools_screen.dart
mobile/lib/features/tools/presentation/add_tool_screen.dart
mobile/lib/features/tools/presentation/project_tools_screen.dart
mobile/lib/features/team/presentation/team_aggregate_screen.dart
mobile/lib/core/routing/app_router.dart
```

---

## Phase dependencies

```
Phase 1 (Quick wins) ─┬─► Phase 5 (Project list & creation)
                      └─► Phase 8 (Notifications & defensive RBAC)

Phase 2 (Stage detail) ─► Phase 3 (Checklist UX) ─► Phase 4 (Reclamation)
Phase 2 ─► Phase 7 (Stage PDF + docs toggle)
Phase 6 (Tools enrichment) — independent
```

P1: phases 1–5. P2: phases 6–8. Phase 9 = backlog (not in this plan).

---

# Phase 1 — Quick Wins (P1)

Cosmetic / 1-handler fixes that unlock visible value with minimal risk. Each task is independent.

## Task 1.1: Profile «Позвонить» button (tel:)

**Files:**
- Modify: `mobile/lib/features/user_profile/presentation/user_profile_screen.dart:137-141`
- Test: `mobile/test/features/user_profile/user_profile_screen_test.dart` (extend existing or create)

- [ ] **Step 1.1.1: Write failing test for tel-launch behaviour**

```dart
// mobile/test/features/user_profile/user_profile_phone_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:repair_control/features/user_profile/presentation/user_profile_screen.dart';
// helpers wrap test with ProviderScope + mock aggregate

class _MockLauncher extends UrlLauncherPlatform {
  Uri? lastLaunched;
  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    lastLaunched = Uri.parse(url);
    return true;
  }
  @override
  LinkDelegate? get linkDelegate => null;
  // ... noSuchMethod fallback for other methods
}

void main() {
  testWidgets('Phone button launches tel: scheme with header.phone', (tester) async {
    final mock = _MockLauncher();
    UrlLauncherPlatform.instance = mock;

    await tester.pumpWidget(/* test harness with header.phone = '+79991112233' */);
    await tester.tap(find.byKey(const ValueKey('user_profile_phone_button')));
    await tester.pumpAndSettle();

    expect(mock.lastLaunched, Uri(scheme: 'tel', path: '+79991112233'));
  });
}
```

- [ ] **Step 1.1.2: Run test, expect failure (`onPressed` is empty)**

```bash
cd mobile && flutter test test/features/user_profile/user_profile_phone_test.dart
# Expect: FAIL — lastLaunched stays null because onPressed: () {}
```

- [ ] **Step 1.1.3: Implement tel-launch**

Replace `user_profile_screen.dart:137-141` block:

```dart
// Was:
//   onPressed: header.phone.isEmpty ? null : () {},
// Becomes:
OutlinedButton.icon(
  key: const ValueKey('user_profile_phone_button'),
  icon: const Icon(PhosphorIconsRegular.phone, size: 16),
  label: const Text('Позвонить'),
  onPressed: header.phone.isEmpty
      ? null
      : () => launchUrl(Uri(scheme: 'tel', path: header.phone)),
),
```

Add import at top of file if missing: `import 'package:url_launcher/url_launcher.dart';`

- [ ] **Step 1.1.4: Run test, expect pass**

```bash
flutter test test/features/user_profile/user_profile_phone_test.dart
# Expect: PASS
```

- [ ] **Step 1.1.5: `flutter analyze` clean**

```bash
flutter analyze lib/features/user_profile
# Expect: 0 issues
```

## Task 1.2: Profile «Написать в чат» button

**Files:**
- Modify: `mobile/lib/features/user_profile/presentation/user_profile_screen.dart:142-146`
- Modify (route): `mobile/lib/core/routing/app_router.dart` (add `/chats/direct/:userId` if missing)
- Modify (repo): `mobile/lib/features/chat/data/chats_repository.dart` (add `ensureDirectChat(String userId)` if backend supports; otherwise show toast)

- [ ] **Step 1.2.1: Confirm backend support**

```bash
grep -rn "direct\|/chats/direct\|chatKind\|ChatKind" mobile/lib/features/chat/data/ mobile/lib/features/chat/domain/
# If no direct-chat endpoint found, treat as backend-blocked: implement toast fallback instead.
```

- [ ] **Step 1.2.2: If backend supports — write `ChatsRepository.ensureDirectChat(userId)` test + impl**

Skip if backend-blocked.

```dart
// chats_repository.dart
Future<Chat> ensureDirectChat(String userId) async {
  final res = await _dio.post<Map<String, dynamic>>(
    '/api/chats/direct',
    data: {'userId': userId},
  );
  return Chat.fromJson(res.data!);
}
```

- [ ] **Step 1.2.3: Wire button**

```dart
// user_profile_screen.dart:142-146
OutlinedButton.icon(
  key: const ValueKey('user_profile_chat_button'),
  icon: const Icon(PhosphorIconsRegular.chatCircle, size: 16),
  label: const Text('Написать в чат'),
  onPressed: () async {
    try {
      final chat = await ref.read(chatsRepositoryProvider).ensureDirectChat(userId);
      if (context.mounted) context.push('/chats/${chat.id}');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось открыть чат')),
        );
      }
    }
  },
),
```

If backend-blocked, replace body with toast `'Прямые чаты пока недоступны'` and add a TODO comment with the backend ticket reference.

- [ ] **Step 1.2.4: Test (mock repository) + analyze**

```bash
flutter test test/features/user_profile/user_profile_chat_test.dart
flutter analyze lib/features/user_profile lib/features/chat
```

## Task 1.3: Move «Заметка» icon from console header to project_card

**Files:**
- Modify: `mobile/lib/features/projects/presentation/project_card.dart:50-82` (add icon to action row)
- Modify: `mobile/lib/features/projects/presentation/console_screen.dart:336-343` (remove icon — but keep long-press alternative? See TZ §11.2)

TZ §19 row "Карточка проекта (шапка)" says note icon goes next to `+`, `🔔`, `⋮` on the **card**. The console header itself does *not* need it.

- [ ] **Step 1.3.1: Add note icon to project_card action row**

In `project_card.dart` find the row containing the kebab menu (around L76):

```dart
// Add before _CardKebab(...)
IconButton(
  icon: const Icon(PhosphorIconsRegular.note, size: 20),
  tooltip: 'Заметки проекта',
  onPressed: () => context.push('/projects/${project.id}/notes'),
),
```

- [ ] **Step 1.3.2: Remove note icon from console_screen.dart header**

Find and delete the note-icon `IconButton` at `console_screen.dart:340-343` and its long-press wrapper at the same location.

- [ ] **Step 1.3.3: Widget test — project_card shows note icon**

```dart
testWidgets('ProjectCard exposes a note shortcut', (tester) async {
  await tester.pumpWidget(_wrap(ProjectCard(project: _sample)));
  expect(find.byTooltip('Заметки проекта'), findsOneWidget);
});
```

- [ ] **Step 1.3.4: Update existing console widget test if it asserts the note icon** (search `'Заметки'` in test/widget/)

- [ ] **Step 1.3.5: `flutter test test/widget/` + `flutter analyze`**

## Task 1.4: Stage stats row — counter «Доработок» instead of «Файлов»

**Files:**
- Modify: `mobile/lib/features/stages/presentation/_widgets/stage_stats_row.dart:40-50`
- Modify: stage aggregate provider — surface rework count (`approvals` of scope=`extra_work` with rejected/in-progress status? Or count of `Complaint` records when backend lands).

- [ ] **Step 1.4.1: Identify counter source**

```bash
grep -rn "reworkCount\|extra_work\|complaints" mobile/lib/features/stages/domain/ mobile/lib/features/stages/data/
```

If `Stage` model exposes `reworkOpen`/`reworkTotal` — use directly. If not, derive from approvals controller (count `extra_work` scope with `pending`/`rejected` status).

- [ ] **Step 1.4.2: Replace "Файлов" cell**

```dart
// stage_stats_row.dart inside the 4-cell row, the cell currently rendering files count:
_StatCell(
  icon: PhosphorIconsRegular.warningCircle,
  label: 'Доработок',
  value: '${stage.reworkOpen}/${stage.reworkTotal}',
),
```

- [ ] **Step 1.4.3: Test — golden + numeric assertion**

```dart
testWidgets('Stats row shows "Доработок: 2/5"', (tester) async {
  await tester.pumpWidget(_wrap(StageStatsRow(stage: _stageWith(reworkOpen: 2, reworkTotal: 5))));
  expect(find.text('2/5'), findsOneWidget);
  expect(find.text('Доработок'), findsOneWidget);
});
```

- [ ] **Step 1.4.4: `flutter test test/features/stages/` + `flutter analyze`**

## Task 1.5: Budget «За этап» filter chips in _MaterialsTab

**Files:**
- Modify: `mobile/lib/features/finance/presentation/budget_screen.dart:437` (the `_MaterialsTab` widget)
- Reuse: `mobile/lib/features/materials/presentation/materials_list_screen.dart:120` (existing stage filter pattern — copy)

- [ ] **Step 1.5.1: Add `_stageId` state to `_MaterialsTab`** (was a `StatelessWidget`, convert to `ConsumerStatefulWidget` if not already).

- [ ] **Step 1.5.2: Render `AppFilterPillBar` above the materials table with the same source provider as `materials_list_screen.dart`**

Copy pattern from materials_list_screen — reuse `stageChipsProvider(projectId)` if available.

```dart
AppFilterPillBar(
  items: [
    AppFilterPill(id: 'all', label: 'Все этапы'),
    for (final s in stages) AppFilterPill(id: s.id, label: 'Этап ${s.order}'),
  ],
  activeId: _stageId,
  onSelect: (id) => setState(() => _stageId = id),
),
```

- [ ] **Step 1.5.3: Filter rows by `_stageId` before passing to table widget**

```dart
final filtered = _stageId == 'all'
    ? rows
    : rows.where((r) => r.stageId == _stageId).toList();
```

- [ ] **Step 1.5.4: Widget test asserts filter works**

```dart
testWidgets('Materials tab filters by stage chip', (tester) async {
  // pump with rows spanning 2 stages
  // tap chip for stage A
  // expect rows for stage B not visible
});
```

- [ ] **Step 1.5.5: `flutter test test/features/finance/` + `flutter analyze`**

---

# Phase 2 — Stage Detail Rework (P1)

Builds on top of Phase 1. Adds the missing requests tab + quick-actions block + stage/step chat entry points.

## Task 2.1: Add `StageTab.requests` enum + tab UI

**Files:**
- Modify: `mobile/lib/features/stages/presentation/_widgets/stage_tabs_bar.dart:5-15`
- Modify: `mobile/lib/features/stages/presentation/stage_detail_screen.dart:200-250` (IndexedStack)
- Create: `mobile/lib/features/stages/presentation/_widgets/stage_requests_tab.dart`

- [ ] **Step 2.1.1: Extend enum**

```dart
// stage_tabs_bar.dart:5
enum StageTab { checklist, approvals, docs, requests }

extension StageTabX on StageTab {
  String get title => switch (this) {
    StageTab.checklist => 'Чек-лист',
    StageTab.approvals => 'Согл.',
    StageTab.docs => 'Докум.',
    StageTab.requests => 'Заявки',
  };
}
```

- [ ] **Step 2.1.2: Create `StageRequestsTab` widget**

It is a thin shim over `materials_list_screen` filtered by stageId.

```dart
// stage_requests_tab.dart
class StageRequestsTab extends ConsumerWidget {
  const StageRequestsTab({super.key, required this.stageId, required this.projectId});
  final String stageId;
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(materialRequestsProvider(projectId));
    return requests.when(
      data: (list) {
        final filtered = list.where((r) => r.stageId == stageId).toList();
        if (filtered.isEmpty) {
          return const AppEmptyState(
            icon: PhosphorIconsRegular.package,
            title: 'Нет заявок',
            subtitle: 'Создайте заявку с экрана «Заявки проекта».',
          );
        }
        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (_, i) => MaterialCard(request: filtered[i]),
        );
      },
      loading: () => const AppLoadingState(),
      error: (e, _) => AppErrorState(
        title: 'Не удалось загрузить заявки',
        subtitle: e is ApiError && e.message != null
            ? e.message!
            : 'Попробуйте ещё раз',
        onRetry: () => ref.invalidate(materialRequestsProvider(projectId)),
      ),
    );
  }
}
```

- [ ] **Step 2.1.3: Add the 4th tab in `stage_detail_screen.dart` IndexedStack**

```dart
// in build:
IndexedStack(
  index: _tab.index,
  children: [
    StageChecklistTab(...),
    StageApprovalsTab(...),
    StageDocsTab(...),
    StageRequestsTab(stageId: stage.id, projectId: stage.projectId),
  ],
),
```

- [ ] **Step 2.1.4: Widget test — all 4 tabs render**

```dart
testWidgets('Stage detail has Заявки tab', (tester) async {
  await tester.pumpWidget(_wrap(StageDetailScreen(stageId: 's1')));
  await tester.pumpAndSettle();
  expect(find.text('Заявки'), findsOneWidget);
  await tester.tap(find.text('Заявки'));
  await tester.pumpAndSettle();
  expect(find.byType(StageRequestsTab), findsOneWidget);
});
```

- [ ] **Step 2.1.5: `flutter test test/features/stages/` + `flutter analyze`**

## Task 2.2: Dual quick-actions block (💬 Чат + ₽ Бюджет)

**Files:**
- Create: `mobile/lib/features/stages/presentation/_widgets/stage_quick_actions_row.dart`
- Modify: `mobile/lib/features/stages/presentation/stage_detail_screen.dart` (insert between executors row and tabs)

- [ ] **Step 2.2.1: Create row widget**

```dart
class StageQuickActionsRow extends StatelessWidget {
  const StageQuickActionsRow({
    super.key,
    required this.onOpenChat,
    required this.onOpenBudget,
  });
  final VoidCallback onOpenChat;
  final VoidCallback onOpenBudget;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: AppPrimaryButton(
              icon: PhosphorIconsFill.chatCircleDots,
              label: 'Чат этапа',
              onPressed: onOpenChat,
              variant: AppButtonVariant.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppPrimaryButton(
              icon: PhosphorIconsRegular.currencyRub,
              label: 'Бюджет этапа',
              onPressed: onOpenBudget,
              variant: AppButtonVariant.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2.2.2: Insert into `stage_detail_screen.dart` between `StageExecutorsRow` and `StageTabsBar`**

```dart
// existing structure:
StageExecutorsRow(...),
StageQuickActionsRow(
  onOpenChat: () => context.push('/stages/${stage.id}/chat'),
  onOpenBudget: () => context.push('/stages/${stage.id}/budget'),
),
StageTabsBar(...),
```

- [ ] **Step 2.2.3: Remove now-redundant budget icon from app bar in stage_detail_screen** (line ~77)

- [ ] **Step 2.2.4: Test + analyze**

## Task 2.3: Stage-level chat route + button wiring

**Files:**
- Modify: `mobile/lib/core/routing/app_router.dart` — add `/stages/:stageId/chat` route
- Modify: backend integration (verify stage chat exists in chat domain — search `chatKind`/`stageId` in chat domain)

- [ ] **Step 2.3.1: Verify backend supports stage chats**

```bash
grep -rn "stageId\|stage_chat\|ChatScope.stage" mobile/lib/features/chat/domain/ mobile/lib/features/chat/data/
```

If backend lacks stage-scoped chats, fall back to project chat with stage filter as a parameter. Document this in the task.

- [ ] **Step 2.3.2: Add route**

```dart
// app_router.dart
GoRoute(
  path: '/stages/:stageId/chat',
  builder: (context, state) {
    final stageId = state.pathParameters['stageId']!;
    return StageChatScreen(stageId: stageId);  // thin wrapper around ChatConversationScreen
  },
),
```

- [ ] **Step 2.3.3: Create `StageChatScreen`** — wrapper that calls `ensureStageChat(stageId)` (if backend supports) and forwards to `ChatConversationScreen`.

- [ ] **Step 2.3.4: Test the navigation flow**

## Task 2.4: Step header chat icon

**Files:**
- Modify: `mobile/lib/features/steps/presentation/step_detail_screen.dart:32-50`

- [ ] **Step 2.4.1: Add chat icon to AppBar actions in step_detail_screen**

```dart
appBar: AppBar(
  title: Text(step.title),
  actions: [
    IconButton(
      tooltip: 'Чат этапа',
      icon: const Icon(PhosphorIconsRegular.chatCircle),
      onPressed: () => context.push('/stages/${step.stageId}/chat'),
    ),
    // existing kebab menu
  ],
),
```

- [ ] **Step 2.4.2: Test that chat icon present + navigates**

---

# Phase 3 — Checklist UX (P1)

## Task 3.1: Drag-reorder steps

**Files:**
- Modify: `mobile/lib/features/stages/presentation/_widgets/stage_checklist_tab.dart:70-150`

Reuse pattern from `mobile/lib/features/stages/presentation/stages_screen.dart:471` (existing `ReorderableListView.builder`).

- [ ] **Step 3.1.1: Replace `ListView.builder` with `ReorderableListView.builder`**

```dart
ReorderableListView.builder(
  itemCount: steps.length,
  onReorder: (oldIndex, newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final reordered = [...steps];
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);
    await ref.read(stepsControllerProvider(stageId).notifier).reorder(
      reordered.map((s) => s.id).toList(),
    );
  },
  itemBuilder: (context, i) => ChecklistStepRow(
    key: ValueKey(steps[i].id),
    step: steps[i],
  ),
),
```

- [ ] **Step 3.1.2: Backend check — does StepsController expose `reorder(List<String> ids)`?**

```bash
grep -rn "reorder\|reorderSteps" mobile/lib/features/steps/application/ mobile/lib/features/steps/data/
```

If no — add wrapper that PATCHes `/api/stages/{id}/steps/reorder` with `{order: [...ids]}`. If backend doesn't expose, mark as backend-blocker; gate UI behind feature flag.

- [ ] **Step 3.1.3: Optimistic update + rollback on error**

- [ ] **Step 3.1.4: Test — drag step, assert new order persisted**

- [ ] **Step 3.1.5: analyze + test**

## Task 3.2: Search inside checklist

**Files:**
- Modify: `mobile/lib/features/stages/presentation/_widgets/stage_checklist_tab.dart`

- [ ] **Step 3.2.1: Add `_query` state + `AppSearchField` above the list**

```dart
AppSearchField(
  controller: _searchCtrl,
  hint: 'Поиск шагов',
  onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
),
```

- [ ] **Step 3.2.2: Filter steps before passing to ReorderableListView**

```dart
final visible = _query.isEmpty
    ? steps
    : steps.where((s) => s.title.toLowerCase().contains(_query)).toList();
```

Gotcha: disable drag when `_query.isNotEmpty` (reordering filtered list is destructive).

- [ ] **Step 3.2.3: Test — type into search, only matching rows visible**

## Task 3.3: «На согласование» badge on step rows

**Files:**
- Modify: `mobile/lib/features/stages/presentation/_widgets/checklist_step_row.dart`

- [ ] **Step 3.3.1: Surface step state**

```bash
grep -rn "pendingApproval\|plan_pending\|StepState" mobile/lib/features/steps/domain/
```

If `Step` already exposes `approvalState` or similar — use directly. Otherwise compute from approvals list filtered by `stepId` + `scope=step`.

- [ ] **Step 3.3.2: Render badge**

```dart
if (step.hasPendingApproval)
  AppPill(
    text: 'На согласование',
    color: AppColors.warning,
    icon: PhosphorIconsRegular.clock,
  ),
```

- [ ] **Step 3.3.3: Test golden — row with pending vs row without**

## Task 3.4: Batch select + bulk actions (DEFER decision)

**Decision needed before this task:** Which bulk actions? Spec says batch ops but doesn't enumerate. Likely:
- Bulk send to approval
- Bulk delete (foreman only)

Park this task until product confirms operations. Tracked but not implemented in this iteration.

- [ ] **Step 3.4.1: Open product question (assign to spec owner) — DO NOT IMPLEMENT until confirmed.**

---

# Phase 4 — Reclamation Flow (P1)

## Task 4.1: Separate `ReclamationSheet` from `extra_work_sheet`

**Files:**
- Create: `mobile/lib/features/steps/presentation/reclamation_sheet.dart`
- Modify: `mobile/lib/features/steps/presentation/step_detail_screen.dart` (add "Отправить на доработку" button)

**Domain decision:** Reclamation is a *defect submission* with photo evidence. Backend likely uses `Approval` with `scope=step` + `verdict=reject` + attached photos, OR a dedicated `Complaint` model. Need to verify.

- [ ] **Step 4.1.1: Backend audit**

```bash
grep -rn "complaint\|Complaint\|reclamation\|RECLAMATION" backend/src 2>/dev/null | head -20
# Also check approvals scope enum:
grep -rn "ApprovalScope\|extra_work\|step_rework\|step_reject" mobile/lib/features/approvals/domain/
```

Decide one of:
1. Backend exposes `POST /api/approvals` with `scope='step'` + `decision='reject'` + photos → use this.
2. Backend has dedicated complaints → use that.
3. Neither → escalate as backend blocker; ship UI behind feature flag.

- [ ] **Step 4.1.2: Create `ReclamationSheet` widget**

```dart
class ReclamationSheet extends ConsumerStatefulWidget {
  const ReclamationSheet({super.key, required this.stepId});
  final String stepId;
  // ... showModalBottomSheet, photo picker, comment TextField, submit button
}
```

Photo picker: reuse existing pattern from `extra_work_sheet.dart` (multiple-photo upload via `compressImage` 1920/80).

- [ ] **Step 4.1.3: Wire submit to chosen backend endpoint**

- [ ] **Step 4.1.4: Add CTA in `step_detail_screen.dart` _ActionCtas section**

```dart
// Visible only to roles that can reclaim (customer / foreman seeing master's step)
if (canReclaim)
  OutlinedButton.icon(
    icon: const Icon(PhosphorIconsRegular.warningOctagon),
    label: const Text('Отправить на доработку'),
    onPressed: () => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ReclamationSheet(stepId: step.id),
    ),
  ),
```

- [ ] **Step 4.1.5: Test — sheet renders, submit calls correct endpoint**

- [ ] **Step 4.1.6: Update reclamation counter in stage_stats_row** (Task 1.4 reads this) — should auto-update via reactive providers.

---

# Phase 5 — Project list & creation UX (P1)

## Task 5.1: Mini-dashboard on project list card

**Files:**
- Modify: `mobile/lib/features/projects/presentation/project_card.dart`

Spec wants: «days to deadline · stages done/total · in-progress count» on the card itself.

- [ ] **Step 5.1.1: Verify card data**

```bash
grep -rn "daysToDeadline\|stagesDone\|inProgress" mobile/lib/features/projects/domain/
```

If `Project` already exposes these → use. If not → derive from progressCache fields.

- [ ] **Step 5.1.2: Add stats row to card below address line**

```dart
Row(
  children: [
    _CardStat(icon: PhosphorIconsRegular.calendar, label: '${project.daysToDeadline}д'),
    const SizedBox(width: 12),
    _CardStat(icon: PhosphorIconsRegular.listChecks,
              label: '${project.stagesDone}/${project.stagesTotal}'),
    const SizedBox(width: 12),
    _CardStat(icon: PhosphorIconsRegular.gear,
              label: '${project.stagesInProgress} в работе'),
  ],
),
```

- [ ] **Step 5.1.3: Golden test for new card layout**

- [ ] **Step 5.1.4: Test + analyze**

## Task 5.2: Drag-reorder stages in create_project step 3

**Files:**
- Modify: `mobile/lib/features/projects/presentation/create_project_screen.dart:450-600` (_Step3)

- [ ] **Step 5.2.1: Convert checkbox list to `ReorderableListView.builder`**

```dart
ReorderableListView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  itemCount: _selectedStages.length,
  onReorder: (oldIndex, newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final moved = _selectedStages.removeAt(oldIndex);
      _selectedStages.insert(newIndex, moved);
    });
  },
  itemBuilder: (_, i) => Card(
    key: ValueKey(_selectedStages[i].templateId),
    child: ListTile(
      title: Text(_selectedStages[i].title),
      leading: const Icon(PhosphorIconsRegular.dotsSixVertical),
      trailing: IconButton(
        icon: const Icon(PhosphorIconsRegular.x),
        onPressed: () => setState(() => _selectedStages.removeAt(i)),
      ),
    ),
  ),
),
```

- [ ] **Step 5.2.2: Test — reorder updates list order**

## Task 5.3: Console — remove duplicate «Прогресс» card

**Files:**
- Modify: `mobile/lib/features/projects/presentation/console_screen.dart:750-810` (_StatsRow)

- [ ] **Step 5.3.1: Delete the «Прогресс» stat card**, keep only «Дедлайн» + «Этапы».

- [ ] **Step 5.3.2: Layout golden test update**

## Task 5.4: Console — add stage filter chips

**Files:**
- Modify: `mobile/lib/features/projects/presentation/console_screen.dart` near `_StagesCarousel`

- [ ] **Step 5.4.1: Add `AppFilterPillBar` above the stages carousel**

Reuse the same enum used in `stages_screen.dart:35-50` (`_Filter` with values All / In work / Pending approval / Paused / Without foreman).

- [ ] **Step 5.4.2: Filter the carousel rows by selected chip**

## Task 5.5: Console — illustration collapse toggle

**Files:**
- Modify: `mobile/lib/features/projects/presentation/console_screen.dart:568, 602` (_HouseSection + AppHouseProgress)

- [ ] **Step 5.5.1: Add `_houseCollapsed` state + chevron button**

```dart
IconButton(
  icon: Icon(_houseCollapsed
      ? PhosphorIconsRegular.caretDown
      : PhosphorIconsRegular.caretUp),
  onPressed: () => setState(() => _houseCollapsed = !_houseCollapsed),
),
```

- [ ] **Step 5.5.2: Use `AnimatedSize` + conditional `AppHouseProgress`** rendering

- [ ] **Step 5.5.3: Persist preference (optional)** — save via `flutter_secure_storage` `console_house_collapsed_{projectId}`. Skip if scope-creep.

- [ ] **Step 5.5.4: Test**

---

# Phase 6 — Tools Enrichment (P2)

## Task 6.1: Add `purchaseDate` + `condition` fields

**Files:**
- Modify: `mobile/lib/features/tools/domain/tool.dart`
- Modify: `mobile/lib/features/tools/data/tools_repository.dart` (DTO mapping)
- Modify: `mobile/lib/features/tools/presentation/add_tool_screen.dart` (form fields)
- Modify: `mobile/lib/features/tools/presentation/my_tools_screen.dart` (card display)

**Backend dependency:** Are `purchaseDate` and `condition` already in `/api/tools` payload? If not, this is **backend-blocked**.

- [ ] **Step 6.1.1: Verify backend payload**

```bash
curl -s http://localhost:3000/api/tools/mine -H "Authorization: Bearer ..." | jq
# or read prisma schema: backend/prisma/schema.prisma — search for `model Tool`
grep -A 20 "model Tool" backend/prisma/schema.prisma
```

If fields absent — STOP and flag as `[BACKEND BLOCKER]` in the task; do not ship UI for fields that have nowhere to persist.

- [ ] **Step 6.1.2: Add fields to `Tool` freezed model**

```dart
@freezed
class Tool with _$Tool {
  const factory Tool({
    // existing fields...
    DateTime? purchaseDate,
    ToolCondition? condition,
  }) = _Tool;
}

enum ToolCondition { newTool, good, worn, broken }
```

- [ ] **Step 6.1.3: Run `build_runner`**

```bash
cd mobile && dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 6.1.4: Update `add_tool_screen.dart` — add date picker + condition dropdown**

- [ ] **Step 6.1.5: Update `my_tools_screen.dart` card — show `purchaseDate` + condition badge**

- [ ] **Step 6.1.6: Tests + analyze**

## Task 6.2: Tool custody history UI

**Files:**
- Create: `mobile/lib/features/tools/presentation/tool_custody_history_screen.dart`
- Modify: `mobile/lib/features/tools/presentation/my_tools_screen.dart` (add "История" menu item)
- Endpoint exists: `/api/tools/:id/custody-history` (per audit).

- [ ] **Step 6.2.1: Add `ToolsRepository.getCustodyHistory(toolId)`** if missing

- [ ] **Step 6.2.2: Create screen with timeline of events**

```dart
class ToolCustodyHistoryScreen extends ConsumerWidget {
  // FutureBuilder/AsyncValue → list of CustodyEvent
  // Each item: timestamp, from→to user, reason
}
```

- [ ] **Step 6.2.3: Add route `/tools/:id/history`** in app_router

- [ ] **Step 6.2.4: Tests + analyze**

## Task 6.3: Batch tool upload

**Files:**
- Create: `mobile/lib/features/tools/presentation/batch_tool_add_sheet.dart`
- Modify: `mobile/lib/features/tools/presentation/my_tools_screen.dart` (add "Добавить несколько" overflow menu)

- [ ] **Step 6.3.1: Sheet with dynamic list of tool entries (name + article + status)**

- [ ] **Step 6.3.2: Submit calls `POST /api/tools/batch` if backend supports OR sequential calls**

```bash
grep -rn "tools/batch\|bulk.*tools" backend/src 2>/dev/null
```

- [ ] **Step 6.3.3: Tests + analyze**

## Task 6.4: Default responsible = brigadir for project tools

**Files:**
- Modify: `mobile/lib/features/tools/presentation/project_tools_screen.dart` (add flow)
- Modify: `mobile/lib/features/tools/presentation/add_tool_screen.dart` (when adding to project, pre-select brigadir)

- [ ] **Step 6.4.1: When creating a tool *in project context*, default `assignedEmployeeId` to project's foreman**

```dart
final brigadirId = ref.read(projectControllerProvider(projectId)).value?.foremanId;
final initial = brigadirId; // pre-fill in form
```

- [ ] **Step 6.4.2: Tests + analyze**

---

# Phase 7 — Stage PDF Report + Documents Toggle (P2)

## Task 7.1: Stage PDF report

**Files:**
- Modify: `mobile/lib/features/stages/presentation/stage_detail_screen.dart` (add PDF export action)
- New: `mobile/lib/features/stages/data/stage_pdf_repository.dart` (or extend stages_repository)

**Backend dependency:** Need `GET /api/stages/:id/report.pdf` endpoint. Verify:

```bash
grep -rn "report.*pdf\|stage.*pdf\|/stages.*report" backend/src 2>/dev/null
```

If missing → **BACKEND BLOCKER**. Park UI behind feature flag.

- [ ] **Step 7.1.1: Confirm endpoint exists or flag blocker**

- [ ] **Step 7.1.2: Add "Экспорт отчёта (PDF)" item in stage app bar kebab menu**

- [ ] **Step 7.1.3: Implement download + share via `printing` or platform-channel as feed_screen does**

- [ ] **Step 7.1.4: Tests + analyze**

## Task 7.2: Stage docs tab — `📷 Фото` / `📄 Документы` toggle

**Files:**
- Modify: `mobile/lib/features/stages/presentation/_widgets/stage_docs_tab.dart:13-50`

- [ ] **Step 7.2.1: Add `_view` state (enum Photo/Docs)**

```dart
enum _DocsView { photos, files }
_DocsView _view = _DocsView.photos;
```

- [ ] **Step 7.2.2: Render `AppSegmentedToggle`** at top

```dart
SegmentedButton<_DocsView>(
  segments: const [
    ButtonSegment(value: _DocsView.photos, icon: Icon(PhosphorIconsRegular.image), label: Text('Фото')),
    ButtonSegment(value: _DocsView.files, icon: Icon(PhosphorIconsRegular.file), label: Text('Документы')),
  ],
  selected: {_view},
  onSelectionChanged: (s) => setState(() => _view = s.first),
),
```

- [ ] **Step 7.2.3: Show only the selected section** (currently both render)

- [ ] **Step 7.2.4: Group docs section by step**

```dart
final byStep = groupBy(docs, (d) => d.stepId);
// Render: для каждого stepId → заголовок "Шаг N: <title>" + список файлов
```

- [ ] **Step 7.2.5: Tests + analyze**

---

# Phase 8 — Notifications + Defensive RBAC (P2)

## Task 8.1: Shared bell-with-badge widget

**Files:**
- Create: `mobile/lib/shared/widgets/app_notifications_bell.dart`
- Modify: app shells — `console_screen.dart`, `chats_screen.dart`, others

- [ ] **Step 8.1.1: Create reusable widget**

```dart
class AppNotificationsBell extends ConsumerWidget {
  const AppNotificationsBell({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(unreadNotificationsCountProvider);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(PhosphorIconsRegular.bell),
          onPressed: () => context.push('/notifications'),
        ),
        if (count > 0)
          Positioned(
            top: 6,
            right: 6,
            child: AppBadge(count: count),
          ),
      ],
    );
  }
}
```

- [ ] **Step 8.1.2: Add to all top-level screens via shell wrapper** (avoid copy-paste)

- [ ] **Step 8.1.3: Tests + analyze**

## Task 8.2: Push indicator on new requests in materials list

**Files:**
- Modify: `mobile/lib/features/materials/presentation/materials_list_screen.dart`

- [ ] **Step 8.2.1: Subscribe to `newMaterialRequestsProvider` (counter of unread)**

- [ ] **Step 8.2.2: Show small bell pill at top of screen if count > 0**

- [ ] **Step 8.2.3: Tap pill → marks all as seen**

## Task 8.3: Customer client-side defensive filter for team

**Files:**
- Modify: `mobile/lib/features/chat/presentation/team_aggregate_screen.dart`

- [ ] **Step 8.3.1: Add role-based filter after fetch**

```dart
final role = ref.watch(currentRoleProvider);
final visible = members.where((m) {
  if (role == SystemRole.customer) {
    return m.role != SystemRole.master; // hide masters
  }
  return true;
}).toList();
```

- [ ] **Step 8.3.2: Test — customer sees no masters even if server returns them**

---

# Phase 9 — Backlog (NOT in this plan)

Tracked for visibility, **not implemented here**:

- [ ] Re-enable hidden questions/substeps in `step_detail_screen.dart` (needs product confirmation)
- [ ] Photo metadata per photo in step (who/when/links-to)
- [ ] Standalone step-level documents screen
- [ ] Bulk operations on checklist (Task 3.4 — pending product spec)
- [ ] AI-chat in Help section (deferred per TZ §15)
- [ ] Monthly AI analytics for brigadir (deferred per TZ §4)

---

# Verification — end of every phase

```bash
cd mobile
flutter analyze
# Expect: 0 issues

flutter test
# Expect: all green (baseline = 176 tests)

# Optionally:
flutter build apk --flavor dev --debug
# Expect: success
```

If `analyze` or tests regress — fix before moving to the next phase.

---

# Backend dependencies summary (verified 2026-06-08)

Status confirmed by direct inspection of `backend/prisma/schema.prisma` + `backend/apps/api/src/modules/`. Production server is up (uptime 45h, healthz=ok).

| Phase / Task | Endpoint / Field | Status |
|---|---|---|
| 1.2 | `POST /api/projects/:projectId/chats/personal {withUserId}` | ✅ **EXISTS** — but requires `projectId` context (no global direct chat). UI must pick a shared project. |
| 2.3 | Stage-scoped chats | 🟡 **PARTIAL** — `ChatsService.ensureStageChat()` exists but no controller route. Need to add `POST /api/stages/:stageId/chat`. Minor backend addition. |
| 3.1 | `PATCH /api/stages/:stageId/steps/reorder {items:[{id,orderIndex}]}` | ✅ **EXISTS** at `steps.controller.ts:95` |
| 4.1 | Reclamation submission | 🔴 **BLOCKED** — no `Complaint` model. `ApprovalScope` has `step` + status=`rejected` but no photo-attachment fields. Decide: extend approval payload with photos, or create new `Complaint` model. |
| 6.1 | `ToolItem.purchaseDate`, `ToolItem.condition` fields | 🔴 **BLOCKED** — `ToolItem` model lacks both fields (schema.prisma:1049). Needs migration + DTO update. |
| 6.3 | Batch tools endpoint | 🟢 **N/A** — sequential calls work; dedicated batch is perf-optimization, defer. |
| 7.1 | Stage PDF report | 🔴 **BLOCKED** — `ExportKind` enum (schema.prisma:338) has `feed_pdf`, `project_zip`, `project_report_pdf` only. Add `stage_report_pdf` + generator in `exports` module. |

**Frontend-only tasks (no backend touch)**: 1.1, 1.3, 1.4, 1.5, 2.1, 2.2, 2.4, 3.2, 3.3, 5.1, 5.2, 5.3, 5.4, 5.5, 6.2, 6.4, 7.2, 8.1, 8.2, 8.3 — **20 of 28 tasks ship without backend changes**.

**Backend track required for**: 2.3 (small — add route), 4.1 (medium — model+endpoint), 6.1 (small — migration), 7.1 (medium — exporter).

---

# Execution choice

**Plan complete and saved to `docs/plans/2026-06-08-newfix-gaps-implementation.md`. Two execution options:**

**1. Subagent-Driven (recommended)** — Fresh subagent per task, review between tasks. Best for this plan because phases are large and isolated.

**2. Inline Execution** — Run tasks in this session with batch checkpoints. Faster for short phases (1, 5), but risks context pressure on long phases.

My recommendation: **Subagent-Driven for Phases 1–5 (P1)**, then re-evaluate Phase 6–8 priority after critical work lands.
