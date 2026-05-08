import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/access/access_guard.dart';
import '../../../core/access/domain_actions.dart';
import '../../../core/realtime/socket_service.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/application/auth_controller.dart';
import '../../onboarding/presentation/widgets/tour_anchor.dart';
import '../../team/application/team_controller.dart';
import '../../team/data/team_repository.dart';
import '../application/chats_controller.dart';
import '../data/chats_repository.dart';
import '../domain/message.dart';

/// Telegram-стиль чат проекта (П1.5).
/// П1.1 — кнопки attach (фото/файлы) удалены.
/// П1.2 — пункт «Переслать» в long-press menu удалён.
/// П1.3 — push идёт всем участникам (поведение на бекенде, см. notifications.service).
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
  ProviderContainer? _containerCache;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _containerCache = ProviderScope.containerOf(context, listen: false);
  }

  @override
  void dispose() {
    _input
      ..removeListener(_onInputChanged)
      ..dispose();
    _typingDebounce?.cancel();
    if (_isTyping) {
      ref.read(socketServiceProvider).typing(widget.chatId, typing: false);
    }
    final container = _containerCache;
    final chatId = widget.chatId;
    if (container != null) {
      Future.microtask(() {
        if (container.read(currentChatIdProvider) == chatId) {
          container.read(currentChatIdProvider.notifier).state = null;
        }
      });
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
        ref.read(socketServiceProvider).typing(widget.chatId, typing: false);
      }
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    if (_sending) return;
    setState(() => _sending = true);
    final failure = await ref
        .read(messagesProvider(widget.chatId).notifier)
        .send(text: text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (failure == null) {
      _input.clear();
      _typingDebounce?.cancel();
      if (_isTyping) {
        _isTyping = false;
        ref.read(socketServiceProvider).typing(widget.chatId, typing: false);
      }
    } else {
      AppToast.show(
        context,
        message: failure.userMessage,
        kind: AppToastKind.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(messagesProvider(widget.chatId));
    final chatAsync = ref.watch(_chatTitleProvider(widget.chatId));
    final me = ref.read(authControllerProvider).userId;

    return AppScaffold(
      showBack: true,
      title: chatAsync.maybeWhen(data: (title) => title, orElse: () => 'Чат'),
      padding: EdgeInsets.zero,
      body: Column(
        children: [
          Expanded(
            child: async.when(
              loading: () => const AppLoadingState(),
              error: (e, _) => AppErrorState(
                title: 'Ошибка',
                onRetry: () => ref.invalidate(messagesProvider(widget.chatId)),
              ),
              data: (msgs) {
                if (msgs.isEmpty) {
                  return const AppEmptyState(
                    title: 'Сообщений ещё нет',
                    subtitle: 'Напишите первое — оно появится здесь.',
                    icon: Icons.chat_bubble_outline_rounded,
                  );
                }
                final canWrite = ref.watch(canProvider(DomainAction.chatWrite));
                final isGroupChat =
                    chatAsync.asData != null &&
                    _isGroupChatTitle(chatAsync.asData!.value);
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) {
                    final msg = msgs[i];
                    final prev = i + 1 < msgs.length ? msgs[i + 1] : null;
                    final showDateSeparator =
                        prev == null ||
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
                          onEdit: canWrite ? () => _promptEdit(msg) : null,
                          onDelete: canWrite
                              ? () => ref
                                    .read(
                                      messagesProvider(widget.chatId).notifier,
                                    )
                                    .delete(msg.id)
                              : null,
                          onTap: msg.authorId == me
                              ? null
                              : () => _showMemberCard(msg.authorId),
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
            _ComposeBar(controller: _input, sending: _sending, onSend: _send),
        ],
      ),
    );
  }

  bool _isGroupChatTitle(String title) {
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

  /// П1.4 — карточка собеседника при тапе на чужое сообщение.
  Future<void> _showMemberCard(String authorUserId) async {
    final chat = await ref.read(chatsRepositoryProvider).get(widget.chatId);
    final projectId = chat.projectId;
    if (projectId == null || !mounted) return;
    final teamAsync = ref.read(teamControllerProvider(projectId));
    final team = teamAsync.value;
    if (team == null || !mounted) return;
    final m = team.members.firstWhere(
      (mm) => mm.userId == authorUserId,
      orElse: () => team.members.first,
    );
    if (m.userId != authorUserId) return; // не нашли — молча
    final user = m.user;
    if (user == null || !mounted) return;
    final commonProjects = await _loadCommonProjects(authorUserId, projectId);
    if (!mounted) return;
    await showMemberCardSheet(
      context,
      data: MemberCardData(
        userId: user.id,
        firstName: user.firstName,
        lastName: user.lastName,
        roleInCurrentProject: m.role.displayName,
        currentProjectTitle: chat.title ?? 'Проект',
        phone: user.phone,
        avatarUrl: user.avatarUrl,
        commonProjects: commonProjects,
      ),
    );
  }

  /// Общие с собеседником проекты (кроме текущего) — для блока «Другие
  /// общие проекты» в карточке. Берётся из закешированного teammates-списка.
  Future<List<({String id, String title, String role})>> _loadCommonProjects(
    String otherUserId,
    String currentProjectId,
  ) async {
    try {
      final groups = await ref.read(myTeammatesProvider.future);
      final out = <({String id, String title, String role})>[];
      for (final g in groups) {
        if (g.projectId == currentProjectId) continue;
        if (g.ownerId == otherUserId) {
          out.add((id: g.projectId, title: g.projectTitle, role: 'Заказчик'));
          continue;
        }
        final mm = g.members.where((x) => x.userId == otherUserId).firstOrNull;
        if (mm != null) {
          out.add((
            id: g.projectId,
            title: g.projectTitle,
            role: mm.role.displayName,
          ));
        }
      }
      return out;
    } on Object {
      return const [];
    }
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
}

final _chatTitleProvider = FutureProvider.family.autoDispose<String, String>((
  ref,
  chatId,
) async {
  try {
    final c = await ref.read(chatsRepositoryProvider).get(chatId);
    return c.title ?? 'Чат';
  } on ChatsException {
    return 'Чат';
  }
});

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.isMine,
    required this.showSenderLabel,
    required this.onEdit,
    required this.onDelete,
    this.onTap,
  });

  final Message message;
  final bool isMine;
  final bool showSenderLabel;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  bool get _editWindowOpen =>
      message.canEdit(byUserId: message.authorId, now: DateTime.now());

  @override
  Widget build(BuildContext context) {
    final body = message.isDeleted ? 'Сообщение удалено' : (message.text ?? '');
    final time = DateFormat('HH:mm', 'ru').format(message.createdAt);
    final senderColor = _seedColor(message.authorId);

    final bubbleAndAvatar = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isMine) ...[
          GestureDetector(
            onTap: onTap,
            child: AppAvatar(seed: message.authorId, size: 32),
          ),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: AppMessageBubble(
            text: body.isEmpty ? '—' : body,
            isMine: isMine,
            italic: message.isDeleted,
            dimmed: message.isDeleted,
            senderLabel: showSenderLabel
                ? _displaySenderName(message.authorId)
                : null,
            senderColor: senderColor,
            time: time,
            editedMark: message.isEdited && !message.isDeleted,
            // П1.2 — forwardedLabel и forward action удалены из UI.
            forwardedLabel: null,
            // П1.4 — короткий тап на чужой бабл показывает карточку участника.
            onTap: onTap,
            onLongPress: message.isDeleted ? null : () => _showActions(context),
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: bubbleAndAvatar,
      ),
    );
  }

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

  /// Long-press menu: «Копировать», «Редактировать» (свои, окно 15 мин), «Удалить» (свои).
  /// П1.2 — пункт «Переслать» удалён.
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
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

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
            // П1.1 — кнопка attach (paperclip/+) удалена.
            Expanded(
              child: TourAnchor(
                id: 'chat_conversation.input',
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
            ),
            const SizedBox(width: 8),
            _SendButton(sending: sending, onTap: sending ? null : onSend),
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
            : const Icon(Icons.send_rounded, color: AppColors.n0, size: 18),
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
