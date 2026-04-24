import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/exports_repository.dart';
import '../domain/export_job.dart';

/// s-download-zip — ExportSheet: выбрать тип + даты → POST /exports.
Future<ExportJob?> showExportSheet(
  BuildContext context,
  WidgetRef ref, {
  required String projectId,
}) async {
  return showAppBottomSheet<ExportJob>(
    context: context,
    isScrollControlled: true,
    child: _Body(projectId: projectId),
  );
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.projectId});
  final String projectId;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  ExportKind _kind = ExportKind.feedPdf;
  DateTime? _from;
  DateTime? _to;
  bool _submitting = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final job = await ref.read(exportsRepositoryProvider).create(
            projectId: widget.projectId,
            kind: _kind,
            dateFrom: _from,
            dateTo: _to,
          );
      if (!mounted) return;
      Navigator.of(context).pop(job);
      AppToast.show(
        context,
        message: 'Экспорт поставлен в очередь. Мы уведомим, когда готово.',
        kind: AppToastKind.success,
      );
    } on ExportsException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.failure.userMessage;
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppBottomSheetHeader(
          title: 'Экспорт',
          subtitle: 'PDF-ленту или ZIP со всеми файлами проекта.',
        ),
        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.x12),
            decoration: BoxDecoration(
              color: AppColors.redBg,
              borderRadius: AppRadius.card,
            ),
            child: Text(
              _error!,
              style: AppTextStyles.body.copyWith(color: AppColors.redText),
            ),
          ),
          const SizedBox(height: AppSpacing.x12),
        ],
        Wrap(
          spacing: 8,
          children: [
            for (final k in ExportKind.values)
              ChoiceChip(
                label: Text(k.displayName),
                selected: _kind == k,
                onSelected: (_) => setState(() => _kind = k),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.x12),
        if (_kind == ExportKind.feedPdf) ...[
          _DateTile(
            label: 'С',
            value: _from,
            onChanged: (d) => setState(() => _from = d),
          ),
          const SizedBox(height: AppSpacing.x8),
          _DateTile(
            label: 'По',
            value: _to,
            minDate: _from,
            onChanged: (d) => setState(() => _to = d),
          ),
          const SizedBox(height: AppSpacing.x8),
        ],
        AppButton(
          label: 'Запустить экспорт',
          isLoading: _submitting,
          onPressed: _submit,
        ),
      ],
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.onChanged,
    this.minDate,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final DateTime? minDate;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? minDate ?? now,
          firstDate: minDate ?? DateTime(now.year - 2),
          lastDate: DateTime(now.year + 2),
          locale: const Locale('ru'),
        );
        if (picked != null) onChanged(picked);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.x12),
        decoration: BoxDecoration(
          color: AppColors.n0,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.n200, width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: AppColors.n400,
            ),
            const SizedBox(width: AppSpacing.x10),
            Text('$label:  ', style: AppTextStyles.caption),
            Text(
              value == null
                  ? 'Не выбрана'
                  : '${value!.day}.${value!.month}.${value!.year}',
              style: AppTextStyles.subtitle,
            ),
          ],
        ),
      ),
    );
  }
}
