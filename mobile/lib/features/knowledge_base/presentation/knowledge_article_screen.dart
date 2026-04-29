import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/knowledge_controller.dart';
import 'widgets/knowledge_asset_view.dart';

class KnowledgeArticleScreen extends ConsumerWidget {
  const KnowledgeArticleScreen({super.key, required this.articleId});

  final String articleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(knowledgeArticleProvider(articleId));

    return AppScaffold(
      showBack: true,
      title: async.value?.title ?? 'Статья',
      backgroundColor: AppColors.n50,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
      body: async.when(
        loading: () => const AppLoadingState(),
        error: (_, __) => AppErrorState(
          title: 'Не удалось загрузить статью',
          onRetry: () => ref.invalidate(knowledgeArticleProvider(articleId)),
        ),
        data: (article) => ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.x16),
          children: [
            Text(
              article.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.n900,
                height: 1.3,
              ),
            ),
            if (article.categoryTitle != null) ...[
              const SizedBox(height: 4),
              Text(
                article.categoryTitle!,
                style: const TextStyle(fontSize: 12, color: AppColors.n400),
              ),
            ],
            const SizedBox(height: AppSpacing.x16),
            MarkdownBody(
              data: article.body,
              selectable: true,
              onTapLink: (text, href, title) async {
                if (href == null || href.isEmpty) return;
                final uri = Uri.tryParse(href);
                if (uri == null) return;
                // Безопасные схемы: http(s), mailto, tel. Всё остальное —
                // потенциальный risk (javascript:, file://, и т.д.) — игнорируем.
                const allowed = {'http', 'https', 'mailto', 'tel'};
                if (!allowed.contains(uri.scheme)) return;
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(
                  fontSize: 15,
                  color: AppColors.n800,
                  height: 1.55,
                ),
                h1: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.n900,
                ),
                h2: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.n900,
                ),
                h3: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.n900,
                ),
                listBullet: const TextStyle(
                  fontSize: 15,
                  color: AppColors.n800,
                ),
                code: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  backgroundColor: AppColors.n100,
                ),
              ),
            ),
            if (article.assets.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.x24),
              const Text(
                'МАТЕРИАЛЫ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.n400,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: AppSpacing.x10),
              for (final asset in article.assets)
                KnowledgeAssetView(asset: asset),
            ],
            const SizedBox(height: AppSpacing.x24),
          ],
        ),
      ),
    );
  }
}
