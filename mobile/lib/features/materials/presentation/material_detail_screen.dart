import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/access/access_guard.dart';
import '../../../core/access/domain_actions.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/utils/money.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/materials_controller.dart';
import '../domain/material_request.dart';
import '_widgets/checklist_item_card.dart';
import '_widgets/material_lifecycle_timeline.dart';
import '_widgets/material_meta_card.dart';
import '_widgets/purchase_progress_chip.dart';
import '_widgets/resolve_option_card.dart';

class MaterialDetailScreen extends ConsumerWidget {
  const MaterialDetailScreen({
    required this.projectId,
    required this.requestId,
    super.key,
  });

  final String projectId;
  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(
      materialsControllerProvider(projectId).select(
        (v) => v.whenData(
          (list) => list.cast<MaterialRequest?>().firstWhere(
                (r) => r?.id == requestId,
                orElse: () => null,
              ),
        ),
      ),
    );

    return AppScaffold(
      showBack: true,
      title: 'Заявка',
      padding: EdgeInsets.zero,
      body: async.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Ошибка',
          onRetry: () =>
              ref.invalidate(materialsControllerProvider(projectId)),
        ),
        data: (request) {
          if (request == null) {
            return const AppEmptyState(
              title: 'Заявка не найдена',
              icon: Icons.error_outline,
            );
          }
          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => ref
                      .invalidate(materialsControllerProvider(projectId)),
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.x16),
                    children: [
                      _Header(request: request),
                      const SizedBox(height: AppSpacing.x16),
                      // Lifecycle (5 шагов: создана → отправлена → куплено →
                      // доставлено → подтверждено).
                      const _SectionLabel(label: 'Жизненный цикл'),
                      const SizedBox(height: AppSpacing.x10),
                      MaterialLifecycleTimeline(
                        steps: _lifecycleSteps(request),
                      ),
                      const SizedBox(height: AppSpacing.x16),
                      const _SectionLabel(label: 'Позиции'),
                      const SizedBox(height: AppSpacing.x10),
                      for (final item in request.items) ...[
                        ChecklistItemCard(
                          item: item,
                          state: _itemState(request, item),
                          onEdit: _canEdit(request, item)
                              ? () => context.push(
                                    '/projects/$projectId/materials/$requestId/items/${item.id}/edit',
                                  )
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.x8),
                      ],
                      const SizedBox(height: AppSpacing.x6),
                      PurchaseProgressChip(
                        bought: request.boughtItemsCount,
                        total: request.items.length,
                      ),
                      if (request.comment?.isNotEmpty ?? false) ...[
                        const SizedBox(height: AppSpacing.x16),
                        _CommentCard(comment: request.comment!),
                      ],
                      const SizedBox(height: AppSpacing.x16),
                      const _SectionLabel(label: 'Детали'),
                      const SizedBox(height: AppSpacing.x10),
                      MaterialMetaCard(rows: _metaRows(request)),
                      const SizedBox(height: AppSpacing.x20),
                    ],
                  ),
                ),
              ),
              _Actions(projectId: projectId, request: request),
            ],
          );
        },
      ),
    );
  }

  ChecklistItemState _itemState(MaterialRequest req, MaterialItem item) {
    if (item.isBought) return ChecklistItemState.bought;
    if (req.status == MaterialRequestStatus.partiallyBought) {
      return ChecklistItemState.pending;
    }
    return ChecklistItemState.pending;
  }

  bool _canEdit(MaterialRequest req, MaterialItem item) {
    if (item.isBought) return true;
    return req.status == MaterialRequestStatus.open ||
        req.status == MaterialRequestStatus.partiallyBought;
  }

  List<LifecycleStep> _lifecycleSteps(MaterialRequest r) {
    final created = LifecycleStep(
      title: 'Заявка создана',
      state: LifecycleStepState.done,
      dateLabel: _fmtDate(r.createdAt),
      immutable: true,
    );
    final sent = LifecycleStep(
      title: 'Отправлена получателю',
      state: r.status == MaterialRequestStatus.draft
          ? LifecycleStepState.pending
          : LifecycleStepState.done,
      dateLabel: r.status == MaterialRequestStatus.draft
          ? '—'
          : _fmtDate(r.updatedAt),
    );
    final bought = LifecycleStep(
      title: r.status == MaterialRequestStatus.partiallyBought
          ? 'Куплено: ${r.boughtItemsCount} из ${r.items.length}'
          : 'Куплено',
      state: switch (r.status) {
        MaterialRequestStatus.bought ||
        MaterialRequestStatus.delivered ||
        MaterialRequestStatus.resolved =>
          LifecycleStepState.done,
        MaterialRequestStatus.partiallyBought => LifecycleStepState.active,
        _ => LifecycleStepState.pending,
      },
      dateLabel: r.finalizedAt == null ? '—' : _fmtDate(r.finalizedAt!),
      immutable: r.status == MaterialRequestStatus.bought ||
          r.status == MaterialRequestStatus.delivered,
    );
    final delivered = LifecycleStep(
      title: 'Доставлено',
      state: r.status == MaterialRequestStatus.delivered
          ? LifecycleStepState.done
          : LifecycleStepState.pending,
      dateLabel: r.deliveredAt == null ? '—' : _fmtDate(r.deliveredAt!),
      immutable: r.status == MaterialRequestStatus.delivered,
    );
    final confirmed = LifecycleStep(
      title: 'Подтверждено получателем',
      state: r.status == MaterialRequestStatus.delivered
          ? LifecycleStepState.done
          : LifecycleStepState.pending,
      dateLabel: r.deliveredAt == null ? '—' : _fmtDate(r.deliveredAt!),
    );
    return [created, sent, bought, delivered, confirmed];
  }

  List<MaterialMetaRow> _metaRows(MaterialRequest r) {
    return [
      MaterialMetaRow(
        'Получатель покупает',
        r.recipient.displayName,
      ),
      MaterialMetaRow(
        'Этап',
        r.stageId == null ? 'Без этапа' : 'Привязан',
      ),
      MaterialMetaRow(
        'Создал',
        _shorten(r.createdById),
      ),
      MaterialMetaRow(
        'Создано',
        _fmtDate(r.createdAt),
      ),
      if (r.finalizedAt != null)
        MaterialMetaRow(
          'Финализировано',
          '${_fmtDate(r.finalizedAt!)} (неизменяемая)',
          valueColor: AppColors.greenDark,
        ),
    ];
  }

  String _fmtDate(DateTime d) => DateFormat('d MMM y · HH:mm', 'ru').format(d);

  String _shorten(String id) =>
      id.length <= 12 ? id : '${id.substring(0, 12)}…';
}

class _Header extends StatelessWidget {
  const _Header({required this.request});

  final MaterialRequest request;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x16),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppRadius.card,
        boxShadow: AppShadows.sh1,
        border: Border.all(color: AppColors.n200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            request.title,
            style: AppTextStyles.h1.copyWith(fontSize: 20),
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.x8),
          Row(
            children: [
              StatusPill(
                label: request.status.displayName,
                semaphore: request.status.semaphore,
              ),
              const SizedBox(width: AppSpacing.x8),
              Expanded(
                child: Text(
                  '${request.items.length} позиций · '
                  '${Money.format(request.totalBoughtPrice)}',
                  style: AppTextStyles.tiny.copyWith(
                    color: AppColors.n400,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppTextStyles.tiny.copyWith(
        color: AppColors.n400,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.comment});

  final String comment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: AppColors.n100,
        borderRadius: AppRadius.card,
      ),
      child: Text(comment, style: AppTextStyles.body),
    );
  }
}

class _Actions extends ConsumerWidget {
  const _Actions({required this.projectId, required this.request});

  final String projectId;
  final MaterialRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buttons = <Widget>[];
    final ctrl = ref.read(materialsControllerProvider(projectId).notifier);
    final canManage =
        ref.watch(canProvider(DomainAction.materialsManage));
    final canFinalize =
        ref.watch(canProvider(DomainAction.materialFinalize));

    switch (request.status) {
      case MaterialRequestStatus.draft:
        if (canManage) {
          buttons.add(AppButton(
            label: 'Отправить заказчику/бригадиру',
            onPressed: () => ctrl.send(request.id),
          ));
        }
      case MaterialRequestStatus.partiallyBought:
      case MaterialRequestStatus.bought:
        if (request.allItemsBought && canFinalize) {
          buttons.add(AppButton(
            label: 'Финализировать (в бюджет)',
            variant: AppButtonVariant.success,
            onPressed: () => ctrl.finalizeRequest(request.id),
          ));
        }
        if (canManage) {
          if (buttons.isNotEmpty) {
            buttons.add(const SizedBox(height: AppSpacing.x8));
          }
          buttons.add(AppButton(
            label: 'Открыть спор',
            variant: AppButtonVariant.destructive,
            onPressed: () => _dispute(context, ref),
          ));
        }
      case MaterialRequestStatus.delivered:
        if (canManage) {
          buttons.add(AppButton(
            label: 'Подтвердить доставку',
            variant: AppButtonVariant.success,
            onPressed: () => ctrl.confirmDelivery(request.id),
          ));
        }
      case MaterialRequestStatus.disputed:
        if (canManage) {
          buttons.add(AppButton(
            label: 'Разрешить спор',
            onPressed: () => _resolve(context, ref),
          ));
        }
      case MaterialRequestStatus.open:
        if (canManage) {
          buttons.add(AppButton(
            label: 'Открыть спор',
            variant: AppButtonVariant.destructive,
            onPressed: () => _dispute(context, ref),
          ));
        }
      case MaterialRequestStatus.resolved:
      case MaterialRequestStatus.cancelled:
        return const SizedBox.shrink();
    }

    if (buttons.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x16,
        AppSpacing.x12,
        AppSpacing.x16,
        AppSpacing.x16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.n0,
        border: Border(top: BorderSide(color: AppColors.n200)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: buttons,
        ),
      ),
    );
  }

  Future<void> _dispute(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    await showAppBottomSheet<void>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppBottomSheetHeader(
            title: 'Открыть спор по заявке',
            subtitle: 'Опишите проблему — заморозим заявку до разрешения.',
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.x12),
            decoration: BoxDecoration(
              color: AppColors.redBg,
              border: Border.all(
                color: AppColors.redDot.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(AppRadius.r12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.report_problem_outlined,
                  size: 16,
                  color: AppColors.redDot,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Заявка будет заморожена, пока спор открыт.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.redDot,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x12),
          TextField(
            controller: controller,
            autofocus: true,
            minLines: 3,
            maxLines: 6,
            maxLength: 2000,
            decoration: InputDecoration(
              hintText: 'Что не так?',
              filled: true,
              fillColor: AppColors.n0,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.r12),
                borderSide:
                    const BorderSide(color: AppColors.n200, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x16),
          Builder(
            builder: (ctx) => AppButton(
              label: 'Открыть спор',
              variant: AppButtonVariant.destructive,
              onPressed: () async {
                final reason = controller.text.trim();
                if (reason.isEmpty) return;
                await ref
                    .read(materialsControllerProvider(projectId).notifier)
                    .dispute(id: request.id, reason: reason);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
            ),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  Future<void> _resolve(BuildContext context, WidgetRef ref) async {
    await showAppBottomSheet<void>(
      context: context,
      child: _ResolveSheet(
        onSubmit: (resolution) async {
          await ref
              .read(materialsControllerProvider(projectId).notifier)
              .resolve(id: request.id, resolution: resolution);
        },
      ),
    );
  }
}

class _ResolveOption {
  const _ResolveOption(this.key, this.icon, this.title, this.subtitle);

  final String key;
  final IconData icon;
  final String title;
  final String subtitle;
}

class _ResolveSheet extends StatefulWidget {
  const _ResolveSheet({required this.onSubmit});

  final Future<void> Function(String resolution) onSubmit;

  @override
  State<_ResolveSheet> createState() => _ResolveSheetState();
}

class _ResolveSheetState extends State<_ResolveSheet> {
  static const _options = [
    _ResolveOption(
      'delivered',
      Icons.local_shipping_outlined,
      'Довезли остаток',
      'Недостающие позиции доставлены',
    ),
    _ResolveOption(
      'refund',
      Icons.payments_outlined,
      'Возврат денег',
      'Скорректировать сумму',
    ),
    _ResolveOption(
      'write_off',
      Icons.event_busy_outlined,
      'Списать',
      'Принять как есть, без компенсации',
    ),
  ];

  _ResolveOption _selected = _options.first;
  final _comment = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final text = _comment.text.trim();
    final resolution =
        text.isEmpty ? _selected.title : '${_selected.title}. $text';
    setState(() => _busy = true);
    try {
      await widget.onSubmit(resolution);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppBottomSheetHeader(
          title: 'Закрыть спор',
          subtitle: 'Как решён спор?',
        ),
        for (final o in _options) ...[
          ResolveOptionCard(
            icon: o.icon,
            title: o.title,
            subtitle: o.subtitle,
            selected: o == _selected,
            onTap: () => setState(() => _selected = o),
          ),
          const SizedBox(height: AppSpacing.x8),
        ],
        const SizedBox(height: AppSpacing.x6),
        TextField(
          controller: _comment,
          minLines: 2,
          maxLines: 5,
          maxLength: 2000,
          decoration: InputDecoration(
            hintText: 'Комментарий (необязательно)',
            filled: true,
            fillColor: AppColors.n50,
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.r12),
              borderSide:
                  const BorderSide(color: AppColors.n200, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(AppSpacing.x12),
          decoration: BoxDecoration(
            color: AppColors.brandLight,
            borderRadius: BorderRadius.circular(AppRadius.r12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: AppColors.brand,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Решение зафиксируется в ленте событий — изменить нельзя.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.brandDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.x16),
        AppButton(
          label: 'Подтвердить и закрыть',
          variant: AppButtonVariant.success,
          icon: Icons.check_rounded,
          onPressed: _busy ? null : _submit,
        ),
      ],
    );
  }
}
