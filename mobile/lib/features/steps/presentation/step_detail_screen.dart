import 'package:flutter/material.dart' hide Step;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/utils/money.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/step_detail_controller.dart';
import '../application/steps_controller.dart';
import '../domain/question.dart';
import '../domain/step.dart';
import '../domain/step_photo.dart';
import '../domain/substep.dart';
import 'add_photo_sheet.dart';
import 'add_substep_sheet.dart';
import 'ask_question_sheet.dart';
import 'step_widgets.dart';

/// c-step-detail / s-step-active / s-step-done:
/// хедер + чек-лист substeps + секция photos + секция questions.
class StepDetailScreen extends ConsumerWidget {
  const StepDetailScreen({
    required this.projectId,
    required this.stageId,
    required this.stepId,
    super.key,
  });

  final String projectId;
  final String stageId;
  final String stepId;

  StepDetailKey get _key => StepDetailKey(
        projectId: projectId,
        stageId: stageId,
        stepId: stepId,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(stepDetailProvider(_key));

    return AppScaffold(
      showBack: true,
      title: 'Шаг',
      padding: EdgeInsets.zero,
      body: async.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить шаг',
          onRetry: () =>
              ref.read(stepDetailProvider(_key).notifier).refresh(),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () =>
              ref.read(stepDetailProvider(_key).notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.x16),
            children: [
              _Header(step: data.step),
              const SizedBox(height: AppSpacing.x20),
              _SubstepsSection(
                detailKey: _key,
                substeps: data.substeps,
              ),
              const SizedBox(height: AppSpacing.x20),
              _PhotosSection(detailKey: _key, photos: data.photos),
              const SizedBox(height: AppSpacing.x20),
              _QuestionsSection(detailKey: _key, questions: data.questions),
              const SizedBox(height: AppSpacing.x24),
              _ActionCtas(
                projectId: projectId,
                stageId: stageId,
                step: data.step,
              ),
              const SizedBox(height: AppSpacing.x16),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.step});

  final Step step;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x16),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppRadius.card,
        boxShadow: AppShadows.sh1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (step.isExtra) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.x8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.purpleBg,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    'ДОП.РАБОТА',
                    style: AppTextStyles.tiny
                        .copyWith(color: AppColors.purple),
                  ),
                ),
                const SizedBox(width: AppSpacing.x8),
              ],
              StepStatusBadge(status: step.status),
            ],
          ),
          const SizedBox(height: AppSpacing.x10),
          Text(step.title, style: AppTextStyles.h1, maxLines: 3),
          if (step.description != null &&
              step.description!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.x8),
            Text(step.description!, style: AppTextStyles.body),
          ],
          if (step.isExtra && step.price != null) ...[
            const SizedBox(height: AppSpacing.x12),
            Row(
              children: [
                const Icon(
                  Icons.payments_outlined,
                  color: AppColors.purple,
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.x6),
                Text(
                  'Цена: ${Money.format(step.price!)}',
                  style: AppTextStyles.subtitle
                      .copyWith(color: AppColors.purple),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SubstepsSection extends ConsumerWidget {
  const _SubstepsSection({
    required this.detailKey,
    required this.substeps,
  });

  final StepDetailKey detailKey;
  final List<Substep> substeps;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = substeps.where((s) => s.isDone).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Подшаги',
              style: AppTextStyles.h2,
            ),
            const SizedBox(width: AppSpacing.x8),
            if (substeps.isNotEmpty)
              Text(
                '$done из ${substeps.length}',
                style: AppTextStyles.caption,
              ),
            const Spacer(),
            TextButton.icon(
              onPressed: () =>
                  showAddSubstepSheet(context, ref, key: detailKey),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Добавить'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x8),
        if (substeps.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.x16),
            decoration: BoxDecoration(
              color: AppColors.n100,
              borderRadius: AppRadius.card,
            ),
            child: const Text(
              'Подшаги помогают разбить работу — нажмите «Добавить».',
              style: AppTextStyles.caption,
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.n0,
              borderRadius: BorderRadius.circular(AppRadius.r20),
              boxShadow: AppShadows.sh1,
            ),
            child: Column(
              children: [
                for (var i = 0; i < substeps.length; i++) ...[
                  _SubstepTile(
                    sub: substeps[i],
                    onToggle: () => ref
                        .read(stepDetailProvider(detailKey).notifier)
                        .toggleSubstep(substeps[i]),
                    onDelete: () => ref
                        .read(stepDetailProvider(detailKey).notifier)
                        .deleteSubstep(substeps[i].id),
                  ),
                  if (i < substeps.length - 1)
                    const Divider(
                      height: 1,
                      color: AppColors.n100,
                      indent: 56,
                    ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _SubstepTile extends StatelessWidget {
  const _SubstepTile({
    required this.sub,
    required this.onToggle,
    required this.onDelete,
  });

  final Substep sub;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(AppRadius.r20),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x16,
          vertical: AppSpacing.x12,
        ),
        child: Row(
          children: [
            Checkbox(
              value: sub.isDone,
              onChanged: (_) => onToggle(),
              activeColor: AppColors.greenDot,
            ),
            Expanded(
              child: Text(
                sub.text,
                style: AppTextStyles.body.copyWith(
                  color: sub.isDone ? AppColors.n400 : AppColors.n800,
                  decoration: sub.isDone
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: AppColors.n400,
                size: 18,
              ),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotosSection extends ConsumerWidget {
  const _PhotosSection({required this.detailKey, required this.photos});

  final StepDetailKey detailKey;
  final List<StepPhoto> photos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Фото', style: AppTextStyles.h2),
            const SizedBox(width: AppSpacing.x8),
            if (photos.isNotEmpty)
              Text('${photos.length}', style: AppTextStyles.caption),
            const Spacer(),
            TextButton.icon(
              onPressed: () =>
                  showAddPhotoSheet(context, ref, key: detailKey),
              icon: const Icon(Icons.photo_camera_outlined, size: 18),
              label: const Text('Добавить'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x8),
        if (photos.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.x16),
            decoration: BoxDecoration(
              color: AppColors.n100,
              borderRadius: AppRadius.card,
            ),
            child: const Text(
              'Фотографии подтверждают выполнение. Размер оптимизируется '
              'автоматически до 1920 px, EXIF очищается.',
              style: AppTextStyles.caption,
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: photos.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (_, i) {
              final photo = photos[i];
              return _PhotoThumb(
                photo: photo,
                onDelete: () => ref
                    .read(stepDetailProvider(detailKey).notifier)
                    .deletePhoto(photo.id),
              );
            },
          ),
      ],
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({required this.photo, required this.onDelete});

  final StepPhoto photo;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final url = photo.thumbUrl ?? photo.url;
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.r12),
          child: url == null
              ? const ColoredBox(
                  color: AppColors.n100,
                  child: Icon(
                    Icons.image_outlined,
                    color: AppColors.n400,
                  ),
                )
              : Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const ColoredBox(
                    color: AppColors.n100,
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.n400,
                    ),
                  ),
                ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 14,
                color: AppColors.n0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuestionsSection extends ConsumerWidget {
  const _QuestionsSection({
    required this.detailKey,
    required this.questions,
  });

  final StepDetailKey detailKey;
  final List<Question> questions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Вопросы', style: AppTextStyles.h2),
            const SizedBox(width: AppSpacing.x8),
            if (questions.isNotEmpty)
              Text(
                '${questions.where((q) => q.status == QuestionStatus.open).length} открыт',
                style: AppTextStyles.caption,
              ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => showAskQuestionSheet(
                context,
                ref,
                detailKey: detailKey,
              ),
              icon: const Icon(Icons.help_outline_rounded, size: 18),
              label: const Text('Задать'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x8),
        if (questions.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.x16),
            decoration: BoxDecoration(
              color: AppColors.n100,
              borderRadius: AppRadius.card,
            ),
            child: const Text(
              'Непонятно что-то про этот шаг? Задайте вопрос — прилетит '
              'уведомление адресату.',
              style: AppTextStyles.caption,
            ),
          )
        else
          Column(
            children: [
              for (final q in questions)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.x8),
                  child: _QuestionCard(question: q),
                ),
            ],
          ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d MMM HH:mm', 'ru');
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x12),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.n200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusChip(status: question.status),
              const Spacer(),
              Text(df.format(question.createdAt),
                  style: AppTextStyles.tiny),
            ],
          ),
          const SizedBox(height: AppSpacing.x8),
          Text(question.text, style: AppTextStyles.body),
          if (question.answer != null) ...[
            const SizedBox(height: AppSpacing.x10),
            Container(
              padding: const EdgeInsets.all(AppSpacing.x10),
              decoration: BoxDecoration(
                color: AppColors.greenLight,
                borderRadius: BorderRadius.circular(AppRadius.r12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.reply,
                    size: 16,
                    color: AppColors.greenDark,
                  ),
                  const SizedBox(width: AppSpacing.x8),
                  Expanded(
                    child: Text(
                      question.answer!,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.greenDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final QuestionStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      QuestionStatus.open => (AppColors.blueBg, AppColors.blueText),
      QuestionStatus.answered => (AppColors.greenLight, AppColors.greenDark),
      QuestionStatus.closed => (AppColors.n100, AppColors.n500),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        status.displayName,
        style: AppTextStyles.tiny.copyWith(color: fg),
      ),
    );
  }
}

class _ActionCtas extends ConsumerWidget {
  const _ActionCtas({
    required this.projectId,
    required this.stageId,
    required this.step,
  });

  final String projectId;
  final String stageId;
  final Step step;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(
      stepsControllerProvider(
        StepsKey(projectId: projectId, stageId: stageId),
      ).notifier,
    );
    if (step.isDone) {
      return AppButton(
        label: 'Отменить «Выполнено»',
        variant: AppButtonVariant.secondary,
        onPressed: () async {
          final failure = await controller.uncomplete(step.id);
          if (context.mounted && failure != null) {
            AppToast.show(
              context,
              message: failure.userMessage,
              kind: AppToastKind.error,
            );
          }
        },
      );
    }
    return AppButton(
      label: 'Отметить выполненным',
      variant: AppButtonVariant.success,
      onPressed: () async {
        final failure = await controller.complete(step.id);
        if (context.mounted) {
          AppToast.show(
            context,
            message: failure == null
                ? 'Шаг выполнен'
                : failure.userMessage,
            kind: failure == null
                ? AppToastKind.success
                : AppToastKind.error,
          );
        }
      },
    );
  }
}
