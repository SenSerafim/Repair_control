import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/utils/money.dart';
import '../../../shared/widgets/widgets.dart';
import '../../projects/domain/membership.dart';
import '../../projects/presentation/money_input.dart';
import '../../team/application/team_controller.dart';
import '../application/stages_controller.dart';
import 'templates_gallery.dart';

/// c-stage-create — 2-табный экран: «Новый» / «Из шаблона».
class CreateStageScreen extends ConsumerStatefulWidget {
  const CreateStageScreen({required this.projectId, super.key});

  final String projectId;

  @override
  ConsumerState<CreateStageScreen> createState() =>
      _CreateStageScreenState();
}

class _CreateStageScreenState extends ConsumerState<CreateStageScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showBack: true,
      title: 'Новый этап',
      padding: EdgeInsets.zero,
      body: Column(
        children: [
          ColoredBox(
            color: AppColors.n0,
            child: TabBar(
              controller: _tabs,
              labelStyle: AppTextStyles.caption
                  .copyWith(fontWeight: FontWeight.w800),
              labelColor: AppColors.brand,
              unselectedLabelColor: AppColors.n400,
              indicatorColor: AppColors.brand,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const [
                Tab(text: 'С нуля'),
                Tab(text: 'Из шаблона'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _BlankForm(projectId: widget.projectId),
                TemplatesGallery(
                  onPick: (t) async {
                    final applied = await showTemplatePreview(
                      context,
                      ref,
                      template: t,
                      projectId: widget.projectId,
                    );
                    if (applied && context.mounted) {
                      context.pop();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BlankForm extends ConsumerStatefulWidget {
  const _BlankForm({required this.projectId});

  final String projectId;

  @override
  ConsumerState<_BlankForm> createState() => _BlankFormState();
}

class _BlankFormState extends ConsumerState<_BlankForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _workBudget = TextEditingController();
  final _materialsBudget = TextEditingController();
  DateTime? _plannedStart;
  DateTime? _plannedEnd;
  final Set<String> _foremanIds = {};
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _workBudget.addListener(_refresh);
    _materialsBudget.addListener(_refresh);
  }

  @override
  void dispose() {
    _workBudget.removeListener(_refresh);
    _materialsBudget.removeListener(_refresh);
    _title.dispose();
    _workBudget.dispose();
    _materialsBudget.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  bool get _datesValid {
    if (_plannedStart == null || _plannedEnd == null) return true;
    return !_plannedEnd!.isBefore(_plannedStart!);
  }

  int? get _totalBudget {
    final w = MoneyInput.readKopecks(_workBudget);
    final m = MoneyInput.readKopecks(_materialsBudget);
    if (w == null && m == null) return null;
    return (w ?? 0) + (m ?? 0);
  }

  Future<void> _submit() async {
    final formOk = _formKey.currentState?.validate() ?? false;
    if (!formOk) {
      setState(() => _error = 'Проверьте поля формы');
      return;
    }
    if (!_datesValid) {
      setState(() => _error = 'Конец должен быть после старта');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final failure = await ref
        .read(stagesControllerProvider(widget.projectId).notifier)
        .create(
          title: _title.text.trim(),
          plannedStart: _plannedStart,
          plannedEnd: _plannedEnd,
          workBudget: MoneyInput.readKopecks(_workBudget),
          materialsBudget: MoneyInput.readKopecks(_materialsBudget),
          foremanIds: _foremanIds.isEmpty ? null : _foremanIds.toList(),
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (failure != null) {
      setState(() => _error = failure.userMessage);
    } else {
      AppToast.show(
        context,
        message: 'Этап создан',
        kind: AppToastKind.success,
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                if (_error != null) ...[
                  AppInlineError(message: _error!),
                  const SizedBox(height: AppSpacing.x12),
                ],
                const _SectionHeader(
                  number: 1,
                  title: 'Название',
                  hint: 'Коротко и понятно — например, «Электрика».',
                ),
                const SizedBox(height: AppSpacing.x10),
                TextFormField(
                  controller: _title,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    final t = (v ?? '').trim();
                    if (t.isEmpty) return 'Введите название';
                    if (t.length < 2) return 'Минимум 2 символа';
                    if (t.length > 200) return 'Максимум 200 символов';
                    return null;
                  },
                  decoration: _dec('Например, Электрика'),
                ),
                const SizedBox(height: AppSpacing.x20),
                const _SectionHeader(
                  number: 2,
                  title: 'Сроки',
                  hint: 'Можно оставить пустыми — добавите позже.',
                ),
                const SizedBox(height: AppSpacing.x10),
                _DateTile(
                  label: 'Плановый старт',
                  value: _plannedStart,
                  onChanged: (d) => setState(() => _plannedStart = d),
                  onClear: _plannedStart == null
                      ? null
                      : () => setState(() => _plannedStart = null),
                ),
                const SizedBox(height: AppSpacing.x10),
                _DateTile(
                  label: 'Плановое завершение',
                  value: _plannedEnd,
                  minDate: _plannedStart,
                  onChanged: (d) => setState(() => _plannedEnd = d),
                  onClear: _plannedEnd == null
                      ? null
                      : () => setState(() => _plannedEnd = null),
                ),
                if (!_datesValid) ...[
                  const SizedBox(height: AppSpacing.x8),
                  Text(
                    'Конец должен быть позже старта.',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.redDot),
                  ),
                ],
                const SizedBox(height: AppSpacing.x20),
                const _SectionHeader(
                  number: 3,
                  title: 'Бюджет',
                  hint: 'Работы и материалы можно указать раздельно.',
                ),
                const SizedBox(height: AppSpacing.x10),
                MoneyInput(controller: _workBudget, label: 'Работы'),
                const SizedBox(height: AppSpacing.x12),
                MoneyInput(
                  controller: _materialsBudget,
                  label: 'Материалы',
                ),
                if (_totalBudget != null && _totalBudget! > 0) ...[
                  const SizedBox(height: AppSpacing.x10),
                  _BudgetSummary(total: _totalBudget!),
                ],
                const SizedBox(height: AppSpacing.x20),
                const _SectionHeader(
                  number: 4,
                  title: 'Бригадиры',
                  hint: 'Кто отвечает за этап. '
                      'Можно выбрать нескольких или не выбирать.',
                ),
                const SizedBox(height: AppSpacing.x10),
                _ForemanPicker(
                  projectId: widget.projectId,
                  selected: _foremanIds,
                  onToggle: (id) => setState(() {
                    if (_foremanIds.contains(id)) {
                      _foremanIds.remove(id);
                    } else {
                      _foremanIds.add(id);
                    }
                  }),
                ),
                const SizedBox(height: AppSpacing.x16),
              ],
            ),
          ),
          // Sticky bottom CTA — не теряется в скролле.
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: const BoxDecoration(
              color: AppColors.n0,
              border: Border(top: BorderSide(color: AppColors.n100)),
            ),
            child: SafeArea(
              top: false,
              child: AppButton(
                label: 'Создать этап',
                isLoading: _submitting,
                onPressed: _submit,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.number,
    required this.title,
    required this.hint,
  });

  final int number;
  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.brandLight,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.brand,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.x10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.subtitle),
              const SizedBox(height: 2),
              Text(
                hint,
                style: AppTextStyles.micro.copyWith(color: AppColors.n400),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BudgetSummary extends StatelessWidget {
  const _BudgetSummary({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x14,
        vertical: AppSpacing.x12,
      ),
      decoration: BoxDecoration(
        color: AppColors.brandLight,
        borderRadius: AppRadius.card,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            size: 18,
            color: AppColors.brand,
          ),
          const SizedBox(width: AppSpacing.x8),
          Expanded(
            child: Text(
              'Итого по этапу',
              style:
                  AppTextStyles.caption.copyWith(color: AppColors.brandDark),
            ),
          ),
          Text(
            Money.format(total),
            style: AppTextStyles.subtitle.copyWith(color: AppColors.brand),
          ),
        ],
      ),
    );
  }
}

class _ForemanPicker extends ConsumerWidget {
  const _ForemanPicker({
    required this.projectId,
    required this.selected,
    required this.onToggle,
  });

  final String projectId;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(teamControllerProvider(projectId));
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.x16),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(AppSpacing.x12),
        decoration: BoxDecoration(
          color: AppColors.n100,
          borderRadius: AppRadius.card,
        ),
        child: const Text(
          'Не удалось загрузить команду. Этап можно создать без бригадира.',
          style: AppTextStyles.caption,
        ),
      ),
      data: (team) {
        final foremen = team.members
            .where((m) => m.role == MembershipRole.foreman)
            .toList();
        if (foremen.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.x14),
            decoration: BoxDecoration(
              color: AppColors.n100,
              borderRadius: AppRadius.card,
              border: Border.all(color: AppColors.n200),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.engineering_outlined,
                  color: AppColors.n400,
                ),
                const SizedBox(width: AppSpacing.x10),
                Expanded(
                  child: Text(
                    'В команде пока нет бригадиров. '
                    'Можно создать этап и назначить позже на странице «Команда».',
                    style:
                        AppTextStyles.caption.copyWith(color: AppColors.n500),
                  ),
                ),
              ],
            ),
          );
        }
        return Column(
          children: [
            for (final m in foremen)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.x8),
                child: _ForemanRow(
                  membership: m,
                  selected: selected.contains(m.userId),
                  onTap: () => onToggle(m.userId),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ForemanRow extends StatelessWidget {
  const _ForemanRow({
    required this.membership,
    required this.selected,
    required this.onTap,
  });

  final Membership membership;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final user = membership.user;
    final name = user == null
        ? 'Бригадир'
        : '${user.firstName} ${user.lastName}'.trim();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.card,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.x12),
          decoration: BoxDecoration(
            color: selected ? AppColors.brandLight : AppColors.n0,
            borderRadius: AppRadius.card,
            border: Border.all(
              color: selected ? AppColors.brand : AppColors.n200,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              AppAvatar(
                seed: membership.userId,
                name: name,
                imageUrl: user?.avatarUrl,
                size: 36,
              ),
              const SizedBox(width: AppSpacing.x10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? '—' : name,
                      style: AppTextStyles.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (user?.phone != null && user!.phone.isNotEmpty)
                      Text(
                        user.phone,
                        style: AppTextStyles.caption,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.x8),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? AppColors.brand : AppColors.n300,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.onChanged,
    this.minDate,
    this.onClear,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final DateTime? minDate;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final formatted = value == null
        ? 'Выберите дату'
        : DateFormat('d MMMM y', 'ru').format(value!);
    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? minDate ?? now,
          firstDate: minDate ?? DateTime(now.year - 1),
          lastDate: DateTime(now.year + 5),
          locale: const Locale('ru'),
        );
        if (picked != null) onChanged(picked);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.x14),
        decoration: BoxDecoration(
          color: AppColors.n0,
          borderRadius: AppRadius.card,
          border: Border.all(
            color: value == null ? AppColors.n200 : AppColors.brand,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: value == null ? AppColors.n400 : AppColors.brand,
            ),
            const SizedBox(width: AppSpacing.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.caption),
                  Text(formatted, style: AppTextStyles.subtitle),
                ],
              ),
            ),
            if (onClear != null)
              IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.n400,
                ),
                onPressed: onClear,
                tooltip: 'Очистить',
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _dec(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.body.copyWith(color: AppColors.n400),
      filled: true,
      fillColor: AppColors.n0,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.r12),
        borderSide: const BorderSide(color: AppColors.n200, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.r12),
        borderSide: const BorderSide(color: AppColors.n200, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.r12),
        borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.r12),
        borderSide: const BorderSide(color: AppColors.redDot, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.r12),
        borderSide: const BorderSide(color: AppColors.redDot, width: 1.5),
      ),
    );
