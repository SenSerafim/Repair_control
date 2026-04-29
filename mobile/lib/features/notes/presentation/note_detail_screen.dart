import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
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
    return AppScaffold(
      showBack: true,
      title: 'Заметка',
      actions: [
        async.maybeWhen(
          data: (notes) {
            final note = notes.firstWhere(
              (n) => n.id == noteId,
              orElse: () => notes.isNotEmpty
                  ? notes.first
                  : Note(
                      id: noteId,
                      scope: NoteScope.personal,
                      authorId: '',
                      text: '',
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    ),
            );
            return IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Удалить',
              onPressed: () => _confirmDelete(context, ref, note),
            );
          },
          orElse: SizedBox.shrink,
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
      AppToast.show(
        context,
        message: 'Удалено',
        kind: AppToastKind.success,
      );
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
        return AppRoleBadgeTone.representative;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lines = note.text.split('\n');
    final title = lines.first.trim();
    final body = lines.length > 1 ? lines.sublist(1).join('\n').trim() : '';
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            AppRoleBadge(label: note.scope.displayName, tone: _badgeTone),
            const SizedBox(width: 8),
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
      ],
    );
  }
}
