import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/api_error.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/invitations_repository.dart';

/// P2: ввод 6-значного кода приглашения для присоединения к проекту.
class JoinByCodeScreen extends ConsumerStatefulWidget {
  const JoinByCodeScreen({super.key, this.prefilledCode});

  final String? prefilledCode;

  @override
  ConsumerState<JoinByCodeScreen> createState() => _JoinByCodeScreenState();
}

class _JoinByCodeScreenState extends ConsumerState<JoinByCodeScreen> {
  final TextEditingController _ctrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledCode != null) {
      _ctrl.text = widget.prefilledCode!;
      // Auto-submit при deep-link.
      WidgetsBinding.instance.addPostFrameCallback((_) => _submit());
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _ctrl.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Введите 6-значный код');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(invitationsRepositoryProvider);
      final result = await repo.joinByCode(code);
      if (!mounted) return;
      AppToast.show(
        context,
        message: 'Вы добавлены в проект',
        kind: AppToastKind.success,
      );
      // Перенаправляем в Console нового проекта.
      context.go('/projects/${result.projectId}');
    } on InvitationsException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _humanError(e.apiError);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Не удалось присоединиться. Попробуйте ещё раз.';
      });
    }
  }

  String _humanError(ApiError api) {
    final code = api.statusCode;
    if (code == 404) return 'Код не найден или уже использован';
    if (code == 410) return 'Срок действия кода истёк';
    if (code == 409) return 'Вы уже участник этого проекта';
    return api.message ?? 'Ошибка присоединения';
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showBack: true,
      title: 'Присоединиться по коду',
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.x16),
          const Text(
            'Введите 6-значный код, который вам прислал заказчик или бригадир.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.x20),
          TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            style: AppTextStyles.h1.copyWith(letterSpacing: 8),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: AppColors.n0,
              hintText: '······',
              hintStyle: AppTextStyles.h1
                  .copyWith(color: AppColors.n300, letterSpacing: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.r12),
                borderSide: const BorderSide(color: AppColors.n200, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.r12),
                borderSide: const BorderSide(color: AppColors.brand, width: 2),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.x12),
            Container(
              padding: const EdgeInsets.all(AppSpacing.x12),
              decoration: BoxDecoration(
                color: AppColors.redBg,
                borderRadius: AppRadius.card,
              ),
              child: Text(
                _error!,
                style: AppTextStyles.body.copyWith(color: AppColors.redText),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.x20),
          AppButton(
            label: 'Присоединиться',
            isLoading: _busy,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
