import 'package:flutter/material.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/widgets.dart';

/// Bottom-sheet выбора периода для бюджет-материалов (e-date-picker):
/// 4 quick-preset chip + 2 date-input + reset/apply.
class DateRange {
  const DateRange({this.from, this.to});
  final DateTime? from;
  final DateTime? to;

  bool get isEmpty => from == null && to == null;

  /// Локализованная подпись для chip.
  String label() {
    if (isEmpty) return 'Весь проект';
    final f = from;
    final t = to;
    String s(DateTime d) {
      const months = [
        'янв',
        'фев',
        'мар',
        'апр',
        'мая',
        'июн',
        'июл',
        'авг',
        'сен',
        'окт',
        'ноя',
        'дек',
      ];
      return '${d.day} ${months[d.month - 1]}';
    }

    if (f != null && t != null) return '${s(f)} — ${s(t)}';
    if (f != null) return 'с ${s(f)}';
    return 'до ${s(t!)}';
  }
}

Future<DateRange?> showDateRangeSheet(
  BuildContext context, {
  required DateRange initial,
}) {
  return showAppBottomSheet<DateRange?>(
    context: context,
    isScrollControlled: true,
    child: _DateRangeBody(initial: initial),
  );
}

class _DateRangeBody extends StatefulWidget {
  const _DateRangeBody({required this.initial});

  final DateRange initial;

  @override
  State<_DateRangeBody> createState() => _DateRangeBodyState();
}

class _DateRangeBodyState extends State<_DateRangeBody> {
  late DateRange _range;

  @override
  void initState() {
    super.initState();
    _range = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppBottomSheetHeader(
          title: 'Период',
          subtitle: 'Выберите диапазон дат для фильтрации',
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _PresetChip(
              label: 'Последние 30 дн',
              onTap: () => _setRange(_lastDays(30)),
              active: _matches(_lastDays(30)),
            ),
            _PresetChip(
              label: 'Этот месяц',
              onTap: () => _setRange(_thisMonth()),
              active: _matches(_thisMonth()),
            ),
            _PresetChip(
              label: 'С начала года',
              onTap: () => _setRange(_thisYear()),
              active: _matches(_thisYear()),
            ),
            _PresetChip(
              label: 'Весь проект',
              onTap: () => _setRange(const DateRange()),
              active: _range.isEmpty,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x16),
        Row(
          children: [
            Expanded(
              child: _DateField(
                label: 'Начало',
                date: _range.from,
                onTap: () => _pickDate(true),
              ),
            ),
            const SizedBox(width: AppSpacing.x10),
            Expanded(
              child: _DateField(
                label: 'Конец',
                date: _range.to,
                onTap: () => _pickDate(false),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x20),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Сбросить',
                variant: AppButtonVariant.ghost,
                onPressed: () =>
                    Navigator.of(context).pop(const DateRange()),
              ),
            ),
            const SizedBox(width: AppSpacing.x10),
            Expanded(
              flex: 2,
              child: AppButton(
                label: 'Применить',
                onPressed: () => Navigator.of(context).pop(_range),
              ),
            ),
          ],
        ),
      ],
    );
  }

  DateRange _lastDays(int n) {
    final to = DateTime.now();
    final from = to.subtract(Duration(days: n));
    return DateRange(from: from, to: to);
  }

  DateRange _thisMonth() {
    final now = DateTime.now();
    return DateRange(
      from: DateTime(now.year, now.month, 1),
      to: now,
    );
  }

  DateRange _thisYear() {
    final now = DateTime.now();
    return DateRange(from: DateTime(now.year, 1, 1), to: now);
  }

  bool _matches(DateRange other) =>
      _range.from?.toIso8601String() == other.from?.toIso8601String() &&
      _range.to?.toIso8601String() == other.to?.toIso8601String();

  void _setRange(DateRange r) => setState(() => _range = r);

  Future<void> _pickDate(bool start) async {
    final initial = (start ? _range.from : _range.to) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      _range = start
          ? DateRange(from: picked, to: _range.to)
          : DateRange(from: _range.from, to: picked);
    });
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.onTap,
    required this.active,
  });

  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.brandLight : AppColors.n0,
          border: Border.all(
            color: active ? AppColors.brand : AppColors.n200,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: active ? AppColors.brand : AppColors.n600,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.tiny.copyWith(
            color: AppColors.n400,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.r12),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.n50,
              border: Border.all(color: AppColors.n200, width: 1.5),
              borderRadius: BorderRadius.circular(AppRadius.r12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: AppColors.n400,
                ),
                const SizedBox(width: 8),
                Text(
                  date == null ? '—' : _fmt(date!),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.n900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}
