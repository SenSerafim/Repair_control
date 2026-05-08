import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/access/access_guard.dart';
import '../../../core/access/domain_actions.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/application/auth_controller.dart';
import '../../team/application/team_controller.dart';
import '../application/tools_controller.dart';
import '../domain/tool.dart';

/// П2.15 — реестр инструментов проекта (вкладка «Инструменты»).
///
/// Видим всем участникам проекта. Колонка «у кого сейчас» показывает
/// текущего держателя (последний confirmed получатель, либо владелец).
/// Бэйдж «есть запрос» — для всех; кнопки approve/reject — только владельцу.
/// Кнопка «+ из моих инструментов» — добавляет из профиля в проект (П3.2).
class ProjectToolsScreen extends ConsumerWidget {
  const ProjectToolsScreen({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registryAsync = ref.watch(projectToolRegistryProvider(projectId));
    final canManageTools = ref.watch(canProvider(DomainAction.toolsManage));

    return AppScaffold(
      showBack: true,
      title: 'Инструменты проекта',
      padding: EdgeInsets.zero,
      body: registryAsync.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить реестр',
          onRetry: () =>
              ref.invalidate(projectToolRegistryProvider(projectId)),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.x16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AppEmptyState(
                    title: 'В проекте пока нет инструментов',
                    subtitle:
                        'Добавьте свои инструменты или попросите участника добавить',
                    icon: Icons.handyman_outlined,
                  ),
                  const SizedBox(height: AppSpacing.x16),
                  if (canManageTools) ...[
                    AppButton(
                      label: 'Добавить из моих',
                      icon: PhosphorIconsBold.plus,
                      onPressed: () =>
                          _showAddFromMy(context, ref, projectId: projectId),
                    ),
                    const SizedBox(height: AppSpacing.x8),
                    // QA-баг #8: альтернативный путь — создать новый
                    // инструмент сразу с привязкой к этому проекту.
                    // Раньше юзер мог вернуться на «Мои инструменты»,
                    // создать там без projectId и потом увидеть, что
                    // в реестре проекта пусто.
                    AppButton(
                      label: 'Создать новый',
                      icon: PhosphorIconsBold.wrench,
                      variant: AppButtonVariant.ghost,
                      onPressed: () => context.push(
                        '${AppRoutes.profileToolAdd}?projectId=$projectId',
                      ),
                    ),
                  ],
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x16,
              AppSpacing.x16,
              AppSpacing.x16,
              AppSpacing.x32,
            ),
            itemCount: entries.length + (canManageTools ? 1 : 0),
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.x10),
            itemBuilder: (_, i) {
              if (canManageTools && i == entries.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: AppButton(
                    label: 'Добавить из моих',
                    icon: PhosphorIconsBold.plus,
                    variant: AppButtonVariant.ghost,
                    onPressed: () =>
                        _showAddFromMy(context, ref, projectId: projectId),
                  ),
                );
              }
              return _RegistryRow(
                projectId: projectId,
                entry: entries[i],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showAddFromMy(
    BuildContext context,
    WidgetRef ref, {
    required String projectId,
  }) async {
    await showAppBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      child: _AddFromMySheet(projectId: projectId),
    );
  }
}

/// Строка реестра: фото / имя / серийник / держатель / actions.
class _RegistryRow extends ConsumerWidget {
  const _RegistryRow({required this.projectId, required this.entry});

  final String projectId;
  final ProjectToolEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.read(authControllerProvider).userId;
    final isOwner = entry.tool.ownerId == me;
    final amHolder = entry.currentHolderId == me;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x12),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.n200),
        boxShadow: AppShadows.sh1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.n100,
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                ),
                child: const Icon(
                  PhosphorIconsRegular.wrench,
                  color: AppColors.n500,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.tool.name,
                      style: AppTextStyles.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (entry.tool.serial != null &&
                        entry.tool.serial!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '№ ${entry.tool.serial}',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.n500),
                      ),
                    ],
                    const SizedBox(height: 4),
                    _HolderTag(entry: entry),
                  ],
                ),
              ),
              if (entry.hasActiveRequest)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.yellowBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Заявка',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.yellowText,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.x10),
          // Действия (зависят от роли):
          // - Не-владелец и не текущий держатель → «Запросить»
          // - Владелец c активной заявкой → «Принять» / «Отклонить»
          //   (но реальная заявка обрабатывается внутри ToolRequestDetail)
          if (!isOwner && !amHolder && entry.tool.availableQty > 0)
            AppButton(
              label: 'Запросить',
              variant: AppButtonVariant.ghost,
              icon: PhosphorIconsRegular.handArrowDown,
              onPressed: () => _request(context, ref),
            ),
          if (isOwner && entry.hasActiveRequest)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Откройте раздел «Выдачи» для обработки заявок',
                style: AppTextStyles.caption.copyWith(color: AppColors.n500),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _request(BuildContext context, WidgetRef ref) async {
    final qtyController = TextEditingController(text: '1');
    final qty = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Запросить ${entry.tool.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Доступно: ${entry.tool.availableQty} ${entry.tool.unit ?? ''}',
              style: AppTextStyles.caption.copyWith(color: AppColors.n500),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Количество'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              final n = int.tryParse(qtyController.text);
              if (n != null && n > 0) Navigator.of(ctx).pop(n);
            },
            child: const Text('Запросить'),
          ),
        ],
      ),
    );
    qtyController.dispose();
    if (qty == null || !context.mounted) return;
    final failure =
        await ref.read(projectToolRegistryProvider(projectId).notifier).requestTool(
              toolItemId: entry.tool.id,
              qty: qty,
            );
    if (!context.mounted) return;
    AppToast.show(
      context,
      message: failure == null
          ? 'Заявка отправлена владельцу'
          : failure.userMessage,
      kind: failure == null ? AppToastKind.success : AppToastKind.error,
    );
  }
}

class _HolderTag extends ConsumerWidget {
  const _HolderTag({required this.entry});

  final ProjectToolEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = entry.tool.projectId != null
        ? ref.watch(teamControllerProvider(entry.tool.projectId!))
        : null;
    final holderName = teamAsync?.maybeWhen(
          data: (team) {
            final m = team.members.firstWhere(
              (m) => m.userId == entry.currentHolderId,
              orElse: () => team.members.isEmpty
                  ? team.members.first
                  : team.members.first,
            );
            final u = m.user;
            if (u == null) return 'Участник';
            return '${u.firstName} ${u.lastName}'.trim();
          },
          orElse: () => null,
        ) ??
        'У владельца';

    final color = entry.isHeldByOwner ? AppColors.brand : AppColors.greenDark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.person_outline, size: 14, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            'У: $holderName',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// П3.2 — bottom-sheet с чек-листом «Моих инструментов» для bulk-add в проект.
class _AddFromMySheet extends ConsumerStatefulWidget {
  const _AddFromMySheet({required this.projectId});

  final String projectId;

  @override
  ConsumerState<_AddFromMySheet> createState() => _AddFromMySheetState();
}

class _AddFromMySheetState extends ConsumerState<_AddFromMySheet> {
  final _selected = <String>{};
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final myAsync = ref.watch(myToolsProvider);
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          const AppBottomSheetHeader(
            title: 'Добавить из моих',
            subtitle: 'Выберите инструменты, которые добавите в проект',
          ),
          Expanded(
            child: myAsync.when(
              loading: () => const AppLoadingState(),
              error: (e, _) => AppErrorState(
                title: 'Ошибка',
                onRetry: () => ref.invalidate(myToolsProvider),
              ),
              data: (tools) {
                // Фильтруем те, что уже в этом проекте.
                final available =
                    tools.where((t) => t.projectId != widget.projectId).toList();
                if (available.isEmpty) {
                  return const AppEmptyState(
                    title: 'Все инструменты уже в проекте',
                    icon: Icons.check_circle_outline,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.x16,
                    vertical: AppSpacing.x8,
                  ),
                  itemCount: available.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final t = available[i];
                    final checked = _selected.contains(t.id);
                    return InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.r12),
                      onTap: () => setState(() {
                        if (checked) {
                          _selected.remove(t.id);
                        } else {
                          _selected.add(t.id);
                        }
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: checked
                              ? AppColors.brandLight
                              : AppColors.n50,
                          borderRadius: BorderRadius.circular(AppRadius.r12),
                          border: Border.all(
                            color: checked
                                ? AppColors.brand
                                : AppColors.n200,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: checked,
                              onChanged: (_) => setState(() {
                                if (checked) {
                                  _selected.remove(t.id);
                                } else {
                                  _selected.add(t.id);
                                }
                              }),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.name,
                                    style: AppTextStyles.subtitle,
                                  ),
                                  if (t.serial != null &&
                                      t.serial!.isNotEmpty)
                                    Text(
                                      '№ ${t.serial} · ${t.totalQty} ${t.unit ?? ''}',
                                      style: AppTextStyles.caption
                                          .copyWith(color: AppColors.n500),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.x16),
            child: AppButton(
              label: _selected.isEmpty
                  ? 'Выберите инструменты'
                  : 'Добавить (${_selected.length})',
              isLoading: _busy,
              onPressed: _selected.isEmpty || _busy ? null : _submit,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    final failure = await ref
        .read(projectToolRegistryProvider(widget.projectId).notifier)
        .addFromMy(_selected.toList());
    if (!mounted) return;
    setState(() => _busy = false);
    Navigator.of(context).pop();
    AppToast.show(
      context,
      message: failure == null
          ? 'Инструменты добавлены'
          : failure.userMessage,
      kind: failure == null ? AppToastKind.success : AppToastKind.error,
    );
  }
}
