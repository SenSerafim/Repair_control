import 'package:flutter/material.dart' hide Step;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../documents/application/documents_controller.dart';
import '../../../documents/domain/document.dart';
import '../../../steps/application/steps_controller.dart';
import '../../../steps/domain/step.dart';

/// Таб «Докум.» в детали этапа — c-stage-docs.
///
/// Task 7.2 (NEWFIX §13 / план Q3): сверху переключатель «Фото / Документы»
/// `SegmentedButton<_DocsView>`, ниже отображается только выбранная секция.
/// В режиме «Документы» файлы группируются по шагу (через [Document.stepId])
/// с заголовками «Шаг N: <title>»; неприсвоенные шагу файлы попадают в
/// группу «Этап (без шага)». Кнопка «Загрузить файл» осталась на месте
/// и показывается в секции документов.
enum _DocsView { photos, files }

class StageDocsTab extends ConsumerStatefulWidget {
  const StageDocsTab({
    required this.projectId,
    required this.stageId,
    super.key,
  });

  final String projectId;
  final String stageId;

  @override
  ConsumerState<StageDocsTab> createState() => _StageDocsTabState();
}

class _StageDocsTabState extends ConsumerState<StageDocsTab> {
  _DocsView _view = _DocsView.photos;

  @override
  Widget build(BuildContext context) {
    final stepsAsync = ref.watch(
      stepsControllerProvider(
        StepsKey(projectId: widget.projectId, stageId: widget.stageId),
      ),
    );
    final docsAsync = ref.watch(
      documentsByStageProvider((
        projectId: widget.projectId,
        stageId: widget.stageId,
      )),
    );

    final photosTotal = stepsAsync.maybeWhen(
      data: (s) => s.fold<int>(0, (a, s) => a + s.photosCount),
      orElse: () => 0,
    );
    final stepsList = stepsAsync.maybeWhen(
      data: (s) => s,
      orElse: () => const <Step>[],
    );

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.x16),
      children: [
        _ViewToggle(
          view: _view,
          onChanged: (v) => setState(() => _view = v),
        ),
        const SizedBox(height: AppSpacing.x16),
        if (_view == _DocsView.photos)
          _PhotosSection(total: photosTotal)
        else
          _FilesSection(
            docsAsync: docsAsync,
            steps: stepsList,
            projectId: widget.projectId,
            stageId: widget.stageId,
          ),
      ],
    );
  }
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.view, required this.onChanged});

  final _DocsView view;
  final ValueChanged<_DocsView> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_DocsView>(
      key: const ValueKey('stage_docs_view_toggle'),
      segments: const [
        ButtonSegment<_DocsView>(
          value: _DocsView.photos,
          icon: Icon(PhosphorIconsRegular.image),
          label: Text('Фото'),
        ),
        ButtonSegment<_DocsView>(
          value: _DocsView.files,
          icon: Icon(PhosphorIconsRegular.file),
          label: Text('Документы'),
        ),
      ],
      selected: {view},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

class _PhotosSection extends StatelessWidget {
  const _PhotosSection({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('stage_docs_photos_section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'ФОТО ШАГОВ · $total'.toUpperCase(),
          style: AppTextStyles.tiny.copyWith(
            color: AppColors.n400,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: AppSpacing.x10),
        if (total == 0)
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
          _PhotoGridStub(count: total),
      ],
    );
  }
}

class _FilesSection extends StatelessWidget {
  const _FilesSection({
    required this.docsAsync,
    required this.steps,
    required this.projectId,
    required this.stageId,
  });

  final AsyncValue<List<Document>> docsAsync;
  final List<Step> steps;
  final String projectId;
  final String stageId;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('stage_docs_files_section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        docsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.x16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text(
            'Не удалось загрузить файлы',
            style: AppTextStyles.caption.copyWith(color: AppColors.redDot),
          ),
          data: (docs) => _FilesBody(
            docs: docs,
            steps: steps,
            projectId: projectId,
            stageId: stageId,
          ),
        ),
      ],
    );
  }
}

class _FilesBody extends StatelessWidget {
  const _FilesBody({
    required this.docs,
    required this.steps,
    required this.projectId,
    required this.stageId,
  });

  final List<Document> docs;
  final List<Step> steps;
  final String projectId;
  final String stageId;

  @override
  Widget build(BuildContext context) {
    final byStep = <String?, List<Document>>{};
    for (final d in docs) {
      byStep.putIfAbsent(d.stepId, () => []).add(d);
    }
    // Сортируем ключи: сначала шаги по orderIndex, затем «без шага» (null)
    // в конец. Это даёт стабильный порядок секций.
    final stepOrder = <String, int>{
      for (var i = 0; i < steps.length; i++) steps[i].id: steps[i].orderIndex,
    };
    final stepTitle = <String, String>{
      for (final s in steps) s.id: s.title,
    };
    final keys = byStep.keys.toList()
      ..sort((a, b) {
        if (a == null && b == null) return 0;
        if (a == null) return 1; // null в конец
        if (b == null) return -1;
        final oa = stepOrder[a] ?? 1 << 30;
        final ob = stepOrder[b] ?? 1 << 30;
        return oa.compareTo(ob);
      });

    return Column(
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
          for (final key in keys) ...[
            _StepGroupHeader(
              title: key == null
                  ? 'Этап (без шага)'
                  : _composeStepHeader(
                      orderIndex: stepOrder[key],
                      title: stepTitle[key],
                    ),
            ),
            const SizedBox(height: AppSpacing.x6),
            for (final d in byStep[key]!) _DocRow(doc: d),
            const SizedBox(height: AppSpacing.x10),
          ],
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
    );
  }

  String _composeStepHeader({int? orderIndex, String? title}) {
    final n = (orderIndex ?? 0) + 1;
    final t = (title == null || title.isEmpty) ? 'без названия' : title;
    return 'Шаг $n: $t';
  }
}

class _StepGroupHeader extends StatelessWidget {
  const _StepGroupHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.x6, bottom: AppSpacing.x4),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.tiny.copyWith(
          color: AppColors.n500,
          letterSpacing: 0.6,
          fontWeight: FontWeight.w700,
        ),
      ),
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
        gradient: AppGradients.surfaceCard,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.n200),
        boxShadow: AppShadows.shCard,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.r8),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [spec.bg.withValues(alpha: 0.82), spec.bg],
              ),
              border: Border.all(color: spec.fg.withValues(alpha: 0.10)),
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
