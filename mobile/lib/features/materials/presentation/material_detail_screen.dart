import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/utils/money.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/materials_controller.dart';
import '../data/materials_repository.dart';
import '../domain/material_request.dart';
import '_widgets/material_meta_card.dart';

/// Простой и прозрачный поток (UI/UX-упрощение 2026-05):
///   - foreman/master создаёт → «Ждёт согласования». Заказчик решает.
///   - customer/representative.canApprove создаёт → сразу «Согласовано».
///   - Отклонено — остаётся в истории. Все роли видят это сразу.
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
          onRetry: () => ref.invalidate(materialsControllerProvider(projectId)),
        ),
        data: (request) {
          if (request == null) {
            return const AppEmptyState(
              title: 'Заявка не найдена',
              icon: Icons.error_outline,
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(materialsControllerProvider(projectId)),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.x16),
              children: [
                _Header(request: request),
                const SizedBox(height: AppSpacing.x16),
                _StatusBanner(status: request.status),
                const SizedBox(height: AppSpacing.x16),
                const _SectionLabel(label: 'Позиции'),
                const SizedBox(height: AppSpacing.x10),
                for (final item in request.items) ...[
                  _ItemRow(item: item),
                  const SizedBox(height: AppSpacing.x8),
                ],
                if (request.comment?.isNotEmpty ?? false) ...[
                  const SizedBox(height: AppSpacing.x16),
                  _CommentCard(comment: request.comment!),
                ],
                const SizedBox(height: AppSpacing.x16),
                const _SectionLabel(label: 'Детали'),
                const SizedBox(height: AppSpacing.x10),
                MaterialMetaCard(rows: _metaRows(request)),
                const SizedBox(height: AppSpacing.x16),
                _AcceptanceActions(request: request),
                const SizedBox(height: AppSpacing.x20),
              ],
            ),
          );
        },
      ),
    );
  }

  List<MaterialMetaRow> _metaRows(MaterialRequest r) {
    return [
      MaterialMetaRow('Получатель покупает', r.recipient.displayName),
      MaterialMetaRow('Этап', r.stageId == null ? 'Без этапа' : 'Привязан'),
      MaterialMetaRow('Создал', _shorten(r.createdById)),
      MaterialMetaRow('Создано', _fmtDate(r.createdAt)),
      if (r.finalizedAt != null && r.status == MaterialRequestStatus.approved)
        MaterialMetaRow(
          'Согласовано',
          _fmtDate(r.finalizedAt!),
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
        gradient: AppGradients.surfaceCard,
        borderRadius: AppRadius.card,
        boxShadow: AppShadows.sh1,
        border: Border.all(color: AppColors.n200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            request.title,
            style: AppTextStyles.h1.copyWith(fontSize: 20, letterSpacing: -0.5),
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
                  '${Money.format(request.totalEstimatedPrice)}',
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

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});

  final MaterialRequestStatus status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      MaterialRequestStatus.pendingApproval => const _Banner(
        icon: Icons.hourglass_top_rounded,
        title: 'Ждёт согласования заказчиком',
        subtitle:
            'Решение появится у всех ролей сразу. Если заказчик отклонит — '
            'заявка останется в истории.',
        color: AppColors.n200,
        iconColor: AppColors.n600,
      ),
      MaterialRequestStatus.approved => const _Banner(
        icon: Icons.check_circle_outline_rounded,
        title: 'Согласовано',
        subtitle:
            'Сумма заявки списана из materials-бюджета проекта. Видна всем ролям.',
        color: AppColors.greenLight,
        iconColor: AppColors.greenDark,
      ),
      // ТЗ NEWFIX §5.7 — статусы приёмки.
      MaterialRequestStatus.delivered => const _Banner(
        icon: Icons.local_shipping_outlined,
        title: 'Доставлено, ждёт приёмки',
        subtitle:
            'Материал у объекта. Бригадир сверяет позиции с фактическим '
            'количеством и принимает полностью или частично.',
        color: AppColors.blueBg,
        iconColor: AppColors.blueText,
      ),
      MaterialRequestStatus.acceptedPartial => const _Banner(
        icon: Icons.inventory_2_outlined,
        title: 'Принято частично',
        subtitle:
            'Часть позиций принята, остаток в ожидании дополнения. После '
            'довоза мастер снова отметит «Доставлено».',
        color: AppColors.yellowBg,
        iconColor: AppColors.yellowText,
      ),
      MaterialRequestStatus.acceptedFull => const _Banner(
        icon: Icons.task_alt_rounded,
        title: 'Принято полностью',
        subtitle: 'Заявка закрыта. Все позиции приняты в полном объёме.',
        color: AppColors.greenLight,
        iconColor: AppColors.greenDark,
      ),
      MaterialRequestStatus.rejected => const _Banner(
        icon: Icons.cancel_outlined,
        title: 'Заказчик отклонил заявку',
        subtitle:
            'Бюджет не списан. Заявка видна всем участникам проекта в истории.',
        color: Color(0xFFFFE5E0),
        iconColor: Color(0xFFB23A2A),
      ),
    };
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.iconColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(color: color, borderRadius: AppRadius.card),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: AppSpacing.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.subtitle.copyWith(
                    color: iconColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.tiny.copyWith(
                    color: AppColors.n700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final MaterialItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.n200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppTextStyles.subtitle.copyWith(
                    color: AppColors.n900,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_fmtQty(item.qty)} ${item.unit ?? ''}',
                  style: AppTextStyles.tiny.copyWith(
                    color: AppColors.n500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.note != null && item.note!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.note!,
                    style: AppTextStyles.tiny.copyWith(
                      color: AppColors.n400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (item.totalPrice != null)
            Text(
              Money.format(item.totalPrice!),
              style: AppTextStyles.subtitle.copyWith(
                color: AppColors.n800,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
        ],
      ),
    );
  }

  String _fmtQty(double q) =>
      q == q.roundToDouble() ? q.toInt().toString() : q.toString();
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

/// Блок кнопок приёмки. ТЗ NEWFIX §5.7.
///
/// Видимость кнопок определяется статусом заявки (RBAC на сервере):
///   approved | acceptedPartial → «Отметить доставку» (любой member)
///   delivered                  → «Принять полностью» + «Принять частично»
///                                (foreman/customer-owner/представитель)
///
/// Если backend возвращает 403 — показываем snackbar. Прятать кнопку по
/// клиентскому RBAC мы не можем без точного знания membershipRole (пока
/// получаем его через ProfileController на верхнем уровне).
class _AcceptanceActions extends ConsumerWidget {
  const _AcceptanceActions({required this.request});

  final MaterialRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (request.canMarkDelivered) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          icon: const Icon(Icons.local_shipping_outlined),
          label: const Text('Отметить «Доставлено»'),
          onPressed: () => _onMarkDelivered(context, ref),
        ),
      );
    }
    if (request.canAccept) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.task_alt_rounded),
              label: const Text('Принять полностью'),
              onPressed: () => _onAcceptFull(context, ref),
            ),
          ),
          const SizedBox(height: AppSpacing.x8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.inventory_2_outlined),
              label: const Text('Принять частично…'),
              onPressed: () => _onAcceptPartial(context, ref),
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> _onMarkDelivered(BuildContext context, WidgetRef ref) async {
    final failure = await ref
        .read(materialDetailProvider(request.id).notifier)
        .markDelivered();
    if (!context.mounted) return;
    if (failure != null) {
      _showError(context, failure.toString());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Доставка отмечена')),
      );
    }
  }

  Future<void> _onAcceptFull(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Принять полностью?'),
        content: const Text(
          'Все позиции будут отмечены как принятые в полном объёме. Это закроет заявку.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Принять'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final failure = await ref
        .read(materialDetailProvider(request.id).notifier)
        .acceptFull();
    if (!context.mounted) return;
    if (failure != null) {
      _showError(context, failure.toString());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заявка принята полностью')),
      );
    }
  }

  Future<void> _onAcceptPartial(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<List<AcceptedItemInput>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.n0,
      builder: (_) => _AcceptPartialSheet(items: request.items),
    );
    if (result == null || result.isEmpty || !context.mounted) return;
    final failure = await ref
        .read(materialDetailProvider(request.id).notifier)
        .acceptPartial(items: result);
    if (!context.mounted) return;
    if (failure != null) {
      _showError(context, failure.toString());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Принято частично')),
      );
    }
  }

  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.redDot,
        content: Text(msg, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}

/// Bottom sheet ввода фактических количеств per item. ТЗ NEWFIX §5.7.
class _AcceptPartialSheet extends StatefulWidget {
  const _AcceptPartialSheet({required this.items});

  final List<MaterialItem> items;

  @override
  State<_AcceptPartialSheet> createState() => _AcceptPartialSheetState();
}

class _AcceptPartialSheetState extends State<_AcceptPartialSheet> {
  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final item in widget.items)
        item.id: TextEditingController(text: item.qty.toString()),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.x16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Принять частично',
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.x4),
            Text(
              'Укажи фактически принятое количество по каждой позиции.\n'
              'Остаток уйдёт в ожидание дополнения — мастер отметит «Доставлено» снова при довозе.',
              style: AppTextStyles.tiny.copyWith(color: AppColors.n500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.x16),
            for (final item in widget.items) ...[
              _PartialItemRow(
                item: item,
                controller: _controllers[item.id]!,
              ),
              const SizedBox(height: AppSpacing.x12),
            ],
            const SizedBox(height: AppSpacing.x8),
            FilledButton(
              onPressed: _onSubmit,
              child: const Text('Принять'),
            ),
            const SizedBox(height: AppSpacing.x8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
          ],
        ),
      ),
    );
  }

  void _onSubmit() {
    final results = <AcceptedItemInput>[];
    for (final item in widget.items) {
      final raw = _controllers[item.id]!.text.trim().replaceAll(',', '.');
      final v = double.tryParse(raw);
      if (v == null || v < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Некорректное число для позиции «${item.name}»',
            ),
          ),
        );
        return;
      }
      if (v > item.qty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Нельзя принять больше заявленного для «${item.name}»',
            ),
          ),
        );
        return;
      }
      results.add(AcceptedItemInput(itemId: item.id, actualQty: v));
    }
    Navigator.pop(context, results);
  }
}

class _PartialItemRow extends StatelessWidget {
  const _PartialItemRow({required this.item, required this.controller});

  final MaterialItem item;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name, style: AppTextStyles.body),
              Text(
                'Заявлено: ${_fmtQty(item.qty)}${item.unit != null ? ' ${item.unit}' : ''}',
                style: AppTextStyles.tiny.copyWith(color: AppColors.n500),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.x12),
        Expanded(
          flex: 2,
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Принято',
              suffixText: item.unit,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.x10,
                vertical: AppSpacing.x8,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _fmtQty(double v) {
    final i = v.toInt();
    return i.toDouble() == v ? '$i' : v.toString();
  }
}
