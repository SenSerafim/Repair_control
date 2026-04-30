import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';
import 'widgets/tour_anchor.dart';

/// Демо-экраны тура — статические виджеты, имитирующие реальные экраны
/// приложения. Не используют Riverpod-провайдеры, не делают сетевых
/// запросов — только визуально похожи на боевые экраны, чтобы пользователь
/// мог узнать их в реальном приложении после прохождения тура.
///
/// `TourAnchor` с нужным `id` обернут вокруг ключевого интерактивного
/// элемента — `TourOverlay` подсвечивает его и рисует bubble рядом.

// ─────────────────────── Общие компоненты ───────────────────────

class _MockHeader extends StatelessWidget {
  const _MockHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
      child: Row(
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: Icon(Icons.arrow_back_rounded, color: AppColors.n700),
          ),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.n900,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _MockChip extends StatelessWidget {
  const _MockChip({required this.text, required this.dotColor, required this.bg, required this.fg});

  final String text;
  final Color dotColor;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }
}

class _MockCard extends StatelessWidget {
  const _MockCard({required this.child, this.padding = const EdgeInsets.all(14)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        boxShadow: AppShadows.sh1,
      ),
      padding: padding,
      child: child,
    );
  }
}

Widget _bg(Widget child) => Container(color: AppColors.n100, child: child);

// ─────────────────────── 1. Console ───────────────────────

class TourMockConsoleScreen extends StatelessWidget {
  const TourMockConsoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _bg(
      SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _MockHeader(
                title: 'Ремонт на Ленинской',
                trailing: Icon(Icons.notifications_outlined, color: AppColors.n700),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _MockChip(
                  text: 'Отставание',
                  dotColor: AppColors.yellowDot,
                  bg: AppColors.yellowBg,
                  fg: AppColors.yellowText,
                ),
              ),
              const SizedBox(height: 16),
              // Прогресс-круг (упрощённо)
              Center(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.yellowDot, width: 8),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('38%', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
                        Text('Прогресс', style: TextStyle(fontSize: 12, color: AppColors.n500)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // NavGrid 2×3 — Этапы / Согласования / Команда / Чаты / Бюджет / Документы
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TourAnchor(
                            id: 'console.stages_tile',
                            child: _MockNavTile(
                              icon: Icons.bolt_rounded,
                              label: 'Этапы',
                              color: AppColors.brand,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: _MockNavTile(
                            icon: Icons.check_box_outlined,
                            label: 'Согласования',
                            color: AppColors.purple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: const [
                        Expanded(child: _MockNavTile(icon: Icons.people_outline, label: 'Команда', color: AppColors.greenDark)),
                        SizedBox(width: 8),
                        Expanded(child: _MockNavTile(icon: Icons.chat_bubble_outline, label: 'Чаты', color: AppColors.brand)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: const [
                        Expanded(child: _MockNavTile(icon: Icons.account_balance_wallet_outlined, label: 'Бюджет', color: AppColors.greenDark)),
                        SizedBox(width: 8),
                        Expanded(child: _MockNavTile(icon: Icons.description_outlined, label: 'Документы', color: AppColors.n600)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MockNavTile extends StatelessWidget {
  const _MockNavTile({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _MockCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.n900)),
        ],
      ),
    );
  }
}

// ─────────────────────── 2. Stages ───────────────────────

class TourMockStagesScreen extends StatelessWidget {
  const TourMockStagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stages = [
      const _StageRow(title: 'Демонтаж', subtitle: 'Готов', dotColor: AppColors.greenDot, progress: 1.0),
      const _StageRow(title: 'Электрика', subtitle: 'В работе · 65%', dotColor: AppColors.yellowDot, progress: 0.65),
      const _StageRow(title: 'Сантехника', subtitle: 'На паузе · 30%', dotColor: AppColors.yellowDot, progress: 0.30),
      const _StageRow(title: 'Стены и потолок', subtitle: 'Ожидает', dotColor: AppColors.n300, progress: 0),
      const _StageRow(title: 'Полы', subtitle: 'Ожидает', dotColor: AppColors.n300, progress: 0),
    ];
    return _bg(
      SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _MockHeader(title: 'Этапы'),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: stages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return TourAnchor(id: 'stages.first_stage_card', child: stages[i]);
                  }
                  return stages[i];
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageRow extends StatelessWidget {
  const _StageRow({required this.title, required this.subtitle, required this.dotColor, required this.progress});

  final String title;
  final String subtitle;
  final Color dotColor;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return _MockCard(
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.n900)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.n500)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: AppColors.n100,
                    valueColor: AlwaysStoppedAnimation(dotColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: AppColors.n400),
        ],
      ),
    );
  }
}

// ─────────────────────── 3. Stage Detail ───────────────────────

class TourMockStageDetailScreen extends StatelessWidget {
  const TourMockStageDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _bg(
      SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _MockHeader(title: 'Электрика'),
            // Tabs mock
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: AppColors.n0, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: const [
                  _MockTab(label: 'Чек-лист', active: true),
                  _MockTab(label: 'Согласования'),
                  _MockTab(label: 'Чат'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  TourAnchor(
                    id: 'stage_detail.first_step',
                    child: _MockStep(title: 'Прокладка кабелей', subtitle: '4/4 подшага · 8 фото', done: true),
                  ),
                  const SizedBox(height: 8),
                  const _MockStep(title: 'Установка подрозетников', subtitle: 'В работе · 3/3', done: false, active: true),
                  const SizedBox(height: 8),
                  const _MockStep(title: 'Установка выключателей', subtitle: 'Ожидает', done: false),
                  const SizedBox(height: 8),
                  const _MockStep(title: 'Подключение щитка', subtitle: 'Ожидает', done: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MockTab extends StatelessWidget {
  const _MockTab({required this.label, this.active = false});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.brand : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? AppColors.n0 : AppColors.n500,
          ),
        ),
      ),
    );
  }
}

class _MockStep extends StatelessWidget {
  const _MockStep({required this.title, required this.subtitle, required this.done, this.active = false});

  final String title;
  final String subtitle;
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = done
        ? AppColors.greenDark
        : active
            ? AppColors.brand
            : AppColors.n300;
    return _MockCard(
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: done ? AppColors.greenDark : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: done ? const Icon(Icons.check, size: 16, color: AppColors.n0) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.n900)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.n500)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.n400),
        ],
      ),
    );
  }
}

// ─────────────────────── 4. Step Detail ───────────────────────

class TourMockStepDetailScreen extends StatelessWidget {
  const TourMockStepDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _bg(
      SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _MockHeader(title: 'Установка подрозетников'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  // Photos grid
                  _MockCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Фото', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.n700)),
                        const SizedBox(height: 8),
                        Row(
                          children: List.generate(
                            3,
                            (_) => Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppColors.n200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.image_outlined, color: AppColors.n500),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Substeps
                  _MockCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Чек-лист', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.n700)),
                        SizedBox(height: 8),
                        _MockSubstep(text: 'Разметить положение'),
                        _MockSubstep(text: 'Высверлить отверстия'),
                        _MockSubstep(text: 'Закрепить алебастром'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TourAnchor(
                    id: 'step_detail.complete_button',
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.brand,
                        borderRadius: BorderRadius.circular(AppRadius.r16),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Отметить готовым',
                        style: TextStyle(color: AppColors.n0, fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MockSubstep extends StatelessWidget {
  const _MockSubstep({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.greenDark, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.n800))),
        ],
      ),
    );
  }
}

// ─────────────────────── 5. Approvals ───────────────────────

class TourMockApprovalsScreen extends StatelessWidget {
  const TourMockApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _bg(
      SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _MockHeader(title: 'Согласования'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: AppColors.n0, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: const [
                  _MockTab(label: 'Активные · 1', active: true),
                  _MockTab(label: 'История · 2'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  TourAnchor(
                    id: 'approvals.first_approval',
                    child: const _MockApproval(
                      title: 'Доп.работы',
                      subtitle: 'Дополнительная розеточная группа',
                      amount: '+ 22 000 ₽',
                      statusText: 'Ожидает решения',
                      statusColor: AppColors.brand,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MockApproval extends StatelessWidget {
  const _MockApproval({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.statusText,
    required this.statusColor,
  });

  final String title;
  final String subtitle;
  final String amount;
  final String statusText;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return _MockCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.n900))),
              Text(amount, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.brand)),
            ],
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.n500)),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(statusText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────── 6. Approval Detail ───────────────────────

class TourMockApprovalDetailScreen extends StatelessWidget {
  const TourMockApprovalDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _bg(
      SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _MockHeader(title: 'Доп. работы'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  _MockCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        _LabeledRow(label: 'Этап', value: 'Электрика'),
                        SizedBox(height: 8),
                        _LabeledRow(label: 'Тип', value: 'Доп. работы'),
                        SizedBox(height: 8),
                        _LabeledRow(label: 'Сумма', value: '+ 22 000 ₽'),
                        SizedBox(height: 12),
                        Text('Причина', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.n700)),
                        SizedBox(height: 4),
                        Text(
                          'Заказчик решил поставить варочную панель на 7 кВт. Нужна отдельная розеточная группа.',
                          style: TextStyle(fontSize: 13, color: AppColors.n800, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Bottom actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.n0,
                        border: Border.all(color: AppColors.redBg, width: 1),
                        borderRadius: BorderRadius.circular(AppRadius.r16),
                      ),
                      alignment: Alignment.center,
                      child: const Text('Отклонить', style: TextStyle(color: AppColors.redText, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TourAnchor(
                      id: 'approval_detail.approve_button',
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.greenDark,
                          borderRadius: BorderRadius.circular(AppRadius.r16),
                        ),
                        alignment: Alignment.center,
                        child: const Text('Одобрить', style: TextStyle(color: AppColors.n0, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledRow extends StatelessWidget {
  const _LabeledRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.n500)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.n900)),
      ],
    );
  }
}

// ─────────────────────── 7. Budget ───────────────────────

class TourMockBudgetScreen extends StatelessWidget {
  const TourMockBudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _bg(
      SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _MockHeader(title: 'Бюджет'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TourAnchor(
                id: 'budget.payments_tab',
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: AppColors.n0, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: const [
                      _MockTab(label: 'Платежи', active: true),
                      _MockTab(label: 'Этапы'),
                      _MockTab(label: 'Материалы'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  _MockCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Общий бюджет', style: TextStyle(fontSize: 13, color: AppColors.n500)),
                        const SizedBox(height: 4),
                        const Text('1 500 000 ₽', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.n900)),
                        const SizedBox(height: 16),
                        const _BudgetRow(label: 'Работы', spent: '285 000 ₽', total: '850 000 ₽', progress: 0.34, color: AppColors.brand),
                        const SizedBox(height: 12),
                        const _BudgetRow(label: 'Материалы', spent: '195 000 ₽', total: '650 000 ₽', progress: 0.30, color: AppColors.purple),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({required this.label, required this.spent, required this.total, required this.progress, required this.color});

  final String label;
  final String spent;
  final String total;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.n800)),
            const Spacer(),
            Text('$spent / $total', style: const TextStyle(fontSize: 12, color: AppColors.n500)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.n100,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────── 8. Payments ───────────────────────

class TourMockPaymentsScreen extends StatelessWidget {
  const TourMockPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _bg(
      SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _MockHeader(title: 'Платежи'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  TourAnchor(
                    id: 'payments_list.first_payment',
                    child: const _PaymentRow(
                      title: 'Аванс на электрику',
                      from: 'Заказчик',
                      to: 'Бригадир',
                      amount: '200 000 ₽',
                      status: 'Подтверждён',
                      statusColor: AppColors.greenDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const _PaymentRow(
                    title: 'Прокладка кабелей',
                    from: 'Бригадир',
                    to: 'Мастер',
                    amount: '95 000 ₽',
                    status: 'Подтверждён',
                    statusColor: AppColors.greenDark,
                  ),
                  const SizedBox(height: 8),
                  const _PaymentRow(
                    title: 'Аванс на сантехнику',
                    from: 'Заказчик',
                    to: 'Бригадир',
                    amount: '80 000 ₽',
                    status: 'Ожидает подтверждения',
                    statusColor: AppColors.yellowDot,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.title,
    required this.from,
    required this.to,
    required this.amount,
    required this.status,
    required this.statusColor,
  });

  final String title;
  final String from;
  final String to;
  final String amount;
  final String status;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return _MockCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.n900))),
              Text(amount, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.brand)),
            ],
          ),
          const SizedBox(height: 6),
          Text('$from → $to', style: const TextStyle(fontSize: 12, color: AppColors.n500)),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────── 9. Materials ───────────────────────

class TourMockMaterialsScreen extends StatelessWidget {
  const TourMockMaterialsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _bg(
      SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _MockHeader(title: 'Материалы'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  TourAnchor(
                    id: 'materials.first_request',
                    child: const _MaterialRow(
                      title: 'Кабель и подрозетники',
                      stage: 'Электрика',
                      itemsBought: 2,
                      itemsTotal: 2,
                      status: 'Доставлено',
                      statusColor: AppColors.greenDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const _MaterialRow(
                    title: 'Сантехника: трубы и фитинги',
                    stage: 'Сантехника',
                    itemsBought: 0,
                    itemsTotal: 4,
                    status: 'Открыто',
                    statusColor: AppColors.brand,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MaterialRow extends StatelessWidget {
  const _MaterialRow({
    required this.title,
    required this.stage,
    required this.itemsBought,
    required this.itemsTotal,
    required this.status,
    required this.statusColor,
  });

  final String title;
  final String stage;
  final int itemsBought;
  final int itemsTotal;
  final String status;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return _MockCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.n900)),
          const SizedBox(height: 4),
          Text(stage, style: const TextStyle(fontSize: 12, color: AppColors.n500)),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('$itemsBought / $itemsTotal куплено', style: const TextStyle(fontSize: 12, color: AppColors.n600)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────── 10. Chats ───────────────────────

class TourMockChatsScreen extends StatelessWidget {
  const TourMockChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _bg(
      SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _MockHeader(title: 'Чаты'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  TourAnchor(
                    id: 'chats.first_chat',
                    child: const _ChatRow(
                      avatarText: 'РЛ',
                      name: 'Общий чат проекта',
                      lastMessage: 'Завтра привезут материалы. Принимать будете?',
                      time: '5 мин',
                      unread: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const _ChatRow(
                    avatarText: 'ИМ',
                    name: 'Иван Мастер',
                    lastMessage: 'Принял, выезжаю.',
                    time: '7 ч',
                    unread: 0,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatRow extends StatelessWidget {
  const _ChatRow({
    required this.avatarText,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.unread,
  });

  final String avatarText;
  final String name;
  final String lastMessage;
  final String time;
  final int unread;

  @override
  Widget build(BuildContext context) {
    return _MockCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: AppColors.brand, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(avatarText, style: const TextStyle(color: AppColors.n0, fontSize: 14, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.n900))),
                    Text(time, style: const TextStyle(fontSize: 11, color: AppColors.n500)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.n600),
                      ),
                    ),
                    if (unread > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: const BoxDecoration(color: AppColors.brand, shape: BoxShape.circle),
                        child: Text('$unread', style: const TextStyle(color: AppColors.n0, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────── 11. Chat Conversation ───────────────────────

class TourMockChatConversationScreen extends StatelessWidget {
  const TourMockChatConversationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _bg(
      SafeArea(
        child: Column(
          children: [
            const _MockHeader(title: 'Общий чат проекта'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                children: const [
                  _MockMsg(text: 'Добрый день! Как продвигается электрика?', mine: false, author: 'Заказчик'),
                  _MockMsg(text: 'Кабели проложили, ставим подрозетники. Завтра пришлю фото.', mine: true, author: 'Вы (бригадир)'),
                  _MockMsg(text: 'Отлично! Спасибо.', mine: false, author: 'Заказчик'),
                  _MockMsg(text: 'Завтра привезут материалы. Принимать будете?', mine: true, author: 'Вы (бригадир)'),
                ],
              ),
            ),
            // Input
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: TourAnchor(
                id: 'chat_conversation.input',
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.n0,
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                    border: Border.all(color: AppColors.n200),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.centerLeft,
                  child: const Text('Сообщение…', style: TextStyle(color: AppColors.n400, fontSize: 14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MockMsg extends StatelessWidget {
  const _MockMsg({required this.text, required this.mine, required this.author});

  final String text;
  final bool mine;
  final String author;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          child: Column(
            crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(author, style: const TextStyle(fontSize: 11, color: AppColors.n500)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: mine ? AppColors.brand : AppColors.n0,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: mine ? null : AppShadows.sh1,
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 13,
                    color: mine ? AppColors.n0 : AppColors.n900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────── 12. Notifications ───────────────────────

class TourMockNotificationsScreen extends StatelessWidget {
  const TourMockNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _bg(
      SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _MockHeader(title: 'Уведомления'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  TourAnchor(
                    id: 'notifications.first_item',
                    child: const _NotifRow(
                      icon: Icons.check_box_outlined,
                      iconColor: AppColors.purple,
                      title: 'Новое согласование',
                      body: 'Бригадир просит одобрить доп. работы — 22 000 ₽',
                      time: '5 мин',
                      unread: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const _NotifRow(
                    icon: Icons.task_alt_rounded,
                    iconColor: AppColors.greenDark,
                    title: 'Шаг готов',
                    body: 'Установка подрозетников отмечена как готовая',
                    time: '3 ч',
                    unread: true,
                  ),
                  const SizedBox(height: 8),
                  const _NotifRow(
                    icon: Icons.account_balance_wallet,
                    iconColor: AppColors.greenDark,
                    title: 'Платёж подтверждён',
                    body: 'Аванс 200 000 ₽ зачислен',
                    time: 'Вчера',
                    unread: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotifRow extends StatelessWidget {
  const _NotifRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.time,
    required this.unread,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final String time;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    return _MockCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                          color: AppColors.n900,
                        ),
                      ),
                    ),
                    Text(time, style: const TextStyle(fontSize: 11, color: AppColors.n500)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(fontSize: 12, color: AppColors.n600, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
