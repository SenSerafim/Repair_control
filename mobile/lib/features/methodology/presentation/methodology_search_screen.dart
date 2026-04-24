import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/methodology_controller.dart';
import '../domain/methodology.dart';

class MethodologySearchScreen extends ConsumerStatefulWidget {
  const MethodologySearchScreen({super.key});

  @override
  ConsumerState<MethodologySearchScreen> createState() =>
      _MethodologySearchScreenState();
}

class _MethodologySearchScreenState
    extends ConsumerState<MethodologySearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      ref.read(methodologySearchQueryProvider.notifier).state = v;
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(methodologySearchResultsProvider);
    final query = ref.watch(methodologySearchQueryProvider);

    return AppScaffold(
      showBack: true,
      title: 'Поиск по методичке',
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
      body: Column(
        children: [
          const SizedBox(height: AppSpacing.x12),
          TextField(
            controller: _controller,
            autofocus: true,
            onChanged: _onChanged,
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.n400,
                size: 20,
              ),
              hintText: 'Например, «гипсокартон»',
              hintStyle:
                  AppTextStyles.body.copyWith(color: AppColors.n400),
              filled: true,
              fillColor: AppColors.n0,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.r12),
                borderSide:
                    const BorderSide(color: AppColors.n200, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x12),
          Expanded(
            child: query.trim().length < 2
                ? const AppEmptyState(
                    title: 'Введите запрос',
                    subtitle: 'Минимум 2 символа.',
                    icon: Icons.search_rounded,
                  )
                : async.when(
                    loading: () => const AppLoadingState(),
                    error: (e, _) => AppErrorState(
                      title: 'Ошибка поиска',
                      onRetry: () => ref
                          .invalidate(methodologySearchResultsProvider),
                    ),
                    data: (hits) {
                      if (hits.isEmpty) {
                        return const AppEmptyState(
                          title: 'Ничего не найдено',
                          icon: Icons.search_off_rounded,
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: hits.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.x10),
                        itemBuilder: (_, i) => _HitRow(
                          hit: hits[i],
                          onTap: () => context.push(
                            '/methodology/articles/${hits[i].id}',
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _HitRow extends StatelessWidget {
  const _HitRow({required this.hit, required this.onTap});

  final MethodologySearchHit hit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.x14),
        decoration: BoxDecoration(
          color: AppColors.n0,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.n200, width: 1.5),
          boxShadow: AppShadows.sh1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(hit.title, style: AppTextStyles.subtitle),
            if (hit.snippet.isNotEmpty) ...[
              const SizedBox(height: 4),
              _SnippetText(snippet: hit.snippet),
            ],
          ],
        ),
      ),
    );
  }
}

/// Рендерит snippet с подсветкой backend-разметки «…» (StartSel/StopSel из FTS).
class _SnippetText extends StatelessWidget {
  const _SnippetText({required this.snippet});

  final String snippet;

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    final regex = RegExp('«([^»]+)»');
    var lastEnd = 0;
    for (final match in regex.allMatches(snippet)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: snippet.substring(lastEnd, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: const TextStyle(
            backgroundColor: AppColors.yellowBg,
            fontWeight: FontWeight.w800,
            color: AppColors.yellowText,
          ),
        ),
      );
      lastEnd = match.end;
    }
    if (lastEnd < snippet.length) {
      spans.add(TextSpan(text: snippet.substring(lastEnd)));
    }
    return Text.rich(
      TextSpan(
        children: spans,
        style: AppTextStyles.caption,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}
