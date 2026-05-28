import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/notes_controller.dart';
import '../data/notes_repository.dart';
import '../domain/note.dart';
import 'note_detail_screen.dart';
import 'quick_note_sheet.dart';

/// NEWFIX-2 §11.5 — экран «Заметки проекта». Хронологический список с
/// фильтрами Все / Мои / Команды. Голосовые заметки воспроизводятся inline.
class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({required this.projectId, super.key});

  final String projectId;

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  NotesListFilter _filter = NotesListFilter.all;

  @override
  Widget build(BuildContext context) {
    final filteredAsync = ref.watch(
      projectNotesByFilterProvider((projectId: widget.projectId, filter: _filter)),
    );
    final allAsync = ref.watch(notesControllerProvider(widget.projectId));

    final counts = _counts(allAsync.valueOrNull ?? const <Note>[]);

    return AppScaffold(
      showBack: true,
      title: 'Заметки',
      padding: EdgeInsets.zero,
      actions: [
        IconButton(
          icon: Icon(PhosphorIconsRegular.plus, color: AppColors.brand),
          tooltip: 'Новая заметка',
          onPressed: () =>
              showQuickNoteSheet(context: context, projectId: widget.projectId),
        ),
      ],
      body: Column(
        children: [
          _FilterBar(
            selected: _filter,
            counts: counts,
            onChanged: (v) => setState(() => _filter = v),
          ),
          Expanded(
            child: filteredAsync.when(
              loading: () => const AppLoadingState(),
              error: (e, _) => AppErrorState(
                title: 'Не удалось загрузить заметки',
                subtitle: e.toString(),
                onRetry: () => ref.invalidate(
                  projectNotesByFilterProvider(
                    (projectId: widget.projectId, filter: _filter),
                  ),
                ),
              ),
              data: (notes) {
                if (notes.isEmpty) {
                  return AppEmptyState(
                    title: _emptyTitle,
                    subtitle: _emptyHint,
                    actionLabel: 'Создать заметку',
                    onAction: () => showQuickNoteSheet(
                      context: context,
                      projectId: widget.projectId,
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref
                      ..invalidate(notesControllerProvider(widget.projectId))
                      ..invalidate(
                        projectNotesByFilterProvider(
                          (projectId: widget.projectId, filter: _filter),
                        ),
                      );
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: notes.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.x10),
                    itemBuilder: (_, i) => _NoteCard(
                      note: notes[i],
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => NoteDetailScreen(
                            projectId: widget.projectId,
                            noteId: notes[i].id,
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

  String get _emptyTitle => switch (_filter) {
    NotesListFilter.all => 'Заметок пока нет',
    NotesListFilter.mine => 'Вы пока не оставили ни одной заметки',
    NotesListFilter.team => 'Командных заметок пока нет',
  };

  String get _emptyHint => switch (_filter) {
    NotesListFilter.all =>
      'Запишите мысль или голосовую заметку — позже разберёте и раздадите задачи.',
    NotesListFilter.mine => 'Создайте быструю личную заметку через «+».',
    NotesListFilter.team =>
      'Общая заметка видна всей команде проекта, включая будущих участников.',
  };

  _Counts _counts(List<Note> all) {
    var mine = 0;
    var team = 0;
    final me = _myUserId(all);
    for (final n in all) {
      if (me != null && n.authorId == me) mine++;
      if (n.scope == NoteScope.teamBroadcast) team++;
    }
    return _Counts(all: all.length, mine: mine, team: team);
  }

  /// Эвристика: если все заметки одного автора — это «я». Когда заметок 0,
  /// возвращаем null — счётчик «Мои» покажет 0. Полноценный currentUserId
  /// прилетит в S20 (PR auth-context provider), сейчас не критично.
  String? _myUserId(List<Note> all) {
    if (all.isEmpty) return null;
    final first = all.first.authorId;
    return all.every((n) => n.authorId == first) ? first : null;
  }
}

class _Counts {
  const _Counts({required this.all, required this.mine, required this.team});
  final int all;
  final int mine;
  final int team;
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selected,
    required this.counts,
    required this.onChanged,
  });

  final NotesListFilter selected;
  final _Counts counts;
  final ValueChanged<NotesListFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppFilterPillBar(
      chips: [
        AppFilterPillSpec(
          id: NotesListFilter.all.apiValue,
          label: 'Все · ${counts.all}',
        ),
        AppFilterPillSpec(
          id: NotesListFilter.mine.apiValue,
          label: 'Мои · ${counts.mine}',
        ),
        AppFilterPillSpec(
          id: NotesListFilter.team.apiValue,
          label: 'Команды · ${counts.team}',
        ),
      ],
      activeId: selected.apiValue,
      onSelect: (id) {
        switch (id) {
          case 'mine':
            onChanged(NotesListFilter.mine);
          case 'team':
            onChanged(NotesListFilter.team);
          case 'all':
          default:
            onChanged(NotesListFilter.all);
        }
      },
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note, required this.onTap});

  final Note note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ts = DateFormat('HH:mm · d MMM', 'ru').format(note.createdAt);
    return Material(
      color: AppColors.n0,
      borderRadius: BorderRadius.circular(AppRadius.r12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.r12),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.x14),
          decoration: BoxDecoration(
            color: AppColors.n0,
            border: Border.all(color: AppColors.n200),
            borderRadius: BorderRadius.circular(AppRadius.r12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _KindIcon(note: note),
                  const SizedBox(width: 8),
                  _ScopePill(scope: note.scope, kind: note.kind),
                  const Spacer(),
                  Text(
                    ts,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.n500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x10),
              if (note.kind == NoteKind.audio)
                _AudioPlayerBar(
                  url: note.audioUrl,
                  durationMs: note.audioDurationMs,
                ),
              if (note.kind == NoteKind.audio &&
                  (note.text != null && note.text!.isNotEmpty))
                const SizedBox(height: AppSpacing.x8),
              if (note.text != null && note.text!.isNotEmpty)
                Text(
                  note.text!,
                  style: AppTextStyles.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KindIcon extends StatelessWidget {
  const _KindIcon({required this.note});
  final Note note;

  @override
  Widget build(BuildContext context) {
    final isAudio = note.kind == NoteKind.audio;
    final isTeam = note.scope == NoteScope.teamBroadcast;
    final bg = isTeam ? AppColors.brandLight : AppColors.n50;
    final fg = isTeam ? AppColors.brand : AppColors.n700;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      child: Icon(
        isAudio ? PhosphorIconsFill.microphone : PhosphorIconsFill.notepad,
        color: fg,
        size: 16,
      ),
    );
  }
}

class _ScopePill extends StatelessWidget {
  const _ScopePill({required this.scope, required this.kind});
  final NoteScope scope;
  final NoteKind kind;

  @override
  Widget build(BuildContext context) {
    final isTeam = scope == NoteScope.teamBroadcast;
    final label = switch (scope) {
      NoteScope.personal => kind == NoteKind.audio ? 'Личная · голос' : 'Личная',
      NoteScope.forMe => 'Адресная',
      NoteScope.stage => 'Этап',
      NoteScope.teamBroadcast =>
        kind == NoteKind.audio ? 'Команды · голос' : 'Команды',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isTeam ? AppColors.brandLight : AppColors.n100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: isTeam ? AppColors.brand : AppColors.n700,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

/// Лёгкий inline-плеер для аудио-заметки в списке. Не загружает поток до
/// первого тапа на «play», чтобы прокрутка не тянула presigned-аудио всех
/// заметок сразу.
class _AudioPlayerBar extends StatefulWidget {
  const _AudioPlayerBar({required this.url, required this.durationMs});

  final String? url;
  final int? durationMs;

  @override
  State<_AudioPlayerBar> createState() => _AudioPlayerBarState();
}

class _AudioPlayerBarState extends State<_AudioPlayerBar> {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _posSub;
  bool _loaded = false;
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration? _total;

  @override
  void initState() {
    super.initState();
    if (widget.durationMs != null) {
      _total = Duration(milliseconds: widget.durationMs!);
    }
    _stateSub = _player.playerStateStream.listen((s) {
      if (!mounted) return;
      setState(() {
        _playing =
            s.playing && s.processingState != ProcessingState.completed;
      });
    });
    _posSub = _player.positionStream.listen((d) {
      if (!mounted) return;
      setState(() => _position = d);
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _posSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    final url = widget.url;
    if (url == null) return;
    if (!_loaded) {
      try {
        final d = await _player.setUrl(url);
        _loaded = true;
        if (d != null && _total == null && mounted) {
          setState(() => _total = d);
        }
      } on Object {
        if (!mounted) return;
        AppToast.show(
          context,
          message: 'Не удалось загрузить аудио',
          kind: AppToastKind.error,
        );
        return;
      }
    }
    if (_playing) {
      await _player.pause();
    } else {
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }
      await _player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _total ?? Duration.zero;
    final progress = total.inMilliseconds == 0
        ? 0.0
        : (_position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
    final disabled = widget.url == null;
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.x8,
        horizontal: AppSpacing.x10,
      ),
      decoration: BoxDecoration(
        color: AppColors.brandLight,
        borderRadius: BorderRadius.circular(AppRadius.r12),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: disabled ? null : _toggle,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: disabled ? AppColors.n300 : AppColors.brand,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: AppColors.n0,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.x10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: AppColors.n0,
                color: AppColors.brand,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.x10),
          Text(
            _fmt(total),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.brand,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
