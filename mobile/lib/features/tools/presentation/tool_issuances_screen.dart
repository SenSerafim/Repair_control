import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/application/auth_controller.dart';
import '../../projects/domain/membership.dart';
import '../../team/application/team_controller.dart';
import '../application/tools_controller.dart';
import '../domain/tool.dart';

class ToolIssuancesScreen extends ConsumerWidget {
  const ToolIssuancesScreen({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(toolIssuancesProvider(projectId));

    return AppScaffold(
      showBack: true,
      title: 'Инструмент на объекте',
      padding: EdgeInsets.zero,
      actions: [
        IconButton(
          icon: const Icon(Icons.add_circle_outline_rounded),
          onPressed: () => _showIssue(context, ref),
        ),
      ],
      body: async.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить',
          onRetry: () => ref.invalidate(toolIssuancesProvider(projectId)),
        ),
        data: (items) {
          if (items.isEmpty) {
            return AppEmptyState(
              title: 'Выдач ещё не было',
              subtitle: 'Выдайте инструмент мастеру — он подтвердит получение.',
              icon: Icons.construction_outlined,
              actionLabel: 'Выдать',
              onAction: () => _showIssue(context, ref),
            );
          }
          final me = ref.read(authControllerProvider).userId;
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.x16),
            itemCount: items.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.x10),
            itemBuilder: (_, i) => _IssuanceCard(
              issuance: items[i],
              meId: me,
              onAction: () => _handleAction(context, ref, items[i], me),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showIssue(BuildContext context, WidgetRef ref) async {
    final tools = ref.read(myToolsProvider).value ?? const <ToolItem>[];
    if (tools.isEmpty) {
      await ref.read(myToolsProvider.future);
      if (!context.mounted) return;
    }
    final teamAsync = ref.read(teamControllerProvider(projectId));
    final masters = teamAsync.value?.members
            .where((m) => m.role == MembershipRole.master)
            .toList() ??
        <Membership>[];
    String? toolId;
    String? toUserId;
    final qty = TextEditingController(text: '1');

    await showAppBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      child: StatefulBuilder(
        builder: (ctx, setState) => SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppBottomSheetHeader(
                title: 'Выдать инструмент',
                subtitle:
                    'Выдача появится у мастера для подтверждения получения.',
              ),
              const Text('Инструмент', style: AppTextStyles.caption),
              const SizedBox(height: AppSpacing.x6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t
                      in (ref.read(myToolsProvider).value ?? const <ToolItem>[]))
                    ChoiceChip(
                      label: Text(
                        '${t.name} (${t.availableQty})',
                      ),
                      selected: toolId == t.id,
                      onSelected: t.availableQty > 0
                          ? (_) => setState(() => toolId = t.id)
                          : null,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.x12),
              const Text('Кому', style: AppTextStyles.caption),
              const SizedBox(height: AppSpacing.x6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in masters)
                    ChoiceChip(
                      label: Text(m.user == null
                          ? 'Мастер'
                          : '${m.user!.firstName} ${m.user!.lastName}'
                              .trim()),
                      selected: toUserId == m.userId,
                      onSelected: (_) =>
                          setState(() => toUserId = m.userId),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.x12),
              TextField(
                controller: qty,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Кол-во',
                  filled: true,
                  fillColor: AppColors.n0,
                ),
              ),
              const SizedBox(height: AppSpacing.x16),
              AppButton(
                label: 'Выдать',
                onPressed: () async {
                  final q = int.tryParse(qty.text);
                  if (toolId == null || toUserId == null || q == null) {
                    return;
                  }
                  final failure = await ref
                      .read(toolIssuancesProvider(projectId).notifier)
                      .issue(
                        toolItemId: toolId!,
                        toUserId: toUserId!,
                        qty: q,
                      );
                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop();
                  if (!context.mounted) return;
                  if (failure != null) {
                    AppToast.show(
                      context,
                      message: failure.userMessage,
                      kind: AppToastKind.error,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
    qty.dispose();
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    ToolIssuance iss,
    String? meId,
  ) async {
    // Получатель подтверждает выдачу.
    if (iss.status == ToolIssuanceStatus.issued && iss.toUserId == meId) {
      await ref
          .read(toolIssuancesProvider(projectId).notifier)
          .confirm(iss.id);
      return;
    }
    // Получатель возвращает.
    if (iss.status == ToolIssuanceStatus.confirmed &&
        iss.toUserId == meId) {
      final qty = TextEditingController(text: '${iss.qty}');
      await showAppBottomSheet<void>(
        context: context,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppBottomSheetHeader(
              title: 'Вернуть инструмент',
              subtitle: 'Укажите количество, которое возвращаете.',
            ),
            TextField(
              controller: qty,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Кол-во',
                filled: true,
                fillColor: AppColors.n0,
              ),
            ),
            const SizedBox(height: AppSpacing.x16),
            Builder(
              builder: (ctx) => AppButton(
                label: 'Вернуть',
                onPressed: () async {
                  final q = int.tryParse(qty.text);
                  if (q == null || q < 0 || q > iss.qty) return;
                  await ref
                      .read(toolIssuancesProvider(projectId).notifier)
                      .requestReturn(id: iss.id, returnedQty: q);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
              ),
            ),
          ],
        ),
      );
      qty.dispose();
      return;
    }
    // Owner подтверждает возврат.
    if (iss.status == ToolIssuanceStatus.returnRequested &&
        iss.issuedById == meId) {
      await ref
          .read(toolIssuancesProvider(projectId).notifier)
          .returnConfirm(iss.id);
    }
  }
}

class _IssuanceCard extends StatelessWidget {
  const _IssuanceCard({
    required this.issuance,
    required this.meId,
    required this.onAction,
  });

  final ToolIssuance issuance;
  final String? meId;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final toolName = issuance.tool?.name ?? 'Инструмент';
    final showAction =
        (issuance.status == ToolIssuanceStatus.issued &&
                issuance.toUserId == meId) ||
            (issuance.status == ToolIssuanceStatus.confirmed &&
                issuance.toUserId == meId) ||
            (issuance.status == ToolIssuanceStatus.returnRequested &&
                issuance.issuedById == meId);
    return GestureDetector(
      onTap: showAction ? onAction : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.x14),
        decoration: BoxDecoration(
          color: AppColors.n0,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.n200, width: 1.5),
          boxShadow: AppShadows.sh1,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: issuance.status.semaphore.bg,
                borderRadius: BorderRadius.circular(AppRadius.r12),
              ),
              child: Icon(
                Icons.construction_outlined,
                color: issuance.status.semaphore.text,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$toolName × ${issuance.qty}',
                    style: AppTextStyles.subtitle,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      StatusPill(
                        label: issuance.status.displayName,
                        semaphore: issuance.status.semaphore,
                      ),
                      const SizedBox(width: AppSpacing.x6),
                      Text(
                        DateFormat('d MMM', 'ru').format(issuance.createdAt),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (showAction)
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.n300,
              ),
          ],
        ),
      ),
    );
  }
}
