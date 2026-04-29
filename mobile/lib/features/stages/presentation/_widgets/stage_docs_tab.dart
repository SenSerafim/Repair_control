import 'package:flutter/material.dart' hide Step;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../documents/application/documents_controller.dart';
import '../../../documents/domain/document.dart';
import '../../../steps/application/steps_controller.dart';

/// Таб «Докум.» в детали этапа — c-stage-docs.
///
/// Состоит из 2 секций: фото шагов (агрегация step.photosCount) и файлы
/// (фильтр по stageId через documentsByStageProvider). Снизу dashed «Загрузить
/// файл» CTA, который ведёт на загрузку проекта/этапа.
class StageDocsTab extends ConsumerWidget {
  const StageDocsTab({
    required this.projectId,
    required this.stageId,
    super.key,
  });

  final String projectId;
  final String stageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stepsAsync = ref.watch(
      stepsControllerProvider(
        StepsKey(projectId: projectId, stageId: stageId),
      ),
    );
    final docsAsync = ref.watch(
      documentsByStageProvider((projectId: projectId, stageId: stageId)),
    );

    final photosTotal = stepsAsync.maybeWhen(
      data: (s) => s.fold<int>(0, (a, s) => a + s.photosCount),
      orElse: () => 0,
    );
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.x16),
      children: [
        Text(
          'ФОТО ШАГОВ · $photosTotal'.toUpperCase(),
          style: AppTextStyles.tiny.copyWith(
            color: AppColors.n400,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: AppSpacing.x10),
        if (photosTotal == 0)
          Container(
            padding: const EdgeInsets.all(AppSpacing.x14),
            decoration: BoxDecoration(
              color: AppColors.n50,
              borderRadius: AppRadius.card,
              border: Border.all(color: AppColors.n200),
            ),
            child: Text(
              'Фото к этапу пока не прикреплены.',
              style: AppTextStyles.caption,
            ),
          )
        else
          _PhotoGridStub(count: photosTotal),
        const SizedBox(height: AppSpacing.x20),
        docsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.x16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text(
            'Не удалось загрузить файлы',
            style: AppTextStyles.caption.copyWith(color: AppColors.redDot),
          ),
          data: (docs) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ФАЙЛЫ · ${docs.length}',
                style: AppTextStyles.tiny.copyWith(
                  color: AppColors.n400,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: AppSpacing.x10),
              if (docs.isEmpty)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.x14),
                  decoration: BoxDecoration(
                    color: AppColors.n50,
                    borderRadius: AppRadius.card,
                    border: Border.all(color: AppColors.n200),
                  ),
                  child: Text(
                    'К этапу не прикреплены файлы.',
                    style: AppTextStyles.caption,
                  ),
                )
              else
                Column(
                  children: [
                    for (final d in docs) _DocRow(doc: d),
                  ],
                ),
              const SizedBox(height: AppSpacing.x16),
              AppDashedBorder(
                borderRadius: AppRadius.r16,
                color: AppColors.brand,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.r16),
                  onTap: () => context.push(
                    '/projects/$projectId/documents/upload?stageId=$stageId',
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.x16,
                      vertical: AppSpacing.x14,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.upload_file_outlined,
                          color: AppColors.brand,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Загрузить файл',
                          style: AppTextStyles.subtitle.copyWith(
                            fontSize: 13,
                            color: AppColors.brand,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PhotoGridStub extends StatelessWidget {
  const _PhotoGridStub({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final tiles = count.clamp(0, 5);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var i = 0; i < tiles; i++)
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.n100,
              borderRadius: BorderRadius.circular(AppRadius.r8),
              border: Border.all(color: AppColors.n200),
            ),
            child: const Icon(
              Icons.image_outlined,
              size: 24,
              color: AppColors.n400,
            ),
          ),
        if (count > 5)
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.brandLight,
              borderRadius: BorderRadius.circular(AppRadius.r8),
            ),
            child: Text(
              '+${count - 5}',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppColors.brandDark,
              ),
            ),
          ),
      ],
    );
  }
}

class _DocRow extends StatelessWidget {
  const _DocRow({required this.doc});

  final Document doc;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d MMM y', 'ru');
    final spec = _iconForCategory(doc.category);
    final sizeKb = (doc.sizeBytes / 1024).toStringAsFixed(0);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.x6),
      padding: const EdgeInsets.all(AppSpacing.x10),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.n200),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: spec.bg,
              borderRadius: BorderRadius.circular(AppRadius.r8),
            ),
            child: Icon(spec.icon, size: 18, color: spec.fg),
          ),
          const SizedBox(width: AppSpacing.x10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.title,
                  style: AppTextStyles.subtitle.copyWith(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${sizeKb} КБ · ${df.format(doc.createdAt)}',
                  style: AppTextStyles.tiny,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ({IconData icon, Color bg, Color fg}) _iconForCategory(DocumentCategory c) {
    return switch (c) {
      DocumentCategory.contract => (
          icon: Icons.description_outlined,
          bg: AppColors.redBg,
          fg: AppColors.redText,
        ),
      DocumentCategory.estimate => (
          icon: Icons.calculate_outlined,
          bg: AppColors.greenLight,
          fg: AppColors.greenDark,
        ),
      DocumentCategory.act => (
          icon: Icons.assignment_turned_in_outlined,
          bg: AppColors.greenLight,
          fg: AppColors.greenDark,
        ),
      DocumentCategory.warranty => (
          icon: Icons.shield_outlined,
          bg: AppColors.yellowBg,
          fg: AppColors.yellowText,
        ),
      DocumentCategory.photo => (
          icon: Icons.image_outlined,
          bg: AppColors.brandLight,
          fg: AppColors.brand,
        ),
      DocumentCategory.blueprint => (
          icon: Icons.architecture_outlined,
          bg: AppColors.brandLight,
          fg: AppColors.brand,
        ),
      DocumentCategory.other => (
          icon: Icons.folder_open_outlined,
          bg: AppColors.n100,
          fg: AppColors.n600,
        ),
    };
  }
}
