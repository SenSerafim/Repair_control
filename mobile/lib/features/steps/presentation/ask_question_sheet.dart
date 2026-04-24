import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../projects/domain/membership.dart';
import '../../team/application/team_controller.dart';
// ignore_for_file: avoid_dynamic_calls
import '../application/step_detail_controller.dart';

/// c-ask-question: задать вопрос конкретному участнику проекта.
Future<bool> showAskQuestionSheet(
  BuildContext context,
  WidgetRef ref, {
  required StepDetailKey detailKey,
}) async {
  final result = await showAppBottomSheet<bool>(
    context: context,
    child: _AskBody(detailKey: detailKey),
    isScrollControlled: true,
  );
  return result ?? false;
}

class _AskBody extends ConsumerStatefulWidget {
  const _AskBody({required this.detailKey});

  final StepDetailKey detailKey;

  @override
  ConsumerState<_AskBody> createState() => _AskBodyState();
}

class _AskBodyState extends ConsumerState<_AskBody> {
  final _text = TextEditingController();
  String? _addresseeId;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _text.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Введите вопрос');
      return;
    }
    if (_addresseeId == null) {
      setState(() => _error = 'Выберите получателя');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final failure = await ref
        .read(stepDetailProvider(widget.detailKey).notifier)
        .askQuestion(text: text, addresseeId: _addresseeId!);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (failure == null) {
      Navigator.of(context).pop(true);
      AppToast.show(
        context,
        message: 'Вопрос отправлен',
        kind: AppToastKind.success,
      );
    } else {
      setState(() => _error = failure.userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamAsync =
        ref.watch(teamControllerProvider(widget.detailKey.projectId));
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppBottomSheetHeader(
            title: 'Задать вопрос',
            subtitle:
                'Адресуйте вопрос конкретному участнику — он увидит его '
                'в своих уведомлениях.',
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
                style:
                    AppTextStyles.body.copyWith(color: AppColors.redText),
              ),
            ),
            const SizedBox(height: AppSpacing.x12),
          ],
          const Text('Получатель', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.x6),
          teamAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.x12),
              child: LinearProgressIndicator(),
            ),
            error: (e, _) => Text(
              'Не удалось загрузить команду',
              style:
                  AppTextStyles.caption.copyWith(color: AppColors.redDot),
            ),
            data: (team) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in team.members.where(
                  (m) => m.role != MembershipRole.master,
                ))
                  _MemberChip(
                    label: _labelOf(m),
                    selected: _addresseeId == m.userId,
                    onTap: () => setState(() => _addresseeId = m.userId),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x16),
          const Text('Вопрос', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.x6),
          TextField(
            controller: _text,
            minLines: 3,
            maxLines: 8,
            maxLength: 2000,
            decoration: InputDecoration(
              hintText: 'Что уточнить?',
              hintStyle:
                  AppTextStyles.body.copyWith(color: AppColors.n400),
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
          const SizedBox(height: AppSpacing.x16),
          AppButton(
            label: 'Отправить',
            isLoading: _submitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  String _labelOf(dynamic m) {
    // Membership — используем позднее типирование: у нас импорт через
    // MembershipRole уже есть; тут достаточно user?.firstName.
    final user = (m as dynamic).user;
    final role = (m as dynamic).role as MembershipRole;
    final name = user == null
        ? role.displayName
        : '${user.firstName} ${user.lastName}'.trim();
    return name.isEmpty ? role.displayName : name;
  }
}

class _MemberChip extends StatelessWidget {
  const _MemberChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x12,
          vertical: AppSpacing.x8,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.brand : AppColors.n100,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: selected ? AppColors.n0 : AppColors.n700,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
