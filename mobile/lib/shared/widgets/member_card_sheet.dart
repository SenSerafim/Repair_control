import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/text_styles.dart';
import '../../core/theme/tokens.dart';
import 'app_avatar.dart';
import 'app_bottom_sheet.dart';
import 'app_option_row.dart';
import 'app_toast.dart';

/// Карточка участника проекта (П1.4 / П2.1).
///
/// Показывается в bottom-sheet'е при тапе на имя в чате (chat_conversation_screen)
/// или в списке команды (team_screen). Содержит: имя+фамилия, аватар, роль в
/// текущем проекте, телефон (с возможностью позвонить), список других общих
/// проектов с этим пользователем (kliккаемый).
class MemberCardData {
  const MemberCardData({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.roleInCurrentProject,
    required this.currentProjectTitle,
    this.phone,
    this.email,
    this.avatarUrl,
    this.commonProjects = const [],
  });

  final String userId;
  final String firstName;
  final String lastName;
  final String roleInCurrentProject;
  final String currentProjectTitle;
  final String? phone;
  final String? email;
  final String? avatarUrl;

  /// Другие общие с текущим пользователем проекты — id, название, роль участника
  /// в этом проекте (для подписи под названием).
  final List<({String id, String title, String role})> commonProjects;

  String get fullName => '$firstName $lastName'.trim();
}

/// Открывает bottom-sheet с карточкой участника.
///
/// [onRemoveFromTeam] — опциональный callback. Если задан, в карточке
/// появляется кнопка «Убрать из команды» (П2.12 — только для заказчика
/// и представителя с canManageTeam, проверка на caller-side).
/// [onOpenChat] — открыть чат проекта.
Future<void> showMemberCardSheet(
  BuildContext context, {
  required MemberCardData data,
  VoidCallback? onRemoveFromTeam,
  VoidCallback? onOpenChat,
  VoidCallback? onOpenProfile,
  ValueChanged<String>? onOpenProject,
}) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    child: _MemberCardSheet(
      data: data,
      onRemoveFromTeam: onRemoveFromTeam,
      onOpenChat: onOpenChat,
      onOpenProfile: onOpenProfile,
      onOpenProject: onOpenProject,
    ),
  );
}

class _MemberCardSheet extends StatelessWidget {
  const _MemberCardSheet({
    required this.data,
    this.onRemoveFromTeam,
    this.onOpenChat,
    this.onOpenProfile,
    this.onOpenProject,
  });

  final MemberCardData data;
  final VoidCallback? onRemoveFromTeam;
  final VoidCallback? onOpenChat;
  final VoidCallback? onOpenProfile;
  final ValueChanged<String>? onOpenProject;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Хедер: аватар + имя + роль ───
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
            child: Row(
              children: [
                AppAvatar(seed: data.userId, size: 56),
                const SizedBox(width: AppSpacing.x12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.fullName.isNotEmpty ? data.fullName : 'Участник',
                        style: AppTextStyles.h2,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${data.currentProjectTitle} · ${data.roleInCurrentProject}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.n500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ─── Телефон (если есть) ───
          if (data.phone != null && data.phone!.trim().isNotEmpty) ...[
            AppOptionRow(
              icon: Icons.phone_outlined,
              iconBg: AppColors.greenLight,
              iconFg: AppColors.greenDark,
              title: data.phone!,
              subtitle: 'Позвонить',
              onTap: () => _launchTel(context, data.phone!),
            ),
            const SizedBox(height: 8),
          ],

          // ─── Email (если есть) ───
          if (data.email != null && data.email!.trim().isNotEmpty) ...[
            AppOptionRow(
              icon: Icons.email_outlined,
              iconBg: AppColors.brandLight,
              iconFg: AppColors.brand,
              title: data.email!,
              subtitle: 'Скопировать',
              onTap: () =>
                  _copyToClipboard(context, data.email!, 'Email скопирован'),
            ),
            const SizedBox(height: 8),
          ],

          // ─── Действие: открыть чат проекта ───
          if (onOpenChat != null) ...[
            AppOptionRow(
              icon: Icons.chat_bubble_outline,
              iconBg: AppColors.brandLight,
              iconFg: AppColors.brand,
              title: 'Открыть чат проекта',
              subtitle: data.currentProjectTitle,
              onTap: () {
                Navigator.of(context).pop();
                onOpenChat!();
              },
            ),
            const SizedBox(height: 8),
          ],

          // ─── Действие: открыть профиль ───
          if (onOpenProfile != null) ...[
            AppOptionRow(
              icon: Icons.person_outline,
              iconBg: AppColors.purpleBg,
              iconFg: AppColors.purple,
              title: 'Профиль участника',
              subtitle: 'Подробная информация',
              onTap: () {
                Navigator.of(context).pop();
                onOpenProfile!();
              },
            ),
            const SizedBox(height: 8),
          ],

          // ─── Список других общих проектов ───
          if (data.commonProjects.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Text(
                'Другие общие проекты',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.n500,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            ...data.commonProjects.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppOptionRow(
                  icon: Icons.folder_open_outlined,
                  iconBg: AppColors.n50,
                  iconFg: AppColors.n500,
                  title: p.title,
                  subtitle: p.role,
                  onTap: () {
                    Navigator.of(context).pop();
                    onOpenProject?.call(p.id);
                  },
                ),
              ),
            ),
          ],

          // ─── Удаление из команды (П2.12) ───
          if (onRemoveFromTeam != null) ...[
            const Divider(height: 24, color: AppColors.n100),
            AppOptionRow(
              icon: Icons.person_remove_outlined,
              iconBg: AppColors.redBg,
              iconFg: AppColors.redText,
              title: 'Убрать из команды',
              subtitle: 'Доступ к проекту прекратится сразу',
              onTap: () async {
                Navigator.of(context).pop();
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('Удалить ${data.fullName}?'),
                    content: const Text(
                      'Участник потеряет доступ к проекту, чату и документам моментально. '
                      'Действие необратимо.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Отмена'),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.redText,
                        ),
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Удалить'),
                      ),
                    ],
                  ),
                );
                if (ok == true) onRemoveFromTeam!();
              },
            ),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _launchTel(BuildContext context, String phone) async {
    final uri = Uri.parse('tel:${phone.replaceAll(RegExp(r'[^0-9+]'), '')}');
    final ok = await canLaunchUrl(uri);
    if (ok) {
      await launchUrl(uri);
    } else if (context.mounted) {
      AppToast.show(
        context,
        message: 'Не удалось открыть набор номера',
        kind: AppToastKind.error,
      );
    }
  }

  Future<void> _copyToClipboard(
    BuildContext context,
    String text,
    String successMessage,
  ) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      AppToast.show(
        context,
        message: successMessage,
        kind: AppToastKind.success,
      );
    }
  }
}
