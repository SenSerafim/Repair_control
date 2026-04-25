import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/access/access_guard.dart';
import '../../../core/access/domain_actions.dart';
import '../../../core/access/system_role.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/utils/money.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/application/auth_controller.dart';
import '../../projects/presentation/money_input.dart';
import '../../stages/application/stages_controller.dart';
import '../application/selfpurchase_controller.dart';
import '../domain/self_purchase.dart';

/// Активный фильтр на экране самозакупов.
enum _Filter {
  all,
  mine,
  awaitingMyDecision;

  String get label => switch (this) {
        _Filter.all => 'Все',
        _Filter.mine => 'Мои',
        _Filter.awaitingMyDecision => 'Ждут моего согласования',
      };
}

final _filterProvider =
    StateProvider.autoDispose<_Filter>((ref) => _Filter.all);

class SelfpurchasesScreen extends ConsumerWidget {
  const SelfpurchasesScreen({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(selfpurchasesControllerProvider(projectId));
    final canCreate =
        ref.watch(canProvider(DomainAction.selfPurchaseCreate));
    final filter = ref.watch(_filterProvider);
    final me = ref.watch(authControllerProvider).userId;

    return AppScaffold(
      showBack: true,
      title: 'Самозакупы',
      padding: EdgeInsets.zero,
      actions: [
        if (canCreate)
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => _showCreate(context, ref),
          ),
      ],
      body: async.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить',
          onRetry: () =>
              ref.invalidate(selfpurchasesControllerProvider(projectId)),
        ),
        data: (items) {
          final filtered = _applyFilter(items, filter, me);
          return Column(
            children: [
              _FilterBar(
                selected: filter,
                onChanged: (f) =>
                    ref.read(_filterProvider.notifier).state = f,
                pendingForMeCount: items
                    .where((sp) =>
                        sp.status == SelfPurchaseStatus.pending &&
                        sp.addresseeId == me)
                    .length,
              ),
              Expanded(
                child: filtered.isEmpty
                    ? AppEmptyState(
                        title: filter == _Filter.awaitingMyDecision
                            ? 'Нет запросов на согласование'
                            : (filter == _Filter.mine
                                ? 'Вы не отправляли самозакупов'
                                : 'Самозакупов ещё нет'),
                        subtitle: canCreate &&
                                filter == _Filter.all
                            ? 'Мастер или бригадир купил сам — создайте отчёт.'
                            : null,
                        icon: Icons.shopping_bag_outlined,
                        actionLabel: canCreate && filter == _Filter.all
                            ? 'Создать'
                            : null,
                        onAction: canCreate && filter == _Filter.all
                            ? () => _showCreate(context, ref)
                            : null,
                      )
                    : RefreshIndicator(
                        onRefresh: () async => ref.invalidate(
                          selfpurchasesControllerProvider(projectId),
                        ),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.x16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.x10),
                          itemBuilder: (_, i) => _Card(
                            sp: filtered[i],
                            onTap: () =>
                                _showDetail(context, ref, filtered[i]),
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<SelfPurchase> _applyFilter(
    List<SelfPurchase> items,
    _Filter filter,
    String? meId,
  ) {
    return switch (filter) {
      _Filter.all => items,
      _Filter.mine =>
        items.where((sp) => sp.byUserId == meId).toList(),
      _Filter.awaitingMyDecision => items
          .where((sp) =>
              sp.status == SelfPurchaseStatus.pending &&
              sp.addresseeId == meId)
          .toList(),
    };
  }

  Future<void> _showCreate(BuildContext context, WidgetRef ref) async {
    await showAppBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      child: _CreateBody(projectId: projectId),
    );
  }

  Future<void> _showDetail(
    BuildContext context,
    WidgetRef ref,
    SelfPurchase sp,
  ) async {
    await showAppBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      child: _DetailBody(sp: sp),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selected,
    required this.onChanged,
    required this.pendingForMeCount,
  });

  final _Filter selected;
  final ValueChanged<_Filter> onChanged;
  final int pendingForMeCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
        children: [
          for (final f in _Filter.values) ...[
            _Chip(
              label: f == _Filter.awaitingMyDecision && pendingForMeCount > 0
                  ? '${f.label} · $pendingForMeCount'
                  : f.label,
              active: selected == f,
              onTap: () => onChanged(f),
            ),
            const SizedBox(width: AppSpacing.x8),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x12,
            vertical: AppSpacing.x6,
          ),
          decoration: BoxDecoration(
            color: active ? AppColors.brand : AppColors.n100,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: active ? AppColors.n0 : AppColors.n700,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateBody extends ConsumerStatefulWidget {
  const _CreateBody({required this.projectId});

  final String projectId;

  @override
  ConsumerState<_CreateBody> createState() => _CreateBodyState();
}

class _CreateBodyState extends ConsumerState<_CreateBody> {
  final _amount = TextEditingController();
  final _comment = TextEditingController();
  String? _stageId;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final kop = MoneyInput.readKopecks(_amount);
    if (kop == null || kop <= 0) {
      setState(() => _error = 'Укажите сумму');
      return;
    }
    final role = ref.read(activeRoleProvider);
    // ТЗ §5.1 + Gaps §4.3: master обязан указать stageId,
    // бэк иначе вернёт InvalidInputError.
    if (role == SystemRole.master && _stageId == null) {
      setState(() => _error = 'Выберите этап (для мастера это обязательно)');
      return;
    }
    setState(() {
      _submitting = true;
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
    setState(() => _submitting = false);
    if (failure == null) {
      Navigator.of(context).pop();
      AppToast.show(
        context,
        message: 'Отправлено',
        kind: AppToastKind.success,
      );
    } else {
      setState(() => _error = failure.userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(activeRoleProvider);
    final stagesAsync = ref.watch(stagesControllerProvider(widget.projectId));
    final isMaster = role == SystemRole.master;
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppBottomSheetHeader(
            title: 'Самозакуп',
            subtitle: isMaster
                ? 'После одобрения бригадиром, а затем заказчиком, сумма '
                    'попадёт в бюджет.'
                : 'После одобрения заказчиком сумма попадёт в бюджет.',
          ),
          if (_error != null) ...[
            AppInlineError(message: _error!),
            const SizedBox(height: AppSpacing.x12),
          ],
          MoneyInput(controller: _amount, label: 'Сумма'),
          const SizedBox(height: AppSpacing.x12),
          Text(
            isMaster ? 'Этап (обязательно)' : 'Этап (опционально)',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSpacing.x6),
          stagesAsync.when(
            loading: () => const SizedBox(
              height: 32,
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
              style:
                  AppTextStyles.caption.copyWith(color: AppColors.redDot),
            ),
            data: (stages) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (!isMaster)
                  ChoiceChip(
                    label: const Text('Без этапа'),
                    selected: _stageId == null,
                    onSelected: (_) => setState(() => _stageId = null),
                  ),
                for (final s in stages)
                  ChoiceChip(
                    label: Text(s.title),
                    selected: _stageId == s.id,
                    onSelected: (_) => setState(() => _stageId = s.id),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x12),
          const Text('Комментарий', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.x6),
          TextField(
            controller: _comment,
            maxLines: 3,
            maxLength: 2000,
            decoration: InputDecoration(
              hintText: 'Что купили, где',
              filled: true,
              fillColor: AppColors.n0,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.r12),
                borderSide: const BorderSide(
                  color: AppColors.n200,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x16),
          AppButton(
            label: 'Отправить на согласование',
            isLoading: _submitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.sp, required this.onTap});

  final SelfPurchase sp;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.x14),
        decoration: BoxDecoration(
          color: AppColors.n0,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.n200, width: 1.5),
          boxShadow: AppShadows.sh1,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: sp.status.semaphore.bg,
                borderRadius: BorderRadius.circular(AppRadius.r12),
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                color: sp.status.semaphore.text,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Money.format(sp.amount),
                    style: AppTextStyles.subtitle,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      StatusPill(
                        label: sp.status.displayName,
                        semaphore: sp.status.semaphore,
                      ),
                      const SizedBox(width: AppSpacing.x6),
                      Text(
                        sp.byRole.displayName,
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                  if (sp.comment?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 4),
                    Text(
                      sp.comment!,
                      style: AppTextStyles.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailBody extends ConsumerStatefulWidget {
  const _DetailBody({required this.sp});

  final SelfPurchase sp;

  @override
  ConsumerState<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends ConsumerState<_DetailBody> {
  bool _busy = false;
  String? _error;

  Future<void> _approve() async {
    setState(() => _busy = true);
    final failure = await ref
        .read(selfpurchasesControllerProvider(widget.sp.projectId).notifier)
        .approve(id: widget.sp.id);
    if (!mounted) return;
    setState(() => _busy = false);
    if (failure == null && context.mounted) {
      Navigator.of(context).pop();
    } else if (failure != null) {
      setState(() => _error = failure.userMessage);
    }
  }

  Future<void> _reject() async {
    final commentCtrl = TextEditingController();
    final ok = await showAppBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      child: _RejectBody(controller: commentCtrl),
    );
    if (ok != true || !mounted) {
      commentCtrl.dispose();
      return;
    }
    setState(() => _busy = true);
    final failure = await ref
        .read(selfpurchasesControllerProvider(widget.sp.projectId).notifier)
        .reject(id: widget.sp.id, comment: commentCtrl.text.trim());
    commentCtrl.dispose();
    if (!mounted) return;
    setState(() => _busy = false);
    if (failure == null && context.mounted) {
      Navigator.of(context).pop();
    } else if (failure != null) {
      setState(() => _error = failure.userMessage);
    }
  }

  /// 6 ролевых вариантов по дизайну `e-selfpurchase-*`:
  /// (status, byRole, isAddressee, isAuthor) → (icon, banner-text, banner-color)
  ({IconData icon, String headline, Color color})? _roleVariant({
    required SelfPurchase sp,
    required bool isAddressee,
    required bool isAuthor,
  }) {
    // master → ждёт foreman
    if (sp.status == SelfPurchaseStatus.pending &&
        sp.byRole == SelfPurchaseBy.master &&
        isAuthor) {
      return (
        icon: Icons.hourglass_empty_rounded,
        headline: 'Ваш самозакуп ждёт подтверждения от бригадира',
        color: AppColors.brand,
      );
    }
    // foreman → ждёт customer
    if (sp.status == SelfPurchaseStatus.pending &&
        sp.byRole == SelfPurchaseBy.foreman &&
        isAuthor) {
      return (
        icon: Icons.hourglass_empty_rounded,
        headline: 'Ваш самозакуп ждёт подтверждения заказчика',
        color: AppColors.brand,
      );
    }
    // адресат должен принять решение
    if (sp.status == SelfPurchaseStatus.pending && isAddressee) {
      return (
        icon: Icons.assignment_late_outlined,
        headline: 'Требуется ваше решение',
        color: AppColors.yellowText,
      );
    }
    // approved
    if (sp.status == SelfPurchaseStatus.approved) {
      return (
        icon: Icons.check_circle_rounded,
        headline: 'Самозакуп подтверждён, сумма учтена в бюджете',
        color: AppColors.greenDark,
      );
    }
    // rejected
    if (sp.status == SelfPurchaseStatus.rejected) {
      return (
        icon: Icons.cancel_outlined,
        headline: 'Самозакуп отклонён',
        color: AppColors.redDot,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final sp = widget.sp;
    final canDecide =
        ref.watch(canProvider(DomainAction.selfPurchaseConfirm));
    final me = ref.watch(authControllerProvider).userId;
    final isAddressee = sp.addresseeId == me;
    final isAuthor = sp.byUserId == me;
    final variant =
        _roleVariant(sp: sp, isAddressee: isAddressee, isAuthor: isAuthor);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppBottomSheetHeader(
          title: Money.format(sp.amount),
          subtitle:
              '${sp.byRole.displayName} · ${DateFormat('d MMM y HH:mm', 'ru').format(sp.createdAt)}',
        ),
        if (variant != null) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.x12),
            decoration: BoxDecoration(
              color: variant.color.withValues(alpha: 0.10),
              borderRadius: AppRadius.card,
              border: Border.all(color: variant.color.withValues(alpha: 0.30)),
            ),
            child: Row(
              children: [
                Icon(variant.icon, color: variant.color),
                const SizedBox(width: AppSpacing.x10),
                Expanded(
                  child: Text(
                    variant.headline,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: variant.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x12),
        ],
        if (_error != null) ...[
          AppInlineError(message: _error!),
          const SizedBox(height: AppSpacing.x12),
        ],
        Row(
          children: [
            StatusPill(
              label: sp.status.displayName,
              semaphore: sp.status.semaphore,
            ),
            const SizedBox(width: AppSpacing.x6),
            if (sp.status == SelfPurchaseStatus.pending && isAddressee)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.x10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.brandLight,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  'Ждёт вашего решения',
                  style: AppTextStyles.tiny.copyWith(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
        if (sp.comment?.isNotEmpty ?? false) ...[
          const SizedBox(height: AppSpacing.x12),
          Container(
            padding: const EdgeInsets.all(AppSpacing.x12),
            decoration: BoxDecoration(
              color: AppColors.n100,
              borderRadius: AppRadius.card,
            ),
            child: Text(sp.comment!, style: AppTextStyles.body),
          ),
        ],
        if (sp.decisionComment?.isNotEmpty ?? false) ...[
          const SizedBox(height: AppSpacing.x12),
          Text(
            sp.status == SelfPurchaseStatus.approved
                ? 'Комментарий одобрившего'
                : 'Причина отказа',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 4),
          Text(sp.decisionComment!, style: AppTextStyles.body),
        ],
        if (sp.status == SelfPurchaseStatus.pending &&
            canDecide &&
            isAddressee) ...[
          const SizedBox(height: AppSpacing.x16),
          AppButton(
            label: 'Одобрить',
            variant: AppButtonVariant.success,
            isLoading: _busy,
            onPressed: _approve,
          ),
          const SizedBox(height: AppSpacing.x8),
          AppButton(
            label: 'Отклонить',
            variant: AppButtonVariant.destructive,
            onPressed: _busy ? null : _reject,
          ),
        ],
      ],
    );
  }
}

class _RejectBody extends StatefulWidget {
  const _RejectBody({required this.controller});

  final TextEditingController controller;

  @override
  State<_RejectBody> createState() => _RejectBodyState();
}

class _RejectBodyState extends State<_RejectBody> {
  static const _minChars = 10;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() => setState(() {}));
  }

  bool get _canSubmit =>
      widget.controller.text.trim().length >= _minChars;

  @override
  Widget build(BuildContext context) {
    final remaining = _minChars - widget.controller.text.trim().length;
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppBottomSheetHeader(
            title: 'Отклонить самозакуп',
            subtitle:
                'Напишите, почему отклоняете — мастер увидит причину и сможет '
                'отправить новый запрос.',
          ),
          TextField(
            controller: widget.controller,
            autofocus: true,
            maxLines: 4,
            maxLength: 2000,
            decoration: InputDecoration(
              hintText: 'Например, «не было согласовано заранее»…',
              filled: true,
              fillColor: AppColors.n0,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.r12),
                borderSide:
                    const BorderSide(color: AppColors.n200, width: 1.5),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              remaining <= 0
                  ? '✓ можно отправлять'
                  : 'осталось $remaining символов',
              style: AppTextStyles.caption.copyWith(
                color: remaining <= 0 ? AppColors.greenDark : AppColors.n400,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x16),
          AppButton(
            label: 'Отклонить',
            variant: AppButtonVariant.destructive,
            onPressed: _canSubmit
                ? () => Navigator.of(context).pop(true)
                : null,
          ),
        ],
      ),
    );
  }
}
