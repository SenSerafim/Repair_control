import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../projects/domain/membership.dart';
import '../../team/application/team_controller.dart';
import '../application/tools_controller.dart';
import '../domain/tool.dart';
import '_widgets/tool_issue_list_item.dart';
import '_widgets/tool_search_bar.dart';

/// e-tool-issue: полноэкранная форма выдачи. Поля: Кому (master из команды),
/// Проект (предзаполнен), Поиск + список (checkbox для available, greyed для
/// issued). Footer-counter + brandLight info-banner.
class IssueToolScreen extends ConsumerStatefulWidget {
  const IssueToolScreen({required this.projectId, super.key});

  final String projectId;

  @override
  ConsumerState<IssueToolScreen> createState() => _IssueToolScreenState();
}

class _IssueToolScreenState extends ConsumerState<IssueToolScreen> {
  String? _toUserId;
  final _selected = <String>{};
  final _searchCtrl = TextEditingController();
  String _search = '';
  bool _busy = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teamAsync = ref.watch(teamControllerProvider(widget.projectId));
    final masters = teamAsync.value?.members
            .where((m) => m.role == MembershipRole.master)
            .toList() ??
        const <Membership>[];
    final toolsAsync = ref.watch(myToolsProvider);
    final tools = toolsAsync.value ?? const <ToolItem>[];
    final filtered = tools
        .where((t) =>
            _search.isEmpty ||
            t.name.toLowerCase().contains(_search.toLowerCase()))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final available = filtered.where((t) => t.availableQty > 0).length;
    final selectedCount = _selected.length;

    return AppScaffold(
      showBack: true,
      title: 'Выдача инструмента',
      padding: EdgeInsets.zero,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.x16),
              children: [
                const _Label(text: 'Кому выдать'),
                const SizedBox(height: 6),
                if (masters.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.x12),
                    decoration: BoxDecoration(
                      color: AppColors.yellowBg,
                      borderRadius:
                          BorderRadius.circular(AppRadius.r12),
                    ),
                    child: Text(
                      'В команде нет мастеров. Сначала добавьте мастера в команду проекта.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.yellowText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final m in masters)
                        ChoiceChip(
                          label: Text(_displayName(m)),
                          selected: _toUserId == m.userId,
                          onSelected: (_) =>
                              setState(() => _toUserId = m.userId),
                        ),
                    ],
                  ),
                const SizedBox(height: AppSpacing.x14),
                const _Label(text: 'Проект'),
                const SizedBox(height: 6),
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: AppColors.n50,
                    border:
                        Border.all(color: AppColors.n200, width: 1.5),
                    borderRadius:
                        BorderRadius.circular(AppRadius.r12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.home_outlined,
                        size: 16,
                        color: AppColors.brand,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Текущий проект',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.n900,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.x14),
                const _Label(text: 'Выберите инструмент'),
                const SizedBox(height: 6),
                ToolSearchBar(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _search = v),
                  hint: 'Поиск: перфоратор, шуруповёрт…',
                ),
                const SizedBox(height: AppSpacing.x10),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.n0,
                    borderRadius: AppRadius.card,
                    border: Border.all(color: AppColors.n200),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (final t in filtered)
                        ToolIssueListItem(
                          tool: t,
                          selected: _selected.contains(t.id),
                          disabled: t.availableQty <= 0,
                          disabledReason: t.availableQty <= 0
                              ? 'Уже выдан'
                              : null,
                          onTap: () => setState(() {
                            if (_selected.contains(t.id)) {
                              _selected.remove(t.id);
                            } else {
                              _selected.add(t.id);
                            }
                          }),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.x10),
                Text(
                  'Всего ${filtered.length} · свободно $available · выбрано $selectedCount',
                  style: AppTextStyles.tiny.copyWith(
                    color: AppColors.n400,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Мастер получит push и должен подтвердить получение.',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.brandDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
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
                label: selectedCount == 0
                    ? 'Выберите инструмент'
                    : 'Выдать $selectedCount инструмент(ов)',
                icon: Icons.check_rounded,
                isLoading: _busy,
                onPressed: selectedCount == 0 || _toUserId == null
                    ? null
                    : _submit,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final to = _toUserId;
    if (to == null) return;
    setState(() => _busy = true);
    final ctrl = ref.read(toolIssuancesProvider(widget.projectId).notifier);
    final failures = <String>[];
    for (final id in _selected) {
      final f = await ctrl.issue(toolItemId: id, toUserId: to, qty: 1);
      if (f != null) failures.add(f.userMessage);
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (failures.isEmpty) {
      AppToast.show(
        context,
        message: '${_selected.length} инструмент(а) выдано',
        kind: AppToastKind.success,
      );
      context.pop(to);
    } else {
      AppToast.show(
        context,
        message: 'Ошибки: ${failures.length}',
        kind: AppToastKind.error,
      );
    }
  }

  String _displayName(Membership m) {
    final user = m.user;
    if (user == null) return 'Мастер';
    return '${user.firstName} ${user.lastName}'.trim();
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
