import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/profile_controller.dart';

/// s-language / s-language-en — bottom-sheet выбора языка интерфейса.
///
/// Активная карточка получает синий чекбокс; tap по неактивной — мгновенное
/// переключение через `profile_controller.updateProfile(language: ...)`.
Future<void> showLanguageSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  await showAppBottomSheet<void>(
    context: context,
    child: const _LanguageSheet(),
  );
}

class _LanguageSheet extends ConsumerStatefulWidget {
  const _LanguageSheet();

  @override
  ConsumerState<_LanguageSheet> createState() => _LanguageSheetState();
}

class _LanguageSheetState extends ConsumerState<_LanguageSheet> {
  bool _busy = false;

  Future<void> _pick(String code) async {
    final current = ref.read(profileControllerProvider).valueOrNull?.language;
    if (current == code || _busy) return;
    setState(() => _busy = true);
    await ref
        .read(profileControllerProvider.notifier)
        .updateProfile(language: code);
    if (!mounted) return;
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(
      profileControllerProvider.select((s) => s.valueOrNull?.language ?? 'ru'),
    );
    final isRu = lang == 'ru';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppBottomSheetHeader(
          title: isRu ? 'Язык приложения' : 'App language',
          subtitle: isRu
              ? 'Интерфейс переключится мгновенно'
              : 'Interface will switch instantly',
        ),
        AppFlagCheckbox(
          flag: '🇷🇺',
          label: 'Русский',
          sub: 'Основной язык',
          selected: isRu,
          onTap: _busy ? null : () => _pick('ru'),
        ),
        const SizedBox(height: AppSpacing.x10),
        AppFlagCheckbox(
          flag: '🇬🇧',
          label: 'English',
          sub: 'Interface language',
          selected: !isRu,
          onTap: _busy ? null : () => _pick('en'),
        ),
      ],
    );
  }
}
