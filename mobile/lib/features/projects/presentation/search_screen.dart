import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/projects_list_controller.dart';
import '../domain/project.dart';
import 'project_card.dart';

/// s-search — клиентский поиск по активным + архивным проектам.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

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

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activeProjectsProvider).value ?? const [];
    final archived = ref.watch(archivedProjectsProvider).value ?? const [];
    final all = [...active, ...archived];

    final results = _query.isEmpty
        ? <Project>[]
        : all
            .where(
              (p) =>
                  p.title.toLowerCase().contains(_query) ||
                  (p.address?.toLowerCase().contains(_query) ?? false),
            )
            .toList();

    return AppScaffold(
      showBack: true,
      title: 'Поиск',
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
      body: Column(
        children: [
          const SizedBox(height: AppSpacing.x12),
          TextField(
            controller: _controller,
            autofocus: true,
            onChanged: _onChanged,
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 20,
                color: AppColors.n400,
              ),
              hintText: 'Название или адрес',
              hintStyle:
                  AppTextStyles.body.copyWith(color: AppColors.n400),
              filled: true,
              fillColor: AppColors.n0,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.r12),
                borderSide:
                    const BorderSide(color: AppColors.n200, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.r12),
                borderSide:
                    const BorderSide(color: AppColors.n200, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.r12),
                borderSide:
                    const BorderSide(color: AppColors.brand, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x12),
          Expanded(
            child: _query.isEmpty
                ? const AppEmptyState(
                    title: 'Начните вводить',
                    subtitle: 'Ищем по названию и адресу проектов.',
                    icon: Icons.search_rounded,
                  )
                : results.isEmpty
                    ? const AppEmptyState(
                        title: 'Ничего не найдено',
                        icon: Icons.search_off_rounded,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: results.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.x10),
                        itemBuilder: (_, i) {
                          final p = results[i];
                          return ProjectCard(
                            project: p,
                            onTap: () =>
                                context.push('/projects/${p.id}'),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
