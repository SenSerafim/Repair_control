import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/methodology_controller.dart';

/// d-method-article — статья методички.
///
/// Body парсится в три типа блоков:
/// - параграфы (обычный текст);
/// - info-блоки (строки начинающиеся с `> ` — выделяются brandLight + accent);
/// - заголовки (`## …`).
class ArticleScreen extends ConsumerWidget {
  const ArticleScreen({required this.articleId, super.key});

  final String articleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(methodologyArticleProvider(articleId));

    return AppScaffold(
      showBack: true,
      title: 'Статья',
      padding: EdgeInsets.zero,
      body: async.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить статью',
          onRetry: () =>
              ref.invalidate(methodologyArticleProvider(articleId)),
        ),
        data: (a) => RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(methodologyArticleProvider(articleId)),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x16,
              AppSpacing.x20,
              AppSpacing.x16,
              AppSpacing.x32,
            ),
            children: [
              Text(
                a.title,
                style: AppTextStyles.screenTitle.copyWith(
                  fontSize: 22,
                  color: AppColors.n900,
                ),
              ),
              const SizedBox(height: AppSpacing.x10),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.brandLight,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      'Версия ${a.version}',
                      style: AppTextStyles.tiny.copyWith(
                        color: AppColors.brand,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x8),
                  Text(
                    'Обновлено ${DateFormat('d MMM y', 'ru').format(a.updatedAt)}',
                    style: AppTextStyles.tiny.copyWith(color: AppColors.n500),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x20),
              ..._renderBody(a.body),
            ],
          ),
        ),
      ),
    );
  }
}

List<Widget> _renderBody(String body) {
  final blocks = <Widget>[];
  final lines = body.split('\n');
  final paragraph = StringBuffer();

  void flushParagraph() {
    if (paragraph.isEmpty) return;
    blocks
      ..add(Text(
        paragraph.toString().trim(),
        style: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.n700,
          height: 1.7,
        ),
      ))
      ..add(const SizedBox(height: AppSpacing.x16));
    paragraph.clear();
  }

  for (final raw in lines) {
    final line = raw.trimRight();
    if (line.isEmpty) {
      flushParagraph();
      continue;
    }
    if (line.startsWith('## ')) {
      flushParagraph();
      blocks
        ..add(Text(
          line.substring(3).trim(),
          style: AppTextStyles.h2.copyWith(
            fontSize: 17,
            color: AppColors.n900,
          ),
        ))
        ..add(const SizedBox(height: AppSpacing.x10));
      continue;
    }
    if (line.startsWith('> ')) {
      flushParagraph();
      blocks
        ..add(_InfoBlock(text: line.substring(2).trim()))
        ..add(const SizedBox(height: AppSpacing.x16));
      continue;
    }
    if (paragraph.isNotEmpty) paragraph.write(' ');
    paragraph.write(line.trim());
  }
  flushParagraph();
  return blocks;
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: AppColors.brandLight,
        borderRadius: BorderRadius.circular(AppRadius.r12),
        border: const Border(
          left: BorderSide(color: AppColors.brand, width: 4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.brand,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.x10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.body.copyWith(
                color: AppColors.blueText,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
