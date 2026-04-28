import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../profile/application/profile_controller.dart';
import '../../projects/application/project_controller.dart';
import '../../projects/domain/membership.dart';
import '../data/team_repository.dart';

/// s-member-not-found — 64×64 yellowBg + magnifyingGlassMinus, SMS preview,
/// 3 кнопки (Отправить SMS / Скопировать ссылку / Попробовать другой номер).
class MemberNotFoundScreen extends ConsumerStatefulWidget {
  const MemberNotFoundScreen({
    required this.projectId,
    required this.phone,
    super.key,
  });

  final String projectId;
  final String phone;

  @override
  ConsumerState<MemberNotFoundScreen> createState() =>
      _MemberNotFoundScreenState();
}

class _MemberNotFoundScreenState
    extends ConsumerState<MemberNotFoundScreen> {
  bool _busy = false;

  Future<void> _sendInvite() async {
    setState(() => _busy = true);
    try {
      await ref.read(teamRepositoryProvider).invite(
            projectId: widget.projectId,
            phone: widget.phone,
            role: MembershipRole.foreman,
          );
      if (!mounted) return;
      AppToast.show(
        context,
        message: 'Приглашение отправлено',
        kind: AppToastKind.success,
      );
      context.go(AppRoutes.projectAddMemberWith(widget.projectId));
    } on TeamException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      AppToast.show(
        context,
        message: e.failure.userMessage,
        kind: AppToastKind.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(projectControllerProvider(widget.projectId));
    final inviter =
        ref.watch(profileControllerProvider).valueOrNull?.firstName ?? '';
    final projectName = project.maybeWhen(
      data: (p) => p.title,
      orElse: () => 'проект',
    );
    final inviteCode = 'abc123';
    final inviteUrl = 'https://kontrolremont.app/invite/$inviteCode';
    final smsBody =
        '${inviter.isEmpty ? 'Вас' : '$inviter И.'} приглашает вас в '
        'приложение «Контроль ремонта» для совместной работы на проекте '
        '«$projectName». Скачайте: $inviteUrl';

    return AppScaffold(
      showBack: true,
      title: 'Подрядчик не найден',
      backgroundColor: AppColors.n50,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.x20),
        children: [
          Center(
            child: Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.yellowBg,
                borderRadius: BorderRadius.circular(AppRadius.r20),
              ),
              child: Icon(
                PhosphorIconsRegular.magnifyingGlassMinus,
                size: 32,
                color: AppColors.yellowText,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x14),
          const Center(
            child: Text(
              'Пользователь не найден',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.n800,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x6),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Номер '),
                    TextSpan(
                      text: _formatPhone(widget.phone),
                      style: const TextStyle(
                        color: AppColors.n700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const TextSpan(
                      text: ' не зарегистрирован в приложении. '
                          'Отправьте SMS-приглашение.',
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.n500,
                  height: 1.6,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x24),
          const Text(
            'ПРЕДПРОСМОТР SMS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.n400,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.x8),
          AppSmsPreviewCard(
            phone: _formatPhone(widget.phone),
            message: smsBody,
          ),
          const SizedBox(height: AppSpacing.x16),
          AppButton(
            label: 'Отправить SMS-приглашение',
            icon: PhosphorIconsFill.paperPlaneTilt,
            isLoading: _busy,
            onPressed: _sendInvite,
          ),
          const SizedBox(height: AppSpacing.x10),
          AppButton(
            label: 'Скопировать ссылку',
            variant: AppButtonVariant.ghost,
            icon: PhosphorIconsRegular.link,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: inviteUrl));
              if (!context.mounted) return;
              AppToast.show(context, message: 'Ссылка скопирована');
            },
          ),
          const SizedBox(height: AppSpacing.x10),
          Center(
            child: GestureDetector(
              onTap: () => context.pop(),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Попробовать другой номер',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.n400,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatPhone(String e164) {
    if (!e164.startsWith('+')) return e164;
    final digits = e164.substring(1).replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11 || !digits.startsWith('7')) return e164;
    return '+7 (${digits.substring(1, 4)}) ${digits.substring(4, 7)}-'
        '${digits.substring(7, 9)}-${digits.substring(9, 11)}';
  }
}
