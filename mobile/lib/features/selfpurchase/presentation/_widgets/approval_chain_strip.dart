import 'package:flutter/material.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';

/// Состояние шага в approval-chain (e-selfpurchase-foreman / pending /
/// confirmed): кто текущий, кто прошёл, кто впереди.
enum ChainStepState { done, current, pending }

/// 2-/3-step approval chain для самозакупов:
/// `мастер → бригадир → заказчик` или `бригадир → заказчик`.
/// Каждый chip — одна сторона; arrow между chip-ами тоже dim/active.
class ApprovalChainStrip extends StatelessWidget {
  const ApprovalChainStrip({
    required this.steps,
    this.footnote,
    super.key,
  });

  final List<ChainStep> steps;

  /// Подпись под цепочкой («После вашего подтверждения…»).
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x14,
        vertical: AppSpacing.x10,
      ),
      decoration: BoxDecoration(
        color: AppColors.n50,
        border: Border.all(color: AppColors.n200),
        borderRadius: BorderRadius.circular(AppRadius.r12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ЦЕПОЧКА ОДОБРЕНИЯ',
            style: AppTextStyles.tiny.copyWith(
              color: AppColors.n400,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                _Chip(step: steps[i]),
                if (i < steps.length - 1)
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 12,
                    color: steps[i + 1].state == ChainStepState.pending
                        ? AppColors.n300
                        : AppColors.n400,
                  ),
              ],
            ],
          ),
          if (footnote != null) ...[
            const SizedBox(height: 6),
            Text(
              footnote!,
              style: AppTextStyles.tiny.copyWith(
                color: AppColors.n400,
                fontWeight: FontWeight.w500,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ChainStep {
  const ChainStep({
    required this.label,
    required this.state,
    required this.tone,
  });

  final String label;
  final ChainStepState state;
  final ChainStepTone tone;
}

enum ChainStepTone { brand, purple, customer }

class _Chip extends StatelessWidget {
  const _Chip({required this.step});

  final ChainStep step;

  @override
  Widget build(BuildContext context) {
    final pending = step.state == ChainStepState.pending;
    final current = step.state == ChainStepState.current;
    final palette = _palette(step.tone);
    final bg = pending
        ? AppColors.n100
        : (current ? palette.bg : palette.bgMuted);
    final fg = pending
        ? AppColors.n500
        : (current ? palette.fg : palette.fgMuted);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(
          color: current ? fg : Colors.transparent,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(AppRadius.r8),
      ),
      child: Text(
        step.label,
        style: AppTextStyles.tiny.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }

  _Palette _palette(ChainStepTone tone) => switch (tone) {
        ChainStepTone.brand => const _Palette(
            bg: AppColors.brandLight,
            bgMuted: AppColors.brandLight,
            fg: AppColors.brand,
            fgMuted: AppColors.brand,
          ),
        ChainStepTone.purple => const _Palette(
            bg: AppColors.purpleBg,
            bgMuted: AppColors.purpleBg,
            fg: AppColors.purple,
            fgMuted: AppColors.purple,
          ),
        ChainStepTone.customer => const _Palette(
            bg: AppColors.brandLight,
            bgMuted: AppColors.n100,
            fg: AppColors.brand,
            fgMuted: AppColors.n500,
          ),
      };
}

class _Palette {
  const _Palette({
    required this.bg,
    required this.bgMuted,
    required this.fg,
    required this.fgMuted,
  });

  final Color bg;
  final Color bgMuted;
  final Color fg;
  final Color fgMuted;
}
