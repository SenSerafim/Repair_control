import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/access/access_guard.dart';
import '../../../core/access/system_role.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../projects/presentation/money_input.dart';
import '../../stages/application/stages_controller.dart';
import '../application/selfpurchase_controller.dart';
import '_widgets/approval_chain_strip.dart';

/// e-selfpurchase / e-selfpurchase-master — экран создания самозакупа.
/// Один экран адаптируется по роли: бригадир → заказчику; мастер → бригадиру.
class CreateSelfPurchaseScreen extends ConsumerStatefulWidget {
  const CreateSelfPurchaseScreen({required this.projectId, super.key});

  final String projectId;

  @override
  ConsumerState<CreateSelfPurchaseScreen> createState() =>
      _CreateSelfPurchaseScreenState();
}

class _CreateSelfPurchaseScreenState
    extends ConsumerState<CreateSelfPurchaseScreen> {
  final _amount = TextEditingController();
  final _comment = TextEditingController();
  String? _stageId;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(activeRoleProvider);
    final isMaster = role == SystemRole.master;
    final stagesAsync = ref.watch(stagesControllerProvider(widget.projectId));
    return AppScaffold(
      showBack: true,
      title: 'Самозакуп',
      padding: EdgeInsets.zero,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.x20),
              children: [
                _RoleBadge(isMaster: isMaster),
                const SizedBox(height: AppSpacing.x12),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.x12),
                  decoration: BoxDecoration(
                    color: AppColors.brandLight,
                    borderRadius:
                        BorderRadius.circular(AppRadius.r12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: AppColors.brand,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isMaster
                              ? 'Заявка уйдёт бригадиру, затем заказчику. Только после двух подтверждений сумма попадёт в бюджет.'
                              : 'Сумма попадёт в бюджет только после подтверждения заказчиком.',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.brandDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.x16),
                if (_error != null) ...[
                  AppInlineError(message: _error!),
                  const SizedBox(height: AppSpacing.x12),
                ],
                _Label(text: isMaster ? 'Этап (обязательно)' : 'Этап'),
                const SizedBox(height: 6),
                stagesAsync.when(
                  loading: () => const SizedBox(
                    height: 48,
                    child: Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  error: (_, __) => Text(
                    'Не удалось загрузить этапы',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.redDot),
                  ),
                  data: (stages) {
                    // Master может создать самозакуп только на этапах
                    // с назначенным бригадиром — он адресат подтверждения
                    // (gaps §4.3, backend: SELFPURCHASE_NO_FOREMAN_ON_STAGE).
                    final visible = isMaster
                        ? stages.where((s) => s.foremanIds.isNotEmpty).toList()
                        : stages;
                    if (isMaster && visible.isEmpty) {
                      return Text(
                        'На ваших этапах ещё нет бригадира — '
                        'самозакуп пока невозможен.',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.redDot),
                      );
                    }
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (!isMaster)
                          ChoiceChip(
                            label: const Text('Без этапа'),
                            selected: _stageId == null,
                            onSelected: (_) =>
                                setState(() => _stageId = null),
                          ),
                        for (final s in visible)
                          ChoiceChip(
                            label: Text(s.title),
                            selected: _stageId == s.id,
                            onSelected: (_) =>
                                setState(() => _stageId = s.id),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.x14),
                const _Label(text: 'Сумма'),
                const SizedBox(height: 6),
                MoneyInput(controller: _amount, label: 'Сумма'),
                const SizedBox(height: AppSpacing.x14),
                const _Label(text: 'Комментарий'),
                const SizedBox(height: 6),
                TextField(
                  controller: _comment,
                  maxLines: 3,
                  maxLength: 2000,
                  decoration: InputDecoration(
                    hintText: 'Что купили, где',
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
                const SizedBox(height: AppSpacing.x16),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.x14),
                  decoration: BoxDecoration(
                    color: AppColors.brandLight,
                    borderRadius:
                        BorderRadius.circular(AppRadius.r12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'СУММА К ПЕРЕДАЧЕ',
                              style: AppTextStyles.tiny.copyWith(
                                color: AppColors.brand,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Дата: сегодня (зафиксируется)',
                              style: AppTextStyles.tiny.copyWith(
                                color: AppColors.brand
                                    .withValues(alpha: 0.7),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        DateFormat('d MMM y', 'ru').format(DateTime.now()),
                        style: AppTextStyles.subtitle.copyWith(
                          color: AppColors.brandDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.x16),
                ApprovalChainStrip(
                  steps: _chainSteps(isMaster),
                  footnote: isMaster
                      ? 'Вы мастер → сначала бригадиру → потом заказчику'
                      : 'Вы бригадир → заявка уйдёт заказчику',
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
                label: isMaster
                    ? 'Отправить бригадиру'
                    : 'Отправить на подтверждение',
                isLoading: _busy,
                icon: Icons.send_rounded,
                onPressed: _submit,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<ChainStep> _chainSteps(bool isMaster) {
    if (isMaster) {
      return const [
        ChainStep(
          label: 'Вы (мастер)',
          state: ChainStepState.current,
          tone: ChainStepTone.purple,
        ),
        ChainStep(
          label: 'Бригадир',
          state: ChainStepState.pending,
          tone: ChainStepTone.purple,
        ),
        ChainStep(
          label: 'Заказчик',
          state: ChainStepState.pending,
          tone: ChainStepTone.customer,
        ),
      ];
    }
    return const [
      ChainStep(
        label: 'Вы (бригадир)',
        state: ChainStepState.current,
        tone: ChainStepTone.purple,
      ),
      ChainStep(
        label: 'Заказчик',
        state: ChainStepState.pending,
        tone: ChainStepTone.customer,
      ),
    ];
  }

  Future<void> _submit() async {
    final kop = MoneyInput.readKopecks(_amount);
    if (kop == null || kop <= 0) {
      setState(() => _error = 'Укажите сумму');
      return;
    }
    final role = ref.read(activeRoleProvider);
    if (role == SystemRole.master && _stageId == null) {
      setState(() => _error = 'Выберите этап (для мастера это обязательно)');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final failure = await ref
        .read(selfpurchasesControllerProvider(widget.projectId).notifier)
        .create(
          amount: kop,
          stageId: _stageId,
          comment: _comment.text.trim().isEmpty
              ? null
              : _comment.text.trim(),
        );
    if (!mounted) return;
    setState(() => _busy = false);
    if (failure == null) {
      AppToast.show(
        context,
        message: 'Отправлено',
        kind: AppToastKind.success,
      );
      context.pop();
    } else {
      setState(() => _error = failure.userMessage);
    }
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.isMaster});

  final bool isMaster;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.purpleBg,
          borderRadius: BorderRadius.circular(AppRadius.r8),
        ),
        child: Text(
          isMaster ? 'Мастер' : 'Бригадир',
          style: AppTextStyles.tiny.copyWith(
            color: AppColors.purple,
            fontWeight: FontWeight.w800,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.tiny.copyWith(
        color: AppColors.n500,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    );
  }
}
