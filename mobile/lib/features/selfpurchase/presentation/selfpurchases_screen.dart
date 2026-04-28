import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/access/access_guard.dart';
import '../../../core/access/domain_actions.dart';
import '../../../core/error/api_error.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/application/auth_controller.dart';
import '../application/selfpurchase_controller.dart';
import '../data/selfpurchase_repository.dart';
import '../domain/self_purchase.dart';
import '_widgets/selfpurchase_list_card.dart';

/// Активный фильтр на экране самозакупов.
enum _Filter {
  all,
  mine,
  awaitingMyDecision;

  String get label => switch (this) {
        _Filter.all => 'Все',
        _Filter.mine => 'Мои',
        _Filter.awaitingMyDecision => 'Ждут моего согласования',
      };
}

final _filterProvider =
    StateProvider.autoDispose<_Filter>((ref) => _Filter.all);

class SelfpurchasesScreen extends ConsumerWidget {
  const SelfpurchasesScreen({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(selfpurchasesControllerProvider(projectId));
    final canCreate =
        ref.watch(canProvider(DomainAction.selfPurchaseCreate));
    final filter = ref.watch(_filterProvider);
    final me = ref.watch(authControllerProvider).userId;

    return AppScaffold(
      showBack: true,
      title: 'Самозакупы',
      padding: EdgeInsets.zero,
      actions: [
        if (canCreate)
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () =>
                context.push('/projects/$projectId/selfpurchases/new'),
          ),
      ],
      body: async.when(
        loading: () => const AppLoadingState(),
        error: (e, _) {
          if (e is SelfPurchaseException &&
              e.apiError.kind == ApiErrorKind.forbidden) {
            return const AppEmptyState(
              title: 'Раздел недоступен',
              subtitle: 'У вашей роли нет доступа к самозакупам.',
              icon: Icons.lock_outline_rounded,
            );
          }
          return AppErrorState(
            title: 'Не удалось загрузить',
            onRetry: () =>
                ref.invalidate(selfpurchasesControllerProvider(projectId)),
          );
        },
        data: (items) {
          final filtered = _applyFilter(items, filter, me);
          return Column(
            children: [
              _FilterBar(
                selected: filter,
                onChanged: (f) =>
                    ref.read(_filterProvider.notifier).state = f,
                pendingForMeCount: items
                    .where((sp) =>
                        sp.status == SelfPurchaseStatus.pending &&
                        sp.addresseeId == me)
                    .length,
              ),
              Expanded(
                child: filtered.isEmpty
                    ? AppEmptyState(
                        title: filter == _Filter.awaitingMyDecision
                            ? 'Нет запросов на согласование'
                            : (filter == _Filter.mine
                                ? 'Вы не отправляли самозакупов'
                                : 'Самозакупов ещё нет'),
                        subtitle: canCreate && filter == _Filter.all
                            ? 'Мастер или бригадир купил сам — создайте отчёт.'
                            : null,
                        icon: Icons.shopping_bag_outlined,
                        actionLabel:
                            canCreate && filter == _Filter.all ? 'Создать' : null,
                        onAction: canCreate && filter == _Filter.all
                            ? () => context.push(
                                  '/projects/$projectId/selfpurchases/new',
                                )
                            : null,
                      )
                    : RefreshIndicator(
                        onRefresh: () async => ref.invalidate(
                          selfpurchasesControllerProvider(projectId),
                        ),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.x16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.x10),
                          itemBuilder: (_, i) => SelfpurchaseListCard(
                            sp: filtered[i],
                            onTap: () => context.push(
                              '/projects/$projectId/selfpurchases/${filtered[i].id}',
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<SelfPurchase> _applyFilter(
    List<SelfPurchase> items,
    _Filter filter,
    String? meId,
  ) {
    return switch (filter) {
      _Filter.all => items,
      _Filter.mine => items.where((sp) => sp.byUserId == meId).toList(),
      _Filter.awaitingMyDecision => items
          .where((sp) =>
              sp.status == SelfPurchaseStatus.pending &&
              sp.addresseeId == meId)
          .toList(),
    };
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selected,
    required this.onChanged,
    required this.pendingForMeCount,
  });

  final _Filter selected;
  final ValueChanged<_Filter> onChanged;
  final int pendingForMeCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
        children: [
          for (final f in _Filter.values) ...[
            _Chip(
              label: f == _Filter.awaitingMyDecision && pendingForMeCount > 0
                  ? '${f.label} · $pendingForMeCount'
                  : f.label,
              active: selected == f,
              onTap: () => onChanged(f),
            ),
            const SizedBox(width: AppSpacing.x8),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x12,
            vertical: AppSpacing.x6,
          ),
          decoration: BoxDecoration(
            color: active ? AppColors.brand : AppColors.n100,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: active ? AppColors.n0 : AppColors.n700,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
