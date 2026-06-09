import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/status_pill.dart';
import '../domain/project.dart';

/// Карточка проекта. Соответствует .card из `design/Кластер B — Проекты.html`.
/// Верхняя полоса (card-top ::before) — 3px accentBar по semaphore.
/// + alert-banner поверх card-top на синих/красных карточках.
class ProjectCard extends StatelessWidget {
  const ProjectCard({
    required this.project,
    this.onTap,
    this.onMenu,
    super.key,
  });

  final Project project;
  final VoidCallback? onTap;
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    final banner = _bannerFor(project);
    final progress = (project.progressCache / 100).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.n0,
            borderRadius: BorderRadius.circular(AppRadius.r20),
            border: Border.all(
              color: banner?.borderColor ?? AppColors.n200,
            ),
            boxShadow: AppShadows.sh2,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.r20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(height: 3, color: project.semaphore.dot),
                if (banner != null) _AlertBanner(spec: banner),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              project.title,
                              style: AppTextStyles.h2,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // NEWFIX-2 §19 — точка входа «Заметки проекта»
                          // прямо с карточки в списке (рядом с ⋮). Раньше
                          // иконка жила только в шапке открытой консоли —
                          // спека требует доступ из списка.
                          IconButton(
                            icon: const Icon(
                              PhosphorIconsRegular.note,
                              size: 20,
                            ),
                            tooltip: 'Заметки проекта',
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.all(AppSpacing.x6),
                            constraints: const BoxConstraints(),
                            color: AppColors.n400,
                            onPressed: () => context.push(
                              '/projects/${project.id}/notes',
                            ),
                          ),
                          if (onMenu != null)
                            GestureDetector(
                              onTap: onMenu,
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.x6),
                                child: Icon(
                                  PhosphorIconsRegular.dotsThreeVertical,
                                  color: AppColors.n400,
                                  size: 20,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (project.address != null &&
                          project.address!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.x6),
                        Row(
                          children: [
                            Icon(
                              PhosphorIconsRegular.mapPin,
                              size: 12,
                              color: AppColors.n400,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                project.address!,
                                style: AppTextStyles.caption,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      // NEWFIX §1 — мини-дашборд: до дедлайна · этапы
                      // done/total · сколько «в работе». Карточка в списке
                      // не подтягивает этапы (только /projects), поэтому
                      // 2 из 3 счётчиков рендерим как `—` с TODO — ждём
                      // расширения payload или отдельного агрегата.
                      const SizedBox(height: AppSpacing.x8),
                      _MiniDashboardRow(project: project),
                      const SizedBox(height: AppSpacing.x10),
                      Row(
                        children: [
                          StatusPill(
                            label: project.semaphoreLabel,
                            semaphore: project.semaphore,
                          ),
                          const SizedBox(width: AppSpacing.x8),
                          Expanded(
                            child: Text(
                              _datesLabel(project),
                              style: AppTextStyles.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.x8),
                      Row(
                        children: [
                          Expanded(
                            child: _ProgressBar(
                              value: progress,
                              semaphore: project.semaphore,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.x10),
                          Text(
                            '${project.progressCache}%',
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.n700,
                            ),
                          ),
                        ],
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

  static String _datesLabel(Project p) {
    final df = DateFormat('d MMM', 'ru');
    final start = p.plannedStart == null ? '—' : df.format(p.plannedStart!);
    final end = p.plannedEnd == null ? '—' : df.format(p.plannedEnd!);
    return '$start — $end';
  }

  static _BannerSpec? _bannerFor(Project p) {
    if (p.isArchived || p.progressCache >= 100) return null;
    if (p.plannedEnd != null && p.semaphore == Semaphore.red) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final due = DateTime(
        p.plannedEnd!.year,
        p.plannedEnd!.month,
        p.plannedEnd!.day,
      );
      final overdue = today.difference(due).inDays;
      if (overdue > 0) {
        return _BannerSpec(
          icon: PhosphorIconsRegular.warningCircle,
          text: 'Дедлайн просрочен на $overdue ${_pluralizeDays(overdue)}',
          bg: const Color(0xFFFEE2E2),
          textColor: const Color(0xFF991B1B),
          borderColor: const Color(0xFFFCA5A5),
        );
      }
    }
    if (p.semaphore == Semaphore.blue) {
      return const _BannerSpec(
        icon: PhosphorIconsRegular.bellRinging,
        text: 'Есть согласования, ждущие вашего решения',
        bg: Color(0xFFFED7AA),
        textColor: Color(0xFF7C2D12),
        borderColor: Color(0xFFFDBA74),
      );
    }
    return null;
  }

  static String _pluralizeDays(int n) {
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod10 == 1 && mod100 != 11) return 'день';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return 'дня';
    return 'дней';
  }
}

class _BannerSpec {
  const _BannerSpec({
    required this.icon,
    required this.text,
    required this.bg,
    required this.textColor,
    required this.borderColor,
  });

  final IconData icon;
  final String text;
  final Color bg;
  final Color textColor;
  final Color borderColor;
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.spec});

  final _BannerSpec spec;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: spec.bg,
      child: Row(
        children: [
          Icon(spec.icon, size: 14, color: spec.textColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              spec.text,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: spec.textColor,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Прогресс-бар с градиентной заливкой по светофору (HTML
/// `.prog-fill-green/yellow/red/blue`). На 0% показываем тонкую
/// pill-затравку, чтобы дорожка не выглядела «пустой/сломанной».
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value, required this.semaphore});

  final double value;
  final Semaphore semaphore;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, c) {
        final fillW = (c.maxWidth * clamped).clamp(8.0, c.maxWidth);
        final gradient = _gradientFor(semaphore);
        return Container(
          height: 5,
          decoration: BoxDecoration(
            color: AppColors.n100,
            borderRadius: BorderRadius.circular(3),
          ),
          alignment: Alignment.centerLeft,
          child: Container(
            width: fillW,
            decoration: BoxDecoration(
              gradient: gradient,
              color: gradient == null ? _solidFor(semaphore) : null,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      },
    );
  }

  static LinearGradient? _gradientFor(Semaphore s) => switch (s) {
    Semaphore.green => const LinearGradient(
      colors: [Color(0xFF34D399), Color(0xFF059669)],
    ),
    Semaphore.yellow => const LinearGradient(
      colors: [Color(0xFFFEF08A), Color(0xFFFBBF24)],
    ),
    Semaphore.blue => const LinearGradient(
      colors: [AppColors.brandMid, AppColors.brand],
    ),
    Semaphore.red => null,
    Semaphore.plan => const LinearGradient(
      colors: [AppColors.brandMid, AppColors.brand],
    ),
  };

  static Color _solidFor(Semaphore s) => switch (s) {
    Semaphore.red => AppColors.redDot,
    _ => AppColors.brand,
  };
}

/// NEWFIX §1 — мини-дашборд под адресом карточки проекта.
///
/// 3 ячейки:
///   • дни до дедлайна (из `project.plannedEnd`),
///   • этапы done/total — TODO: пока `—` (Project payload не несёт счётчики этапов),
///   • этапов «в работе»  — TODO: пока `—` (то же).
///
/// Когда бэкенд расширит `/projects` или появится агрегат-провайдер,
/// замените `—` на реальные значения. Сейчас компонент даёт визуальный
/// якорь и сохраняет контракт верстки (`Row` с 3 stats).
class _MiniDashboardRow extends StatelessWidget {
  const _MiniDashboardRow({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final daysToDeadline = project.plannedEnd
        ?.difference(DateTime.now())
        .inDays;
    final isOverdue = daysToDeadline != null && daysToDeadline < 0;

    final String daysLabel;
    if (daysToDeadline == null) {
      daysLabel = '—';
    } else if (daysToDeadline >= 0) {
      // Кириллица «д» — валидный identifier char в Dart, поэтому
      // оборачиваем подстановку в `${...}`, иначе парсер съест букву.
      // ignore: unnecessary_brace_in_string_interps
      daysLabel = '${daysToDeadline}д';
    } else {
      daysLabel = '${daysToDeadline.abs()}д просрочено';
    }

    return Row(
      children: [
        _CardStat(
          icon: PhosphorIconsRegular.calendar,
          value: daysLabel,
          color: isOverdue ? AppColors.redDot : null,
        ),
        const SizedBox(width: AppSpacing.x12),
        // TODO(newfix-§1): подставить project.stagesDone / project.stagesTotal,
        // когда payload `/projects` начнёт их отдавать (или появится
        // агрегатный провайдер). Сейчас — заглушка `—/—`.
        const _CardStat(
          icon: PhosphorIconsRegular.listChecks,
          value: '—/—',
        ),
        const SizedBox(width: AppSpacing.x12),
        // TODO(newfix-§1): подставить project.stagesInProgress, см. выше.
        const _CardStat(
          icon: PhosphorIconsRegular.gear,
          value: '— в работе',
        ),
      ],
    );
  }
}

class _CardStat extends StatelessWidget {
  const _CardStat({required this.icon, required this.value, this.color});

  final IconData icon;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color ?? AppColors.n400),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color ?? AppColors.n600,
          ),
        ),
      ],
    );
  }
}
