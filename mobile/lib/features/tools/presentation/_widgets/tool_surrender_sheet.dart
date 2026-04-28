import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/tools_controller.dart';
import '../../domain/tool.dart';

/// e-tool-surrender: мастер выбирает несколько issuance-ов для возврата
/// бригадиру за один раз. Каждая отмеченная позиция отправляется через
/// `requestReturn(qty)` последовательно.
Future<void> showToolSurrenderSheet(
  BuildContext context,
  WidgetRef ref, {
  required String projectId,
  required List<ToolIssuance> issuances,
}) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    child: _Body(projectId: projectId, issuances: issuances),
  );
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.projectId, required this.issuances});

  final String projectId;
  final List<ToolIssuance> issuances;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  final _selected = <String>{};
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppBottomSheetHeader(
          title: 'Сдать инструмент',
          subtitle: 'Выберите позиции для возврата бригадиру',
        ),
        Column(
          children: [
            for (final iss in widget.issuances)
              _Row(
                issuance: iss,
                selected: _selected.contains(iss.id),
                onTap: () => setState(() {
                  if (_selected.contains(iss.id)) {
                    _selected.remove(iss.id);
                  } else {
                    _selected.add(iss.id);
                  }
                }),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.x16),
        AppButton(
          label: _selected.isEmpty
              ? 'Выберите хотя бы один'
              : 'Отправить ${_selected.length} на подтверждение',
          icon: Icons.check_rounded,
          isLoading: _busy,
          onPressed: _selected.isEmpty ? null : _submit,
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Бригадир получит уведомление и подтвердит возврат',
            style: AppTextStyles.tiny.copyWith(
              color: AppColors.n400,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    final ctrl = ref.read(toolIssuancesProvider(widget.projectId).notifier);
    final errors = <String>[];
    for (final id in _selected) {
      final iss = widget.issuances.firstWhere((i) => i.id == id);
      final f = await ctrl.requestReturn(id: iss.id, returnedQty: iss.qty);
      if (f != null) errors.add(f.userMessage);
    }
    if (!mounted) return;
    setState(() => _busy = false);
    Navigator.of(context).pop();
    if (errors.isNotEmpty) {
      AppToast.show(
        context,
        message: 'Ошибки: ${errors.length}',
        kind: AppToastKind.error,
      );
    } else {
      AppToast.show(
        context,
        message: 'Отправлено на подтверждение',
        kind: AppToastKind.success,
      );
    }
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.issuance,
    required this.selected,
    required this.onTap,
  });

  final ToolIssuance issuance;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.x8),
        padding: const EdgeInsets.all(AppSpacing.x12),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandLight : AppColors.n0,
          border: Border.all(
            color: selected ? AppColors.brand : AppColors.n200,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(AppRadius.r12),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.brand : Colors.transparent,
                border: selected
                    ? null
                    : Border.all(color: AppColors.n300, width: 2),
                borderRadius: BorderRadius.circular(AppRadius.r8),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: AppColors.n0,
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${issuance.tool?.name ?? 'Инструмент'} × ${issuance.qty}',
                    style: AppTextStyles.subtitle.copyWith(
                      color: AppColors.n800,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
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
