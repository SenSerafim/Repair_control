import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/notes/data/notes_repository.dart';
import '../../features/notes/domain/note.dart';
import '../../features/steps/data/steps_repository.dart';
import 'offline_queue.dart';

/// Регистрирует реальные HTTP-handlers на [OfflineQueue].
///
/// Вызвать один раз в bootstrap после `offlineQueueProvider.load()`.
/// Handlers работают напрямую с repositories (без controllers),
/// потому что при drain'е мы только отправляем запрос на сервер —
/// обновление состояния происходит либо через websocket, либо при
/// следующем invalidate/refresh.
void registerOfflineHandlers(ProviderContainer container) {
  final queue = container.read(offlineQueueProvider);
  final stepsRepo = container.read(stepsRepositoryProvider);
  final notesRepo = container.read(notesRepositoryProvider);

  queue
    ..registerHandler(OfflineActionKind.stepToggle, (a) async {
      final id = a.payload['stepId'] as String;
      final complete = a.payload['complete'] as bool;
      if (complete) {
        await stepsRepo.completeStep(id);
      } else {
        await stepsRepo.uncompleteStep(id);
      }
    })
    ..registerHandler(OfflineActionKind.substepToggle, (a) async {
      final id = a.payload['substepId'] as String;
      final complete = a.payload['complete'] as bool;
      if (complete) {
        await stepsRepo.completeSubstep(id);
      } else {
        await stepsRepo.uncompleteSubstep(id);
      }
    })
    ..registerHandler(OfflineActionKind.noteCreate, (a) async {
      await notesRepo.create(
        projectId: a.payload['projectId'] as String,
        scope: NoteScope.fromString(a.payload['scope'] as String?),
        text: a.payload['text'] as String,
        addresseeId: a.payload['addresseeId'] as String?,
        stageId: a.payload['stageId'] as String?,
      );
    })
    ..registerHandler(OfflineActionKind.questionAnswer, (a) async {
      await stepsRepo.answerQuestion(
        questionId: a.payload['questionId'] as String,
        answer: a.payload['answer'] as String,
      );
    });
}
