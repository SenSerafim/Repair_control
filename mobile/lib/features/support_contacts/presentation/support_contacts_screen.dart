import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/support_contacts_controller.dart';
import '../domain/support_contacts.dart';

/// Единый экран контактов поддержки. На него ведут все кнопки
/// «Связаться» в приложении (Help, Profile, ConsoleScreen).
class SupportContactsScreen extends ConsumerWidget {
  const SupportContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(supportContactsProvider);

    return AppScaffold(
      showBack: true,
      title: 'Поддержка',
      backgroundColor: AppColors.n50,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
      body: async.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить контакты',
          onRetry: () => ref.invalidate(supportContactsProvider),
        ),
        data: (contacts) => _Body(contacts: contacts),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.contacts});
  final SupportContacts contacts;

  @override
  Widget build(BuildContext context) {
    if (contacts.isEmpty) {
      return const AppEmptyState(
        title: 'Контакты пока не настроены',
        subtitle: 'Администратор добавит каналы связи в ближайшее время.',
      );
    }

    final rows = <Widget>[
      if (contacts.maxUrl != null)
        AppMenuRow(
          icon: PhosphorIconsFill.chatTeardropDots,
          iconBg: AppColors.brandLight,
          iconColor: AppColors.brand,
          label: 'Написать в MAX',
          value: _shortUrl(contacts.maxUrl!),
          valueColor: AppColors.brand,
          onTap: () => _launch(Uri.parse(contacts.maxUrl!)),
        ),
      if (contacts.vkUrl != null)
        AppMenuRow(
          icon: PhosphorIconsFill.chats,
          iconBg: AppColors.brandLight,
          iconColor: AppColors.brand,
          label: 'Написать во VK',
          value: _shortUrl(contacts.vkUrl!),
          valueColor: AppColors.brand,
          onTap: () => _launch(Uri.parse(contacts.vkUrl!)),
        ),
      if (contacts.telegramUrl != null)
        AppMenuRow(
          icon: PhosphorIconsFill.paperPlaneTilt,
          iconBg: AppColors.brandLight,
          iconColor: AppColors.brand,
          label: 'Написать в Telegram',
          value: _shortUrl(contacts.telegramUrl!),
          valueColor: AppColors.brand,
          onTap: () => _launch(Uri.parse(contacts.telegramUrl!)),
        ),
      if (contacts.email case final email?)
        AppMenuRow(
          icon: PhosphorIconsFill.envelopeSimple,
          iconBg: AppColors.brandLight,
          iconColor: AppColors.brand,
          label: 'Написать на почту',
          value: email,
          valueColor: AppColors.brand,
          onTap: () => _launch(Uri(scheme: 'mailto', path: email)),
        ),
      if (contacts.phone case final phone?)
        AppMenuRow(
          icon: PhosphorIconsFill.phone,
          iconBg: AppColors.greenLight,
          iconColor: AppColors.greenDark,
          label: 'Позвонить',
          value: phone,
          valueColor: AppColors.greenDark,
          onTap: () => _launch(Uri(scheme: 'tel', path: phone)),
        ),
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x16),
      children: [
        const Text(
          'Свяжитесь с поддержкой удобным способом. Ответим в рабочее время.',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.n500,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.x16),
        AppMenuGroup(children: rows),
        const SizedBox(height: AppSpacing.x24),
      ],
    );
  }

  static String _shortUrl(String raw) {
    return raw.replaceFirst(RegExp('^https?://'), '');
  }

  static Future<void> _launch(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
