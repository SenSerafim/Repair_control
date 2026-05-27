import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/projects_list_controller.dart';
import '../domain/project.dart';
import 'project_card.dart';

/// s-search — клиентский поиск по активным + архивным проектам с фильтр-чипами.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

enum _SearchFilter { all, overdue, atRisk, onTrack, awaiting }

enum _SortBy {
  recent('Сначала свежие'),
  alpha('По названию'),
  deadline('По дедлайну');

  const _SortBy(this.label);
  final String label;
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';
  _SearchFilter _filter = _SearchFilter.all;
  _SortBy _sort = _SortBy.recent;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _query = v.trim().toLowerCase());
    });
  }

  bool _matchesFilter(Project p) {
    return switch (_filter) {
      _SearchFilter.all => true,
      _SearchFilter.overdue => p.semaphore == Semaphore.red,
      _SearchFilter.atRisk => p.semaphore == Semaphore.yellow,
      _SearchFilter.onTrack => p.semaphore == Semaphore.green,
      _SearchFilter.awaiting => p.semaphore == Semaphore.blue,
    };
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activeProjectsProvider).value ?? const [];
    final archived = ref.watch(archivedProjectsProvider).value ?? const [];
    final all = [...active, ...archived];

    final results =
        (_query.isEmpty
                ? all
                : all.where(
                    (p) =>
                        p.title.toLowerCase().contains(_query) ||
                        (p.address?.toLowerCase().contains(_query) ?? false),
                  ))
            .where(_matchesFilter)
            .toList();
    // Сортировка применяется поверх result-list, чтобы выбранные фильтры
    // не «прыгали» при смене сортировки.
    switch (_sort) {
      case _SortBy.recent:
        results.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case _SortBy.alpha:
        results.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
      case _SortBy.deadline:
        results.sort((a, b) {
          final ae = a.plannedEnd;
          final be = b.plannedEnd;
          if (ae == null && be == null) return 0;
          if (ae == null) return 1;
          if (be == null) return -1;
          return ae.compareTo(be);
        });
    }

    return AppScaffold(
      showBack: true,
      title: 'Поиск',
      backgroundColor: AppColors.n50,
      padding: EdgeInsets.zero,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: AppInput(
              controller: _controller,
              placeholder: 'Название или адрес',
              autofocus: true,
              onChanged: _onChanged,
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 14, right: 8),
                child: Icon(
                  PhosphorIconsRegular.magnifyingGlass,
                  size: 18,
                  color: AppColors.n400,
                ),
              ),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(
                        PhosphorIconsRegular.xCircle,
                        size: 18,
                        color: AppColors.n400,
                      ),
                      onPressed: () {
                        _controller.clear();
                        _onChanged('');
                      },
                    ),
            ),
          ),
          AppFilterChips(
            activeId: _filter.name,
            onSelect: (id) => setState(
              () => _filter = _SearchFilter.values.firstWhere(
                (f) => f.name == id,
                orElse: () => _SearchFilter.all,
              ),
            ),
            chips: const [
              AppFilterChipSpec(id: 'all', label: 'Все'),
              AppFilterChipSpec(id: 'overdue', label: 'Просроченные'),
              AppFilterChipSpec(id: 'atRisk', label: 'В зоне риска'),
              AppFilterChipSpec(id: 'onTrack', label: 'По графику'),
              AppFilterChipSpec(id: 'awaiting', label: 'Ждут действия'),
            ],
          ),
          const SizedBox(height: AppSpacing.x6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
            child: Row(
              children: [
                _SortChip(
                  current: _sort,
                  onSelected: (s) => setState(() => _sort = s),
                ),
                const Spacer(),
                Text(
                  '${results.length} ${_pluralResults(results.length)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.n400,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
          Expanded(
            child: _query.isEmpty && _filter == _SearchFilter.all
                ? const _Hint()
                : results.isEmpty
                ? const AppEmptyState(
                    title: 'Ничего не найдено',
                    subtitle: 'Попробуйте изменить запрос или сбросить фильтры',
                    icon: PhosphorIconsRegular.magnifyingGlassMinus,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: results.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.x10),
                    itemBuilder: (_, i) => ProjectCard(
                      project: results[i],
                      onTap: () => context.push('/projects/${results[i].id}'),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Sort-чип с пунктирной обводкой (HTML `s-search` — `.fc.fc-dashed`).
/// Тап показывает bottom-sheet с тремя пресетами.
class _SortChip extends StatelessWidget {
  const _SortChip({required this.current, required this.onSelected});

  final _SortBy current;
  final ValueChanged<_SortBy> onSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      onTap: () async {
        final picked = await showAppBottomSheet<_SortBy>(
          context: context,
          child: _SortSheet(current: current),
        );
        if (picked != null) onSelected(picked);
      },
      child: AppDashedBorder(
        color: AppColors.n300,
        borderRadius: AppRadius.pill,
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIconsRegular.funnelSimple,
              size: 12,
              color: AppColors.n500,
            ),
            const SizedBox(width: 6),
            Text(
              current.label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.n600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              PhosphorIconsRegular.caretUpDown,
              size: 12,
              color: AppColors.n400,
            ),
          ],
        ),
      ),
    );
  }
}

class _SortSheet extends StatelessWidget {
  const _SortSheet({required this.current});

  final _SortBy current;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppBottomSheetHeader(title: 'Сортировка', centered: true),
        const SizedBox(height: AppSpacing.x10),
        for (final s in _SortBy.values)
          InkWell(
            onTap: () => Navigator.of(context).pop(s),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Icon(
                    s == current
                        ? PhosphorIconsBold.checkCircle
                        : PhosphorIconsRegular.circle,
                    size: 20,
                    color: s == current ? AppColors.brand : AppColors.n300,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    s.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: s == current ? AppColors.brand : AppColors.n800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.x4),
      ],
    );
  }
}

String _pluralResults(int n) {
  final mod10 = n % 10;
  final mod100 = n % 100;
  if (mod10 == 1 && mod100 != 11) return 'результат';
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
    return 'результата';
  }
  return 'результатов';
}

class _Hint extends StatelessWidget {
  const _Hint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.n100,
                borderRadius: BorderRadius.circular(AppRadius.r20),
              ),
              child: Icon(
                PhosphorIconsRegular.magnifyingGlass,
                size: 26,
                color: AppColors.n400,
              ),
            ),
            const SizedBox(height: AppSpacing.x12),
            const Text(
              'Поиск по объектам',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.n800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Введите название или адрес — мы найдём в активных и в архиве',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.n500,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
