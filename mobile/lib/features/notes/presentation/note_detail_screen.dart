import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/application/auth_controller.dart';
import '../application/notes_controller.dart';
import '../domain/note.dart';

/// `f-note-detail` (`Кластер F`).
class NoteDetailScreen extends ConsumerWidget {
  const NoteDetailScreen({
    required this.projectId,
    required this.noteId,
    super.key,
  });

  final String projectId;
  final String noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notesControllerProvider(projectId));
    final currentUserId = ref.watch(authControllerProvider).userId;
    return AppScaffold(
      showBack: true,
      title: 'Заметка',
      // Author-only edit/delete. Backend проверяет authorId; UI прячет действия,
      // которые иначе вернут 403 (B4).
      actions: [
        async.maybeWhen(
          data: (notes) {
            final note = notes.where((n) => n.id == noteId).firstOrNull;
            if (note == null) return const SizedBox.shrink();
            final isAuthor =
                currentUserId != null && note.authorId == currentUserId;
            if (!isAuthor) return const SizedBox.shrink();
            return Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Редактировать',
                  onPressed: () => _showEditSheet(context, ref, note),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: 'Удалить',
                  onPressed: () => _confirmDelete(context, ref, note),
                ),
              ],
            );
          },
          orElse: () => const SizedBox.shrink(),
        ),
      ],
      body: async.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить',
          onRetry: () => ref.invalidate(notesControllerProvider(projectId)),
        ),
        data: (notes) {
          final note = notes.where((n) => n.id == noteId).firstOrNull;
          if (note == null) {
            return const AppEmptyState(
              title: 'Заметка не найдена',
              icon: Icons.help_outline_rounded,
            );
          }
          return _Content(note: note);
        },
      ),
    );
  }

  Future<void> _showEditSheet(
    BuildContext context,
    WidgetRef ref,
    Note note,
  ) async {
    await showAppBottomSheet<void>(
      context: context,
      child: _EditNoteBody(projectId: projectId, note: note),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Note note,
  ) async {
    final ok = await showAppBottomSheet<bool>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Text(
              'Удалить заметку?',
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
              'Действие нельзя отменить',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.n400,
              ),
            ),
          ),
          AppButton(
            label: 'Удалить',
            variant: AppButtonVariant.destructive,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: 8),
          AppButton(
            label: 'Отмена',
            variant: AppButtonVariant.secondary,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final failure = await ref
        .read(notesControllerProvider(projectId).notifier)
        .delete(note.id);
    if (!context.mounted) return;
    if (failure == null) {
      Navigator.of(context).pop();
      AppToast.show(context, message: 'Удалено', kind: AppToastKind.success);
    } else {
      AppToast.show(
        context,
        message: failure.userMessage,
        kind: AppToastKind.error,
      );
    }
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.note});

  final Note note;

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
    final text = note.text ?? '';
    final lines = text.split('\n');
    final title = lines.first.trim();
    final body = lines.length > 1 ? lines.sublist(1).join('\n').trim() : '';
    final hasText = text.isNotEmpty;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            AppRoleBadge(label: note.scope.displayName, tone: _badgeTone),
            const SizedBox(width: 8),
            if (note.kind == NoteKind.audio) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.brandLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Голос',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              DateFormat('d MMMM · HH:mm', 'ru').format(note.createdAt),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.n400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (note.kind == NoteKind.audio) ...[
          _NoteDetailAudioPlayer(
            url: note.audioUrl,
            durationMs: note.audioDurationMs,
          ),
          const SizedBox(height: 18),
        ],
        if (hasText)
          Text(
            title.isEmpty ? 'Заметка' : title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.n900,
              height: 1.3,
              letterSpacing: -0.4,
            ),
          ),
        if (body.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.n700,
              height: 1.75,
            ),
          ),
        ],
        if (!hasText && note.kind == NoteKind.audio)
          Text(
            'Голосовая заметка без подписи',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.n400,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }
}

/// Плеер с прогресс-баром для детального экрана. В будущем (вариант B) сюда
/// добавится transcript-блок ниже плеера.
class _NoteDetailAudioPlayer extends StatefulWidget {
  const _NoteDetailAudioPlayer({required this.url, required this.durationMs});
  final String? url;
  final int? durationMs;

  @override
  State<_NoteDetailAudioPlayer> createState() => _NoteDetailAudioPlayerState();
}

class _NoteDetailAudioPlayerState extends State<_NoteDetailAudioPlayer> {
  final _player = AudioPlayer();
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
    _player.playerStateStream.listen((s) {
      if (!mounted) return;
      setState(() {
        _playing = s.playing && s.processingState != ProcessingState.completed;
      });
    });
    _player.positionStream.listen((d) {
      if (!mounted) return;
      setState(() => _position = d);
    });
  }

  @override
  void dispose() {
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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: AppColors.brandLight,
        borderRadius: BorderRadius.circular(AppRadius.r12),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _toggle,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.brand,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: AppColors.n0,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.x14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: AppColors.n0,
                    color: AppColors.brand,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_fmt(_position)} / ${_fmt(total)}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
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

/// Bottom-sheet для PATCH /notes/:noteId — доступно только автору заметки (B3).
class _EditNoteBody extends ConsumerStatefulWidget {
  const _EditNoteBody({required this.projectId, required this.note});

  final String projectId;
  final Note note;

  @override
  ConsumerState<_EditNoteBody> createState() => _EditNoteBodyState();
}

class _EditNoteBodyState extends ConsumerState<_EditNoteBody> {
  late final TextEditingController _text = TextEditingController(
    text: widget.note.text ?? '',
  );
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final value = _text.text.trim();
    if (value.isEmpty && widget.note.kind == NoteKind.text) {
      setState(() => _error = 'Введите текст');
      return;
    }
    if (value == (widget.note.text ?? '')) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final failure = await ref
        .read(notesControllerProvider(widget.projectId).notifier)
        .updateText(noteId: widget.note.id, text: value);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (failure == null) {
      Navigator.of(context).pop();
      AppToast.show(context, message: 'Сохранено', kind: AppToastKind.success);
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
          padding: EdgeInsets.only(bottom: 16),
          child: Text(
            'Редактировать заметку',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.n900,
            ),
          ),
        ),
        if (_error != null) ...[
          AppInlineError(message: _error!),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _text,
          minLines: 4,
          maxLines: 8,
          maxLength: 5000,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Текст заметки',
            hintStyle: AppTextStyles.body.copyWith(color: AppColors.n500),
            filled: true,
            fillColor: AppColors.n50,
            contentPadding: const EdgeInsets.all(14),
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
