import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/step_detail_controller.dart';
import '../domain/question.dart';

/// d-question-reply — полноэкранный ответ на вопрос бригадира.
///
/// Покажет покупательский question (purple-card), TextArea для ответа
/// и placeholder photo-row (фото — задел на след. итерацию). Sticky
/// ActionBar с кнопкой «Отправить ответ».
class QuestionReplyScreen extends ConsumerStatefulWidget {
  const QuestionReplyScreen({
    required this.projectId,
    required this.stageId,
    required this.stepId,
    required this.questionId,
    super.key,
  });

  final String projectId;
  final String stageId;
  final String stepId;
  final String questionId;

  @override
  ConsumerState<QuestionReplyScreen> createState() =>
      _QuestionReplyScreenState();
}

class _QuestionReplyScreenState extends ConsumerState<QuestionReplyScreen> {
  final _controller = TextEditingController();
  bool _submitting = false;
  String? _error;
  int _length = 0;

  StepDetailKey get _key => StepDetailKey(
        projectId: widget.projectId,
        stageId: widget.stageId,
        stepId: widget.stepId,
      );

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final l = _controller.text.trim().length;
      if (l != _length) setState(() => _length = l);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final answer = _controller.text.trim();
    if (answer.isEmpty) {
      setState(() => _error = 'Напишите ответ');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final failure = await ref
        .read(stepDetailProvider(_key).notifier)
        .answerQuestion(
          questionId: widget.questionId,
          answer: answer,
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (failure == null) {
      AppToast.show(
        context,
        message: 'Ответ отправлен',
        kind: AppToastKind.success,
      );
      context.pop();
    } else {
      setState(() => _error = failure.userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(stepDetailProvider(_key));

    return AppScaffold(
      showBack: true,
      title: 'Ответ на вопрос',
      padding: EdgeInsets.zero,
      body: async.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить',
          onRetry: () => ref.invalidate(stepDetailProvider(_key)),
        ),
        data: (data) {
          final q = data.questions
              .where((x) => x.id == widget.questionId)
              .cast<Question?>()
              .firstOrNull;
          if (q == null) {
            return const AppEmptyState(
              title: 'Вопрос не найден',
              subtitle: 'Возможно, он уже закрыт или удалён.',
              icon: Icons.help_outline_rounded,
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.x16,
                    AppSpacing.x16,
                    AppSpacing.x16,
                    AppSpacing.x24,
                  ),
                  children: [
                    _QuestionBox(question: q),
                    const SizedBox(height: AppSpacing.x16),
                    if (_error != null) ...[
                      _ErrorBanner(message: _error!),
                      const SizedBox(height: AppSpacing.x12),
                    ],
                    const _Label('Ваш ответ'),
                    const SizedBox(height: AppSpacing.x8),
                    TextField(
                      controller: _controller,
                      autofocus: true,
                      minLines: 5,
                      maxLines: 10,
                      maxLength: 2000,
                      decoration: _textDec('Опишите подробно...'),
                    ),
                    const SizedBox(height: AppSpacing.x14),
                    const _Label('Фото (опционально)'),
                    const SizedBox(height: AppSpacing.x8),
                    const Row(
                      children: [
                        _PhotoSlot(icon: Icons.camera_alt_outlined),
                        SizedBox(width: 8),
                        _PhotoSlot(icon: Icons.add_rounded),
                      ],
                    ),
                  ],
                ),
              ),
              AppActionBar(
                children: [
                  AppButton(
                    label: 'Отправить ответ',
                    isLoading: _submitting,
                    onPressed: _length > 0 && !_submitting ? _submit : null,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontFamily: 'Manrope',
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: AppColors.n400,
        letterSpacing: 0.5,
        height: 1.2,
      ),
    );
  }
}

class _QuestionBox extends StatelessWidget {
  const _QuestionBox({required this.question});
  final Question question;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d MMMM y · HH:mm', 'ru');
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: AppColors.purpleBg,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.purple, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.help_outline_rounded,
                size: 18,
                color: AppColors.purple,
              ),
              SizedBox(width: 6),
              Text(
                'ВОПРОС',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.purple,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x8),
          Text(
            question.text,
            style: AppTextStyles.subtitle.copyWith(
              color: AppColors.n900,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.x10),
          Text(
            'Открыт ${df.format(question.createdAt)}',
            style: AppTextStyles.tiny.copyWith(color: AppColors.purple),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x12),
      decoration: BoxDecoration(
        color: AppColors.redBg,
        borderRadius: AppRadius.card,
      ),
      child: Text(
        message,
        style: AppTextStyles.body.copyWith(color: AppColors.redText),
      ),
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Загрузка фото скоро будет доступна',
      child: Container(
        width: 56,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.n100,
          borderRadius: BorderRadius.circular(AppRadius.r12),
          border: Border.all(color: AppColors.n200),
        ),
        child: Icon(icon, color: AppColors.n400, size: 22),
      ),
    );
  }
}

InputDecoration _textDec(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.body.copyWith(color: AppColors.n400),
      filled: true,
      fillColor: AppColors.n0,
      contentPadding: const EdgeInsets.all(12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.r12),
        borderSide: const BorderSide(color: AppColors.n200, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.r12),
        borderSide: const BorderSide(color: AppColors.n200, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.r12),
        borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
      ),
    );
