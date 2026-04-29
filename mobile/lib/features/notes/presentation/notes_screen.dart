import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/notes_controller.dart';
import '../domain/note.dart';
import 'note_detail_screen.dart';

/// `f-notes` / `f-notes-shared` / `f-notes-empty` (`Кластер F`).
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
          icon: const Icon(Icons.add_rounded, color: AppColors.brand),
          tooltip: 'Создать заметку',
          onPressed: () => _showCreateSheet(context),
        ),
      ],
      body: Column(
        children: [
          _FilterBar(
            selected: _filter,
            onChanged: (v) => setState(() => _filter = v),
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
                        _filter == null ? 'Нет заметок' : 'Ничего не найдено',
                    subtitle: _filter == null
                        ? 'Создайте заметку — личную для себя или общую для '
                            'всей команды'
                        : null,
                    icon: Icons.sticky_note_2_outlined,
                    actionLabel: 'Создать заметку',
                    onAction: () => _showCreateSheet(context),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(
                    notesControllerProvider(widget.projectId),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _NoteTile(
                      note: filtered[i],
                      onTap: () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => NoteDetailScreen(
                            projectId: widget.projectId,
                            noteId: filtered[i].id,
                          ),
                        ),
                      ),
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

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onChanged});

  final NoteScope? selected;
  final ValueChanged<NoteScope?> onChanged;

  @override
  Widget build(BuildContext context) {
    final chips = <AppFilterPillSpec>[
      const AppFilterPillSpec(id: '__all__', label: 'Все'),
      for (final s in NoteScope.values)
        AppFilterPillSpec(id: s.name, label: s.displayName),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.n0,
        border: Border(bottom: BorderSide(color: AppColors.n100)),
      ),
      child: AppFilterPillBar(
        chips: chips,
        activeId: selected?.name ?? '__all__',
        onSelect: (id) {
          if (id == '__all__') {
            onChanged(null);
          } else {
            onChanged(NoteScope.values.firstWhere((s) => s.name == id));
          }
        },
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  const _NoteTile({required this.note, required this.onTap});

  final Note note;
  final VoidCallback onTap;

  String get _title {
    final lines = note.text.split('\n');
    final firstLine = lines.first.trim();
    if (firstLine.length > 60) return '${firstLine.substring(0, 57)}…';
    return firstLine.isEmpty ? 'Заметка' : firstLine;
  }

  String get _body {
    final lines = note.text.split('\n');
    if (lines.length > 1) return lines.sublist(1).join(' ').trim();
    if (note.text.length > 60) return note.text;
    return '';
  }

  AppRoleBadgeTone get _badgeTone {
    switch (note.scope) {
      case NoteScope.personal:
        return AppRoleBadgeTone.customer;
      case NoteScope.forMe:
        return AppRoleBadgeTone.foreman;
      case NoteScope.stage:
        return AppRoleBadgeTone.representative;
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d MMM', 'ru');
    return Material(
      color: AppColors.n0,
      borderRadius: BorderRadius.circular(AppRadius.r16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.n0,
            border: Border.all(color: AppColors.n200),
            borderRadius: BorderRadius.circular(AppRadius.r16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.n900,
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppRoleBadge(
                    label: note.scope.displayName,
                    tone: _badgeTone,
                    variant: AppRoleBadgeVariant.compact,
                  ),
                ],
              ),
              if (_body.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  _body,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.n500,
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  AppAvatar(seed: note.authorId, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    df.format(note.createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.n400,
                    ),
                  ),
                  const Spacer(),
                  if (note.scope != NoteScope.personal) ...[
                    const Icon(
                      Icons.visibility_outlined,
                      size: 12,
                      color: AppColors.n400,
                    ),
                    const SizedBox(width: 3),
                    const Text(
                      'Команда',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.n400,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
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
        const Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: Text(
            'Новая заметка',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.n900,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Text(
            'Видимость и текст заметки',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.n400,
            ),
          ),
        ),
        if (_error != null) ...[
          AppInlineError(message: _error!),
          const SizedBox(height: 12),
        ],
        const Text(
          'ВИДИМОСТЬ',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.n500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in NoteScope.values)
              GestureDetector(
                onTap: () => setState(() => _scope = s),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: AppDurations.fast,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: _scope == s ? AppColors.brandLight : AppColors.n0,
                    border: Border.all(
                      color: _scope == s ? AppColors.brand : AppColors.n200,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    s.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _scope == s ? AppColors.brand : AppColors.n600,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'ТЕКСТ ЗАМЕТКИ',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.n500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _text,
          minLines: 4,
          maxLines: 8,
          maxLength: 5000,
          decoration: InputDecoration(
            hintText: 'Что нужно запомнить?',
            hintStyle: AppTextStyles.body.copyWith(color: AppColors.n400),
            filled: true,
            fillColor: AppColors.n50,
            contentPadding: const EdgeInsets.all(14),
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
        const SizedBox(height: 16),
        AppButton(
          label: 'Сохранить',
          isLoading: _submitting,
          onPressed: _submit,
        ),
      ],
    );
  }
}
