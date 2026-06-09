import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/tools_controller.dart';
import '../domain/tool.dart';

/// Task 6.2: отдельный экран «История инструмента» — full-screen timeline всех
/// событий передачи (custody handover). Доступен из меню в `MyToolsScreen` и
/// из шапки `ToolDetailScreen` через route `/tools/:toolId/history?name=...`.
///
/// Зачем отдельно от tool_detail_screen: на детали отображается компактный
/// timeline только когда инструмент в проекте; здесь — полный список с
/// поиском «когда был у кого-то» и пустым/error-состоянием на ровном фоне.
class ToolCustodyHistoryScreen extends ConsumerWidget {
  const ToolCustodyHistoryScreen({
    required this.toolId,
    this.toolName = '',
    super.key,
  });

  final String toolId;

  /// Имя инструмента — передаётся через ?name=... query, чтобы избежать
  /// дополнительного GET /api/tools/:id ради одной строки в шапке.
  final String toolName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(toolCustodyHistoryProvider(toolId));

    return AppScaffold(
      showBack: true,
      title: 'История инструмента',
      backgroundColor: AppColors.n50,
      padding: EdgeInsets.zero,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (toolName.isNotEmpty) _SubtitleBar(name: toolName),
          Expanded(
            child: async.when(
              loading: () => const AppLoadingState(),
              error: (_, __) => AppErrorState(
                title: 'Не удалось загрузить историю',
                subtitle:
                    'Проверьте подключение и попробуйте ещё раз. '
                    'Если повторится — напишите в поддержку.',
                onRetry: () =>
                    ref.invalidate(toolCustodyHistoryProvider(toolId)),
              ),
              data: (events) {
                if (events.isEmpty) {
                  return const AppEmptyState(
                    title: 'Нет истории',
                    subtitle:
                        'Этот инструмент ещё не передавался между '
                        'участниками проекта.',
                    icon: PhosphorIconsRegular.clockCounterClockwise,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(toolCustodyHistoryProvider(toolId));
                    // Дожидаемся завершения нового запроса, чтобы spinner
                    // не пропадал раньше времени.
                    await ref.read(
                      toolCustodyHistoryProvider(toolId).future,
                    );
                  },
                  child: ListView.separated(
                    key: const ValueKey('tool_custody_history_list'),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.x16,
                      AppSpacing.x12,
                      AppSpacing.x16,
                      AppSpacing.x24,
                    ),
                    itemCount: events.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.x10),
                    itemBuilder: (_, i) => _EventCard(event: events[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SubtitleBar extends StatelessWidget {
  const _SubtitleBar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x16,
        AppSpacing.x8,
        AppSpacing.x16,
        AppSpacing.x12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.n0,
        border: Border(
          bottom: BorderSide(color: AppColors.n100),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.brandLight,
              borderRadius: BorderRadius.circular(AppRadius.r12),
            ),
            child: const Icon(
              PhosphorIconsFill.wrench,
              size: 18,
              color: AppColors.brand,
            ),
          ),
          const SizedBox(width: AppSpacing.x12),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.n800,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final ToolCustodyEvent event;

  static final DateFormat _df = DateFormat('dd.MM.yyyy HH:mm');

  String _holderLabel(PublicUser? user, String fallbackId) {
    if (user != null) return user.displayName;
    // Fallback: ровно 6 первых символов id, чтобы не пугать пользователя
    // длинным uuid. TODO: подключить users-provider при доработке.
    if (fallbackId.length > 6) return '#${fallbackId.substring(0, 6)}';
    return '#$fallbackId';
  }

  @override
  Widget build(BuildContext context) {
    final isInitial = event.isInitial;
    final holder = _holderLabel(event.holder, event.holderId);
    final prev = event.previousHolderId == null
        ? null
        : _holderLabel(event.previousHolder, event.previousHolderId!);

    final headline = isInitial
        ? 'Добавлен в проект'
        : (prev != null ? '$prev  →  $holder' : 'Перешёл к $holder');
    final dotColor = isInitial ? AppColors.brand : AppColors.greenDark;
    final badgeBg = isInitial ? AppColors.brandLight : AppColors.greenLight;
    final badgeColor = isInitial ? AppColors.brand : AppColors.greenDark;
    final badgeLabel = isInitial ? 'СТАРТ' : 'ПЕРЕДАЧА';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.n100),
        boxShadow: AppShadows.sh1,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        badgeLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: badgeColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _df.format(event.createdAt.toLocal()),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.n400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.x8),
                Text(
                  headline,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.n800,
                    letterSpacing: -0.1,
                  ),
                ),
                if (isInitial)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'у ${_holderLabel(event.holder, event.holderId)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.n500,
                      ),
                    ),
                  ),
                if (event.note != null && event.note!.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.x6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.x10),
                    decoration: BoxDecoration(
                      color: AppColors.n50,
                      borderRadius: BorderRadius.circular(AppRadius.r12),
                    ),
                    child: Text(
                      '«${event.note}»',
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppColors.n600,
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
