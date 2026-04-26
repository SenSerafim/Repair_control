import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/access/domain_actions.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../projects/domain/membership.dart';
import '../application/team_controller.dart';
import '../domain/representative_rights_l10n.dart';

/// s-rep-rights-inline — чек-лист прав представителя, привязан к Membership.
///
/// Записывает в Membership.permissions (JSONB на бэкенде) — ключи это
/// `DomainAction.value`, значения — bool.
Future<void> showRepRightsSheet(
  BuildContext context,
  WidgetRef ref, {
  required String projectId,
  required Membership member,
}) async {
  await showAppBottomSheet<void>(
    context: context,
    child: _RightsBody(projectId: projectId, member: member),
  );
}

class _RightsBody extends ConsumerStatefulWidget {
  const _RightsBody({required this.projectId, required this.member});

  final String projectId;
  final Membership member;

  @override
  ConsumerState<_RightsBody> createState() => _RightsBodyState();
}

class _RightsBodyState extends ConsumerState<_RightsBody> {
  late final Map<String, bool> _rights;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _rights = <String, bool>{};
    for (final a in _representativeActions) {
      _rights[a.value] = false;
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final failure = await ref
        .read(teamControllerProvider(widget.projectId).notifier)
        .updatePermissions(
          membershipId: widget.member.id,
          permissions: _rights,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (failure == null) {
      Navigator.of(context).pop();
      AppToast.show(
        context,
        message: 'Права сохранены',
        kind: AppToastKind.success,
      );
    } else {
      setState(() => _error = failure.userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppBottomSheetHeader(
            title: 'Права представителя',
            subtitle:
                'Представитель действует от имени заказчика. Отметьте, '
                'какие действия ему разрешены на этом проекте.',
          ),
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
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final group in _groups) ...[
                  Padding(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.x8,
                      bottom: AppSpacing.x6,
                    ),
                    child: Text(group.title, style: AppTextStyles.micro),
                  ),
                  for (final action in group.actions)
                    _RightRow(
                      label: action.label,
                      action: action.action,
                      enabled: _rights[action.action.value] ?? false,
                      onChanged: (v) => setState(
                        () => _rights[action.action.value] = v,
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x16),
          AppButton(
            label: 'Сохранить',
            isLoading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

class _RightRow extends StatelessWidget {
  const _RightRow({
    required this.label,
    required this.action,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final DomainAction action;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!enabled),
      borderRadius: BorderRadius.circular(AppRadius.r12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x4,
          vertical: AppSpacing.x10,
        ),
        child: Row(
          children: [
            Checkbox(
              value: enabled,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: AppColors.brand,
            ),
            const SizedBox(width: AppSpacing.x8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.body),
                  Text(
                    kRightsRu[action]?.description ?? action.value,
                    style: AppTextStyles.micro,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Group {
  const _Group({required this.title, required this.actions});
  final String title;
  final List<_ActionDef> actions;
}

class _ActionDef {
  const _ActionDef({required this.action, required this.label});
  final DomainAction action;
  final String label;
}

const _groups = <_Group>[
  _Group(
    title: 'Проекты и этапы',
    actions: [
      _ActionDef(
        action: DomainAction.projectEdit,
        label: 'Редактировать проект',
      ),
      _ActionDef(
        action: DomainAction.stageManage,
        label: 'Управлять этапами',
      ),
      _ActionDef(
        action: DomainAction.stageStart,
        label: 'Запускать этапы',
      ),
      _ActionDef(
        action: DomainAction.stagePause,
        label: 'Ставить на паузу',
      ),
    ],
  ),
  _Group(
    title: 'Согласования',
    actions: [
      _ActionDef(
        action: DomainAction.approvalRequest,
        label: 'Запрашивать согласования',
      ),
      _ActionDef(
        action: DomainAction.approvalDecide,
        label: 'Принимать решение',
      ),
    ],
  ),
  _Group(
    title: 'Финансы',
    actions: [
      _ActionDef(
        action: DomainAction.financeBudgetView,
        label: 'Видеть бюджет',
      ),
      _ActionDef(
        action: DomainAction.financePaymentCreate,
        label: 'Создавать выплаты',
      ),
      _ActionDef(
        action: DomainAction.financePaymentConfirm,
        label: 'Подтверждать выплаты',
      ),
    ],
  ),
  _Group(
    title: 'Материалы и инструмент',
    actions: [
      _ActionDef(
        action: DomainAction.materialsManage,
        label: 'Управлять материалами',
      ),
      _ActionDef(
        action: DomainAction.toolsIssue,
        label: 'Выдавать инструмент',
      ),
    ],
  ),
];

List<DomainAction> get _representativeActions =>
    _groups.expand((g) => g.actions.map((a) => a.action)).toList();
