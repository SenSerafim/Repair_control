import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/access/access_guard.dart';
import '../../../core/access/domain_actions.dart';
import '../../../core/realtime/socket_service.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/application/auth_controller.dart';
import '../../profile/data/profile_repository.dart';
import '../application/chats_controller.dart';
import '../data/chats_repository.dart';
import '../domain/chat.dart';
import '../domain/message.dart';

class ChatConversationScreen extends ConsumerStatefulWidget {
  const ChatConversationScreen({required this.chatId, super.key});

  final String chatId;

  @override
  ConsumerState<ChatConversationScreen> createState() =>
      _ChatConversationScreenState();
}

class _ChatConversationScreenState
    extends ConsumerState<ChatConversationScreen> {
  final _input = TextEditingController();
  bool _sending = false;
  bool _isTyping = false;
  Timer? _typingDebounce;

  @override
  void initState() {
    super.initState();
    _input.addListener(_onInputChanged);
    // Регистрируем чат как «открытый» — FcmService при foreground push'е
    // подавит local-notification если chatId совпадает.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(currentChatIdProvider.notifier).state = widget.chatId;
      }
    });
  }

  @override
  void dispose() {
    _input
      ..removeListener(_onInputChanged)
      ..dispose();
    _typingDebounce?.cancel();
    if (_isTyping) {
      // Финальный «typing=false» при выходе из чата.
      ref
          .read(socketServiceProvider)
          .typing(widget.chatId, typing: false);
    }
    // Сбрасываем «открытый чат» если ещё мы.
    final container = ProviderScope.containerOf(context, listen: false);
    if (container.read(currentChatIdProvider) == widget.chatId) {
      container.read(currentChatIdProvider.notifier).state = null;
    }
    super.dispose();
  }

  void _onInputChanged() {
    final hasText = _input.text.trim().isNotEmpty;
    if (hasText && !_isTyping) {
      _isTyping = true;
      ref.read(socketServiceProvider).typing(widget.chatId, typing: true);
    }
    // Отправляем typing=false если 3 сек тишины (бэк сам отзовёт через 5 сек,
    // мы же — раньше, чтобы UI у других обновился быстрее).
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(seconds: 3), () {
      if (_isTyping) {
        _isTyping = false;
        ref
            .read(socketServiceProvider)
            .typing(widget.chatId, typing: false);
      }
    });
  }

  Future<void> _send({List<String>? attachmentKeys}) async {
    final text = _input.text.trim();
    if (text.isEmpty && (attachmentKeys == null || attachmentKeys.isEmpty)) {
      return;
    }
    if (_sending) return;
    setState(() => _sending = true);
    final failure = await ref
        .read(messagesProvider(widget.chatId).notifier)
        .send(text: text, attachmentKeys: attachmentKeys);
    if (!mounted) return;
    setState(() => _sending = false);
    if (failure == null) {
      _input.clear();
      // После успешной отправки — typing=false (если был активен).
      _typingDebounce?.cancel();
      if (_isTyping) {
        _isTyping = false;
        ref
            .read(socketServiceProvider)
            .typing(widget.chatId, typing: false);
      }
    } else {
      AppToast.show(
        context,
        message: failure.userMessage,
        kind: AppToastKind.error,
      );
    }
  }

  Future<void> _openAttach() async {
    final picked = await showAppBottomSheet<_AttachChoice>(
      context: context,
      child: _AttachSheet(
        onPick: (c) => Navigator.of(context).pop(c),
      ),
    );
    if (picked == null || !mounted) return;
    await _uploadAndSend(picked);
  }

  Future<void> _uploadAndSend(_AttachChoice choice) async {
    setState(() => _sending = true);
    try {
      final picker = ImagePicker();
      final x = choice == _AttachChoice.photo
          ? await picker.pickImage(
              source: ImageSource.gallery,
              imageQuality: 80,
              maxWidth: 1920,
            )
          : null;
      if (x == null) {
        if (mounted) setState(() => _sending = false);
        return;
      }
      final file = File(x.path);
      final size = await file.length();
      final name = x.name;
      final mime = _mimeFromName(name);
      final repo = ref.read(profileRepositoryProvider);
      final presigned = await repo.presignUpload(
        originalName: name,
        mimeType: mime,
        sizeBytes: size,
        scope: 'chat_attachment',
      );
      final bytes = await file.readAsBytes();
      final dio = Dio();
      await dio.put<void>(
        presigned.url,
        data: bytes,
        options: Options(
          headers: {...presigned.headers, 'Content-Type': mime},
        ),
      );
      await _send(attachmentKeys: [presigned.key]);
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          message: 'Не удалось загрузить вложение',
          kind: AppToastKind.error,
        );
        setState(() => _sending = false);
      }
    }
  }

  String _mimeFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    return 'application/octet-stream';
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(messagesProvider(widget.chatId));
    final chatAsync = ref.watch(_chatTitleProvider(widget.chatId));
    final me = ref.read(authControllerProvider).userId;

    return AppScaffold(
      showBack: true,
      title: chatAsync.maybeWhen(
        data: (title) => title,
        orElse: () => 'Чат',
      ),
      padding: EdgeInsets.zero,
      body: Column(
        children: [
          Expanded(
            child: async.when(
              loading: () => const AppLoadingState(),
              error: (e, _) => AppErrorState(
                title: 'Ошибка',
                onRetry: () =>
                    ref.invalidate(messagesProvider(widget.chatId)),
              ),
              data: (msgs) {
                if (msgs.isEmpty) {
                  return const AppEmptyState(
                    title: 'Сообщений ещё нет',
                    subtitle: 'Напишите первое — оно появится здесь.',
                    icon: Icons.chat_bubble_outline_rounded,
                  );
                }
                final canWrite =
                    ref.watch(canProvider(DomainAction.chatWrite));
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(AppSpacing.x12),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) => _Bubble(
                    message: msgs[i],
                    isMine: msgs[i].authorId == me,
                    onEdit: canWrite ? () => _promptEdit(msgs[i]) : null,
                    onDelete: canWrite
                        ? () => ref
                            .read(messagesProvider(widget.chatId).notifier)
                            .delete(msgs[i].id)
                        : null,
                    onForward: () => _openForwardSheet(msgs[i]),
                  ),
                );
              },
            ),
          ),
          _TypingBar(chatId: widget.chatId, meId: me),
          if (ref.watch(canProvider(DomainAction.chatWrite)))
            _ComposeBar(
              controller: _input,
              sending: _sending,
              onSend: _send,
              onAttach: _openAttach,
            ),
        ],
      ),
    );
  }

  Future<void> _promptEdit(Message m) async {
    final c = TextEditingController(text: m.text ?? '');
    await showAppBottomSheet<void>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppBottomSheetHeader(
            title: 'Редактировать',
            subtitle: 'Можно править 15 минут после отправки.',
          ),
          TextField(
            controller: c,
            maxLines: 5,
            minLines: 2,
            decoration: const InputDecoration(
              filled: true,
              fillColor: AppColors.n0,
            ),
          ),
          const SizedBox(height: AppSpacing.x16),
          Builder(
            builder: (ctx) => AppButton(
              label: 'Сохранить',
              onPressed: () async {
                await ref
                    .read(messagesProvider(widget.chatId).notifier)
                    .edit(messageId: m.id, text: c.text.trim());
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
            ),
          ),
        ],
      ),
    );
    c.dispose();
  }

  Future<void> _openForwardSheet(Message m) async {
    final chat = await ref.read(chatsRepositoryProvider).get(widget.chatId);
    final projectId = chat.projectId;
    if (projectId == null) {
      if (!mounted) return;
      AppToast.show(
        context,
        message: 'Пересылка доступна только для чатов проекта',
        kind: AppToastKind.info,
      );
      return;
    }
    final chats = await ref
        .read(chatsRepositoryProvider)
        .listProject(projectId);
    if (!mounted) return;
    final targets = chats.where((c) => c.id != widget.chatId).toList();
    await showAppBottomSheet<void>(
      context: context,
      child: _ForwardSheet(
        preview: m.text ?? (m.hasAttachments ? 'Вложение' : '—'),
        chats: targets,
        onPick: (toChatId) async {
          final f = await ref
              .read(messagesProvider(widget.chatId).notifier)
              .forward(messageId: m.id, toChatId: toChatId);
          if (!mounted) return;
          Navigator.of(context).pop();
          AppToast.show(
            context,
            message: f == null ? 'Переслано' : f.userMessage,
            kind: f == null ? AppToastKind.success : AppToastKind.error,
          );
        },
      ),
    );
  }
}

/// Lightweight-провайдер для заголовка чата в AppBar.
final _chatTitleProvider =
    FutureProvider.family.autoDispose<String, String>((ref, chatId) async {
  try {
    final c = await ref.read(chatsRepositoryProvider).get(chatId);
    return c.title ?? 'Чат';
  } on ChatsException {
    return 'Чат';
  }
});

enum _AttachChoice { photo, document }

class _AttachSheet extends StatelessWidget {
  const _AttachSheet({required this.onPick});

  final ValueChanged<_AttachChoice> onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppBottomSheetHeader(
          title: 'Прикрепить',
          subtitle: 'Выберите тип вложения',
        ),
        Row(
          children: [
            Expanded(
              child: _AttachTile(
                label: 'Фото',
                icon: Icons.image_outlined,
                bg: AppColors.brandLight,
                iconColor: AppColors.brand,
                onTap: () => onPick(_AttachChoice.photo),
              ),
            ),
            const SizedBox(width: AppSpacing.x12),
            Expanded(
              child: _AttachTile(
                label: 'Документ',
                icon: Icons.description_outlined,
                bg: AppColors.greenLight,
                iconColor: AppColors.greenDot,
                onTap: () => onPick(_AttachChoice.document),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AttachTile extends StatelessWidget {
  const _AttachTile({
    required this.label,
    required this.icon,
    required this.bg,
    required this.iconColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color bg;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.r16),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x12,
          vertical: AppSpacing.x16,
        ),
        decoration: BoxDecoration(
          color: AppColors.n50,
          border: Border.all(color: AppColors.n200),
          borderRadius: BorderRadius.circular(AppRadius.r16),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: AppSpacing.x8),
            Text(label, style: AppTextStyles.subtitle),
          ],
        ),
      ),
    );
  }
}

class _ForwardSheet extends StatelessWidget {
  const _ForwardSheet({
    required this.preview,
    required this.chats,
    required this.onPick,
  });

  final String preview;
  final List<Chat> chats;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppBottomSheetHeader(
          title: 'Переслать сообщение',
          subtitle: 'Выберите чат для пересылки',
        ),
        Container(
          padding: const EdgeInsets.all(AppSpacing.x12),
          decoration: BoxDecoration(
            color: AppColors.n50,
            border: Border.all(color: AppColors.n200),
            borderRadius: BorderRadius.circular(AppRadius.r12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Сообщение',
                style: AppTextStyles.tiny.copyWith(color: AppColors.n400),
              ),
              const SizedBox(height: 4),
              Text(
                preview,
                style: AppTextStyles.body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.x16),
        if (chats.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.x16),
            child: Text(
              'Нет других чатов в этом проекте',
              style: AppTextStyles.caption.copyWith(color: AppColors.n500),
              textAlign: TextAlign.center,
            ),
          )
        else
          ...chats.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.x6),
              child: InkWell(
                onTap: () => onPick(c.id),
                borderRadius: BorderRadius.circular(AppRadius.r12),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.x12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.n200, width: 1.5),
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: AppColors.brandLight,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          _iconFor(c.type),
                          size: 18,
                          color: AppColors.brand,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.x12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.title ?? c.type.displayName,
                              style: AppTextStyles.subtitle,
                            ),
                            Text(
                              c.type.displayName,
                              style: AppTextStyles.tiny
                                  .copyWith(color: AppColors.n500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  IconData _iconFor(ChatType t) => switch (t) {
        ChatType.project => Icons.home_outlined,
        ChatType.stage => Icons.layers_outlined,
        ChatType.personal => Icons.person_outline,
        ChatType.group => Icons.group_outlined,
      };
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.isMine,
    required this.onEdit,
    required this.onDelete,
    required this.onForward,
  });

  final Message message;
  final bool isMine;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback onForward;

  /// 15-мин окно редактирования (ТЗ §10.2): после истечения сервер вернёт
  /// CHAT_MESSAGE_EDIT_WINDOW_EXPIRED. На клиенте дублируем UX-гейтом.
  bool get _editWindowOpen =>
      message.canEdit(byUserId: message.authorId, now: DateTime.now());

  @override
  Widget build(BuildContext context) {
    final bgColor = isMine ? AppColors.brand : AppColors.n100;
    final txtColor = isMine ? AppColors.n0 : AppColors.n800;
    final body = message.isDeleted
        ? 'Сообщение удалено'
        : (message.text ?? (message.hasAttachments ? 'Вложение' : ''));
    final bubble = GestureDetector(
      onLongPress: message.isDeleted ? null : () => _showActions(context),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        margin: const EdgeInsets.only(bottom: AppSpacing.x6),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x12,
          vertical: AppSpacing.x8,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          // Дизайн `Кластер F`: outgoing — острый угол снизу-справа,
          // incoming — острый угол снизу-слева (классический «хвостик»).
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadius.r16),
            topRight: const Radius.circular(AppRadius.r16),
            bottomLeft: Radius.circular(isMine ? AppRadius.r16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : AppRadius.r16),
          ),
        ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.isForwarded)
                Text(
                  'Переслано',
                  style: AppTextStyles.tiny.copyWith(
                    color: txtColor.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              if (message.hasAttachments && !message.isDeleted)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.attach_file_rounded,
                        size: 14,
                        color: txtColor.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${message.attachmentKeys.length} вложение(й)',
                        style: AppTextStyles.tiny.copyWith(color: txtColor),
                      ),
                    ],
                  ),
                ),
              if (body.isNotEmpty)
                Text(
                  body,
                  style: AppTextStyles.body.copyWith(
                    color: txtColor,
                    fontStyle: message.isDeleted
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('HH:mm', 'ru').format(message.createdAt),
                    style: AppTextStyles.tiny.copyWith(
                      color: txtColor.withValues(alpha: 0.6),
                    ),
                  ),
                  if (message.isEdited) ...[
                    const SizedBox(width: 4),
                    Text(
                      'изм.',
                      style: AppTextStyles.tiny.copyWith(
                        color: txtColor.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
      ),
    );
    // Incoming сообщения: avatar отправителя (32×32) слева — по дизайну
    // `Кластер F` chat-conversation. Outgoing: bubble прижат вправо без
    // аватара (свои сообщения не нуждаются в идентификации).
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            AppAvatar(
              seed: message.authorId,
              size: 32,
            ),
            const SizedBox(width: AppSpacing.x6),
          ],
          Flexible(child: bubble),
        ],
      ),
    );
  }

  void _showActions(BuildContext context) {
    showAppBottomSheet<void>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppBottomSheetHeader(title: 'Действия'),
          ListTile(
            leading: const Icon(Icons.reply_all_rounded),
            title: const Text('Переслать'),
            onTap: () {
              Navigator.of(context).pop();
              onForward();
            },
          ),
          if (isMine) ...[
            if (onEdit != null)
              ListTile(
                enabled: _editWindowOpen,
                leading: Icon(
                  Icons.edit_outlined,
                  color: _editWindowOpen ? null : AppColors.n400,
                ),
                title: Text(
                  _editWindowOpen
                      ? 'Редактировать'
                      : 'Редактирование недоступно — окно истекло',
                  style: TextStyle(
                    color: _editWindowOpen ? null : AppColors.n500,
                  ),
                ),
                onTap: _editWindowOpen
                    ? () {
                        Navigator.of(context).pop();
                        onEdit!();
                      }
                    : null,
              ),
            if (onDelete != null)
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: AppColors.redDot),
                title: const Text(
                  'Удалить',
                  style: TextStyle(color: AppColors.redDot),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  onDelete!();
                },
              ),
          ],
        ],
      ),
    );
  }
}

class _ComposeBar extends StatelessWidget {
  const _ComposeBar({
    required this.controller,
    required this.sending,
    required this.onSend,
    required this.onAttach,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onAttach;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x12,
          AppSpacing.x8,
          AppSpacing.x12,
          AppSpacing.x12,
        ),
        decoration: const BoxDecoration(
          color: AppColors.n0,
          border: Border(top: BorderSide(color: AppColors.n200)),
        ),
        child: Row(
          children: [
            InkResponse(
              onTap: sending ? null : onAttach,
              radius: 22,
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.n100,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.add_rounded,
                  size: 20,
                  color: AppColors.n500,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.x8),
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Сообщение…',
                  hintStyle:
                      AppTextStyles.body.copyWith(color: AppColors.n400),
                  filled: true,
                  fillColor: AppColors.n100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.x8),
            AppAnimatedSendButton(
              onTap: sending ? null : onSend,
              sending: sending,
            ),
          ],
        ),
      ),
    );
  }
}

/// Узкая полоска «X печатает…» над `_ComposeBar`. Слушает
/// `typingUsersProvider(chatId)` — он наполняется в MessagesController
/// из WS-события `presence:typing` и сбрасывается через 5s бездействия.
class _TypingBar extends ConsumerWidget {
  const _TypingBar({required this.chatId, required this.meId});

  final String chatId;
  final String? meId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typing = ref.watch(typingUsersProvider(chatId));
    final others = typing.where((u) => u != meId).toList();
    if (others.isEmpty) return const SizedBox.shrink();
    final label = others.length == 1
        ? 'Печатает…'
        : '${others.length} участника печатают…';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x16,
        vertical: 6,
      ),
      color: AppColors.n50,
      child: Row(
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 1.5),
          ),
          const SizedBox(width: AppSpacing.x8),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.n500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
