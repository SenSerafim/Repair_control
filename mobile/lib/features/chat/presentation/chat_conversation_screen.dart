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
import '../../projects/data/projects_repository.dart';
import '../../projects/domain/membership.dart';
import '../../team/application/team_controller.dart';
import '../../team/data/team_repository.dart';
import '../application/chats_controller.dart';
import '../data/chats_repository.dart';
import '../domain/chat.dart';
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
    final container = _containerCache;
    final chatId = widget.chatId;
    // ref в dispose() стреляет _assertNotDisposed — берём провайдеры из кэша
    // контейнера, он переживает виджет.
    if (_isTyping && container != null) {
      container.read(socketServiceProvider).typing(chatId, typing: false);
    }
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
    final chatAsync = ref.watch(_chatDetailProvider(widget.chatId));
    final me = ref.read(authControllerProvider).userId;
    final chat = chatAsync.asData?.value;
    final projectId = chat?.projectId;
    // Подгружаем участников + owner, чтобы рендерить реальные имена и фото
    // в bubble вместо «6-символьного хвостика UUID».
    final teamAsync = projectId == null
        ? null
        : ref.watch(teamControllerProvider(projectId));
    final ownerAsync = projectId == null
        ? null
        : ref.watch(_projectOwnerProvider(projectId));
    final senders = _SenderIndex.build(
      team: teamAsync?.value,
      owner: ownerAsync?.value,
      chat: chat,
    );

    return AppScaffold(
      showBack: true,
      title: _resolveTitle(chat, ownerAsync?.value),
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
                // Sender labels во всех чатах кроме personal. Раньше эвристика
                // по тексту title ('чат'/'проект'/'этап') давала ложные
                // срабатывания для project-чата с title=null.
                final showSenderLabels =
                    chat == null || chat.type != ChatType.personal;
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
                    final sender = senders.byId(msg.authorId);
                    final prevSameAuthor =
                        prev != null && prev.authorId == msg.authorId;
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
                          sender: sender,
                          showSenderLabel:
                              showSenderLabels &&
                              msg.authorId != me &&
                              !prevSameAuthor,
                          showAvatar:
                              msg.authorId != me &&
                              (showDateSeparator || !prevSameAuthor),
                          onEdit: canWrite ? () => _promptEdit(msg) : null,
                          onDelete: canWrite
                              ? () => ref
                                    .read(
                                      messagesProvider(widget.chatId).notifier,
                                    )
                                    .delete(msg.id)
                              : null,
                          onTapAvatar: msg.authorId == me
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

  String _resolveTitle(Chat? chat, _OwnerUser? owner) {
    if (chat == null) return 'Чат';
    if (chat.title != null && chat.title!.isNotEmpty) return chat.title!;
    switch (chat.type) {
      case ChatType.project:
        return 'Общий чат проекта';
      case ChatType.stage:
        return 'Чат этапа';
      case ChatType.group:
        return 'Группа';
      case ChatType.personal:
        return owner?.fullName ?? 'Личный чат';
    }
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

  /// П1.4 — карточка собеседника при тапе на кружок-аватар.
  /// Раньше fallback'или на `team.members.first` если автор не найден →
  /// открывалась карточка случайного человека или тихо ничего. Теперь
  /// корректно покрываем owner-customer'а через `_projectOwnerProvider`;
  /// при отсутствии данных — toast, а не молчание.
  Future<void> _showMemberCard(String authorUserId) async {
    final chat = ref.read(_chatDetailProvider(widget.chatId)).asData?.value;
    final projectId = chat?.projectId;
    if (chat == null || projectId == null || !mounted) return;
    final team = ref.read(teamControllerProvider(projectId)).asData?.value;
    final owner = ref.read(_projectOwnerProvider(projectId)).asData?.value;

    String firstName;
    String lastName;
    String? phone;
    String? avatarUrl;
    String roleLabel;

    final m = team?.members
        .where((mm) => mm.userId == authorUserId)
        .firstOrNull;
    final mu = m?.user;
    if (mu != null) {
      firstName = mu.firstName;
      lastName = mu.lastName;
      phone = mu.phone;
      avatarUrl = mu.avatarUrl;
      roleLabel = m!.role.displayName;
    } else if (owner != null && owner.id == authorUserId) {
      firstName = owner.firstName;
      lastName = owner.lastName;
      phone = owner.phone;
      avatarUrl = owner.avatarUrl;
      roleLabel = 'Заказчик';
    } else {
      AppToast.show(
        context,
        message: 'Информация об участнике не загружена',
        kind: AppToastKind.info,
      );
      return;
    }

    final commonProjects = await _loadCommonProjects(authorUserId, projectId);
    if (!mounted) return;
    await showMemberCardSheet(
      context,
      data: MemberCardData(
        userId: authorUserId,
        firstName: firstName,
        lastName: lastName,
        roleInCurrentProject: roleLabel,
        currentProjectTitle: owner?.projectTitle ?? chat.title ?? 'Проект',
        phone: phone,
        avatarUrl: avatarUrl,
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

/// Полный Chat — для заголовка, projectId и chat.type (sender-labels стратегия).
final _chatDetailProvider = FutureProvider.family.autoDispose<Chat, String>((
  ref,
  chatId,
) async {
  return ref.read(chatsRepositoryProvider).get(chatId);
});

/// Owner-customer проекта — отдельный провайдер, т.к. owner иногда не виден в
/// team-listing у бригадира/мастера (иерархия §1.4). Сначала пробуем
/// myTeammates (агрегат с готовым `owner`), потом fallback на project.get.
final _projectOwnerProvider = FutureProvider.family
    .autoDispose<_OwnerUser?, String>((ref, projectId) async {
      try {
        final groups = await ref.read(myTeammatesProvider.future);
        final g = groups.where((x) => x.projectId == projectId).firstOrNull;
        final o = g?.owner;
        if (o != null) {
          return _OwnerUser(
            id: o.id,
            firstName: o.firstName,
            lastName: o.lastName,
            phone: o.phone,
            avatarUrl: o.avatarUrl,
            projectTitle: g?.projectTitle ?? '',
          );
        }
      } on Object {
        /* fallback ниже */
      }
      try {
        final p = await ref.read(projectsRepositoryProvider).get(projectId);
        return _OwnerUser(
          id: p.ownerId,
          firstName: '',
          lastName: '',
          phone: null,
          avatarUrl: null,
          projectTitle: p.title,
        );
      } on Object {
        return null;
      }
    });

class _OwnerUser {
  const _OwnerUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.avatarUrl,
    required this.projectTitle,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? avatarUrl;
  final String projectTitle;

  String get fullName => '$firstName $lastName'.trim();
}

class _SenderInfo {
  const _SenderInfo({
    required this.userId,
    required this.displayName,
    required this.shortLabel,
    required this.isActive,
    this.avatarUrl,
  });

  final String userId;
  final String displayName;
  final String shortLabel;
  final String? avatarUrl;

  /// false — участник был удалён из команды (Chat.participants.leftAt != null).
  /// ТЗ §10.3 — рядом с именем показываем «удалён из команды».
  final bool isActive;
}

class _SenderIndex {
  const _SenderIndex(this._byId);
  final Map<String, _SenderInfo> _byId;

  static _SenderIndex build({TeamState? team, _OwnerUser? owner, Chat? chat}) {
    final leftIds = <String>{};
    for (final p in chat?.participants ?? const <ChatParticipant>[]) {
      if (p.leftAt != null) leftIds.add(p.userId);
    }
    final out = <String, _SenderInfo>{};
    if (owner != null &&
        (owner.firstName.isNotEmpty || owner.lastName.isNotEmpty)) {
      out[owner.id] = _SenderInfo(
        userId: owner.id,
        displayName: owner.fullName,
        shortLabel: _shorten(owner.firstName, owner.lastName),
        avatarUrl: owner.avatarUrl,
        isActive: !leftIds.contains(owner.id),
      );
    }
    for (final m in team?.members ?? const <Membership>[]) {
      final u = m.user;
      if (u == null) continue;
      final full = '${u.firstName} ${u.lastName}'.trim();
      out[u.id] = _SenderInfo(
        userId: u.id,
        displayName: full.isEmpty ? _phoneLabel(u.phone) : full,
        shortLabel: _shorten(u.firstName, u.lastName, u.phone),
        avatarUrl: u.avatarUrl,
        isActive: !leftIds.contains(u.id),
      );
    }
    return _SenderIndex(out);
  }

  _SenderInfo? byId(String userId) => _byId[userId];

  static String _shorten(String first, String last, [String phone = '']) {
    final f = first.trim();
    final l = last.trim();
    if (f.isEmpty && l.isEmpty) return _phoneLabel(phone);
    if (f.isEmpty) return l;
    if (l.isEmpty) return f;
    return '$f ${l.characters.first}.';
  }
}

// Серафим 08.06.2026: вместо безличного «Участник» когда ФИО пусто —
// показываем последние 4 цифры телефона. Если и телефона нет — fallback.
String _phoneLabel(String phone) {
  final p = phone.trim();
  if (p.isEmpty) return 'Участник';
  if (p.length <= 4) return p;
  return '+•• ${p.substring(p.length - 4)}';
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.isMine,
    required this.sender,
    required this.showSenderLabel,
    required this.showAvatar,
    required this.onEdit,
    required this.onDelete,
    this.onTapAvatar,
  });

  final Message message;
  final bool isMine;
  final _SenderInfo? sender;
  final bool showSenderLabel;
  final bool showAvatar;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  /// Тап по кружку-аватару — открывает MemberCardSheet (П1.4).
  final VoidCallback? onTapAvatar;

  bool get _editWindowOpen =>
      message.canEdit(byUserId: message.authorId, now: DateTime.now());

  @override
  Widget build(BuildContext context) {
    final body = message.isDeleted ? 'Сообщение удалено' : (message.text ?? '');
    final time = DateFormat('HH:mm', 'ru').format(message.createdAt);
    final senderColor = _seedColor(message.authorId);
    final baseLabel = sender?.shortLabel ?? _fallbackName(message.authorId);
    // ТЗ §10.3 — пометка «удалён из команды» для покинувшего участника.
    final senderLabel = sender != null && !sender!.isActive
        ? '$baseLabel · удалён из команды'
        : baseLabel;

    // Слот аватара — всегда зарезервированные 32px, чтобы серия сообщений
    // от одного автора выравнивалась. Без аватара — пустая шкафа той же ширины.
    final avatarSlot = isMine
        ? const SizedBox.shrink()
        : SizedBox(
            width: 32,
            child: showAvatar
                ? GestureDetector(
                    onTap: onTapAvatar,
                    behavior: HitTestBehavior.opaque,
                    child: Semantics(
                      button: true,
                      label:
                          sender?.displayName ?? 'Открыть карточку участника',
                      child: AppAvatar(
                        seed: message.authorId,
                        name: sender?.displayName,
                        imageUrl: sender?.avatarUrl,
                        size: 32,
                      ),
                    ),
                  )
                : null,
          );

    final bubbleAndAvatar = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isMine) ...[avatarSlot, const SizedBox(width: 6)],
        Flexible(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(AppRadius.r16),
                topRight: const Radius.circular(AppRadius.r16),
                bottomLeft: Radius.circular(isMine ? AppRadius.r16 : 4),
                bottomRight: Radius.circular(isMine ? 4 : AppRadius.r16),
              ),
              boxShadow: isMine
                  ? const [
                      BoxShadow(
                        color: Color(0x524F6EF7),
                        offset: Offset(0, 5),
                        blurRadius: 14,
                        spreadRadius: -3,
                      ),
                    ]
                  : const [
                      BoxShadow(
                        color: Color(0x140D1229),
                        offset: Offset(0, 3),
                        blurRadius: 10,
                        spreadRadius: -4,
                      ),
                    ],
            ),
            child: AppMessageBubble(
              text: body.isEmpty ? '—' : body,
              isMine: isMine,
              italic: message.isDeleted,
              dimmed: message.isDeleted,
              senderLabel: showSenderLabel ? senderLabel : null,
              senderColor: senderColor,
              time: time,
              editedMark: message.isEdited && !message.isDeleted,
              forwardedLabel: null,
              onLongPress: message.isDeleted
                  ? null
                  : () => _showActions(context),
            ),
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

  /// Fallback на случай если team-controller ещё не загружен — короткий
  /// 6-символьный префикс UUID, чтобы хоть как-то различать авторов.
  String _fallbackName(String userId) {
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        decoration: const BoxDecoration(
          color: AppColors.n0,
          border: Border(top: BorderSide(color: AppColors.n200)),
          boxShadow: [
            BoxShadow(
              color: Color(0x0F0D1229),
              offset: Offset(0, -2),
              blurRadius: 8,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // П1.1 — кнопка attach (paperclip/+) удалена.
            Expanded(
              child: TourAnchor(
                id: 'chat_conversation.input',
                child: Container(
                  constraints: const BoxConstraints(minHeight: 42),
                  decoration: BoxDecoration(
                    color: AppColors.n50,
                    border: Border.all(color: AppColors.n200, width: 1.5),
                    borderRadius: BorderRadius.circular(14),
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
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          gradient: AppGradients.bubbleOut,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x6B4F6EF7),
              offset: Offset(0, 6),
              blurRadius: 18,
              spreadRadius: -2,
            ),
            BoxShadow(
              color: Color(0x333A56D4),
              offset: Offset(0, 2),
              blurRadius: 4,
            ),
          ],
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
