import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/knowledge_controller.dart';

class KnowledgeSearchScreen extends ConsumerStatefulWidget {
  const KnowledgeSearchScreen({super.key});

  @override
  ConsumerState<KnowledgeSearchScreen> createState() =>
      _KnowledgeSearchScreenState();
}

class _KnowledgeSearchScreenState extends ConsumerState<KnowledgeSearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';
  Timer? _debounce;

  @override
  void dispose() {
    _ctrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final hits = _query.length >= 2
        ? ref.watch(knowledgeSearchProvider(_query))
        : null;

    return AppScaffold(
      showBack: true,
      title: 'Поиск в Базе знаний',
      backgroundColor: AppColors.n50,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
      body: Column(
        children: [
          const SizedBox(height: AppSpacing.x12),
          TextField(
            controller: _ctrl,
            autofocus: true,
            onChanged: _onChanged,
            decoration: InputDecoration(
              hintText: 'Что ищем?',
              prefixIcon: const Icon(PhosphorIconsFill.magnifyingGlass,
                  size: 18, color: AppColors.n400),
              filled: true,
              fillColor: AppColors.n0,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.r12),
                borderSide: const BorderSide(color: AppColors.n200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.r12),
                borderSide: const BorderSide(color: AppColors.n200),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x12),
          Expanded(
            child: hits == null
                ? const Center(
                    child: Text(
                      'Введите минимум 2 символа',
                      style: TextStyle(color: AppColors.n400, fontSize: 13),
                    ),
                  )
                : hits.when(
                    loading: () => const AppLoadingState(),
                    error: (_, __) => AppErrorState(
                      title: 'Поиск не удался',
                      onRetry: () =>
                          ref.invalidate(knowledgeSearchProvider(_query)),
                    ),
                    data: (results) => results.isEmpty
                        ? const AppEmptyState(
                            title: 'Ничего не найдено',
                            subtitle: 'Попробуйте другие слова.',
                          )
                        : ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: results.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 6),
                            itemBuilder: (_, i) {
                              final h = results[i];
                              return Container(
                                decoration: BoxDecoration(
                                  color: AppColors.n0,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.r12),
                                ),
                                child: ListTile(
                                  title: Text(
                                    h.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.n900,
                                    ),
                                  ),
                                  subtitle: _StripMarkSnippet(snippet: h.snippet),
                                  onTap: () => context.push(
                                    AppRoutes.knowledgeArticleWith(h.id),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Простая отрисовка снипета с подсветкой <mark>...</mark> от ts_headline.
class _StripMarkSnippet extends StatelessWidget {
  const _StripMarkSnippet({required this.snippet});
  final String snippet;

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    final regex = RegExp('<mark>(.*?)</mark>');
    var lastEnd = 0;
    for (final match in regex.allMatches(snippet)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: snippet.substring(lastEnd, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(1) ?? '',
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.brand,
        ),
      ));
      lastEnd = match.end;
    }
    if (lastEnd < snippet.length) {
      spans.add(TextSpan(text: snippet.substring(lastEnd)));
    }
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 13, color: AppColors.n500, height: 1.4),
        children: spans,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}
