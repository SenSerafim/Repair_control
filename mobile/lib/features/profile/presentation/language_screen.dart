import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/profile_controller.dart';

/// s-language — RU/EN toggle.
class LanguageScreen extends ConsumerStatefulWidget {
  const LanguageScreen({super.key});

  @override
  ConsumerState<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends ConsumerState<LanguageScreen> {
  bool _saving = false;

  Future<void> _select(String code) async {
    final current = ref.read(profileControllerProvider).value?.language;
    if (current == code) return;
    setState(() => _saving = true);
    final failure = await ref
        .read(profileControllerProvider.notifier)
        .updateProfile(language: code);
    if (!mounted) return;
    setState(() => _saving = false);
    if (failure != null) {
      AppToast.show(
        context,
        message: failure.userMessage,
        kind: AppToastKind.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(profileControllerProvider);
    final current = async.value?.language ?? 'ru';

    return AppScaffold(
      showBack: true,
      title: 'Язык',
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
      body: ListView(
        padding: const EdgeInsets.only(top: AppSpacing.x16),
        children: [
          _LanguageOption(
            label: 'Русский',
            code: 'ru',
            selected: current == 'ru',
            saving: _saving,
            onTap: () => _select('ru'),
          ),
          const SizedBox(height: AppSpacing.x10),
          _LanguageOption(
            label: 'English',
            code: 'en',
            selected: current == 'en',
            saving: _saving,
            onTap: () => _select('en'),
          ),
          const SizedBox(height: AppSpacing.x16),
          const Text(
            'EN-перевод — задел (не все строки переведены). '
            'Полный EN — в бэклоге после релиза.',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.code,
    required this.selected,
    required this.saving,
    required this.onTap,
  });

  final String label;
  final String code;
  final bool selected;
  final bool saving;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.all(AppSpacing.x16),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandLight : AppColors.n0,
          borderRadius: AppRadius.card,
          border: Border.all(
            color: selected ? AppColors.brand : AppColors.n200,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.h2),
                  Text(code.toUpperCase(), style: AppTextStyles.caption),
                ],
              ),
            ),
            if (selected && !saving)
              const Icon(Icons.check_circle, color: AppColors.brand)
            else if (saving && selected)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }
}
