import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/profile_repository.dart';

/// s-feedback — форма обратной связи.
class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _text = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(profileRepositoryProvider)
          .submitFeedback(text: _text.text.trim());
      if (!mounted) return;
      AppToast.show(
        context,
        message: 'Спасибо! Мы прочитаем ваше сообщение.',
        kind: AppToastKind.success,
      );
      await Navigator.of(context).maybePop();
    } on ProfileException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.failure.userMessage);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showBack: true,
      title: 'Обратная связь',
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          children: [
            const SizedBox(height: AppSpacing.x16),
            const Text(
              'Расскажите, что работает не так, или предложите улучшение. '
              'Мы читаем всё.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.x16),
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.x12),
                decoration: BoxDecoration(
                  color: AppColors.redBg,
                  borderRadius: AppRadius.card,
                ),
                child: Text(
                  _error!,
                  style:
                      AppTextStyles.body.copyWith(color: AppColors.redText),
                ),
              ),
              const SizedBox(height: AppSpacing.x12),
            ],
            TextFormField(
              controller: _text,
              maxLines: 8,
              minLines: 5,
              maxLength: 5000,
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.length < 5) return 'Введите хотя бы 5 символов';
                return null;
              },
              decoration: InputDecoration(
                hintText: 'Ваше сообщение…',
                hintStyle:
                    AppTextStyles.body.copyWith(color: AppColors.n400),
                filled: true,
                fillColor: AppColors.n0,
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                  borderSide: const BorderSide(
                    color: AppColors.n200,
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                  borderSide: const BorderSide(
                    color: AppColors.n200,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                  borderSide: const BorderSide(
                    color: AppColors.brand,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.x20),
            AppButton(
              label: 'Отправить',
              isLoading: _submitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
