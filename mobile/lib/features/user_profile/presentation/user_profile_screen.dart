import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/utils/money.dart';
import '../../../shared/widgets/widgets.dart';
import '../../chat/data/chats_repository.dart';
import '../../tools/application/tools_controller.dart' as tc;
import '../../tools/domain/tool.dart';
import '../data/user_profile_repository.dart';
import '../domain/user_profile_aggregate.dart';

/// Локальный provider — список «Моих» инструментов, доступных для выдачи
/// (т.е. не закреплённых ни за проектом, ни за сотрудником). Использует
/// существующий [tc.myToolsProvider], добавляя фильтр по статусу in_storage.
final _myToolsForAssignProvider =
    Provider.autoDispose<AsyncValue<List<ToolItem>>>((ref) {
      final all = ref.watch(tc.myToolsProvider);
      return all.whenData(
        (tools) =>
            tools.where((t) => t.status == ToolStatus.inStorage).toList(),
      );
    });

/// Удобный шорткат на основной контроллер «Моих инструментов».
final _myToolsCtrlProvider = tc.myToolsProvider;

/// ТЗ NEWFIX §4: новый экран профиля сотрудника. 5 секций (объекты /
/// статистика / инструмент / рекламации / выплаты) + шапка с
/// «Позвонить» / «Написать в чат». Видимость выплат — по флагу
/// `payouts.visible` с бекенда (заказчик не видит).
class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(userProfileAggregateProvider(userId));
    return AppScaffold(
      showBack: true,
      title: 'Профиль сотрудника',
      padding: EdgeInsets.zero,
      body: async.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить профиль',
          subtitle: e.toString(),
          onRetry: () => ref.invalidate(userProfileAggregateProvider(userId)),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(userProfileAggregateProvider(userId)),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.x16),
            children: [
              _Header(
                header: data.user,
                objects: data.objects,
                viewedUserId: userId,
              ),
              const SizedBox(height: AppSpacing.x16),
              _ObjectsSection(items: data.objects),
              const SizedBox(height: AppSpacing.x16),
              _MonthStatsSection(stats: data.monthStats),
              const SizedBox(height: AppSpacing.x16),
              _ToolsSection(items: data.tools, employeeUserId: userId),
              const SizedBox(height: AppSpacing.x16),
              _ReclamationsSection(value: data.reclamations),
              const SizedBox(height: AppSpacing.x16),
              _PayoutsSection(payouts: data.payouts),
              const SizedBox(height: AppSpacing.x24),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({
    required this.header,
    required this.objects,
    required this.viewedUserId,
  });
  final UserProfileHeader header;
  final List<UserProfileObject> objects;
  final String viewedUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initials =
        (header.firstName.isNotEmpty ? header.firstName.substring(0, 1) : '?') +
        (header.lastName.isNotEmpty ? header.lastName.substring(0, 1) : '');
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x16),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.n200, width: 1.5),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.brand,
            backgroundImage: header.avatarUrl != null
                ? NetworkImage(header.avatarUrl!)
                : null,
            child: header.avatarUrl == null
                ? Text(
                    initials.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  header.fullName.isEmpty ? 'Без имени' : header.fullName,
                  style: AppTextStyles.subtitle.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                if (header.activeRole.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _roleLabel(header.activeRole),
                    style: AppTextStyles.tiny.copyWith(color: AppColors.n400),
                  ),
                ],
              ],
            ),
          ),
          // ТЗ §4.3: «Позвонить» — открывает системный звонок через tel:
          // (NEWFIX gaps Task 1.1). «Написать в чат» — отдельный эпик.
          IconButton(
            key: const ValueKey('user_profile_phone_button'),
            icon: const Icon(Icons.phone_outlined),
            tooltip: header.phone,
            onPressed: header.phone.isEmpty
                ? null
                : () => launchUrl(Uri(scheme: 'tel', path: header.phone)),
          ),
          // NEWFIX gaps Task 1.2: «Написать в чат» — backend имеет только
          // POST /api/projects/:projectId/chats/personal (нет глобального
          // direct-чата). Поэтому используем первый общий проект.
          IconButton(
            key: const ValueKey('user_profile_chat_button'),
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Написать в чат',
            onPressed: () async {
              if (objects.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Нет общих проектов с этим сотрудником'),
                  ),
                );
                return;
              }
              final projectId = objects.first.projectId;
              try {
                final chat = await ref
                    .read(chatsRepositoryProvider)
                    .createPersonal(
                      projectId: projectId,
                      withUserId: viewedUserId,
                    );
                if (context.mounted) {
                  unawaited(context.push('/chats/${chat.id}'));
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Не удалось открыть чат')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  String _roleLabel(String r) {
    switch (r) {
      case 'customer':
        return 'Заказчик';
      case 'representative':
        return 'Представитель';
      case 'contractor':
        return 'Бригадир';
      case 'master':
        return 'Мастер';
      case 'admin':
        return 'Администратор';
      default:
        return r;
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.icon});
  final String title;
  final IconData? icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.n200, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: AppColors.n500),
                const SizedBox(width: 6),
              ],
              Text(
                title,
                style: AppTextStyles.tiny.copyWith(
                  color: AppColors.n500,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x10),
          child,
        ],
      ),
    );
  }
}

class _ObjectsSection extends StatelessWidget {
  const _ObjectsSection({required this.items});
  final List<UserProfileObject> items;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.apartment_outlined,
      title: 'ОБЪЕКТЫ (${items.length})',
      child: items.isEmpty
          ? const Text(
              'Сотрудник не назначен ни на один объект',
              style: TextStyle(color: AppColors.n400),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final o in items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: InkWell(
                      onTap: () => context.push('/projects/${o.projectId}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            o.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.n900,
                              fontSize: 14,
                            ),
                          ),
                          if (o.stages.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              o.stages
                                  .map((s) => 'Этап ${s.orderIndex + 1}')
                                  .join(' · '),
                              style: AppTextStyles.tiny.copyWith(
                                color: AppColors.n400,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _MonthStatsSection extends StatelessWidget {
  const _MonthStatsSection({required this.stats});
  final UserProfileMonthStats stats;

  @override
  Widget build(BuildContext context) {
    final monthName = _monthRu(DateTime.now().month);
    return _SectionCard(
      icon: Icons.insights_outlined,
      title: 'СТАТИСТИКА · $monthName'.toUpperCase(),
      child: Text(
        'Шагов выполнено: ${stats.stepsDoneThisMonth}',
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.n900,
        ),
      ),
    );
  }

  static String _monthRu(int m) {
    const names = [
      '',
      'январь',
      'февраль',
      'март',
      'апрель',
      'май',
      'июнь',
      'июль',
      'август',
      'сентябрь',
      'октябрь',
      'ноябрь',
      'декабрь',
    ];
    return names[m];
  }
}

class _ToolsSection extends ConsumerWidget {
  const _ToolsSection({required this.items, required this.employeeUserId});
  final List<UserProfileTool> items;
  final String employeeUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SectionCard(
      icon: Icons.build_outlined,
      title: 'ИНСТРУМЕНТ ЗА СОТРУДНИКОМ',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (items.isEmpty)
            const Text(
              'Закреплённого инструмента нет',
              style: TextStyle(color: AppColors.n400),
            )
          else
            for (final t in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 6, color: AppColors.n300),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t.serial == null || t.serial!.isEmpty
                            ? t.name
                            : '${t.name} · ${t.serial}',
                        style: const TextStyle(color: AppColors.n900),
                      ),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: AppSpacing.x12),
          // NEWFIX-2 §9.2 — точка входа выдачи инструмента сотруднику.
          _AssignToolButton(employeeUserId: employeeUserId),
        ],
      ),
    );
  }
}

/// Кнопка «+ Выдать инструмент» — открывает sheet «Мои инструменты» и
/// после выбора вызывает POST /tools/:id/assign-to-employee. После выдачи
/// инвалидируем агрегат, чтобы список «Инструмент за сотрудником» обновился.
class _AssignToolButton extends ConsumerWidget {
  const _AssignToolButton({required this.employeeUserId});
  final String employeeUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Выдать инструмент'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brand,
          side: BorderSide(color: AppColors.brand.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.r12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: () => _showAssignSheet(context, ref, employeeUserId),
      ),
    );
  }
}

Future<void> _showAssignSheet(
  BuildContext context,
  WidgetRef ref,
  String employeeUserId,
) async {
  await showAppBottomSheet<void>(
    context: context,
    child: _AssignToolSheet(employeeUserId: employeeUserId),
  );
}

class _AssignToolSheet extends ConsumerWidget {
  const _AssignToolSheet({required this.employeeUserId});
  final String employeeUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_myToolsForAssignProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppBottomSheetHeader(title: 'Выдать инструмент'),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 360),
          child: async.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Не удалось загрузить: $e'),
            ),
            data: (tools) {
              if (tools.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Свободных инструментов нет.\n'
                    'Добавьте инструмент в «Мои инструменты» (Профиль).',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.n400),
                  ),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                itemCount: tools.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (_, i) {
                  final t = tools[i];
                  return Material(
                    color: AppColors.n50,
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.r12),
                      onTap: () async {
                        Navigator.of(context).pop();
                        final failure = await ref
                            .read(
                              // тут импорт tools controller внизу файла
                              _myToolsCtrlProvider.notifier,
                            )
                            .assignToEmployee(
                              toolId: t.id,
                              employeeUserId: employeeUserId,
                            );
                        if (!context.mounted) return;
                        if (failure != null) {
                          AppToast.show(
                            context,
                            message: failure.userMessage,
                            kind: AppToastKind.error,
                          );
                        } else {
                          AppToast.show(
                            context,
                            message: 'Инструмент выдан',
                            kind: AppToastKind.success,
                          );
                          // Перечитать профиль, чтобы список обновился.
                          ref.invalidate(
                            userProfileAggregateProvider(employeeUserId),
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.brandLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.build_outlined,
                                color: AppColors.brand,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.n800,
                                    ),
                                  ),
                                  if (t.serial != null && t.serial!.isNotEmpty)
                                    Text(
                                      'Серийный: ${t.serial}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.n500,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ReclamationsSection extends StatelessWidget {
  const _ReclamationsSection({required this.value});
  final UserProfileReclamations value;

  @override
  Widget build(BuildContext context) {
    final hasData = value.total > 0;
    return _SectionCard(
      icon: Icons.warning_amber_outlined,
      title: 'РЕКЛАМАЦИИ',
      child: hasData
          ? Text(
              '${value.completed} выполнено / ${value.total} всего',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.n900,
              ),
            )
          : const Text(
              'Рекламаций нет',
              style: TextStyle(color: AppColors.n400),
            ),
    );
  }
}

class _PayoutsSection extends StatelessWidget {
  const _PayoutsSection({required this.payouts});
  final UserProfilePayouts payouts;

  @override
  Widget build(BuildContext context) {
    if (!payouts.visible) {
      return _SectionCard(
        icon: Icons.account_balance_wallet_outlined,
        title: 'ВЫПЛАТЫ',
        child: const Text(
          'У вас нет доступа к этим выплатам',
          style: TextStyle(color: AppColors.n400),
        ),
      );
    }
    return _SectionCard(
      icon: Icons.account_balance_wallet_outlined,
      title: 'ВЫПЛАТЫ · ${_monthRu(DateTime.now().month).toUpperCase()}',
      child: payouts.byProject.isEmpty
          ? const Text(
              'Выплат за этот месяц не было',
              style: TextStyle(color: AppColors.n400),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final p in payouts.byProject)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            p.title,
                            style: const TextStyle(color: AppColors.n900),
                          ),
                        ),
                        Text(
                          Money.format(p.amount),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.n900,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Divider(height: 16),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Итого',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.n900,
                        ),
                      ),
                    ),
                    Text(
                      Money.format(payouts.monthTotal),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.greenDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  static String _monthRu(int m) {
    const names = [
      '',
      'январь',
      'февраль',
      'март',
      'апрель',
      'май',
      'июнь',
      'июль',
      'август',
      'сентябрь',
      'октябрь',
      'ноябрь',
      'декабрь',
    ];
    return names[m];
  }
}
