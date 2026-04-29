import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../support_contacts/application/support_contacts_controller.dart';
import '../../support_contacts/domain/support_contacts.dart';
import '../application/faq_controller.dart';

/// s-help — экран «Помощь и FAQ»: contact-row + FAQ.
/// Контакты подгружаются из админки через supportContactsProvider —
/// раньше были захардкожены, теперь админ управляет ими в /admin/settings.
class HelpScreen extends ConsumerWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(faqProvider);
    final contactsAsync = ref.watch(supportContactsProvider);

    return AppScaffold(
      showBack: true,
      title: 'Помощь',
      backgroundColor: AppColors.n50,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
      body: async.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить FAQ',
          onRetry: () => ref.read(faqProvider.notifier).refresh(),
        ),
        data: (sections) => ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.x16),
          children: [
            const Text(
              'Выберите способ связи или найдите ответ в часто '
              'задаваемых вопросах.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.n500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.x16),
            ...contactsAsync.maybeWhen(
              data: _buildContactRows,
              orElse: () => const <Widget>[],
            ),
            const SizedBox(height: AppSpacing.x12),
            AppMenuGroup(
              children: [
                AppMenuRow(
                  icon: PhosphorIconsFill.bookOpen,
                  iconBg: AppColors.brandLight,
                  iconColor: AppColors.brand,
                  label: 'База знаний',
                  value: 'Обучающие материалы',
                  onTap: () => context.push(AppRoutes.knowledge),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.x4),
              child: Text(
                'ЧАСТО ЗАДАВАЕМЫЕ ВОПРОСЫ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.n400,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.x10),
            for (final section in sections) ...[
              if (sections.length > 1) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.x4,
                    AppSpacing.x12,
                    AppSpacing.x4,
                    AppSpacing.x6,
                  ),
                  child: Text(
                    section.title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.n500,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
              AppMenuGroup(
                children: [
                  for (final item in section.items)
                    AppMenuRow(
                      label: item.question,
                      onTap: () => context.push(
                        AppRoutes.profileFaqDetailWith(item.id),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.x24),
          ],
        ),
      ),
    );
  }

  /// Контакт-строки. Скрывает пустые поля; если все пусты — возвращает
  /// пустой список (секция контактов не рисуется).
  List<Widget> _buildContactRows(SupportContacts contacts) {
    if (contacts.isEmpty) return const <Widget>[];
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
    return [AppMenuGroup(children: rows)];
  }

  static String _shortUrl(String raw) {
    return raw.replaceFirst(RegExp('^https?://'), '');
  }

  Future<void> _launch(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
