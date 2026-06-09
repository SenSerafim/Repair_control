import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/application/auth_controller.dart';
import '../application/tools_controller.dart';
import '../domain/tool.dart';

/// Детальная карточка инструмента. Self-custody модель: показывает кто держит
/// сейчас, CTA «Я забрал», и timeline передач. Доступен из my_tools (личный)
/// и project_tools_board (проектный).
class ToolDetailScreen extends ConsumerWidget {
  const ToolDetailScreen({required this.toolId, super.key});

  final String toolId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(toolDetailProvider(toolId));

    return AppScaffold(
      showBack: true,
      title: 'Инструмент',
      backgroundColor: AppColors.n50,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
      actions: [
        // Task 6.2 — кнопка-вход в full-screen «История инструмента».
        IconButton(
          tooltip: 'История передач',
          icon: const Icon(
            PhosphorIconsRegular.clockCounterClockwise,
            color: AppColors.brand,
          ),
          onPressed: () => context.push(
            AppRoutes.toolCustodyHistoryWith(
              toolId,
              name: async.valueOrNull?.name,
            ),
          ),
        ),
      ],
      body: async.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить',
          subtitle: e.toString(),
          onRetry: () => ref.invalidate(toolDetailProvider(toolId)),
        ),
        data: (tool) => _Body(tool: tool),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.tool});
  final ToolItem tool;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(authControllerProvider).userId;
    final isHeldByMe = me != null && tool.isHeldBy(me);
    final canClaim = tool.isInProject && me != null && !isHeldByMe;
    final df = DateFormat('dd.MM.yyyy');

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x20),
      children: [
        _HeroCard(tool: tool, isHeldByMe: isHeldByMe),
        const SizedBox(height: AppSpacing.x16),
        if (tool.isInProject) ...[
          _HolderBlock(tool: tool, isHeldByMe: isHeldByMe),
          const SizedBox(height: AppSpacing.x12),
        ],
        if (canClaim) ...[
          _ClaimCta(toolId: tool.id, projectId: tool.projectId!),
          const SizedBox(height: AppSpacing.x16),
        ],
        _InfoCard(tool: tool, df: df),
        if (tool.isInProject) ...[
          const SizedBox(height: AppSpacing.x20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'ИСТОРИЯ ПЕРЕДАЧ',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.n400,
                letterSpacing: 0.6,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x10),
          _CustodyTimeline(toolId: tool.id),
        ],
        const SizedBox(height: AppSpacing.x32),
        if (me != null && tool.isOwnedBy(me))
          AppButton(
            label: tool.isInProject ? 'Забрать из проекта' : 'Удалить инструмент',
            variant: AppButtonVariant.ghostDanger,
            icon: PhosphorIconsRegular.trash,
            onPressed: () => _onDangerAction(context, ref, tool),
          ),
      ],
    );
  }

  Future<void> _onDangerAction(
    BuildContext context,
    WidgetRef ref,
    ToolItem t,
  ) async {
    if (t.isInProject) {
      // Detach: убрать из проекта, инструмент возвращается в личный профиль.
      final pid = t.projectId!;
      final failure = await ref
          .read(projectToolsBoardProvider(pid).notifier)
          .detach(t.id);
      if (!context.mounted) return;
      if (failure != null) {
        AppToast.show(context, message: failure.userMessage, kind: AppToastKind.error);
      } else {
        AppToast.show(context, message: 'Инструмент забран из проекта');
        context.pop();
      }
    } else {
      final failure = await ref.read(myToolsProvider.notifier).remove(t.id);
      if (!context.mounted) return;
      if (failure != null) {
        AppToast.show(context, message: failure.userMessage, kind: AppToastKind.error);
      } else {
        AppToast.show(context, message: 'Удалено');
        context.pop();
      }
    }
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.tool, required this.isHeldByMe});
  final ToolItem tool;
  final bool isHeldByMe;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x16),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppRadius.card,
        boxShadow: AppShadows.sh1,
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.brandLight,
              borderRadius: BorderRadius.circular(AppRadius.r16),
            ),
            child: Icon(PhosphorIconsFill.wrench, size: 32, color: AppColors.brand),
          ),
          const SizedBox(width: AppSpacing.x14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tool.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.n800,
                    letterSpacing: -0.2,
                  ),
                ),
                if (tool.serial != null && tool.serial!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '№ ${tool.serial}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.n400,
                    ),
                  ),
                ],
                if (isHeldByMe) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.greenLight,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: const Text(
                      '👤 У меня',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.greenDark,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClaimCta extends ConsumerStatefulWidget {
  const _ClaimCta({required this.toolId, required this.projectId});
  final String toolId;
  final String projectId;

  @override
  ConsumerState<_ClaimCta> createState() => _ClaimCtaState();
}

class _ClaimCtaState extends ConsumerState<_ClaimCta> {
  bool _busy = false;

  Future<void> _claim() async {
    setState(() => _busy = true);
    final failure = await ref
        .read(projectToolsBoardProvider(widget.projectId).notifier)
        .claim(toolId: widget.toolId);
    if (!mounted) return;
    setState(() => _busy = false);
    if (failure != null) {
      AppToast.show(context, message: failure.userMessage, kind: AppToastKind.error);
    } else {
      ref.invalidate(toolDetailProvider(widget.toolId));
      AppToast.show(context, message: 'Инструмент теперь у вас', kind: AppToastKind.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: 'Я забрал этот инструмент',
      icon: PhosphorIconsBold.handArrowDown,
      isLoading: _busy,
      onPressed: _claim,
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.tool, required this.df});
  final ToolItem tool;
  final DateFormat df;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppRadius.card,
        boxShadow: AppShadows.sh1,
      ),
      child: Column(
        children: [
          _DetailRow(
            label: 'Владелец',
            value: tool.owner?.displayName ?? '—',
          ),
          if (tool.article != null && tool.article!.isNotEmpty) ...[
            const _Divider(),
            _DetailRow(label: 'Артикул', value: tool.article!),
          ],
          if (tool.serial != null && tool.serial!.isNotEmpty) ...[
            const _Divider(),
            _DetailRow(label: 'Серийный №', value: tool.serial!),
          ],
          const _Divider(),
          _DetailRow(label: 'Статус', value: tool.status.displayName),
          if (tool.status == ToolStatus.inStorage &&
              tool.storageLocation != null &&
              tool.storageLocation!.isNotEmpty) ...[
            const _Divider(),
            _DetailRow(label: 'Место', value: tool.storageLocation!),
          ],
          const _Divider(),
          _DetailRow(label: 'Добавлен', value: df.format(tool.createdAt)),
        ],
      ),
    );
  }
}

/// Заметный блок «у кого сейчас инструмент» с tap-to-call и ссылкой на
/// профиль. Виден только для инструментов в проекте.
class _HolderBlock extends StatelessWidget {
  const _HolderBlock({required this.tool, required this.isHeldByMe});
  final ToolItem tool;
  final bool isHeldByMe;

  @override
  Widget build(BuildContext context) {
    final holder = tool.holder;
    final holderName = holder?.displayName ?? 'Неизвестный участник';
    final isWithOwner = tool.holder?.id == tool.owner?.id;

    final headline = isHeldByMe
        ? 'Сейчас у вас'
        : (isWithOwner ? 'У владельца' : 'Передан');
    final headlineColor = isHeldByMe ? AppColors.greenDark : AppColors.brand;
    final bg = isHeldByMe ? AppColors.greenLight : AppColors.brandLight;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: AppColors.n0,
        border: Border.all(
          color: isHeldByMe ? AppColors.greenDark : AppColors.brand,
          width: 1.2,
        ),
        borderRadius: AppRadius.card,
        boxShadow: AppShadows.sh1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  headline.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: headlineColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Avatar(user: holder),
              const SizedBox(width: AppSpacing.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isHeldByMe ? '$holderName (вы)' : holderName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.n800,
                        letterSpacing: -0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (holder?.hasPhone ?? false) ...[
                      const SizedBox(height: 2),
                      Text(
                        holder!.phone!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.n400,
                        ),
                      ),
                    ] else if (holder == null)
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Text(
                          'Контакт недоступен',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.n400,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (!isHeldByMe && (holder?.hasPhone ?? false)) ...[
            const SizedBox(height: AppSpacing.x12),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Позвонить',
                    icon: PhosphorIconsBold.phone,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => _call(context, holder!.phone!),
                  ),
                ),
                const SizedBox(width: AppSpacing.x8),
                Expanded(
                  child: AppButton(
                    label: 'Скопировать',
                    icon: PhosphorIconsRegular.copy,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => _copy(context, holder!.phone!),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _call(BuildContext context, String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'\s'), ''));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      AppToast.show(
        context,
        message: 'Не удалось открыть телефон',
        kind: AppToastKind.error,
      );
    }
  }

  Future<void> _copy(BuildContext context, String phone) async {
    await Clipboard.setData(ClipboardData(text: phone));
    if (context.mounted) {
      AppToast.show(context, message: 'Телефон скопирован');
    }
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user});
  final PublicUser? user;

  @override
  Widget build(BuildContext context) {
    final url = user?.avatarUrl;
    final initials = user?.initials ?? '?';
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.n100,
        shape: BoxShape.circle,
        image: url != null && url.isNotEmpty
            ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
            : null,
      ),
      child: url == null || url.isEmpty
          ? Text(
              initials,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.n700,
              ),
            )
          : null,
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.n400,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.n800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, color: AppColors.n100);
}

class _CustodyTimeline extends ConsumerWidget {
  const _CustodyTimeline({required this.toolId});
  final String toolId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(toolCustodyHistoryProvider(toolId));
    final df = DateFormat('dd.MM.yyyy HH:mm');

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))),
      ),
      error: (e, _) => AppErrorState(
        title: 'Не удалось загрузить историю',
        onRetry: () => ref.invalidate(toolCustodyHistoryProvider(toolId)),
      ),
      data: (events) {
        if (events.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.x14),
            decoration: BoxDecoration(
              color: AppColors.n0,
              borderRadius: AppRadius.card,
              boxShadow: AppShadows.sh1,
            ),
            child: const Text(
              'История пуста',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.n400,
              ),
            ),
          );
        }
        return Container(
          padding: const EdgeInsets.all(AppSpacing.x14),
          decoration: BoxDecoration(
            color: AppColors.n0,
            borderRadius: AppRadius.card,
            boxShadow: AppShadows.sh1,
          ),
          child: Column(
            children: [
              for (var i = 0; i < events.length; i++)
                _TimelineRow(
                  event: events[i],
                  df: df,
                  last: i == events.length - 1,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.event, required this.df, required this.last});
  final ToolCustodyEvent event;
  final DateFormat df;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final holderName = event.holder?.displayName ?? event.holderId;
    final prevName = event.previousHolder?.displayName;
    final title = event.isInitial
        ? 'Добавлен в проект — у $holderName'
        : (prevName != null
            ? '$holderName забрал у $prevName'
            : '$holderName забрал');
    final dot = event.isInitial ? AppColors.brand : AppColors.greenDark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            if (!last)
              Container(
                width: 2,
                height: 36,
                color: AppColors.n200,
                margin: const EdgeInsets.only(top: 4),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: last ? 0 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.n800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  df.format(event.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.n400,
                  ),
                ),
                if (event.note != null && event.note!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '«${event.note}»',
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppColors.n600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
