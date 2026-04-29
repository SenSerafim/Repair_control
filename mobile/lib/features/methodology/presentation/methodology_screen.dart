import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/methodology_controller.dart';

/// d-methodology / d-method-empty.
class MethodologyScreen extends ConsumerStatefulWidget {
  const MethodologyScreen({super.key});

  @override
  ConsumerState<MethodologyScreen> createState() => _MethodologyScreenState();
}

class _MethodologyScreenState extends ConsumerState<MethodologyScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(methodologySectionsProvider);

    return AppScaffold(
      showBack: true,
      title: 'Методичка',
      padding: EdgeInsets.zero,
      body: Column(
        children: [
          _SearchBar(
            controller: _search,
            onSubmit: (q) {
              if (q.trim().isEmpty) return;
              context.push('/methodology/search?q=${Uri.encodeComponent(q)}');
            },
            onTapField: () => context.push('/methodology/search'),
          ),
          Expanded(
            child: async.when(
              loading: () => const AppLoadingState(),
              error: (e, _) => AppErrorState(
                title: 'Не удалось загрузить',
                onRetry: () =>
                    ref.read(methodologySectionsProvider.notifier).refresh(),
              ),
              data: (sections) {
                if (sections.isEmpty) {
                  return const AppEmptyState(
                    title: 'Контент готовится',
                    subtitle:
                        'Методичка наполняется администратором. Загляните позже.',
                    icon: Icons.menu_book_outlined,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(methodologySectionsProvider.notifier).refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.x16,
                      AppSpacing.x10,
                      AppSpacing.x16,
                      AppSpacing.x20,
                    ),
                    itemCount: sections.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.x10),
                    itemBuilder: (_, i) {
                      final s = sections[i];
                      return _SectionRow(
                        title: s.title,
                        articleCount: s.articles.length,
                        onTap: () =>
                            context.push('/methodology/sections/${s.id}'),
                      );
                    },
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

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onSubmit,
    required this.onTapField,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmit;
  final VoidCallback onTapField;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x16,
        AppSpacing.x12,
        AppSpacing.x16,
        AppSpacing.x6,
      ),
      child: GestureDetector(
        onTap: onTapField,
        behavior: HitTestBehavior.opaque,
        child: AbsorbPointer(
          child: TextField(
            controller: controller,
            onSubmitted: onSubmit,
            decoration: InputDecoration(
              hintText: 'Поиск по статьям...',
              hintStyle:
                  AppTextStyles.body.copyWith(color: AppColors.n400),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.n400,
              ),
              filled: true,
              fillColor: AppColors.n100,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.r12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.r12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionRow extends StatelessWidget {
  const _SectionRow({
    required this.title,
    required this.articleCount,
    required this.onTap,
  });

  final String title;
  final int articleCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tone = MethodologySectionTone.fromTitle(title);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.x14),
        decoration: BoxDecoration(
          color: AppColors.n0,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.n200),
          boxShadow: AppShadows.sh1,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tone.bg,
                borderRadius: BorderRadius.circular(AppRadius.r12),
              ),
              child: Icon(tone.icon, color: tone.fg, size: 22),
            ),
            const SizedBox(width: AppSpacing.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.subtitle.copyWith(
                      fontSize: 15,
                      color: AppColors.n900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _articlesLabel(articleCount),
                    style: AppTextStyles.tiny.copyWith(color: AppColors.n500),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.n300,
            ),
          ],
        ),
      ),
    );
  }

  static String _articlesLabel(int n) {
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod10 == 1 && mod100 != 11) return '$n статья';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
      return '$n статьи';
    }
    return '$n статей';
  }
}

/// Маппинг title-раздела → цвет/иконка. Совпадение по подстроке (lower-case).
class MethodologySectionTone {
  const MethodologySectionTone({
    required this.icon,
    required this.bg,
    required this.fg,
  });

  final IconData icon;
  final Color bg;
  final Color fg;

  static const _fallback = MethodologySectionTone(
    icon: Icons.folder_special_outlined,
    bg: AppColors.brandLight,
    fg: AppColors.brand,
  );

  static MethodologySectionTone fromTitle(String title) {
    final t = title.toLowerCase();
    if (t.contains('электр')) {
      return const MethodologySectionTone(
        icon: Icons.bolt_rounded,
        bg: AppColors.yellowBg,
        fg: AppColors.yellowText,
      );
    }
    if (t.contains('сантех') || t.contains('водосн')) {
      return const MethodologySectionTone(
        icon: Icons.water_drop_outlined,
        bg: AppColors.blueBg,
        fg: AppColors.blueText,
      );
    }
    if (t.contains('демонт') || t.contains('снос')) {
      return const MethodologySectionTone(
        icon: Icons.construction_rounded,
        bg: AppColors.redBg,
        fg: AppColors.redText,
      );
    }
    if (t.contains('штукат')) {
      return const MethodologySectionTone(
        icon: Icons.format_paint_outlined,
        bg: AppColors.n100,
        fg: AppColors.n600,
      );
    }
    if (t.contains('плит')) {
      return const MethodologySectionTone(
        icon: Icons.grid_view_rounded,
        bg: AppColors.brandLight,
        fg: AppColors.brand,
      );
    }
    if (t.contains('покрас') || t.contains('покрытие')) {
      return const MethodologySectionTone(
        icon: Icons.brush_outlined,
        bg: AppColors.purpleBg,
        fg: AppColors.purple,
      );
    }
    if (t.contains('пол')) {
      return const MethodologySectionTone(
        icon: Icons.layers_outlined,
        bg: AppColors.greenLight,
        fg: AppColors.greenDark,
      );
    }
    if (t.contains('кондици') || t.contains('вентил')) {
      return const MethodologySectionTone(
        icon: Icons.air_rounded,
        bg: AppColors.blueBg,
        fg: AppColors.blueText,
      );
    }
    return _fallback;
  }
}
