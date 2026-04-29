import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_providers.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/legal_publications_controller.dart';
import '../domain/legal_publication.dart';

/// Bottom-sheet со списком юридических PDF-публикаций. Тап на пункт
/// открывает PDF в внешнем браузере по публичному URL — пользователь
/// может расшарить ссылку, и она работает без авторизации.
class LegalPublicationsSheet extends ConsumerWidget {
  const LegalPublicationsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LegalPublicationsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(legalPublicationsProvider);
    final apiBaseUrl = ref.read(appEnvProvider).apiBaseUrl;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.x12),
        decoration: BoxDecoration(
          color: AppColors.n0,
          borderRadius: BorderRadius.circular(AppRadius.r20),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Юридические документы',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.n900,
                ),
              ),
              const SizedBox(height: AppSpacing.x6),
              const Text(
                'Тап откроет PDF в браузере. Ссылку можно сохранить или поделиться.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.n500,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.x16),
              Flexible(
                child: async.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: AppLoadingState(),
                  ),
                  error: (_, __) => AppErrorState(
                    title: 'Не удалось загрузить документы',
                    onRetry: () => ref.invalidate(legalPublicationsProvider),
                  ),
                  data: (items) => items.isEmpty
                      ? const AppEmptyState(
                          title: 'Документов пока нет',
                          subtitle:
                              'Администратор опубликует политики и согласия в ближайшее время.',
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.x4),
                          itemBuilder: (_, i) => _Row(
                            doc: items[i],
                            url: items[i].publicUrl(apiBaseUrl),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.x8),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Закрыть'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.doc, required this.url});

  final LegalPublication doc;
  final String url;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.r12),
      onTap: () => _open(url),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x12,
          vertical: AppSpacing.x12,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.brandLight,
                borderRadius: BorderRadius.circular(AppRadius.r12),
              ),
              child: const Icon(
                PhosphorIconsFill.filePdf,
                color: AppColors.brand,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.n900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Версия ${doc.version} · ${_humanSize(doc.sizeBytes)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.n500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_outward_rounded,
              size: 20,
              color: AppColors.n400,
            ),
          ],
        ),
      ),
    );
  }

  static String _humanSize(int bytes) {
    if (bytes < 1024) return '$bytes Б';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} КБ';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} МБ';
  }

  static Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
