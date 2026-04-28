import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/faq_controller.dart';
import '../domain/faq.dart';

/// s-help — список FAQ секций с раскрывающимися item'ами.
class HelpScreen extends ConsumerWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(faqProvider);

    return AppScaffold(
      showBack: true,
      title: 'Помощь и FAQ',
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
      body: async.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить FAQ',
          onRetry: () => ref.read(faqProvider.notifier).refresh(),
        ),
        data: (sections) {
          if (sections.isEmpty) {
            return AppEmptyState(
              title: 'Помощь временно недоступна',
              subtitle:
                  'Не удалось получить разделы. Потяните вниз, чтобы обновить.',
              icon: Icons.help_outline,
              onAction: () => ref.read(faqProvider.notifier).refresh(),
              actionLabel: 'Обновить',
            );
          }
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.x12),
            children: [
              for (final s in sections) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.x4,
                    vertical: AppSpacing.x8,
                  ),
                  child: Text(s.title, style: AppTextStyles.micro),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.n0,
                    borderRadius: BorderRadius.circular(AppRadius.r20),
                    boxShadow: AppShadows.sh1,
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < s.items.length; i++) ...[
                        _FaqItemTile(item: s.items[i]),
                        if (i < s.items.length - 1)
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.x16,
                            ),
                            child: Divider(
                              height: 1,
                              color: AppColors.n100,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.x16),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _FaqItemTile extends StatefulWidget {
  const _FaqItemTile({required this.item});

  final FaqItem item;

  @override
  State<_FaqItemTile> createState() => _FaqItemTileState();
}

class _FaqItemTileState extends State<_FaqItemTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      borderRadius: BorderRadius.circular(AppRadius.r20),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x16,
          vertical: AppSpacing.x14,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.item.question,
                    style: AppTextStyles.subtitle,
                  ),
                ),
                AnimatedRotation(
                  duration: AppDurations.fast,
                  turns: _expanded ? 0.5 : 0,
                  child: const Icon(
                    Icons.expand_more_rounded,
                    color: AppColors.n400,
                  ),
                ),
              ],
            ),
            AnimatedCrossFade(
              duration: AppDurations.fast,
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.x8),
                child: Text(
                  widget.item.answer,
                  style: AppTextStyles.body,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
