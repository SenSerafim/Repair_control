import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';

/// s-feedback — простой экран с центральной иконкой и кнопкой
/// «Открыть Telegram». Полная форма обратной связи остаётся в админке.
class FeedbackScreen extends ConsumerWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      showBack: true,
      title: 'Обратная связь',
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppGradients.brandButton,
              borderRadius: BorderRadius.circular(AppRadius.r24),
              boxShadow: AppShadows.shBlue,
            ),
            child: Icon(
              PhosphorIconsFill.chatCircleDots,
              color: AppColors.n0,
              size: 32,
            ),
          ),
          const SizedBox(height: AppSpacing.x20),
          const Text(
            'Напишите нам',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.n800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: AppSpacing.x10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.x24),
            child: Text(
              'Предложения, баги, вопросы — всё принимаем. '
              'Отвечаем в Telegram в течение 24 часов.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.n500,
                height: 1.55,
              ),
            ),
          ),
          const Spacer(flex: 3),
          AppButton(
            label: 'Открыть Telegram',
            icon: PhosphorIconsFill.chatCircleDots,
            onPressed: _openTelegram,
          ),
          const SizedBox(height: AppSpacing.x24),
        ],
      ),
    );
  }

  Future<void> _openTelegram() async {
    final tgApp = Uri.parse('tg://resolve?domain=kontrolremont');
    final tgWeb = Uri.parse('https://t.me/kontrolremont');
    if (await canLaunchUrl(tgApp)) {
      await launchUrl(tgApp, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(tgWeb, mode: LaunchMode.externalApplication);
    }
  }
}
