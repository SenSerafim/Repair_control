import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../team/application/team_controller.dart';
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
    // QA-баг #2: модалка должна открываться на текущем фильтре, а не на
    // дефолтном «Только мне». Передаём активный _filter как начальный scope
    // для _CreateNoteBody, если он выбран.
    await showAppBottomSheet<void>(
      context: context,
      child: _CreateNoteBody(
        projectId: widget.projectId,
        initialScope: _filter,
      ),
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
      case NoteScope.teamBroadcast:
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
  const _CreateNoteBody({required this.projectId, this.initialScope});

  final String projectId;
  final NoteScope? initialScope;

  @override
  ConsumerState<_CreateNoteBody> createState() => _CreateNoteBodyState();
}

class _CreateNoteBodyState extends ConsumerState<_CreateNoteBody> {
  late NoteScope _scope = widget.initialScope ?? NoteScope.personal;
  /// QA-баг #5: при scope=forMe нужен явный addressee. Заполняется picker'ом
  /// из участников проекта; кнопка submit disabled, пока null.
  String? _addresseeId;
  String? _addresseeName;
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
    if (_scope == NoteScope.forMe && _addresseeId == null) {
      setState(() => _error = 'Выберите получателя');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final failure = await ref
        .read(notesControllerProvider(widget.projectId).notifier)
        .create(
          scope: _scope,
          text: _text.text.trim(),
          addresseeId: _scope == NoteScope.forMe ? _addresseeId : null,
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (failure == null) {
      Navigator.of(context).pop();
    } else {
      setState(() => _error = failure.userMessage);
    }
  }

  Future<void> _pickAddressee() async {
    final teamAsync =
        ref.read(teamControllerProvider(widget.projectId));
    final team = teamAsync.value;
    if (team == null) {
      setState(() => _error = 'Команда ещё загружается, попробуйте ещё раз');
      return;
    }
    if (team.members.isEmpty) {
      setState(() =>
          _error = 'В команде проекта пока нет других участников');
      return;
    }
    final selected = await showAppBottomSheet<({String id, String name})>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppBottomSheetHeader(title: 'Выберите получателя'),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: team.members.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, i) {
                final m = team.members[i];
                final user = m.user;
                final fullName = user == null
                    ? m.userId
                    : '${user.firstName} ${user.lastName}'.trim();
                return ListTile(
                  leading: AppAvatar(
                    seed: m.userId,
                    name: fullName.isEmpty ? null : fullName,
                    imageUrl: user?.avatarUrl,
                  ),
                  title:
                      Text(fullName.isEmpty ? 'Без имени' : fullName),
                  subtitle: Text(m.role.displayName),
                  onTap: () => Navigator.of(context).pop((
                    id: m.userId,
                    name: fullName.isEmpty ? 'Участник' : fullName,
                  )),
                );
              },
            ),
          ),
        ],
      ),
    );
    if (!mounted || selected == null) return;
    setState(() {
      _addresseeId = selected.id;
      _addresseeName = selected.name;
      _error = null;
    });
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
          'КТО УВИДИТ ЗАМЕТКУ',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.n500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        for (final s in NoteScope.values) ...[
          _ScopeOption(
            scope: s,
            selected: _scope == s,
            onTap: () => setState(() {
              _scope = s;
              if (s != NoteScope.forMe) {
                _addresseeId = null;
                _addresseeName = null;
              }
            }),
          ),
          if (s != NoteScope.values.last) const SizedBox(height: 8),
        ],
        if (_scope == NoteScope.forMe) ...[
          const SizedBox(height: 12),
          const Text(
            'ПОЛУЧАТЕЛЬ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.n500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Material(
            color: AppColors.n0,
            borderRadius: BorderRadius.circular(AppRadius.r12),
            child: InkWell(
              onTap: _pickAddressee,
              borderRadius: BorderRadius.circular(AppRadius.r12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.n200),
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline_rounded,
                        color: AppColors.n400),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _addresseeName ?? 'Выбрать участника',
                        style: TextStyle(
                          fontSize: 14,
                          color: _addresseeName == null
                              ? AppColors.n400
                              : AppColors.n900,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.n400),
                  ],
                ),
              ),
            ),
          ),
        ],
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

class _ScopeOption extends StatelessWidget {
  const _ScopeOption({
    required this.scope,
    required this.selected,
    required this.onTap,
  });

  final NoteScope scope;
  final bool selected;
  final VoidCallback onTap;

  IconData get _icon => switch (scope) {
        NoteScope.personal => Icons.lock_outline_rounded,
        NoteScope.forMe => Icons.person_outline_rounded,
        NoteScope.stage => Icons.groups_outlined,
        NoteScope.teamBroadcast => Icons.campaign_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.r12),
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandLight : AppColors.n0,
          border: Border.all(
            color: selected ? AppColors.brand : AppColors.n200,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(AppRadius.r12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _icon,
              size: 22,
              color: selected ? AppColors.brand : AppColors.n500,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scope.displayName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: selected ? AppColors.brand : AppColors.n800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    scope.hint,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.n500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? AppColors.brand : AppColors.n300,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
