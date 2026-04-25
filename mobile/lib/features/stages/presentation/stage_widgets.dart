import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/status_pill.dart';
import '../domain/stage.dart';
import '../domain/traffic_light.dart';

/// Расширенный StageStatus: включает 2 computed-состояния из ТЗ §2.4.
enum StageDisplayStatus {
  pending,
  active,
  paused,
  review,
  done,
  rejected,
  overdue, // computed: plannedEnd прошёл, но не done
  lateStart; // computed: pending + plannedStart прошёл

  String get displayName => switch (this) {
        StageDisplayStatus.pending => 'Ожидает',
        StageDisplayStatus.active => 'В работе',
        StageDisplayStatus.paused => 'На паузе',
        StageDisplayStatus.review => 'На приёмке',
        StageDisplayStatus.done => 'Завершён',
        StageDisplayStatus.rejected => 'Отклонён',
        StageDisplayStatus.overdue => 'Просрочен',
        StageDisplayStatus.lateStart => 'Опоздал со стартом',
      };

  Semaphore get semaphore => switch (this) {
        StageDisplayStatus.pending => Semaphore.plan,
        StageDisplayStatus.active => Semaphore.green,
        StageDisplayStatus.paused => Semaphore.yellow,
        StageDisplayStatus.review => Semaphore.blue,
        StageDisplayStatus.done => Semaphore.green,
        StageDisplayStatus.rejected => Semaphore.red,
        StageDisplayStatus.overdue => Semaphore.red,
        StageDisplayStatus.lateStart => Semaphore.red,
      };

  /// Полная формула ТЗ §2.4: делегирует [computeTrafficLight] для
  /// определения «цветовой ветки» и докручивает её до конкретного
  /// `StageDisplayStatus` (нужен для текста badge'а и логики CTA).
  static StageDisplayStatus of(Stage s, {DateTime? now}) {
    final when = now ?? DateTime.now();
    final base = s.status;
    if (base == StageStatus.done) return StageDisplayStatus.done;
    if (base == StageStatus.rejected) return StageDisplayStatus.rejected;
    if (base == StageStatus.paused) return StageDisplayStatus.paused;
    if (base == StageStatus.review) return StageDisplayStatus.review;

    // lateStart важнее overdue — он сигнализирует «не нажали Старт»,
    // в то время как overdue говорит о просрочке уже работающего этапа.
    if (s.isLateStart(when)) return StageDisplayStatus.lateStart;
    if (s.plannedEnd != null && s.plannedEnd!.isBefore(when)) {
      return StageDisplayStatus.overdue;
    }
    return base == StageStatus.active
        ? StageDisplayStatus.active
        : StageDisplayStatus.pending;
  }

  /// Цветовая ветка светофора по ТЗ §2.4 (для banner'ов и progress-bars).
  TrafficLight get trafficLight => switch (this) {
        StageDisplayStatus.pending => TrafficLight.grey,
        StageDisplayStatus.active => TrafficLight.green,
        StageDisplayStatus.paused => TrafficLight.yellow,
        StageDisplayStatus.review => TrafficLight.blue,
        StageDisplayStatus.done => TrafficLight.green,
        StageDisplayStatus.rejected => TrafficLight.red,
        StageDisplayStatus.overdue => TrafficLight.red,
        StageDisplayStatus.lateStart => TrafficLight.red,
      };
}

class StageStatusBadge extends StatelessWidget {
  const StageStatusBadge({required this.display, super.key});

  final StageDisplayStatus display;

  @override
  Widget build(BuildContext context) {
    return StatusPill(
      label: display.displayName,
      semaphore: display.semaphore,
    );
  }
}

/// Карточка этапа. Используется в tile-view и list-view (разные layout'ы).
class StageCard extends StatelessWidget {
  const StageCard({
    required this.stage,
    required this.onTap,
    this.showDragHandle = false,
    this.index,
    super.key,
  });

  final Stage stage;
  final VoidCallback onTap;
  final bool showDragHandle;

  /// Номер этапа (1-based) в списке для display.
  final int? index;

  @override
  Widget build(BuildContext context) {
    final display = StageDisplayStatus.of(stage);
    final progress = (stage.progressCache / 100).clamp(0.0, 1.0);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Hero(
        tag: 'stage-${stage.id}',
        flightShuttleBuilder: (_, __, dir, fromCtx, toCtx) {
          final hero =
              (dir == HeroFlightDirection.push ? fromCtx : toCtx).widget
                  as Hero;
          return hero.child;
        },
        child: Material(
          color: Colors.transparent,
          child: Container(
        decoration: BoxDecoration(
          color: AppColors.n0,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.n200, width: 1.5),
          boxShadow: AppShadows.sh1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: display.semaphore.dot,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.r16),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (index != null) ...[
                        _NumberBadge(
                          index: index!,
                          semaphore: display.semaphore,
                        ),
                        const SizedBox(width: AppSpacing.x10),
                      ],
                      Expanded(
                        child: Text(
                          stage.title,
                          style: AppTextStyles.h2,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (showDragHandle)
                        const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Icon(
                            Icons.drag_handle_rounded,
                            color: AppColors.n400,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.x8),
                  Row(
                    children: [
                      StageStatusBadge(display: display),
                      const SizedBox(width: AppSpacing.x8),
                      Expanded(
                        child: Text(
                          _dates(stage),
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${stage.progressCache}%',
                        style: AppTextStyles.caption.copyWith(
                          color: display.semaphore.text,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.x8),
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.n100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: display.semaphore.dot,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
          ),
        ),
    );
  }

  static String _dates(Stage s) {
    String fmt(DateTime d) => DateFormat('d MMM', 'ru').format(d);
    final start = s.plannedStart == null ? '—' : fmt(s.plannedStart!);
    final end = s.plannedEnd == null ? '—' : fmt(s.plannedEnd!);
    return '$start → $end';
  }
}

class _NumberBadge extends StatelessWidget {
  const _NumberBadge({required this.index, required this.semaphore});

  final int index;
  final Semaphore semaphore;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: semaphore.bg,
        borderRadius: BorderRadius.circular(AppRadius.r8),
      ),
      child: Text(
        '$index',
        style: AppTextStyles.micro.copyWith(color: semaphore.text),
      ),
    );
  }
}

/// Компактная tile-карточка (для 2-col grid).
class StageTile extends StatelessWidget {
  const StageTile({
    required this.stage,
    required this.index,
    required this.onTap,
    super.key,
  });

  final Stage stage;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final display = StageDisplayStatus.of(stage);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.x12),
        decoration: BoxDecoration(
          color: AppColors.n0,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.n200, width: 1.5),
          boxShadow: AppShadows.sh1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _NumberBadge(index: index, semaphore: display.semaphore),
                const Spacer(),
                Text(
                  '${stage.progressCache}%',
                  style: AppTextStyles.caption.copyWith(
                    color: display.semaphore.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x10),
            Text(
              stage.title,
              style: AppTextStyles.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.x8),
            StageStatusBadge(display: display),
            const SizedBox(height: AppSpacing.x8),
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.n100,
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (stage.progressCache / 100).clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: display.semaphore.dot,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
