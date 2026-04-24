import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/stages_controller.dart';
import '../domain/pause_reason.dart';

/// c-pause-sheet / c-pause-other — выбор причины паузы.
/// Для `other` комментарий обязателен.
Future<bool> showPauseSheet(
  BuildContext context,
  WidgetRef ref, {
  required String projectId,
  required String stageId,
}) async {
  final result = await showAppBottomSheet<bool>(
    context: context,
    child: _PauseBody(projectId: projectId, stageId: stageId),
  );
  return result ?? false;
}

class _PauseBody extends ConsumerStatefulWidget {
  const _PauseBody({required this.projectId, required this.stageId});

  final String projectId;
  final String stageId;

  @override
  ConsumerState<_PauseBody> createState() => _PauseBodyState();
}

class _PauseBodyState extends ConsumerState<_PauseBody> {
  PauseReason? _reason;
  final _comment = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  bool get _commentRequired => _reason == PauseReason.other;

  bool get _canSubmit =>
      _reason != null &&
      !(_commentRequired && _comment.text.trim().isEmpty);

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final failure = await ref
        .read(stagesControllerProvider(widget.projectId).notifier)
        .pause(
          stageId: widget.stageId,
          reason: _reason!,
          comment:
              _comment.text.trim().isEmpty ? null : _comment.text.trim(),
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (failure == null) {
      Navigator.of(context).pop(true);
      AppToast.show(
        context,
        message: 'Этап на паузе',
        kind: AppToastKind.success,
      );
    } else {
      setState(() => _error = failure.userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppBottomSheetHeader(
          title: 'Поставить на паузу',
          subtitle: 'Пауза не засчитывается в срок этапа — '
              'дедлайн автоматически сдвинется на её длительность.',
        ),
        if (_error != null) ...[
          AppInlineError(message: _error!),
          const SizedBox(height: AppSpacing.x12),
        ],
        for (final r in PauseReason.values) ...[
          _ReasonTile(
            reason: r,
            selected: _reason == r,
            onTap: () => setState(() => _reason = r),
          ),
          const SizedBox(height: AppSpacing.x8),
        ],
        if (_commentRequired) ...[
          const SizedBox(height: AppSpacing.x8),
          const Text(
            'Комментарий (обязательно)',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSpacing.x6),
          TextField(
            controller: _comment,
            minLines: 3,
            maxLines: 6,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'В чём причина паузы?',
              hintStyle: AppTextStyles.body.copyWith(color: AppColors.n400),
              filled: true,
              fillColor: AppColors.n0,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.r12),
                borderSide:
                    const BorderSide(color: AppColors.n200, width: 1.5),
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.x16),
        AppButton(
          label: 'Поставить на паузу',
          variant: AppButtonVariant.destructive,
          isLoading: _submitting,
          onPressed: _canSubmit ? _submit : null,
        ),
      ],
    );
  }
}

class _ReasonTile extends StatelessWidget {
  const _ReasonTile({
    required this.reason,
    required this.selected,
    required this.onTap,
  });

  final PauseReason reason;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.all(AppSpacing.x12),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandLight : AppColors.n0,
          borderRadius: AppRadius.card,
          border: Border.all(
            color: selected ? AppColors.brand : AppColors.n200,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.brand
                    : AppColors.brandLight,
                borderRadius: BorderRadius.circular(AppRadius.r12),
              ),
              child: Icon(
                reason.icon,
                size: 20,
                color: selected ? AppColors.n0 : AppColors.brand,
              ),
            ),
            const SizedBox(width: AppSpacing.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reason.displayName, style: AppTextStyles.subtitle),
                  Text(reason.hint, style: AppTextStyles.caption),
                ],
              ),
            ),
            AnimatedOpacity(
              duration: AppDurations.fast,
              opacity: selected ? 1 : 0,
              child: const Icon(
                Icons.check_circle,
                color: AppColors.brand,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
