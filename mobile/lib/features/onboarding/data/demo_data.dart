import '../../../shared/widgets/status_pill.dart' show Semaphore;
import '../../approvals/domain/approval.dart';
import '../../chat/domain/chat.dart';
import '../../chat/domain/message.dart';
import '../../finance/domain/budget.dart';
import '../../finance/domain/payment.dart';
import '../../materials/domain/material_request.dart';
import '../../notifications/domain/app_notification.dart';
import '../../projects/domain/project.dart';
import '../../stages/domain/stage.dart';
import '../../steps/domain/question.dart';
import '../../steps/domain/step.dart';
import '../../steps/domain/step_photo.dart';
import '../../steps/domain/substep.dart';

/// Канонический «готовый» проект, на котором проводится демо-тур.
/// Все экраны во время `/tour` route видят именно эти данные —
/// репозитории override-нуты на `Demo*Repository`, отдающие подмножества
/// этого набора. После завершения тура моки выходят из скоупа.
class DemoData {
  DemoData._();

  // ─────────── IDs (стабильные, чтобы ссылки между сущностями работали) ───────────

  static const String projectId = 'demo-project';

  static const String userCustomerId = 'demo-user-customer';
  static const String userRepresentativeId = 'demo-user-representative';
  static const String userForemanId = 'demo-user-foreman';
  static const String userMasterId = 'demo-user-master';

  static const String stageDemoId = 'demo-stage-demolition';
  static const String stageElectricsId = 'demo-stage-electrics';
  static const String stagePlumbingId = 'demo-stage-plumbing';
  static const String stageWallsId = 'demo-stage-walls';
  static const String stageFloorId = 'demo-stage-floor';
  static const String stageFinishingId = 'demo-stage-finishing';

  static const String stepDemoLoadId = 'demo-step-demo-load';
  static const String stepDemoWallsId = 'demo-step-demo-walls';
  static const String stepDemoFloorId = 'demo-step-demo-floor';
  static const String stepElectricsCablingId = 'demo-step-electrics-cabling';
  static const String stepElectricsSocketsId = 'demo-step-electrics-sockets';

  static const String approvalPlanId = 'demo-approval-plan';
  static const String approvalStageAcceptId = 'demo-approval-stage-accept';
  static const String approvalExtraWorkId = 'demo-approval-extra-work';

  static const String paymentAdvanceId = 'demo-payment-advance';
  static const String paymentDistributionId = 'demo-payment-distribution';

  static const String materialRequestId = 'demo-material-request';

  static const String chatProjectId = 'demo-chat-project';
  static const String chatPersonalId = 'demo-chat-personal';

  // ─────────── Время ───────────
  // Привязываемся к фиксированному «сейчас» внутри тура, чтобы прогресс
  // выглядел осмысленно (этап в середине, есть просрочки, есть законченные).
  static final DateTime _now = DateTime(2026, 4, 30, 14, 0);
  static final DateTime _projectStart = _now.subtract(const Duration(days: 21));
  static final DateTime _projectEnd = _now.add(const Duration(days: 49));
  static DateTime get demoNow => _now;

  // ─────────── Project ───────────

  static final Project project = Project(
    id: projectId,
    ownerId: userCustomerId,
    title: 'Ремонт квартиры на Ленинской',
    address: 'г. Москва, ул. Ленинская, 14, кв. 67',
    description: '3-комнатная квартира 78 м². Полный ремонт «под ключ».',
    plannedStart: _projectStart,
    plannedEnd: _projectEnd,
    status: ProjectStatus.active,
    workBudget: 850000_00,
    materialsBudget: 650000_00,
    progressCache: 38,
    semaphore: Semaphore.yellow,
    planApproved: true,
    requiresPlanApproval: true,
    archivedAt: null,
    createdAt: _projectStart.subtract(const Duration(days: 3)),
    updatedAt: _now.subtract(const Duration(hours: 2)),
  );

  // ─────────── Stages (6 шт.: 2 done, 1 active, 1 paused, 2 pending) ───────────

  static final List<Stage> stages = [
    Stage(
      id: stageDemoId,
      projectId: projectId,
      title: 'Демонтаж',
      orderIndex: 0,
      status: StageStatus.done,
      plannedStart: _projectStart,
      plannedEnd: _projectStart.add(const Duration(days: 7)),
      originalEnd: _projectStart.add(const Duration(days: 7)),
      pauseDurationMs: 0,
      workBudget: 90000_00,
      materialsBudget: 15000_00,
      foremanIds: const [userForemanId],
      progressCache: 100,
      planApproved: true,
      startedAt: _projectStart,
      sentToReviewAt: _projectStart.add(const Duration(days: 6)),
      doneAt: _projectStart.add(const Duration(days: 7)),
      createdAt: _projectStart.subtract(const Duration(days: 2)),
      updatedAt: _projectStart.add(const Duration(days: 7)),
    ),
    Stage(
      id: stageElectricsId,
      projectId: projectId,
      title: 'Электрика',
      orderIndex: 1,
      status: StageStatus.active,
      plannedStart: _projectStart.add(const Duration(days: 7)),
      plannedEnd: _projectStart.add(const Duration(days: 21)),
      originalEnd: _projectStart.add(const Duration(days: 21)),
      pauseDurationMs: 0,
      workBudget: 180000_00,
      materialsBudget: 95000_00,
      foremanIds: const [userForemanId],
      progressCache: 65,
      planApproved: true,
      startedAt: _projectStart.add(const Duration(days: 8)),
      sentToReviewAt: null,
      doneAt: null,
      createdAt: _projectStart.subtract(const Duration(days: 2)),
      updatedAt: _now.subtract(const Duration(hours: 3)),
    ),
    Stage(
      id: stagePlumbingId,
      projectId: projectId,
      title: 'Сантехника',
      orderIndex: 2,
      status: StageStatus.paused,
      plannedStart: _projectStart.add(const Duration(days: 14)),
      plannedEnd: _projectStart.add(const Duration(days: 28)),
      originalEnd: _projectStart.add(const Duration(days: 28)),
      pauseDurationMs: const Duration(days: 2).inMilliseconds,
      workBudget: 130000_00,
      materialsBudget: 110000_00,
      foremanIds: const [userForemanId],
      progressCache: 30,
      planApproved: true,
      startedAt: _projectStart.add(const Duration(days: 15)),
      sentToReviewAt: null,
      doneAt: null,
      createdAt: _projectStart.subtract(const Duration(days: 2)),
      updatedAt: _now.subtract(const Duration(days: 2)),
    ),
    Stage(
      id: stageWallsId,
      projectId: projectId,
      title: 'Стены и потолок',
      orderIndex: 3,
      status: StageStatus.pending,
      plannedStart: _projectStart.add(const Duration(days: 21)),
      plannedEnd: _projectStart.add(const Duration(days: 35)),
      originalEnd: _projectStart.add(const Duration(days: 35)),
      pauseDurationMs: 0,
      workBudget: 220000_00,
      materialsBudget: 180000_00,
      foremanIds: const [userForemanId],
      progressCache: 0,
      planApproved: true,
      startedAt: null,
      sentToReviewAt: null,
      doneAt: null,
      createdAt: _projectStart.subtract(const Duration(days: 2)),
      updatedAt: _projectStart.subtract(const Duration(days: 2)),
    ),
    Stage(
      id: stageFloorId,
      projectId: projectId,
      title: 'Полы',
      orderIndex: 4,
      status: StageStatus.pending,
      plannedStart: _projectStart.add(const Duration(days: 35)),
      plannedEnd: _projectStart.add(const Duration(days: 49)),
      originalEnd: _projectStart.add(const Duration(days: 49)),
      pauseDurationMs: 0,
      workBudget: 140000_00,
      materialsBudget: 160000_00,
      foremanIds: const [userForemanId],
      progressCache: 0,
      planApproved: true,
      startedAt: null,
      sentToReviewAt: null,
      doneAt: null,
      createdAt: _projectStart.subtract(const Duration(days: 2)),
      updatedAt: _projectStart.subtract(const Duration(days: 2)),
    ),
    Stage(
      id: stageFinishingId,
      projectId: projectId,
      title: 'Финишная отделка',
      orderIndex: 5,
      status: StageStatus.pending,
      plannedStart: _projectStart.add(const Duration(days: 49)),
      plannedEnd: _projectStart.add(const Duration(days: 70)),
      originalEnd: _projectStart.add(const Duration(days: 70)),
      pauseDurationMs: 0,
      workBudget: 90000_00,
      materialsBudget: 90000_00,
      foremanIds: const [userForemanId],
      progressCache: 0,
      planApproved: true,
      startedAt: null,
      sentToReviewAt: null,
      doneAt: null,
      createdAt: _projectStart.subtract(const Duration(days: 2)),
      updatedAt: _projectStart.subtract(const Duration(days: 2)),
    ),
  ];

  static Stage stageById(String id) => stages.firstWhere((s) => s.id == id);

  // ─────────── Steps ───────────

  static final List<Step> steps = [
    // Демонтаж — 3 шага, все done
    Step(
      id: stepDemoLoadId,
      stageId: stageDemoId,
      title: 'Вынос мебели и старых покрытий',
      orderIndex: 0,
      type: StepType.regular,
      status: StepStatus.done,
      price: 25000_00,
      description: 'Включая утилизацию строительного мусора.',
      authorId: userForemanId,
      assigneeIds: const [userMasterId],
      doneAt: _projectStart.add(const Duration(days: 3)),
      doneById: userMasterId,
      createdAt: _projectStart,
      updatedAt: _projectStart.add(const Duration(days: 3)),
      substepsCount: 3,
      substepsDone: 3,
      photosCount: 4,
    ),
    Step(
      id: stepDemoWallsId,
      stageId: stageDemoId,
      title: 'Демонтаж перегородок',
      orderIndex: 1,
      type: StepType.regular,
      status: StepStatus.done,
      price: 38000_00,
      description: 'Снос ненесущей перегородки между кухней и гостиной.',
      authorId: userForemanId,
      assigneeIds: const [userMasterId],
      doneAt: _projectStart.add(const Duration(days: 5)),
      doneById: userMasterId,
      createdAt: _projectStart,
      updatedAt: _projectStart.add(const Duration(days: 5)),
      substepsCount: 2,
      substepsDone: 2,
      photosCount: 6,
    ),
    Step(
      id: stepDemoFloorId,
      stageId: stageDemoId,
      title: 'Снятие старой стяжки',
      orderIndex: 2,
      type: StepType.regular,
      status: StepStatus.done,
      price: 27000_00,
      description: null,
      authorId: userForemanId,
      assigneeIds: const [userMasterId],
      doneAt: _projectStart.add(const Duration(days: 7)),
      doneById: userMasterId,
      createdAt: _projectStart,
      updatedAt: _projectStart.add(const Duration(days: 7)),
      substepsCount: 1,
      substepsDone: 1,
      photosCount: 3,
    ),
    // Электрика — 2 шага: 1 done, 1 pendingApproval (ключевой шаг для тура)
    Step(
      id: stepElectricsCablingId,
      stageId: stageElectricsId,
      title: 'Прокладка кабелей',
      orderIndex: 0,
      type: StepType.regular,
      status: StepStatus.done,
      price: 95000_00,
      description: 'ВВГ-нг 3×2.5 / 3×1.5, штробление по проекту.',
      authorId: userForemanId,
      assigneeIds: const [userMasterId],
      doneAt: _now.subtract(const Duration(days: 4)),
      doneById: userMasterId,
      createdAt: _projectStart.add(const Duration(days: 8)),
      updatedAt: _now.subtract(const Duration(days: 4)),
      substepsCount: 4,
      substepsDone: 4,
      photosCount: 8,
    ),
    Step(
      id: stepElectricsSocketsId,
      stageId: stageElectricsId,
      title: 'Установка подрозетников',
      orderIndex: 1,
      type: StepType.regular,
      status: StepStatus.pendingApproval,
      price: 48000_00,
      description: 'Подрозетники под стандарт 71 мм, по схеме заказчика.',
      authorId: userForemanId,
      assigneeIds: const [userMasterId],
      doneAt: _now.subtract(const Duration(hours: 3)),
      doneById: userMasterId,
      createdAt: _projectStart.add(const Duration(days: 10)),
      updatedAt: _now.subtract(const Duration(hours: 3)),
      substepsCount: 3,
      substepsDone: 3,
      photosCount: 5,
    ),
  ];

  static List<Step> stepsForStage(String stageId) =>
      steps.where((s) => s.stageId == stageId).toList();

  static Step stepById(String id) => steps.firstWhere((s) => s.id == id);

  // ─────────── Substeps (только для центрального шага тура) ───────────

  static final List<Substep> substepsForStep = [
    Substep(
      id: 'demo-substep-1',
      stepId: stepElectricsSocketsId,
      text: 'Разметить положение всех подрозетников по плану',
      authorId: userForemanId,
      isDone: true,
      doneAt: _now.subtract(const Duration(hours: 8)),
      doneById: userMasterId,
      createdAt: _now.subtract(const Duration(days: 1)),
      updatedAt: _now.subtract(const Duration(hours: 8)),
    ),
    Substep(
      id: 'demo-substep-2',
      stepId: stepElectricsSocketsId,
      text: 'Высверлить отверстия коронкой 71 мм',
      authorId: userForemanId,
      isDone: true,
      doneAt: _now.subtract(const Duration(hours: 5)),
      doneById: userMasterId,
      createdAt: _now.subtract(const Duration(days: 1)),
      updatedAt: _now.subtract(const Duration(hours: 5)),
    ),
    Substep(
      id: 'demo-substep-3',
      stepId: stepElectricsSocketsId,
      text: 'Закрепить подрозетники алебастром, проверить уровень',
      authorId: userForemanId,
      isDone: true,
      doneAt: _now.subtract(const Duration(hours: 3)),
      doneById: userMasterId,
      createdAt: _now.subtract(const Duration(days: 1)),
      updatedAt: _now.subtract(const Duration(hours: 3)),
    ),
  ];

  // ─────────── Photos ───────────

  static final List<StepPhoto> photosForStep = [
    StepPhoto(
      id: 'demo-photo-1',
      stepId: stepElectricsSocketsId,
      fileKey: 'demo/photos/sockets-1.jpg',
      thumbKey: 'demo/photos/sockets-1.thumb.jpg',
      mimeType: 'image/jpeg',
      sizeBytes: 245000,
      uploadedBy: userMasterId,
      exifCleared: true,
      createdAt: _now.subtract(const Duration(hours: 4)),
    ),
    StepPhoto(
      id: 'demo-photo-2',
      stepId: stepElectricsSocketsId,
      fileKey: 'demo/photos/sockets-2.jpg',
      thumbKey: 'demo/photos/sockets-2.thumb.jpg',
      mimeType: 'image/jpeg',
      sizeBytes: 268000,
      uploadedBy: userMasterId,
      exifCleared: true,
      createdAt: _now.subtract(const Duration(hours: 4)),
    ),
  ];

  // ─────────── Questions ───────────

  static final List<Question> questionsForStep = [
    Question(
      id: 'demo-question-1',
      stepId: stepElectricsSocketsId,
      authorId: userMasterId,
      addresseeId: userForemanId,
      text: 'В прихожей нужны 2 розетки рядом с зеркалом или одна?',
      status: QuestionStatus.answered,
      answer: 'Две — для подсветки и для робота-пылесоса.',
      answeredAt: _now.subtract(const Duration(hours: 6)),
      answeredBy: userForemanId,
      createdAt: _now.subtract(const Duration(hours: 9)),
      updatedAt: _now.subtract(const Duration(hours: 6)),
    ),
  ];

  // ─────────── Approvals (3 шт.) ───────────

  static final List<Approval> approvals = [
    Approval(
      id: approvalPlanId,
      scope: ApprovalScope.plan,
      projectId: projectId,
      stageId: null,
      stepId: null,
      payload: const {'note': 'Согласование плана работ на 6 этапов.'},
      requestedById: userForemanId,
      addresseeId: userCustomerId,
      status: ApprovalStatus.approved,
      attemptNumber: 1,
      requiresReassign: false,
      decidedAt: _projectStart.subtract(const Duration(days: 1)),
      decidedById: userCustomerId,
      decisionComment: 'План согласован. Можно начинать.',
      createdAt: _projectStart.subtract(const Duration(days: 2)),
      updatedAt: _projectStart.subtract(const Duration(days: 1)),
    ),
    Approval(
      id: approvalStageAcceptId,
      scope: ApprovalScope.stageAccept,
      projectId: projectId,
      stageId: stageDemoId,
      stepId: null,
      payload: const {'stageTitle': 'Демонтаж'},
      requestedById: userForemanId,
      addresseeId: userCustomerId,
      status: ApprovalStatus.approved,
      attemptNumber: 1,
      requiresReassign: false,
      decidedAt: _projectStart.add(const Duration(days: 7, hours: 4)),
      decidedById: userCustomerId,
      decisionComment: 'Принимаю. Отлично.',
      createdAt: _projectStart.add(const Duration(days: 7)),
      updatedAt: _projectStart.add(const Duration(days: 7, hours: 4)),
    ),
    Approval(
      id: approvalExtraWorkId,
      scope: ApprovalScope.extraWork,
      projectId: projectId,
      stageId: stageElectricsId,
      stepId: null,
      payload: const {
        'title': 'Дополнительная розеточная группа на кухне',
        'price': 22000_00,
        'reason': 'Заказчик решил поставить варочную панель на 7 кВт.',
      },
      requestedById: userForemanId,
      addresseeId: userCustomerId,
      status: ApprovalStatus.pending,
      attemptNumber: 1,
      requiresReassign: false,
      decidedAt: null,
      decidedById: null,
      decisionComment: null,
      createdAt: _now.subtract(const Duration(hours: 5)),
      updatedAt: _now.subtract(const Duration(hours: 5)),
    ),
  ];

  static Approval approvalById(String id) =>
      approvals.firstWhere((a) => a.id == id);

  // ─────────── Payments ───────────

  static final List<Payment> payments = [
    Payment(
      id: paymentAdvanceId,
      projectId: projectId,
      stageId: stageElectricsId,
      parentPaymentId: null,
      kind: PaymentKind.advance,
      fromUserId: userCustomerId,
      toUserId: userForemanId,
      amount: 200000_00,
      resolvedAmount: null,
      comment: 'Аванс на материалы по электрике',
      photoKey: null,
      status: PaymentStatus.confirmed,
      confirmedAt: _now.subtract(const Duration(days: 6)),
      disputedAt: null,
      resolvedAt: null,
      cancelledAt: null,
      createdAt: _now.subtract(const Duration(days: 7)),
      updatedAt: _now.subtract(const Duration(days: 6)),
      children: const [],
      disputes: const [],
    ),
    Payment(
      id: paymentDistributionId,
      projectId: projectId,
      stageId: stageElectricsId,
      parentPaymentId: paymentAdvanceId,
      kind: PaymentKind.distribution,
      fromUserId: userForemanId,
      toUserId: userMasterId,
      amount: 95000_00,
      resolvedAmount: null,
      comment: 'Прокладка кабелей',
      photoKey: null,
      status: PaymentStatus.confirmed,
      confirmedAt: _now.subtract(const Duration(days: 4)),
      disputedAt: null,
      resolvedAt: null,
      cancelledAt: null,
      createdAt: _now.subtract(const Duration(days: 5)),
      updatedAt: _now.subtract(const Duration(days: 4)),
      children: const [],
      disputes: const [],
    ),
    Payment(
      id: 'demo-payment-3',
      projectId: projectId,
      stageId: stagePlumbingId,
      parentPaymentId: null,
      kind: PaymentKind.advance,
      fromUserId: userCustomerId,
      toUserId: userForemanId,
      amount: 80000_00,
      resolvedAmount: null,
      comment: 'Аванс на сантехнику',
      photoKey: null,
      status: PaymentStatus.pending,
      confirmedAt: null,
      disputedAt: null,
      resolvedAt: null,
      cancelledAt: null,
      createdAt: _now.subtract(const Duration(days: 1)),
      updatedAt: _now.subtract(const Duration(days: 1)),
      children: const [],
      disputes: const [],
    ),
  ];

  static Payment paymentById(String id) =>
      payments.firstWhere((p) => p.id == id);

  // ─────────── Budget ───────────

  static ProjectBudget get projectBudget {
    const totalWork = 850000_00;
    const totalMaterials = 650000_00;
    const spentWork = 285000_00;
    const spentMaterials = 195000_00;
    return const ProjectBudget(
      work: BudgetBucket(
        planned: totalWork,
        spent: spentWork,
        remaining: totalWork - spentWork,
      ),
      materials: BudgetBucket(
        planned: totalMaterials,
        spent: spentMaterials,
        remaining: totalMaterials - spentMaterials,
      ),
      total: BudgetBucket(
        planned: totalWork + totalMaterials,
        spent: spentWork + spentMaterials,
        remaining: (totalWork + totalMaterials) - (spentWork + spentMaterials),
      ),
      stages: [
        StageBudget(
          stageId: stageDemoId,
          title: 'Демонтаж',
          work: BudgetBucket(planned: 90000_00, spent: 90000_00, remaining: 0),
          materials:
              BudgetBucket(planned: 15000_00, spent: 14200_00, remaining: 800_00),
          total: BudgetBucket(
              planned: 105000_00, spent: 104200_00, remaining: 800_00),
        ),
        StageBudget(
          stageId: stageElectricsId,
          title: 'Электрика',
          work:
              BudgetBucket(planned: 180000_00, spent: 143000_00, remaining: 37000_00),
          materials:
              BudgetBucket(planned: 95000_00, spent: 78500_00, remaining: 16500_00),
          total: BudgetBucket(
              planned: 275000_00, spent: 221500_00, remaining: 53500_00),
        ),
        StageBudget(
          stageId: stagePlumbingId,
          title: 'Сантехника',
          work: BudgetBucket(
              planned: 130000_00, spent: 52000_00, remaining: 78000_00),
          materials: BudgetBucket(
              planned: 110000_00, spent: 0, remaining: 110000_00),
          total: BudgetBucket(
              planned: 240000_00, spent: 52000_00, remaining: 188000_00),
        ),
      ],
    );
  }

  // ─────────── Materials ───────────

  static final List<MaterialRequest> materialRequests = [
    MaterialRequest(
      id: materialRequestId,
      projectId: projectId,
      stageId: stageElectricsId,
      createdById: userForemanId,
      recipient: MaterialRecipient.foreman,
      title: 'Кабель и подрозетники',
      comment: 'Купить с запасом 10%, ВВГ-нг от Кабельного Альянса.',
      status: MaterialRequestStatus.delivered,
      finalizedAt: _now.subtract(const Duration(days: 5)),
      deliveredAt: _now.subtract(const Duration(days: 4)),
      deliveredById: userMasterId,
      createdAt: _now.subtract(const Duration(days: 8)),
      updatedAt: _now.subtract(const Duration(days: 4)),
      items: [
        MaterialItem(
          id: 'demo-mat-item-1',
          requestId: materialRequestId,
          name: 'Кабель ВВГ-нг 3×2.5',
          qty: 80,
          unit: 'м',
          note: null,
          pricePerUnit: 195_00,
          totalPrice: 15600_00,
          isBought: true,
          boughtAt: _now.subtract(const Duration(days: 6)),
          createdAt: _now.subtract(const Duration(days: 8)),
          updatedAt: _now.subtract(const Duration(days: 6)),
        ),
        MaterialItem(
          id: 'demo-mat-item-2',
          requestId: materialRequestId,
          name: 'Подрозетник Schneider 71 мм',
          qty: 38,
          unit: 'шт',
          note: 'С распорными лапками',
          pricePerUnit: 95_00,
          totalPrice: 3610_00,
          isBought: true,
          boughtAt: _now.subtract(const Duration(days: 6)),
          createdAt: _now.subtract(const Duration(days: 8)),
          updatedAt: _now.subtract(const Duration(days: 6)),
        ),
      ],
      disputes: const [],
    ),
    MaterialRequest(
      id: 'demo-material-request-2',
      projectId: projectId,
      stageId: stagePlumbingId,
      createdById: userForemanId,
      recipient: MaterialRecipient.customer,
      title: 'Сантехника: трубы и фитинги',
      comment: null,
      status: MaterialRequestStatus.open,
      finalizedAt: null,
      deliveredAt: null,
      deliveredById: null,
      createdAt: _now.subtract(const Duration(days: 2)),
      updatedAt: _now.subtract(const Duration(days: 2)),
      items: [
        MaterialItem(
          id: 'demo-mat-item-3',
          requestId: 'demo-material-request-2',
          name: 'Полипропиленовая труба PN20 D25',
          qty: 60,
          unit: 'м',
          note: null,
          pricePerUnit: 125_00,
          totalPrice: null,
          isBought: false,
          boughtAt: null,
          createdAt: _now.subtract(const Duration(days: 2)),
          updatedAt: _now.subtract(const Duration(days: 2)),
        ),
      ],
      disputes: const [],
    ),
  ];

  static MaterialRequest materialById(String id) =>
      materialRequests.firstWhere((m) => m.id == id);

  // ─────────── Chats & Messages ───────────

  static final List<Chat> chats = [
    Chat(
      id: chatProjectId,
      type: ChatType.project,
      projectId: projectId,
      stageId: null,
      title: 'Общий чат проекта',
      visibleToCustomer: true,
      createdById: userForemanId,
      createdAt: _projectStart.subtract(const Duration(days: 1)),
      participants: [
        ChatParticipant(
          userId: userCustomerId,
          joinedAt: _projectStart.subtract(const Duration(days: 1)),
        ),
        ChatParticipant(
          userId: userForemanId,
          joinedAt: _projectStart.subtract(const Duration(days: 1)),
        ),
        ChatParticipant(
          userId: userMasterId,
          joinedAt: _projectStart,
        ),
      ],
      unreadCount: 2,
      lastMessagePreview: 'Завтра привезут материалы. Принимать будете?',
      lastMessageAt: _now.subtract(const Duration(hours: 1)),
    ),
    Chat(
      id: chatPersonalId,
      type: ChatType.personal,
      projectId: projectId,
      stageId: null,
      title: null,
      visibleToCustomer: false,
      createdById: userForemanId,
      createdAt: _projectStart.add(const Duration(days: 5)),
      participants: [
        ChatParticipant(
          userId: userForemanId,
          joinedAt: _projectStart.add(const Duration(days: 5)),
        ),
        ChatParticipant(
          userId: userMasterId,
          joinedAt: _projectStart.add(const Duration(days: 5)),
        ),
      ],
      unreadCount: 0,
      lastMessagePreview: 'Принял, выезжаю.',
      lastMessageAt: _now.subtract(const Duration(hours: 7)),
    ),
  ];

  static Chat chatById(String id) => chats.firstWhere((c) => c.id == id);

  static final List<Message> messagesForProjectChat = [
    Message(
      id: 'demo-msg-1',
      chatId: chatProjectId,
      authorId: userCustomerId,
      text: 'Добрый день! Как продвигается электрика?',
      attachmentKeys: const [],
      forwardedFromId: null,
      editedAt: null,
      deletedAt: null,
      createdAt: _now.subtract(const Duration(hours: 5)),
    ),
    Message(
      id: 'demo-msg-2',
      chatId: chatProjectId,
      authorId: userForemanId,
      text: 'Кабели проложили, сейчас ставим подрозетники. Завтра пришлю фото.',
      attachmentKeys: const [],
      forwardedFromId: null,
      editedAt: null,
      deletedAt: null,
      createdAt: _now.subtract(const Duration(hours: 4)),
    ),
    Message(
      id: 'demo-msg-3',
      chatId: chatProjectId,
      authorId: userCustomerId,
      text: 'Отлично! Спасибо.',
      attachmentKeys: const [],
      forwardedFromId: null,
      editedAt: null,
      deletedAt: null,
      createdAt: _now.subtract(const Duration(hours: 3, minutes: 50)),
    ),
    Message(
      id: 'demo-msg-4',
      chatId: chatProjectId,
      authorId: userForemanId,
      text: 'Завтра привезут материалы. Принимать будете?',
      attachmentKeys: const [],
      forwardedFromId: null,
      editedAt: null,
      deletedAt: null,
      createdAt: _now.subtract(const Duration(hours: 1)),
    ),
  ];

  static List<Message> messagesForChat(String chatId) {
    if (chatId == chatProjectId) return messagesForProjectChat;
    return const [];
  }

  // ─────────── Notifications ───────────

  static final List<AppNotification> notifications = [
    AppNotification(
      id: 'demo-notif-1',
      kind: 'approval_requested',
      title: 'Новое согласование',
      body: 'Бригадир просит одобрить доп. работы — 22 000 ₽',
      data: const {
        'approvalId': approvalExtraWorkId,
        'projectId': projectId,
      },
      receivedAt: _now.subtract(const Duration(hours: 5)),
      read: false,
    ),
    AppNotification(
      id: 'demo-notif-2',
      kind: 'step_completed',
      title: 'Шаг готов',
      body: 'Установка подрозетников отмечена как готовая',
      data: const {
        'stepId': stepElectricsSocketsId,
        'projectId': projectId,
      },
      receivedAt: _now.subtract(const Duration(hours: 3)),
      read: false,
    ),
    AppNotification(
      id: 'demo-notif-3',
      kind: 'payment_confirmed',
      title: 'Платёж подтверждён',
      body: 'Аванс 200 000 ₽ зачислен',
      data: const {
        'paymentId': paymentAdvanceId,
        'projectId': projectId,
      },
      receivedAt: _now.subtract(const Duration(days: 6)),
      read: true,
    ),
    AppNotification(
      id: 'demo-notif-4',
      kind: 'message_new',
      title: 'Новое сообщение',
      body: 'Бригадир: «Завтра привезут материалы. Принимать будете?»',
      data: const {
        'chatId': chatProjectId,
        'projectId': projectId,
      },
      receivedAt: _now.subtract(const Duration(hours: 1)),
      read: false,
    ),
    AppNotification(
      id: 'demo-notif-5',
      kind: 'stage_started',
      title: 'Этап запущен',
      body: 'Электрика — старт работ',
      data: const {
        'stageId': stageElectricsId,
        'projectId': projectId,
      },
      receivedAt: _now.subtract(const Duration(days: 22)),
      read: true,
    ),
  ];
}
