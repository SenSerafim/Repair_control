import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/access/representative_rights.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../projects/domain/membership.dart';
import '../application/team_controller.dart';
import '../domain/representative_rights_l10n.dart';

/// s-rep-rights-inline — чек-лист прав представителя, привязан к Membership.
///
/// Записывает в Membership.permissions (JSONB на бэкенде) — ключи это
/// `RepresentativeRight.jsonKey` (camelCase, совместимо с
/// `sanitizeRepresentativeRights`), значения — bool.
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
  late final Map<RepresentativeRight, bool> _rights;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _rights = <RepresentativeRight, bool>{
      for (final r in RepresentativeRight.values) r: false,
    };
    // Подтягиваем уже выданные права из membership-кэша. В членстве
    // representativeRights — List<String> с jsonKey (`canApprove`,
    // `canSeeBudget`, ...), см. `Membership.parse` + `_parseRights`.
    for (final raw in widget.member.representativeRights) {
      final r = RepresentativeRight.fromJsonKey(raw);
      if (r != null) _rights[r] = true;
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final permissions = <String, bool>{
      for (final entry in _rights.entries) entry.key.jsonKey: entry.value,
    };
    final failure = await ref
        .read(teamControllerProvider(widget.projectId).notifier)
        .updatePermissions(
          membershipId: widget.member.id,
          permissions: permissions,
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
                style: AppTextStyles.body.copyWith(color: AppColors.redText),
              ),
            ),
            const SizedBox(height: AppSpacing.x12),
          ],
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final group in kRepresentativeRightGroups) ...[
                  Padding(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.x8,
                      bottom: AppSpacing.x6,
                    ),
                    child: Text(group.title, style: AppTextStyles.micro),
                  ),
                  for (final right in group.rights)
                    _RightRow(
                      right: right,
                      enabled: _rights[right] ?? false,
                      onChanged: (v) => setState(() => _rights[right] = v),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x16),
          AppButton(label: 'Сохранить', isLoading: _saving, onPressed: _save),
        ],
      ),
    );
  }
}

class _RightRow extends StatelessWidget {
  const _RightRow({
    required this.right,
    required this.enabled,
    required this.onChanged,
  });

  final RepresentativeRight right;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final label = kRepresentativeRightLabels[right];
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
                  Text(label?.title ?? right.jsonKey, style: AppTextStyles.body),
                  if (label != null)
                    Text(label.description, style: AppTextStyles.micro),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
