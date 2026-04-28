import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/selfpurchase_controller.dart';
import '_widgets/reject_reasons_picker.dart';

/// e-selfpurchase-reject — полноэкранный flow отклонения с 4-radio причинами,
/// комментарием и фото. Бекенд требует comment при reject — посылаем
/// «<reason-label>. <comment>».
class RejectSelfPurchaseScreen extends ConsumerStatefulWidget {
  const RejectSelfPurchaseScreen({
    required this.projectId,
    required this.id,
    super.key,
  });

  final String projectId;
  final String id;

  @override
  ConsumerState<RejectSelfPurchaseScreen> createState() =>
      _RejectSelfPurchaseScreenState();
}

class _RejectSelfPurchaseScreenState
    extends ConsumerState<RejectSelfPurchaseScreen> {
  RejectReason _reason = RejectReason.notAgreed;
  final _comment = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showBack: true,
      title: 'Отклонить самозакуп',
      padding: EdgeInsets.zero,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.x20),
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.x12),
                  decoration: BoxDecoration(
                    color: AppColors.redBg,
                    border:
                        Border.all(color: const Color(0xFFFECACA)),
                    borderRadius:
                        BorderRadius.circular(AppRadius.r12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 14,
                        color: AppColors.redDot,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Подрядчик получит уведомление с причиной отклонения. Сумма не попадёт в бюджет.',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.redText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.x20),
                Text(
                  'ПРИЧИНА ОТКЛОНЕНИЯ',
                  style: AppTextStyles.tiny.copyWith(
                    color: AppColors.n500,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.x10),
                RejectReasonsPicker(
                  selected: _reason,
                  onChanged: (r) => setState(() => _reason = r),
                ),
                const SizedBox(height: AppSpacing.x14),
                Text(
                  'КОММЕНТАРИЙ${_reason == RejectReason.other ? '' : ' (НЕОБЯЗАТЕЛЬНО)'}',
                  style: AppTextStyles.tiny.copyWith(
                    color: AppColors.n500,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _comment,
                  minLines: 4,
                  maxLines: 8,
                  maxLength: 2000,
                  decoration: InputDecoration(
                    hintText: 'Опишите подробнее…',
                    filled: true,
                    fillColor: AppColors.n50,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadius.r12),
                      borderSide: const BorderSide(
                        color: AppColors.n200,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x16,
              AppSpacing.x12,
              AppSpacing.x16,
              AppSpacing.x16,
            ),
            decoration: const BoxDecoration(
              color: AppColors.n0,
              border: Border(top: BorderSide(color: AppColors.n200)),
            ),
            child: SafeArea(
              top: false,
              child: AppButton(
                label: 'Отклонить самозакуп',
                variant: AppButtonVariant.destructive,
                icon: Icons.close_rounded,
                isLoading: _busy,
                onPressed: _submit,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final extra = _comment.text.trim();
    if (_reason == RejectReason.other && extra.isEmpty) {
      AppToast.show(
        context,
        message: 'Укажите причину отклонения',
        kind: AppToastKind.error,
      );
      return;
    }
    final fullComment =
        extra.isEmpty ? _reason.label : '${_reason.label}. $extra';
    setState(() => _busy = true);
    final failure = await ref
        .read(selfpurchasesControllerProvider(widget.projectId).notifier)
        .reject(id: widget.id, comment: fullComment);
    if (!mounted) return;
    setState(() => _busy = false);
    if (failure != null) {
      AppToast.show(
        context,
        message: failure.userMessage,
        kind: AppToastKind.error,
      );
      return;
    }
    AppToast.show(
      context,
      message: 'Отклонено',
      kind: AppToastKind.success,
    );
    context.pop();
  }
}
