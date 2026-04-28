import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/faq_controller.dart';

/// s-faq-detail — статья FAQ. Если id — `semaphore`/`how_traffic_light`,
/// рендерим спец-блоки 4 цветов (зелёный/жёлтый/красный/синий) согласно
/// дизайну. Иначе показываем простой текст.
class FaqDetailScreen extends ConsumerWidget {
  const FaqDetailScreen({required this.itemId, super.key});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(faqItemProvider(itemId));

    return AppScaffold(
      showBack: true,
      title: 'Помощь',
      backgroundColor: AppColors.n50,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
      body: async.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить статью',
          subtitle: e.toString(),
          onRetry: () => ref.invalidate(faqItemProvider(itemId)),
        ),
        data: (item) => ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.x20),
          children: [
            Text(
              item.question,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.n800,
                letterSpacing: -0.3,
                height: 1.3,
              ),
            ),
            const SizedBox(height: AppSpacing.x16),
            if (_isSemaphoreTopic(item.question)) ...[
              Text(
                item.answer,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.n600,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: AppSpacing.x20),
              const _SemaphoreBlock(
                color: Color(0xFFECFDF5),
                iconColor: AppColors.greenDark,
                icon: PhosphorIconsFill.checkCircle,
                title: 'Зелёный — по графику',
                description:
                    'Все шаги активного этапа выполняются вовремя, дедлайны '
                    'не нарушены, нет открытых споров.',
              ),
              SizedBox(height: AppSpacing.x10),
              _SemaphoreBlock(
                color: Color(0xFFFFFBEB),
                iconColor: AppColors.yellowText,
                icon: PhosphorIconsFill.warning,
                title: 'Жёлтый — отставание',
                description:
                    'Один или несколько шагов отстают от плана, но дедлайн '
                    'этапа ещё не нарушен. Стоит ускориться.',
              ),
              SizedBox(height: AppSpacing.x10),
              _SemaphoreBlock(
                color: Color(0xFFFEF2F2),
                iconColor: AppColors.redDot,
                icon: PhosphorIconsFill.xCircle,
                title: 'Красный — просрочка',
                description:
                    'Дедлайн этапа нарушен или есть открытый спор по '
                    'выплате/материалам. Требуется вмешательство.',
              ),
              SizedBox(height: AppSpacing.x10),
              _SemaphoreBlock(
                color: Color(0xFFEFF6FF),
                iconColor: AppColors.brand,
                icon: PhosphorIconsFill.clock,
                title: 'Синий — ждёт действия',
                description:
                    'Этап ждёт согласования заказчиком, бригадира или '
                    'отправки материалов. Видим, чьего хода ждём.',
              ),
            ] else
              Text(
                item.answer,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.n600,
                  height: 1.7,
                ),
              ),
            const SizedBox(height: AppSpacing.x40),
          ],
        ),
      ),
    );
  }

  bool _isSemaphoreTopic(String question) {
    final q = question.toLowerCase();
    return q.contains('светофор');
  }
}

class _SemaphoreBlock extends StatelessWidget {
  const _SemaphoreBlock({
    required this.color,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.description,
  });

  final Color color;
  final Color iconColor;
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.r16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: AppSpacing.x10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.n800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.n600,
                    height: 1.55,
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
