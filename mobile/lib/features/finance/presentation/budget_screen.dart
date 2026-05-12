import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/access/access_guard.dart';
import '../../../core/access/domain_actions.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/utils/money.dart';
import '../../../shared/widgets/widgets.dart';
import '../../approvals/application/approvals_controller.dart';
import '../../approvals/domain/approval.dart';
import '../application/budget_controller.dart';
import '../application/payments_controller.dart';
import '../domain/budget.dart';
import '../domain/money_flow.dart';
import '_widgets/budget_hero_card.dart';
import '_widgets/budget_materials_table.dart';
import '_widgets/budget_tabs_bar.dart';
import '_widgets/date_range_sheet.dart';
import '_widgets/foreman_wallet_card.dart';
import '_widgets/money_summary_chip.dart';
import '_widgets/payment_row_card.dart';
import 'payment_sheets.dart';

/// Активный таб бюджета — хранится в ProviderScope `_budgetTabProvider`.
final _budgetTabProvider = StateProvider.autoDispose<BudgetTab>(
  (ref) => BudgetTab.payments,
);

/// Активный date-range для таба «Материалы». Пустой = «Весь проект».
final _materialsRangeProvider = StateProvider.autoDispose<DateRange>(
  (ref) => const DateRange(),
);

/// e-budget — главный экран бюджета: hero + 3 таба.
class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // RBAC-проверки на UI-уровне дублируют backend (`finance.budget.*`,
    // `finance.payment.create`). Ситуации:
    //  · нет `view`  → экран блокируется заглушкой (заказчик не настроил
    //    делегирование представителю, мастер на проекте без бюджета и т.п.);
    //  · есть `view`, нет `edit`  → bare-read: hero + табы, без кнопки
    //    «Открыть проект» в empty-state и без «Новая выплата» в footer;
    //  · есть `view` + `paymentCreate` → отображается «Новая выплата».
    //
    // ВАЖНО: проверка прав ДО `ref.watch(projectBudgetProvider)`. Иначе при
    // прямом переходе на экран (deeplink, ошибка скрытия плитки выше) watch
    // успеет запустить build() контроллера → улетит GET /budget → бэкенд
    // вернёт 403. Заглушка отрисуется, но в логах останутся «лишние» 403.
    final canViewBudget = ref.watch(
      canInProjectProvider((
        action: DomainAction.financeBudgetView,
        projectId: projectId,
      )),
    );

    if (!canViewBudget) {
      return const AppScaffold(
        showBack: true,
        title: 'Бюджет проекта',
        body: Center(
          child: AppEmptyState(
            title: 'Бюджет недоступен',
            subtitle:
                'У вас нет прав на просмотр бюджета этого проекта. '
                'Обратитесь к заказчику.',
            icon: Icons.lock_outline_rounded,
          ),
        ),
      );
    }

    final async = ref.watch(projectBudgetProvider(projectId));
    final tab = ref.watch(_budgetTabProvider);
    // "Новая выплата" в шапке бюджета — это создание ОБЩЕГО аванса из бюджета
    // (заказчик→бригадир/мастер). Бригадир здесь кнопку не видит: он
    // распределяет на детайле родительского аванса (см. payment_detail_screen).
    final canCreatePayment = ref.watch(
      canInProjectProvider((
        action: DomainAction.financePaymentCreateAdvance,
        projectId: projectId,
      )),
    );
    final canEditBudget = ref.watch(
      canInProjectProvider((
        action: DomainAction.financeBudgetEdit,
        projectId: projectId,
      )),
    );

    return AppScaffold(
      showBack: true,
      title: 'Бюджет проекта',
      padding: EdgeInsets.zero,
      body: async.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить бюджет',
          onRetry: () => ref.invalidate(projectBudgetProvider(projectId)),
        ),
        data: (b) {
          // ТЗ §7 / §10 — master видит только свои выплаты (без planned/spent проекта).
          if (b.viewerKind == BudgetViewerKind.master) {
            return _MasterEarningsView(
              projectId: projectId,
              earnings: b.earnings,
            );
          }
          // «Совсем пусто» — нет ни плана, ни этапов. Полный empty-state с CTA.
          final fullyEmpty =
              b.total.planned == 0 && b.total.spent == 0 && b.stages.isEmpty;
          if (fullyEmpty) {
            return AppEmptyState(
              title: 'Бюджет не задан',
              subtitle: canEditBudget
                  ? 'Укажите бюджет работ и материалов в настройках проекта.'
                  : 'Заказчик ещё не задал бюджет — обратитесь к нему.',
              icon: Icons.account_balance_wallet_outlined,
              actionLabel: canEditBudget ? 'Открыть проект' : null,
              onAction: canEditBudget
                  ? () => context.push(AppRoutes.projectEditWith(projectId))
                  : null,
            );
          }
          // Шапка с нулями + есть этапы → показываем inline-баннер
          // и не блокируем остальной экран (выплаты/история).
          final headerZero = b.total.planned == 0 && b.total.spent == 0;
          // Единый внешний скролл: header + табы + контент таба + (опц.)
          // кнопка «Новая выплата» прокручиваются вместе — без вложенного
          // скролла внутри таба.
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(projectBudgetProvider(projectId)),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(budget: b, projectId: projectId),
                  if (headerZero || b.noStageBudget)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.x16,
                        0,
                        AppSpacing.x16,
                        AppSpacing.x12,
                      ),
                      child: _NoBudgetBanner(
                        isForeman: b.noStageBudget,
                        canEdit: canEditBudget,
                        onEdit: canEditBudget
                            ? () => context
                                  .push(AppRoutes.projectEditWith(projectId))
                            : null,
                      ),
                    ),
                  BudgetTabsBar(
                    selected: tab,
                    onChanged: (t) =>
                        ref.read(_budgetTabProvider.notifier).state = t,
                    paymentsCount: 0,
                  ),
                  switch (tab) {
                    BudgetTab.payments => _PaymentsTab(
                      projectId: projectId,
                      canCreatePayment: canCreatePayment,
                    ),
                    BudgetTab.materials => _MaterialsTab(projectId: projectId),
                    BudgetTab.history => _HistoryTab(projectId: projectId),
                  },
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Hero (общий бюджет + 2 mini-card). Для роли foreman сверху добавляется
/// «Моя касса» с агрегированным остатком (получено − распределено).
class _Header extends ConsumerWidget {
  const _Header({required this.budget, required this.projectId});

  final ProjectBudget budget;
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Wallet получаем из moneyFlow — бэк отдаёт его только в foreman-срезе.
    // Watch без range (вся история проекта), чтобы агрегаты были полными.
    final wallet = budget.viewerKind == BudgetViewerKind.foreman
        ? ref
              .watch(
                moneyFlowFilteredProvider(
                  MoneyFlowQuery(projectId: projectId),
                ),
              )
              .value
              ?.wallet
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x16,
        vertical: AppSpacing.x14,
      ),
      child: Column(
        children: [
          if (wallet != null) ...[
            ForemanWalletCard(wallet: wallet),
            const SizedBox(height: AppSpacing.x10),
            // Primary CTA для бригадира — простой путь выплаты мастеру.
            // Раньше эта кнопка пряталась внутри PaymentDetailScreen, и
            // бригадиры её не находили. Теперь — заметным CTA под кассой.
            AppButton(
              label: 'Выплатить мастеру',
              icon: Icons.payments_rounded,
              onPressed: () => showPayMasterFromWalletSheet(
                context,
                ref,
                projectId: projectId,
                available: wallet.available,
              ),
            ),
            const SizedBox(height: AppSpacing.x12),
          ],
          BudgetHeroCard(
            total: budget.total,
            work: budget.work,
            materials: budget.materials,
          ),
        ],
      ),
    );
  }
}

/// Таб «Выплаты»: sub-summary chip + список выплат + (опц.) кнопка-создания.
/// Возвращает Column — встраивается в общий SingleChildScrollView страницы.
class _PaymentsTab extends ConsumerWidget {
  const _PaymentsTab({
    required this.projectId,
    required this.canCreatePayment,
  });

  final String projectId;
  final bool canCreatePayment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(paymentsControllerProvider(projectId));
    final approvalsAsync = ref.watch(approvalsControllerProvider(projectId));
    return paymentsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.x40),
        child: AppLoadingState(skeleton: AppListSkeleton()),
      ),
      error: (e, _) => AppErrorState(
        title: 'Не удалось загрузить выплаты',
        onRetry: () => ref.invalidate(paymentsControllerProvider(projectId)),
      ),
      data: (payments) {
        final total = payments.fold<int>(0, (a, p) => a + p.amount);

        // Pending-extras (доп.работы) уведомление.
        final pendingExtras =
            approvalsAsync.value?.pending
                .where((a) => a.scope == ApprovalScope.extraWork)
                .toList() ??
            const <Approval>[];
        final extrasTotal = pendingExtras.fold<int>(
          0,
          (acc, a) => acc + (a.extraPrice ?? 0),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.x10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
              child: MoneySummaryChip(
                title: 'Итого выплат',
                total: total,
              ),
            ),
            if (pendingExtras.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.x10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
                child: _PendingExtrasBanner(
                  count: pendingExtras.length,
                  total: extrasTotal,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.x12),
            if (payments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.x16,
                  vertical: AppSpacing.x40,
                ),
                child: Text(
                  'Выплат пока нет',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(color: AppColors.n400),
                ),
              )
            else
              for (final p in payments) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.x16,
                  ),
                  child: PaymentRowCard(
                    payment: p,
                    recipientName: _shorten(p.toUserId),
                    onTap: () =>
                        context.push(AppRoutes.paymentDetailWith(p.id)),
                  ),
                ),
                const SizedBox(height: AppSpacing.x8),
              ],
            if (canCreatePayment)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x16,
                  AppSpacing.x16,
                  AppSpacing.x16,
                  AppSpacing.x8,
                ),
                child: AppButton(
                  label: 'Новая выплата',
                  icon: Icons.add_rounded,
                  onPressed: () =>
                      context.push('/projects/$projectId/payments/new'),
                ),
              ),
            const SizedBox(height: AppSpacing.x24),
          ],
        );
      },
    );
  }

  String _shorten(String userId) =>
      userId.length <= 12 ? userId : '${userId.substring(0, 12)}…';
}

class _PendingExtrasBanner extends StatelessWidget {
  const _PendingExtrasBanner({required this.count, required this.total});

  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: AppColors.yellowBg,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.yellowDot.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.schedule_rounded,
            color: AppColors.yellowText,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.x10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Доп.работы ожидают одобрения',
                  style: AppTextStyles.subtitle.copyWith(
                    color: AppColors.yellowText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count запрос(ов) · ${Money.format(total)} — попадут в '
                  'бюджет после согласования заказчиком',
                  style: AppTextStyles.tiny.copyWith(
                    color: AppColors.yellowText,
                    fontStyle: FontStyle.italic,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Таб «Материалы»: search + filter chips + date-range chip + table.
class _MaterialsTab extends ConsumerStatefulWidget {
  const _MaterialsTab({required this.projectId});

  final String projectId;

  @override
  ConsumerState<_MaterialsTab> createState() => _MaterialsTabState();
}

class _MaterialsTabState extends ConsumerState<_MaterialsTab> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final range = ref.watch(_materialsRangeProvider);
    final query = MoneyFlowQuery(
      projectId: widget.projectId,
      from: range.from,
      to: range.to,
    );
    final flowAsync = ref.watch(moneyFlowFilteredProvider(query));
    return flowAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.x40),
        child: AppLoadingState(),
      ),
      error: (e, _) => AppErrorState(
        title: 'Не удалось загрузить',
        onRetry: () => ref.invalidate(moneyFlowFilteredProvider(query)),
      ),
      data: (flow) {
        final allRows = flow.materialPurchases
            .map(
              (m) => BudgetMaterialsRow(
                title: m.title,
                subtitle: _materialSubtitle(m),
                qtyLabel: '${m.itemCount}',
                amount: m.totalSpent,
              ),
            )
            .toList();
        final spRows = flow.approvedSelfpurchases
            .map(
              (sp) => BudgetMaterialsRow(
                title: 'Самозакуп: ${sp.byUserName}',
                subtitle: sp.comment ?? 'самозакуп',
                qtyLabel: '—',
                amount: sp.amount,
                highlight: true,
              ),
            )
            .toList();
        final rows = [...allRows, ...spRows]
            .where(
              (r) =>
                  _search.isEmpty ||
                  r.title.toLowerCase().contains(_search.toLowerCase()) ||
                  r.subtitle.toLowerCase().contains(_search.toLowerCase()),
            )
            .toList();
        final pending = flow.pendingMaterials
            .where(
              (m) =>
                  _search.isEmpty ||
                  m.title.toLowerCase().contains(_search.toLowerCase()) ||
                  m.requestedByName
                      .toLowerCase()
                      .contains(_search.toLowerCase()),
            )
            .toList();
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.x16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Search
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.n0,
                border: Border.all(color: AppColors.n200, width: 1.5),
                borderRadius: BorderRadius.circular(AppRadius.r12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    size: 16,
                    color: AppColors.n400,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _search = v),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Поиск по материалам',
                        hintStyle: AppTextStyles.caption.copyWith(
                          color: AppColors.n400,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.x10),
            // Date-range chip
            Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  onTap: () async {
                    final picked = await showDateRangeSheet(
                      context,
                      initial: range,
                    );
                    if (picked != null) {
                      ref.read(_materialsRangeProvider.notifier).state = picked;
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.n0,
                      border: Border.all(color: AppColors.n200, width: 1.5),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 12,
                          color: AppColors.n600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          range.label(),
                          style: AppTextStyles.tiny.copyWith(
                            color: AppColors.n600,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x10),
            if (pending.isNotEmpty) ...[
              _PendingMaterialsSection(items: pending),
              const SizedBox(height: AppSpacing.x12),
            ],
            if (rows.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.x40),
                child: Text(
                  pending.isEmpty
                      ? 'Нет покупок за выбранный период'
                      : 'Купленных материалов пока нет',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(color: AppColors.n400),
                ),
              )
            else
              BudgetMaterialsTable(rows: rows),
            const SizedBox(height: AppSpacing.x16),
            AppButton(
              label: 'Скачать отчёт по материалам',
              icon: Icons.file_download_outlined,
              variant: AppButtonVariant.secondary,
              onPressed: () => _showExportSoon(context),
            ),
            const SizedBox(height: AppSpacing.x24),
          ],
          ),
        );
      },
    );
  }

  /// Подпись «купил: …» под материалом. Заказчик/представитель видят,
  /// бригадирский запрос или собственная покупка — у каждой роли свой бэйдж.
  String _materialSubtitle(MaterialPurchaseFlow m) {
    final qty = '${m.itemCount} ${_pluralPositions(m.itemCount)}';
    final who = m.boughtBy == MaterialBoughtBy.customer
        ? 'купил заказчик'
        : 'купил ${m.requestedByName}';
    return '$qty · $who';
  }

  String _pluralPositions(int n) {
    if (n == 1) return 'позиция';
    if (n >= 2 && n <= 4) return 'позиции';
    return 'позиций';
  }

  void _showExportSoon(BuildContext context) {
    AppToast.show(
      context,
      message: 'Экспорт отчёта подключим в следующей итерации',
    );
  }
}

/// Inline-баннер «Бюджет не задан / Заказчик не разнёс бюджет по этапам».
/// Показывается, когда total.planned=0 у customer/representative с этапами,
/// или когда у foreman noStageBudget=true.
class _NoBudgetBanner extends StatelessWidget {
  const _NoBudgetBanner({
    required this.isForeman,
    required this.canEdit,
    this.onEdit,
  });

  final bool isForeman;
  final bool canEdit;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final title = isForeman
        ? 'Бюджет по вашим этапам не задан'
        : 'Бюджет проекта не задан';
    final subtitle = isForeman
        ? 'Заказчик не распределил бюджет по этапам. Обратитесь к нему, '
              'чтобы суммы появились в шапке.'
        : canEdit
        ? 'Укажите бюджет работ и материалов, чтобы видеть прогноз и остаток.'
        : 'Заказчик ещё не задал бюджет — обратитесь к нему.';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: AppColors.yellowBg,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.yellowDot.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.yellowText,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.x10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.subtitle.copyWith(
                    color: AppColors.yellowText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.tiny.copyWith(
                    color: AppColors.yellowText,
                    fontSize: 11,
                  ),
                ),
                if (canEdit && onEdit != null && !isForeman) ...[
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: onEdit,
                    child: Text(
                      'Открыть редактирование →',
                      style: AppTextStyles.tiny.copyWith(
                        color: AppColors.brand,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Master-view экрана бюджета. ТЗ §7 / §10:
/// мастер видит только свои персональные выплаты — без планнинга проекта.
class _MasterEarningsView extends StatelessWidget {
  const _MasterEarningsView({required this.projectId, required this.earnings});

  // ignore: unused_element_parameter — projectId зарезервирован для будущих CTA.
  final String projectId;
  final List<MasterEarning> earnings;

  @override
  Widget build(BuildContext context) {
    // В упрощённой модели платёж = факт передачи денег. Все earnings
    // отображаются единой лентой — никаких подсекций по статусу.
    final totalReceived = earnings.fold<int>(0, (a, e) => a + e.amount);

    if (earnings.isEmpty) {
      return const AppEmptyState(
        title: 'Выплат ещё не было',
        subtitle:
            'Когда заказчик или бригадир сделает выплату — вы увидите её здесь.',
        icon: Icons.payments_outlined,
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x16,
        AppSpacing.x14,
        AppSpacing.x16,
        AppSpacing.x40,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.x16),
          decoration: BoxDecoration(
            color: AppColors.greenLight,
            borderRadius: AppRadius.card,
            border: Border.all(color: AppColors.greenDot.withValues(alpha: 0.3)),
            boxShadow: AppShadows.shCard,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.n0,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.greenDark.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 20,
                      color: AppColors.greenDark,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x10),
                  Text(
                    'ПОЛУЧЕНО ПО ПРОЕКТУ',
                    style: AppTextStyles.tiny.copyWith(
                      color: AppColors.greenDark,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x8),
              Text(
                Money.format(totalReceived),
                style: AppTextStyles.h1.copyWith(
                  color: AppColors.greenDark,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Сумма всех выплат вам по этому проекту',
                style: AppTextStyles.tiny.copyWith(
                  color: AppColors.n600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.x16),
        _EarningsSection(title: 'Все выплаты', items: earnings),
        ],
      ),
    );
  }
}

class _EarningsSection extends StatelessWidget {
  const _EarningsSection({required this.title, required this.items});

  final String title;
  final List<MasterEarning> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: AppTextStyles.subtitle.copyWith(
            color: AppColors.n700,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.x8),
        for (final e in items) ...[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x14,
              vertical: AppSpacing.x12,
            ),
            decoration: BoxDecoration(
              color: AppColors.n0,
              borderRadius: AppRadius.card,
              border: Border.all(color: AppColors.n200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Money.format(e.amount),
                        style: AppTextStyles.h2.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _fmtDate(e.createdAt),
                        style: AppTextStyles.tiny.copyWith(
                          color: AppColors.n500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: AppColors.greenDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x8),
        ],
      ],
    );
  }

  String _fmtDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd.$mm.${d.year}';
  }
}

/// Таб «История» — единая лента движений: авансы / распределения / самозакупы / материалы.
/// Использует тот же moneyFlowFilteredProvider, что и Материалы (бэк отдаёт срез по роли).
class _HistoryTab extends ConsumerStatefulWidget {
  const _HistoryTab({required this.projectId});
  final String projectId;

  @override
  ConsumerState<_HistoryTab> createState() => _HistoryTabState();
}

enum _HistoryFilter { all, advances, distributions, selfpurchases, materials }

class _HistoryTabState extends ConsumerState<_HistoryTab> {
  _HistoryFilter _filter = _HistoryFilter.all;

  @override
  Widget build(BuildContext context) {
    final range = ref.watch(_materialsRangeProvider);
    final query = MoneyFlowQuery(
      projectId: widget.projectId,
      from: range.from,
      to: range.to,
    );
    final flowAsync = ref.watch(moneyFlowFilteredProvider(query));
    return flowAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.x40),
        child: AppLoadingState(),
      ),
      error: (e, _) => AppErrorState(
        title: 'Не удалось загрузить историю',
        onRetry: () => ref.invalidate(moneyFlowFilteredProvider(query)),
      ),
      data: (flow) {
        // Сводим все 4 источника в единую отсортированную ленту.
        final rows = <_HistoryRow>[];
        if (_filter == _HistoryFilter.all ||
            _filter == _HistoryFilter.advances) {
          for (final a in flow.advances) {
            rows.add(
              _HistoryRow(
                kind: _HistoryKind.advance,
                title: 'Аванс → ${a.toUserName}',
                subtitle: 'аванс',
                amount: a.amount,
                when: a.createdAt,
              ),
            );
          }
        }
        if (_filter == _HistoryFilter.all ||
            _filter == _HistoryFilter.distributions) {
          for (final d in flow.distributions) {
            rows.add(
              _HistoryRow(
                kind: _HistoryKind.distribution,
                title: 'Распределение → ${d.toUserName}',
                subtitle: 'распределение',
                amount: d.amount,
                when: d.createdAt,
              ),
            );
          }
        }
        if (_filter == _HistoryFilter.all ||
            _filter == _HistoryFilter.selfpurchases) {
          for (final sp in flow.approvedSelfpurchases) {
            rows.add(
              _HistoryRow(
                kind: _HistoryKind.selfpurchase,
                title: 'Самозакуп: ${sp.byUserName}',
                subtitle: sp.comment ?? 'одобрено заказчиком',
                amount: sp.amount,
                when: sp.decidedAt ?? DateTime.now(),
              ),
            );
          }
        }
        if (_filter == _HistoryFilter.all ||
            _filter == _HistoryFilter.materials) {
          for (final m in flow.materialPurchases) {
            final who = m.boughtBy == MaterialBoughtBy.customer
                ? 'купил заказчик'
                : 'купил ${m.requestedByName}';
            rows.add(
              _HistoryRow(
                kind: _HistoryKind.material,
                title: m.title,
                subtitle: '${m.itemCount} поз. · $who',
                amount: m.totalSpent,
                when: DateTime.now(),
              ),
            );
          }
          // Отклонённые материалы — серая строка, amount зачёркнут.
          for (final r in flow.rejectedMaterials) {
            rows.add(
              _HistoryRow(
                kind: _HistoryKind.rejected,
                title: r.title,
                subtitle: 'отклонено · запросил ${r.requestedByName}',
                amount: r.estimatedTotal,
                when: r.decidedAt,
              ),
            );
          }
        }
        if (_filter == _HistoryFilter.all ||
            _filter == _HistoryFilter.selfpurchases) {
          for (final sp in flow.rejectedSelfpurchases) {
            rows.add(
              _HistoryRow(
                kind: _HistoryKind.rejected,
                title: 'Самозакуп: ${sp.byUserName}',
                subtitle: 'отклонено${sp.comment != null ? ' · ${sp.comment}' : ''}',
                amount: sp.amount,
                when: sp.decidedAt ?? DateTime.now(),
              ),
            );
          }
        }
        rows.sort((a, b) => b.when.compareTo(a.when));

        return Padding(
          padding: const EdgeInsets.all(AppSpacing.x16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final f in _HistoryFilter.values) ...[
                    _FilterChip(
                      label: _filterLabel(f),
                      active: _filter == f,
                      onTap: () => setState(() => _filter = f),
                    ),
                    const SizedBox(width: AppSpacing.x6),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.x10),
            InkWell(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              onTap: () async {
                final picked = await showDateRangeSheet(
                  context,
                  initial: range,
                );
                if (picked != null) {
                  ref.read(_materialsRangeProvider.notifier).state = picked;
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.n0,
                  border: Border.all(color: AppColors.n200, width: 1.5),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 12,
                      color: AppColors.n600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      range.label(),
                      style: AppTextStyles.tiny.copyWith(
                        color: AppColors.n600,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.x12),
            if (rows.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.x40),
                child: Text(
                  'Движений по выбранным фильтрам нет',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(color: AppColors.n400),
                ),
              )
            else
              for (final r in rows) ...[
                _HistoryRowCard(row: r),
                const SizedBox(height: AppSpacing.x8),
              ],
            const SizedBox(height: AppSpacing.x16),
          ],
          ),
        );
      },
    );
  }

  String _filterLabel(_HistoryFilter f) => switch (f) {
    _HistoryFilter.all => 'Все',
    _HistoryFilter.advances => 'Авансы',
    _HistoryFilter.distributions => 'Распределения',
    _HistoryFilter.selfpurchases => 'Самозакуп',
    _HistoryFilter.materials => 'Материалы',
  };
}

enum _HistoryKind { advance, distribution, selfpurchase, material, rejected }

class _HistoryRow {
  _HistoryRow({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.when,
  });
  final _HistoryKind kind;
  final String title;
  final String subtitle;
  final int amount;
  final DateTime when;
}

class _HistoryRowCard extends StatelessWidget {
  const _HistoryRowCard({required this.row});
  final _HistoryRow row;

  @override
  Widget build(BuildContext context) {
    final (icon, color, bg) = switch (row.kind) {
      _HistoryKind.advance => (
        Icons.south_west_rounded,
        AppColors.brand,
        AppColors.brandLight,
      ),
      _HistoryKind.distribution => (
        Icons.north_east_rounded,
        AppColors.greenDark,
        AppColors.greenLight,
      ),
      _HistoryKind.selfpurchase => (
        Icons.shopping_bag_outlined,
        AppColors.yellowText,
        AppColors.yellowBg,
      ),
      _HistoryKind.material => (
        Icons.local_shipping_outlined,
        AppColors.n700,
        AppColors.n100,
      ),
      _HistoryKind.rejected => (
        Icons.cancel_outlined,
        AppColors.n500,
        AppColors.n100,
      ),
    };
    final isRejected = row.kind == _HistoryKind.rejected;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x12),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.n200),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: AppSpacing.x10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.title,
                  style: AppTextStyles.subtitle.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isRejected ? AppColors.n500 : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  row.subtitle,
                  style: AppTextStyles.tiny.copyWith(color: AppColors.n500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.x8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Money.format(row.amount),
                style: AppTextStyles.subtitle.copyWith(
                  fontWeight: FontWeight.w900,
                  color: isRejected ? AppColors.n400 : null,
                  decoration: isRejected ? TextDecoration.lineThrough : null,
                ),
              ),
              Text(
                _fmtDate(row.when),
                style: AppTextStyles.tiny.copyWith(
                  color: AppColors.n400,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd.$mm.${d.year}';
  }
}

/// Секция «На согласовании» в табе «Материалы».
/// Полупрозрачная карточка с yellow-акцентом — суммы НЕ учтены в spent,
/// заказчик/представитель ещё не приняли решение.
class _PendingMaterialsSection extends StatelessWidget {
  const _PendingMaterialsSection({required this.items});

  final List<PendingMaterialFlow> items;

  @override
  Widget build(BuildContext context) {
    final total = items.fold<int>(0, (acc, m) => acc + m.estimatedTotal);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.yellowBg,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.yellowDot.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x14,
              AppSpacing.x12,
              AppSpacing.x14,
              AppSpacing.x8,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 16,
                  color: AppColors.yellowText,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'НА СОГЛАСОВАНИИ · ${items.length}',
                    style: AppTextStyles.tiny.copyWith(
                      color: AppColors.yellowText,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Text(
                  '≈ ${Money.format(total)}',
                  style: AppTextStyles.tiny.copyWith(
                    color: AppColors.yellowText,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Divider(height: 1, color: AppColors.yellowDot.withValues(alpha: 0.2)),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.x14,
                vertical: AppSpacing.x10,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          items[i].title,
                          style: AppTextStyles.subtitle.copyWith(
                            color: AppColors.yellowText,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'запросил ${items[i].requestedByName} · '
                          '${items[i].itemCount} поз.',
                          style: AppTextStyles.tiny.copyWith(
                            color: AppColors.yellowText,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '≈ ${Money.format(items[i].estimatedTotal)}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.yellowText,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x14,
              0,
              AppSpacing.x14,
              AppSpacing.x10,
            ),
            child: Text(
              'Суммы попадут в бюджет после одобрения заказчиком.',
              style: AppTextStyles.tiny.copyWith(
                color: AppColors.yellowText,
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.brand : AppColors.n0,
          border: Border.all(
            color: active ? AppColors.brand : AppColors.n200,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: AppTextStyles.tiny.copyWith(
            color: active ? AppColors.n0 : AppColors.n700,
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
