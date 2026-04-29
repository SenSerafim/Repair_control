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
import 'chat_attachment_preview_screen.dart';

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
      ref
          .read(socketServiceProvider)
          .typing(widget.chatId, typing: false);
    }
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

  Future<void> _send({String? overrideText, List<String>? attachmentKeys}) async {
    final text = (overrideText ?? _input.text).trim();
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
      if (overrideText == null) _input.clear();
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
    if (picked == _AttachChoice.photo) {
      await _photoFlow();
    } else {
      await _documentFlow();
    }
  }

  Future<void> _photoFlow() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1920,
    );
    if (x == null || !mounted) return;
    final result = await Navigator.of(context).push<ChatAttachmentResult>(
      MaterialPageRoute(
        builder: (_) => ChatAttachmentPreviewScreen(file: File(x.path)),
      ),
    );
    if (result == null || !mounted) return;
    await _uploadAndSend(
      file: File(x.path),
      filename: x.name,
      caption: result.caption,
    );
  }

  Future<void> _documentFlow() async {
    final picker = ImagePicker();
    final x = await picker.pickMedia(imageQuality: 80, maxWidth: 1920);
    if (x == null || !mounted) return;
    await _uploadAndSend(file: File(x.path), filename: x.name);
  }

  Future<void> _uploadAndSend({
    required File file,
    required String filename,
    String? caption,
  }) async {
    setState(() => _sending = true);
    try {
      final size = await file.length();
      final mime = _mimeFromName(filename);
      final repo = ref.read(profileRepositoryProvider);
      final presigned = await repo.presignUpload(
        originalName: filename,
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
      await _send(
        overrideText: caption,
        attachmentKeys: [presigned.key],
      );
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
                final isGroupChat = chatAsync.asData != null &&
                    _isGroupChatTitle(chatAsync.asData!.value);
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) {
                    final msg = msgs[i];
                    final prev = i + 1 < msgs.length ? msgs[i + 1] : null;
                    final showDateSeparator = prev == null ||
                        !_sameDay(prev.createdAt, msg.createdAt);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showDateSeparator)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child: Text(
                                _formatDateSeparator(msg.createdAt),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.n400,
                                ),
                              ),
                            ),
                          ),
                        _Bubble(
                          message: msg,
                          isMine: msg.authorId == me,
                          showSenderLabel: isGroupChat && msg.authorId != me,
                          showForwardAction:
                              isGroupChat && !msg.isDeleted,
                          onEdit: canWrite ? () => _promptEdit(msg) : null,
                          onDelete: canWrite
                              ? () => ref
                                  .read(messagesProvider(widget.chatId)
                                      .notifier)
                                  .delete(msg.id)
                              : null,
                          onForward: () => _openForwardSheet(msg),
                        ),
                      ],
                    );
                  },
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

  bool _isGroupChatTitle(String title) {
    // Heuristic: project/stage chats typically have non-personal titles.
    // Точная инфа в Chat.type, но через заголовок достаточно для отображения
    // sender-label и forward-action.
    return title.toLowerCase().contains('чат') ||
        title.toLowerCase().contains('проект') ||
        title.toLowerCase().contains('этап');
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDateSeparator(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tDate = DateTime(t.year, t.month, t.day);
    final diff = today.difference(tDate).inDays;
    if (diff == 0) return 'Сегодня';
    if (diff == 1) return 'Вчера';
    return DateFormat('d MMMM y', 'ru').format(t);
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
              fillColor: AppColors.n50,
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
        const Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: Text(
            'Прикрепить',
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
            'Выберите тип вложения',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.n400,
            ),
          ),
        ),
        AppOptionRow(
          icon: Icons.image_outlined,
          iconBg: AppColors.brandLight,
          iconFg: AppColors.brand,
          title: 'Фото',
          subtitle: 'Из галереи или камеры',
          onTap: () => onPick(_AttachChoice.photo),
        ),
        const SizedBox(height: 10),
        AppOptionRow(
          icon: Icons.description_outlined,
          iconBg: AppColors.greenLight,
          iconFg: AppColors.greenDark,
          title: 'Документ',
          subtitle: 'PDF, DOCX, изображение',
          onTap: () => onPick(_AttachChoice.document),
        ),
      ],
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
        const Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: Text(
            'Переслать сообщение',
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
            'Выберите чат для пересылки',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.n400,
            ),
          ),
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
              const Text(
                'Сообщение',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.n400,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                preview,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.n700,
                  height: 1.4,
                ),
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
              padding: const EdgeInsets.only(bottom: 10),
              child: AppOptionRow(
                icon: _iconFor(c.type),
                iconBg: _bgFor(c.type),
                iconFg: _fgFor(c.type),
                title: c.title ?? c.type.displayName,
                subtitle: '${c.type.displayName} · ${c.participants.length} участников',
                onTap: () => onPick(c.id),
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

  Color _bgFor(ChatType t) => switch (t) {
        ChatType.project => AppColors.brandLight,
        ChatType.stage => AppColors.yellowBg,
        ChatType.personal => AppColors.greenLight,
        ChatType.group => AppColors.purpleBg,
      };

  Color _fgFor(ChatType t) => switch (t) {
        ChatType.project => AppColors.brand,
        ChatType.stage => AppColors.yellowText,
        ChatType.personal => AppColors.greenDark,
        ChatType.group => AppColors.purple,
      };
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.isMine,
    required this.showSenderLabel,
    required this.showForwardAction,
    required this.onEdit,
    required this.onDelete,
    required this.onForward,
  });

  final Message message;
  final bool isMine;
  final bool showSenderLabel;
  final bool showForwardAction;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback onForward;

  bool get _editWindowOpen =>
      message.canEdit(byUserId: message.authorId, now: DateTime.now());

  @override
  Widget build(BuildContext context) {
    final body = message.isDeleted
        ? 'Сообщение удалено'
        : (message.text ??
            (message.hasAttachments ? 'Вложение' : ''));
    final time = DateFormat('HH:mm', 'ru').format(message.createdAt);
    final senderColor = _seedColor(message.authorId);

    final bubbleAndAvatar = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isMine) ...[
          AppAvatar(
            seed: message.authorId,
            size: 32,
          ),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: AppMessageBubble(
            text: body.isEmpty ? '—' : body,
            isMine: isMine,
            italic: message.isDeleted,
            dimmed: message.isDeleted,
            senderLabel:
                showSenderLabel ? _displaySenderName(message.authorId) : null,
            senderColor: senderColor,
            time: time,
            editedMark: message.isEdited && !message.isDeleted,
            forwardedLabel: message.isForwarded ? 'Переслано' : null,
            onLongPress:
                message.isDeleted ? null : () => _showActions(context),
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Align(
            alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
            child: bubbleAndAvatar,
          ),
          if (showForwardAction)
            Padding(
              padding: EdgeInsets.only(left: isMine ? 0 : 38),
              child: AppMessageActions(
                onForward: onForward,
                alignToRight: isMine,
              ),
            ),
        ],
      ),
    );
  }

  /// Стабильный цвет имени отправителя из brand/green/purple/orange/red.
  Color _seedColor(String userId) {
    const palette = [
      AppColors.brand,
      AppColors.greenDark,
      AppColors.purple,
      Color(0xFFD97706),
      AppColors.redDot,
    ];
    return palette[userId.hashCode.abs() % palette.length];
  }

  String _displaySenderName(String userId) {
    if (userId.length <= 6) return userId;
    return '${userId.substring(0, 6)}…';
  }

  void _showActions(BuildContext context) {
    showAppBottomSheet<void>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Действия',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.n900,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.reply_all_rounded, color: AppColors.brand),
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
                  color: _editWindowOpen ? AppColors.brand : AppColors.n400,
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
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppColors.redDot,
                ),
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
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: const BoxDecoration(
          color: AppColors.n0,
          border: Border(top: BorderSide(color: AppColors.n200)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
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
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 40),
                decoration: BoxDecoration(
                  color: AppColors.n50,
                  border: Border.all(color: AppColors.n200, width: 1.5),
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.n900,
                  ),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    hintText: 'Сообщение…',
                    hintStyle: AppTextStyles.body.copyWith(
                      color: AppColors.n400,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _SendButton(
              sending: sending,
              onTap: sending ? null : onSend,
            ),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.sending, required this.onTap});

  final bool sending;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: AppGradients.brandButton,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.shBlue,
        ),
        alignment: Alignment.center,
        child: sending
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.n0),
                ),
              )
            : const Icon(
                Icons.send_rounded,
                color: AppColors.n0,
                size: 18,
              ),
      ),
    );
  }
}

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: AppColors.n50,
      child: Row(
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 1.5),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.n400,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
