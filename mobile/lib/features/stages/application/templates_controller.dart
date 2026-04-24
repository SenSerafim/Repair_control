import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/stages_repository.dart';
import '../domain/template.dart';

/// Платформенные шаблоны — статичны, но на всякий случай через AsyncNotifier.
final platformTemplatesProvider =
    AsyncNotifierProvider<PlatformTemplatesController, List<StageTemplate>>(
  PlatformTemplatesController.new,
);

class PlatformTemplatesController
    extends AsyncNotifier<List<StageTemplate>> {
  @override
  Future<List<StageTemplate>> build() async {
    return ref.read(stagesRepositoryProvider).listPlatformTemplates();
  }
}

final userTemplatesProvider =
    AsyncNotifierProvider<UserTemplatesController, List<StageTemplate>>(
  UserTemplatesController.new,
);

class UserTemplatesController extends AsyncNotifier<List<StageTemplate>> {
  @override
  Future<List<StageTemplate>> build() async {
    return ref.read(stagesRepositoryProvider).listUserTemplates();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      state = AsyncData(
        await ref.read(stagesRepositoryProvider).listUserTemplates(),
      );
    } on StagesException catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final templateDetailProvider = AsyncNotifierProvider.family<
    TemplateDetailController, StageTemplate, String>(
  TemplateDetailController.new,
);

class TemplateDetailController
    extends FamilyAsyncNotifier<StageTemplate, String> {
  @override
  Future<StageTemplate> build(String templateId) {
    return ref.read(stagesRepositoryProvider).getTemplate(templateId);
  }
}
