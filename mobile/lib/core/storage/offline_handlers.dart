import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/finance/data/payments_repository.dart';
import '../../features/materials/data/materials_repository.dart';
import '../../features/notes/data/notes_repository.dart';
import '../../features/notes/domain/note.dart';
import '../../features/selfpurchase/data/selfpurchase_repository.dart';
import '../../features/stages/data/stages_repository.dart';
import '../../features/stages/domain/pause_reason.dart';
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
  final stagesRepo = container.read(stagesRepositoryProvider);
  final paymentsRepo = container.read(paymentsRepositoryProvider);
  final selfpurchaseRepo =
      container.read(selfPurchaseRepositoryProvider);
  final materialsRepo = container.read(materialsRepositoryProvider);

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
    })
    ..registerHandler(OfflineActionKind.stagePause, (a) async {
      await stagesRepo.pause(
        projectId: a.payload['projectId'] as String,
        stageId: a.payload['stageId'] as String,
        reason: PauseReason.fromApiValue(a.payload['reason'] as String?),
        comment: a.payload['comment'] as String?,
      );
    })
    ..registerHandler(OfflineActionKind.stageResume, (a) async {
      await stagesRepo.resume(
        projectId: a.payload['projectId'] as String,
        stageId: a.payload['stageId'] as String,
      );
    })
    ..registerHandler(OfflineActionKind.paymentDispute, (a) async {
      await paymentsRepo.dispute(
        id: a.payload['paymentId'] as String,
        reason: a.payload['reason'] as String,
      );
    })
    ..registerHandler(OfflineActionKind.selfpurchaseCreate, (a) async {
      await selfpurchaseRepo.create(
        projectId: a.payload['projectId'] as String,
        amount: (a.payload['amount'] as num).toInt(),
        stageId: a.payload['stageId'] as String?,
        comment: a.payload['comment'] as String?,
      );
    })
    ..registerHandler(OfflineActionKind.materialMarkBought, (a) async {
      await materialsRepo.markBought(
        requestId: a.payload['requestId'] as String,
        itemId: a.payload['itemId'] as String,
        pricePerUnit: (a.payload['pricePerUnit'] as num).toInt(),
      );
    });
}
