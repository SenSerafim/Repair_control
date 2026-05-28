import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:record/record.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/notes_controller.dart';
import '../data/notes_repository.dart';
import '../domain/note.dart';

/// NEWFIX-2 §11 — Быстрая заметка. Вызывается с иконки «Заметка» в шапке
/// ConsoleScreen. Два режима: Текст / Голос. Видимость: Личная / Команды
/// (= NoteScope.personal / NoteScope.teamBroadcast).
///
/// MVP (вариант A): голосовые заметки — только аудио. Поля transcript* в
/// модели заложены под вариант B (фоновый STT) и пока остаются null.
Future<bool?> showQuickNoteSheet({
  required BuildContext context,
  required String projectId,
}) {
  return showAppBottomSheet<bool>(
    context: context,
    child: _QuickNoteSheet(projectId: projectId),
  );
}

enum _Mode { text, voice }

class _QuickNoteSheet extends ConsumerStatefulWidget {
  const _QuickNoteSheet({required this.projectId});

  final String projectId;

  @override
  ConsumerState<_QuickNoteSheet> createState() => _QuickNoteSheetState();
}

class _QuickNoteSheetState extends ConsumerState<_QuickNoteSheet> {
  final TextEditingController _text = TextEditingController();
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  Timer? _ticker;
  StreamSubscription<RecordState>? _recSub;

  _Mode _mode = _Mode.text;
  NoteScope _visibility = NoteScope.personal;

  bool _isRecording = false;
  Duration _recordedFor = Duration.zero;
  String? _recordedPath;
  Duration? _recordedDuration;

  @override
  void dispose() {
    _ticker?.cancel();
    _recSub?.cancel();
    unawaited(_recorder.stop());
    unawaited(_recorder.dispose());
    unawaited(_player.dispose());
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppBottomSheetHeader(title: 'Новая заметка'),
          const SizedBox(height: AppSpacing.x14),
          _ModeSwitcher(
            mode: _mode,
            hasRecording: _recordedPath != null,
            onChanged: _isRecording ? null : (m) => setState(() => _mode = m),
          ),
          const SizedBox(height: AppSpacing.x16),
          if (_mode == _Mode.text) _TextField(controller: _text),
          if (_mode == _Mode.voice)
            _VoiceRecorder(
              isRecording: _isRecording,
              recordedFor: _recordedFor,
              recordedPath: _recordedPath,
              recordedDuration: _recordedDuration,
              player: _player,
              onStart: _startRecording,
              onStop: _stopRecording,
              onDiscard: _discardRecording,
            ),
          const SizedBox(height: AppSpacing.x20),
          _VisibilityChooser(
            selected: _visibility,
            onChanged: (v) => setState(() => _visibility = v),
          ),
          const SizedBox(height: AppSpacing.x20),
          AppButton(
            label: 'Сохранить',
            onPressed: _canSave ? _save : null,
          ),
          const SizedBox(height: AppSpacing.x8),
          TextButton(
            onPressed: () {
              final router = GoRouter.of(context);
              Navigator.of(context).pop();
              router.push('/projects/${widget.projectId}/notes');
            },
            child: const Text('Все заметки проекта'),
          ),
        ],
      ),
    );
  }

  bool get _canSave {
    if (_isRecording) return false;
    if (_mode == _Mode.text) return _text.text.trim().isNotEmpty;
    return _recordedPath != null;
  }

  Future<void> _startRecording() async {
    final hasPerm = await _recorder.hasPermission();
    if (!hasPerm) {
      if (!mounted) return;
      AppToast.show(
        context,
        message: 'Нужен доступ к микрофону',
        kind: AppToastKind.error,
      );
      return;
    }
    final dir = await getTemporaryDirectory();
    final path = p.join(
      dir.path,
      'note_${DateTime.now().millisecondsSinceEpoch}.m4a',
    );
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, sampleRate: 44100),
      path: path,
    );
    if (!mounted) return;
    setState(() {
      _isRecording = true;
      _recordedFor = Duration.zero;
      _recordedPath = null;
      _recordedDuration = null;
    });
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      setState(() => _recordedFor += const Duration(milliseconds: 200));
    });
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    _ticker?.cancel();
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _recordedPath = path;
      _recordedDuration = _recordedFor;
    });
  }

  Future<void> _discardRecording() async {
    final path = _recordedPath;
    if (path != null) {
      final f = File(path);
      if (await f.exists()) {
        try {
          await f.delete();
        } on Object {
          // best-effort cleanup
        }
      }
    }
    await _player.stop();
    if (!mounted) return;
    setState(() {
      _recordedPath = null;
      _recordedDuration = null;
      _recordedFor = Duration.zero;
    });
  }

  Future<void> _save() async {
    final controller = ref.read(notesControllerProvider(widget.projectId).notifier);
    if (_mode == _Mode.text) {
      final failure = await controller.create(
        scope: _visibility,
        kind: NoteKind.text,
        text: _text.text.trim(),
      );
      if (!mounted) return;
      if (failure != null) {
        AppToast.show(context, message: failure.userMessage, kind: AppToastKind.error);
        return;
      }
      Navigator.of(context).pop(true);
      return;
    }
    final path = _recordedPath;
    if (path == null) return;
    try {
      final repo = ref.read(notesRepositoryProvider);
      final uploaded = await repo.uploadAudio(
        file: File(path),
        mimeType: 'audio/mp4',
      );
      final failure = await controller.create(
        scope: _visibility,
        kind: NoteKind.audio,
        text: _text.text.trim().isEmpty ? null : _text.text.trim(),
        audioKey: uploaded.audioKey,
        audioMimeType: uploaded.mimeType,
        audioDurationMs: _recordedDuration?.inMilliseconds,
      );
      if (!mounted) return;
      if (failure != null) {
        AppToast.show(context, message: failure.userMessage, kind: AppToastKind.error);
        return;
      }
      Navigator.of(context).pop(true);
    } on NotesException catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        message: e.failure.userMessage,
        kind: AppToastKind.error,
      );
    }
  }
}

class _ModeSwitcher extends StatelessWidget {
  const _ModeSwitcher({
    required this.mode,
    required this.hasRecording,
    required this.onChanged,
  });

  final _Mode mode;
  final bool hasRecording;
  final ValueChanged<_Mode>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _modeChip(
            label: 'Текст',
            icon: PhosphorIconsRegular.notepad,
            active: mode == _Mode.text,
            onTap: onChanged == null ? null : () => onChanged!(_Mode.text),
          ),
        ),
        const SizedBox(width: AppSpacing.x10),
        Expanded(
          child: _modeChip(
            label: hasRecording ? 'Голос (готово)' : 'Голос',
            icon: PhosphorIconsRegular.microphone,
            active: mode == _Mode.voice,
            onTap: onChanged == null ? null : () => onChanged!(_Mode.voice),
          ),
        ),
      ],
    );
  }

  Widget _modeChip({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback? onTap,
  }) {
    final bg = active ? AppColors.brandLight : AppColors.n50;
    final fg = active ? AppColors.brand : AppColors.n700;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.r12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.x12,
            horizontal: AppSpacing.x12,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.r12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.body.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      maxLines: 6,
      maxLength: 5000,
      decoration: InputDecoration(
        hintText: 'Записать заметку…',
        filled: true,
        fillColor: AppColors.n50,
        contentPadding: const EdgeInsets.all(AppSpacing.x14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.r12),
          borderSide: BorderSide.none,
        ),
        counterText: '',
      ),
      style: AppTextStyles.body,
    );
  }
}

class _VoiceRecorder extends StatelessWidget {
  const _VoiceRecorder({
    required this.isRecording,
    required this.recordedFor,
    required this.recordedPath,
    required this.recordedDuration,
    required this.player,
    required this.onStart,
    required this.onStop,
    required this.onDiscard,
  });

  final bool isRecording;
  final Duration recordedFor;
  final String? recordedPath;
  final Duration? recordedDuration;
  final AudioPlayer player;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x16),
      decoration: BoxDecoration(
        color: AppColors.n50,
        borderRadius: BorderRadius.circular(AppRadius.r12),
      ),
      child: Column(
        children: [
          if (recordedPath == null) ...[
            Text(
              isRecording ? 'Запись… ${_fmt(recordedFor)}' : 'Готов к записи',
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.x14),
            _RecordButton(
              isRecording: isRecording,
              onTap: isRecording ? onStop : onStart,
            ),
          ] else ...[
            Row(
              children: [
                _PlayButton(player: player, path: recordedPath!),
                const SizedBox(width: AppSpacing.x12),
                Expanded(
                  child: Text(
                    'Запись · ${_fmt(recordedDuration ?? Duration.zero)}',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    PhosphorIconsRegular.trash,
                    color: AppColors.redText,
                  ),
                  onPressed: onDiscard,
                  tooltip: 'Удалить запись',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _RecordButton extends StatelessWidget {
  const _RecordButton({required this.isRecording, required this.onTap});
  final bool isRecording;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: isRecording ? AppColors.redText : AppColors.brand,
          shape: BoxShape.circle,
          boxShadow: AppShadows.sh1,
        ),
        child: Icon(
          isRecording ? Icons.stop_rounded : Icons.mic_rounded,
          color: AppColors.n0,
          size: 32,
        ),
      ),
    );
  }
}

class _PlayButton extends StatefulWidget {
  const _PlayButton({required this.player, required this.path});
  final AudioPlayer player;
  final String path;

  @override
  State<_PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<_PlayButton> {
  StreamSubscription<PlayerState>? _sub;
  bool _playing = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _sub = widget.player.playerStateStream.listen((s) {
      if (!mounted) return;
      setState(() => _playing = s.playing && s.processingState != ProcessingState.completed);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (!_loaded) {
      await widget.player.setFilePath(widget.path);
      _loaded = true;
    }
    if (_playing) {
      await widget.player.pause();
    } else {
      if (widget.player.processingState == ProcessingState.completed) {
        await widget.player.seek(Duration.zero);
      }
      await widget.player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: AppColors.brand,
          shape: BoxShape.circle,
        ),
        child: Icon(
          _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: AppColors.n0,
          size: 24,
        ),
      ),
    );
  }
}

class _VisibilityChooser extends StatelessWidget {
  const _VisibilityChooser({required this.selected, required this.onChanged});

  final NoteScope selected;
  final ValueChanged<NoteScope> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _option(
            label: 'Личная',
            scope: NoteScope.personal,
            active: selected == NoteScope.personal,
          ),
        ),
        const SizedBox(width: AppSpacing.x10),
        Expanded(
          child: _option(
            label: 'Общая для команды',
            scope: NoteScope.teamBroadcast,
            active: selected == NoteScope.teamBroadcast,
          ),
        ),
      ],
    );
  }

  Widget _option({
    required String label,
    required NoteScope scope,
    required bool active,
  }) {
    final bg = active ? AppColors.brandLight : AppColors.n50;
    final fg = active ? AppColors.brand : AppColors.n700;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(scope),
        borderRadius: BorderRadius.circular(AppRadius.r12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.x12,
            horizontal: AppSpacing.x12,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.r12),
          ),
          child: Row(
            children: [
              Icon(
                active ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 18,
                color: fg,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.body.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
