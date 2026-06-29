import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../projects/domain/membership.dart';
import '../../../team/application/team_controller.dart';

/// Кто ведёт этап: бригадир + мастер (если назначен) в один ряд.
///
/// Зачем: до 2026-05 ассистенты «спрятались» в 3-точечном меню header'а,
/// поэтому пользователи (особенно заказчики, которые впервые открывают
/// этап) не догадывались, что мастера/бригадира можно назначить здесь же.
/// Ряд решает 2 задачи:
///   1) Прозрачно показывает текущих исполнителей (или подсказку «не
///      назначен»), синхронизируясь с `teamControllerProvider` — после
///      WS-броадкаста `project:membership_changed` строки обновятся без
///      pull-to-refresh.
///   2) Когда у наблюдателя есть `canAssign`, обе ячейки кликабельны →
///      открывают тот же sheet выбора, что и пункты меню.
class StageExecutorsRow extends ConsumerWidget {
  const StageExecutorsRow({
    required this.projectId,
    required this.foremanIds,
    required this.masterId,
    required this.canAssign,
    required this.showMaster,
    required this.onAssignForeman,
    required this.onAssignMaster,
    super.key,
  });

  final String projectId;
  final List<String> foremanIds;
  final String? masterId;
  final bool canAssign;
  final bool showMaster;
  final VoidCallback onAssignForeman;
  final VoidCallback onAssignMaster;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamControllerProvider(projectId));
    final members = teamAsync.maybeWhen(
      data: (t) => t.members,
      orElse: () => const <Membership>[],
    );
    final foremanId = foremanIds.isNotEmpty ? foremanIds.first : null;
    final foreman = _findMember(members, foremanId);
    final master = _findMember(members, masterId);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.n200),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _ExecutorCell(
                kind: _ExecutorKind.foreman,
                member: foreman,
                canAssign: canAssign,
                onTap: canAssign ? onAssignForeman : null,
              ),
            ),
            if (showMaster) ...[
              Container(width: 1, color: AppColors.n100),
              Expanded(
                child: _ExecutorCell(
                  kind: _ExecutorKind.master,
                  member: master,
                  canAssign: canAssign,
                  onTap: canAssign ? onAssignMaster : null,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Membership? _findMember(List<Membership> members, String? userId) {
    if (userId == null) return null;
    try {
      return members.firstWhere((m) => m.userId == userId);
    } catch (_) {
      return null;
    }
  }
}

enum _ExecutorKind { foreman, master }

class _ExecutorCell extends StatelessWidget {
  const _ExecutorCell({
    required this.kind,
    required this.member,
    required this.canAssign,
    required this.onTap,
  });

  final _ExecutorKind kind;
  final Membership? member;
  final bool canAssign;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final label = switch (kind) {
      _ExecutorKind.foreman => 'Бригадир',
      _ExecutorKind.master => 'Мастер',
    };
    final user = member?.user;
    final name = user == null
        ? null
        : '${user.firstName} ${user.lastName}'.trim();
    final hasMember = member != null;
    final placeholder = canAssign
        ? (kind == _ExecutorKind.foreman ? 'Назначить' : 'Не назначен')
        : 'Не назначен';
    return InkWell(
      borderRadius: AppRadius.card,
      onTap: onTap,
      child: Padding(
        // Компактная ячейка исполнителя (Егор 29.06.2026): h x12→x10,
        // v x8→x6, аватар 32→26 — сэкономили ~16px высоты шапки.
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x10,
          vertical: AppSpacing.x6,
        ),
        child: Row(
          children: [
            if (hasMember)
              AppAvatar(
                seed: member!.userId,
                name: (name?.isNotEmpty ?? false) ? name : null,
                imageUrl: user?.avatarUrl,
                size: 26,
              )
            else
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppColors.n100,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: AppColors.n200),
                ),
                child: Icon(
                  kind == _ExecutorKind.foreman
                      ? Icons.engineering_outlined
                      : Icons.handyman_outlined,
                  size: 14,
                  color: AppColors.n500,
                ),
              ),
            const SizedBox(width: AppSpacing.x8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: AppTextStyles.tiny.copyWith(
                      color: AppColors.n500,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    (name?.isNotEmpty ?? false) ? name! : placeholder,
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w800,
                      color: hasMember ? AppColors.n800 : AppColors.n500,
                      fontStyle: hasMember
                          ? FontStyle.normal
                          : FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (canAssign)
              Icon(
                hasMember ? Icons.edit_outlined : Icons.add_rounded,
                size: 16,
                color: AppColors.brand,
              ),
          ],
        ),
      ),
    );
  }
}
