import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/notes_controller.dart';
import '../domain/note.dart';

/// s-notes — список заметок по проекту. Фильтр по scope.
class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({required this.projectId, super.key});

  final String projectId;

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  NoteScope? _filter;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(notesControllerProvider(widget.projectId));

    return AppScaffold(
      showBack: true,
      title: 'Заметки',
      padding: EdgeInsets.zero,
      actions: [
        IconButton(
          icon: const Icon(Icons.add_rounded),
          onPressed: () => _showCreateSheet(context),
        ),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.x16),
            child: SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(
                    label: 'Все',
                    selected: _filter == null,
                    onTap: () => setState(() => _filter = null),
                  ),
                  const SizedBox(width: AppSpacing.x6),
                  for (final s in NoteScope.values) ...[
                    _FilterChip(
                      label: s.displayName,
                      selected: _filter == s,
                      onTap: () => setState(() => _filter = s),
                    ),
                    const SizedBox(width: AppSpacing.x6),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const AppLoadingState(),
              error: (e, _) => AppErrorState(
                title: 'Не удалось загрузить заметки',
                onRetry: () => ref.invalidate(
                  notesControllerProvider(widget.projectId),
                ),
              ),
              data: (notes) {
                final filtered = _filter == null
                    ? notes
                    : notes.where((n) => n.scope == _filter).toList();
                if (filtered.isEmpty) {
                  return AppEmptyState(
                    title:
                        _filter == null ? 'Заметок нет' : 'Ничего не найдено',
                    subtitle:
                        'Заметки помогут не забыть важное — тап «+» вверху.',
                    icon: Icons.sticky_note_2_outlined,
                    actionLabel: 'Добавить',
                    onAction: () => _showCreateSheet(context),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(
                    notesControllerProvider(widget.projectId),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.x16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.x10),
                    itemBuilder: (_, i) => _NoteTile(
                      note: filtered[i],
                      onDelete: () => ref
                          .read(notesControllerProvider(widget.projectId)
                              .notifier)
                          .delete(filtered[i].id),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateSheet(BuildContext context) async {
    await showAppBottomSheet<void>(
      context: context,
      child: _CreateNoteBody(projectId: widget.projectId),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x12,
          vertical: AppSpacing.x6,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.brand : AppColors.n100,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: selected ? AppColors.n0 : AppColors.n700,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  const _NoteTile({required this.note, required this.onDelete});

  final Note note;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d MMM, HH:mm', 'ru');
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppRadius.card,
        boxShadow: AppShadows.sh1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.x8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.brandLight,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  note.scope.displayName,
                  style: AppTextStyles.tiny.copyWith(color: AppColors.brand),
                ),
              ),
              const Spacer(),
              Text(df.format(note.createdAt), style: AppTextStyles.tiny),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                color: AppColors.n400,
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x8),
          Text(note.text, style: AppTextStyles.body),
        ],
      ),
    );
  }
}

class _CreateNoteBody extends ConsumerStatefulWidget {
  const _CreateNoteBody({required this.projectId});

  final String projectId;

  @override
  ConsumerState<_CreateNoteBody> createState() => _CreateNoteBodyState();
}

class _CreateNoteBodyState extends ConsumerState<_CreateNoteBody> {
  NoteScope _scope = NoteScope.personal;
  final _text = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_text.text.trim().isEmpty) {
      setState(() => _error = 'Введите текст');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final failure = await ref
        .read(notesControllerProvider(widget.projectId).notifier)
        .create(scope: _scope, text: _text.text.trim());
    if (!mounted) return;
    setState(() => _submitting = false);
    if (failure == null) {
      Navigator.of(context).pop();
    } else {
      setState(() => _error = failure.userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppBottomSheetHeader(title: 'Новая заметка'),
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
        const Text('Кому', style: AppTextStyles.caption),
        const SizedBox(height: AppSpacing.x6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in NoteScope.values)
              GestureDetector(
                onTap: () => setState(() => _scope = s),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.x12,
                    vertical: AppSpacing.x6,
                  ),
                  decoration: BoxDecoration(
                    color: _scope == s
                        ? AppColors.brand
                        : AppColors.n100,
                    borderRadius:
                        BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    s.displayName,
                    style: AppTextStyles.caption.copyWith(
                      color:
                          _scope == s ? AppColors.n0 : AppColors.n700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.x12),
        TextField(
          controller: _text,
          minLines: 3,
          maxLines: 6,
          maxLength: 5000,
          decoration: InputDecoration(
            hintText: 'Что нужно запомнить?',
            hintStyle: AppTextStyles.body.copyWith(color: AppColors.n400),
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
        const SizedBox(height: AppSpacing.x16),
        AppButton(
          label: 'Сохранить',
          isLoading: _submitting,
          onPressed: _submit,
        ),
      ],
    );
  }
}
