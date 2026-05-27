/// 31 DOMAIN_ACTION из backend/libs/rbac/src/rbac.types.ts.
/// Клиентская копия матрицы — скрывает кнопки, которые сервер всё равно
/// запретит. Сервер — финальный гард, это UX-слой.
enum DomainAction {
  projectCreate('project.create'),
  projectEdit('project.edit'),
  projectArchive('project.archive'),
  projectInviteMember('project.invite_member'),
  stageManage('stage.manage'),
  stageStart('stage.start'),
  stagePause('stage.pause'),
  stepManage('step.manage'),
  stepAddSubstep('step.add_substep'),
  stepPhotoUpload('step.photo.upload'),
  approvalList('approval.list'),
  approvalRequest('approval.request'),
  approvalDecide('approval.decide'),
  financeBudgetView('finance.budget.view'),
  financeBudgetEdit('finance.budget.edit'),
  // Создание платежа (заказчик / представитель с canCreatePayments).
  // Заказчик может платить напрямую foreman или master без согласований.
  financePaymentCreateAdvance('finance.payment.create_advance'),
  // Распределение из родительского аванса мастеру (только бригадир-получатель).
  financePaymentDistribute('finance.payment.distribute'),
  materialsManage('materials.manage'),
  materialFinalize('material.finalize'),
  selfPurchaseCreate('selfpurchase.create'),
  selfPurchaseConfirm('selfpurchase.confirm'),
  toolsViewProject('tools.view_project'),
  toolsAddToProject('tools.add_to_project'),
  toolsClaim('tools.claim'),
  chatRead('chat.read'),
  chatWrite('chat.write'),
  chatCreatePersonal('chat.create_personal'),
  chatCreateGroup('chat.create_group'),
  chatToggleCustomerVisibility('chat.toggle_customer_visibility'),
  chatModerate('chat.moderate'),
  documentRead('document.read'),
  documentWrite('document.write'),
  documentDelete('document.delete'),
  feedExport('feed.export'),
  noteManage('note.manage'),
  questionManage('question.manage'),
  methodologyRead('methodology.read'),
  methodologyEdit('methodology.edit');

  const DomainAction(this.value);

  final String value;
}
