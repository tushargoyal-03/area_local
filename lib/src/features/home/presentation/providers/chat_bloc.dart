import 'dart:async';
import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';

// --- Events ---
abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

class LoadConversationsRequested extends ChatEvent {
  final String currentUserId;
  const LoadConversationsRequested({required this.currentUserId});

  @override
  List<Object?> get props => [currentUserId];
}

class LoadMessagesRequested extends ChatEvent {
  final String chatId;
  final String currentUserId;
  const LoadMessagesRequested(
      {required this.chatId, required this.currentUserId});

  @override
  List<Object?> get props => [chatId, currentUserId];
}

class SendMessageRequested extends ChatEvent {
  final String chatId;
  final String text;
  final String currentUserId;
  const SendMessageRequested({
    required this.chatId,
    required this.text,
    required this.currentUserId,
  });

  @override
  List<Object?> get props => [chatId, text, currentUserId];
}

class StartDirectChatRequested extends ChatEvent {
  final BuildContext context;
  final String recipientId;
  final String recipientName;
  final String currentUserId;
  const StartDirectChatRequested({
    required this.context,
    required this.recipientId,
    required this.recipientName,
    required this.currentUserId,
  });

  @override
  List<Object?> get props => [recipientId, recipientName, currentUserId];
}

class RealtimeMessageReceived extends ChatEvent {
  final Map<String, dynamic> message;
  final String currentUserId;
  const RealtimeMessageReceived(
      {required this.message, required this.currentUserId});

  @override
  List<Object?> get props => [message, currentUserId];
}

class RealtimePresenceStatusChanged extends ChatEvent {
  final Map<String, dynamic> presence;
  const RealtimePresenceStatusChanged({required this.presence});

  @override
  List<Object?> get props => [presence];
}

class RealtimeTypingStatusChanged extends ChatEvent {
  final Map<String, dynamic> typing;
  const RealtimeTypingStatusChanged({required this.typing});

  @override
  List<Object?> get props => [typing];
}

class SendTypingStatusRequested extends ChatEvent {
  final String chatId;
  final bool isTyping;
  const SendTypingStatusRequested(
      {required this.chatId, required this.isTyping});

  @override
  List<Object?> get props => [chatId, isTyping];
}

class MarkMessagesAsReadRequested extends ChatEvent {
  final String chatId;
  const MarkMessagesAsReadRequested({required this.chatId});

  @override
  List<Object?> get props => [chatId];
}

class RealtimeMessagesRead extends ChatEvent {
  final Map<String, dynamic> readInfo;
  const RealtimeMessagesRead({required this.readInfo});

  @override
  List<Object?> get props => [readInfo];
}

class DisconnectChatRequested extends ChatEvent {
  const DisconnectChatRequested();
}

// --- States ---
class ChatState extends Equatable {
  final List<AppConversation> conversations;
  final List<AppChatMessage> activeRoomMessages;
  final bool isConversationsLoading;
  final bool isMessagesLoading;
  final String? activeRoomChatId;
  final bool isPartnerTyping;
  final String? errorMessage;

  const ChatState({
    this.conversations = const [],
    this.activeRoomMessages = const [],
    this.isConversationsLoading = false,
    this.isMessagesLoading = false,
    this.activeRoomChatId,
    this.isPartnerTyping = false,
    this.errorMessage,
  });

  ChatState copyWith({
    List<AppConversation>? conversations,
    List<AppChatMessage>? activeRoomMessages,
    bool? isConversationsLoading,
    bool? isMessagesLoading,
    String? activeRoomChatId,
    bool? isPartnerTyping,
    String? errorMessage,
  }) {
    return ChatState(
      conversations: conversations ?? this.conversations,
      activeRoomMessages: activeRoomMessages ?? this.activeRoomMessages,
      isConversationsLoading:
          isConversationsLoading ?? this.isConversationsLoading,
      isMessagesLoading: isMessagesLoading ?? this.isMessagesLoading,
      activeRoomChatId: activeRoomChatId ?? this.activeRoomChatId,
      isPartnerTyping: isPartnerTyping ?? this.isPartnerTyping,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        conversations,
        activeRoomMessages,
        isConversationsLoading,
        isMessagesLoading,
        activeRoomChatId,
        isPartnerTyping,
        errorMessage,
      ];
}

// --- Bloc ---
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatService _service = ChatService.instance;

  StreamSubscription<Map<String, dynamic>>? _msgSub;
  StreamSubscription<Map<String, dynamic>>? _presenceSub;
  StreamSubscription<Map<String, dynamic>>? _typingSub;
  StreamSubscription<Map<String, dynamic>>? _readSub;

  ChatBloc() : super(const ChatState()) {
    on<LoadConversationsRequested>(_onLoadConversations);
    on<LoadMessagesRequested>(_onLoadMessages);
    on<SendMessageRequested>(_onSendMessage);
    on<StartDirectChatRequested>(_onStartDirectChat);
    on<RealtimeMessageReceived>(_onRealtimeMessageReceived);
    on<RealtimePresenceStatusChanged>(_onRealtimePresenceStatusChanged);
    on<RealtimeTypingStatusChanged>(_onRealtimeTypingStatusChanged);
    on<SendTypingStatusRequested>(_onSendTypingStatus);
    on<MarkMessagesAsReadRequested>(_onMarkMessagesAsRead);
    on<RealtimeMessagesRead>(_onRealtimeMessagesRead);
    on<DisconnectChatRequested>(_onDisconnectChat);
  }

  Future<void> _onLoadConversations(
    LoadConversationsRequested event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(isConversationsLoading: true));

    // Connect WebSockets
    await _service.connectSocket();

    // Setup listeners if not already active
    _cancelStreamSubscriptions();

    _msgSub = _service.onMessageReceived.listen((msg) {
      add(RealtimeMessageReceived(
          message: msg, currentUserId: event.currentUserId));
    });
    _presenceSub = _service.onPresenceStatusChanged.listen((presence) {
      add(RealtimePresenceStatusChanged(presence: presence));
    });
    _typingSub = _service.onTypingStatusChanged.listen((typing) {
      add(RealtimeTypingStatusChanged(typing: typing));
    });
    _readSub = _service.onMessagesRead.listen((readInfo) {
      add(RealtimeMessagesRead(readInfo: readInfo));
    });

    final result = await _service.getConversations();

    result.fold(
      (failure) => emit(state.copyWith(
          isConversationsLoading: false, errorMessage: failure.message)),
      (list) {
        final parsedConvs = list.map((item) {
          final conv = item as Map<String, dynamic>;
          final participants = List<String>.from(
              conv['participants']?.map((e) => e.toString()) ?? []);

          // Identify the neighbor profile from participantProfiles list
          final otherUser =
              (conv['participantProfiles'] as List<dynamic>?)?.firstWhere(
            (p) => p is Map && p['userId']?.toString() != event.currentUserId,
            orElse: () => null,
          ) as Map<String, dynamic>?;

          final lastMsg = conv['lastMessage'] as Map<String, dynamic>?;

          return AppConversation(
            id: conv['_id']?.toString() ?? '',
            participants: participants,
            lastMessageText: lastMsg?['text']?.toString() ?? 'No messages yet',
            lastMessageTime:
                DateTime.tryParse(conv['updatedAt']?.toString() ?? ''),
            recipientName: otherUser?['displayName']?.toString() ??
                otherUser?['emailOrPhone']?.toString() ??
                'Neighbor',
            recipientAvatar: otherUser?['avatarUrl']?.toString(),
            recipientId: otherUser?['userId']?.toString() ?? '',
            unreadCount: 0, // In dynamic apps, computed from readBy
            isRecipientOnline: (otherUser?['isOnline'] as bool?) ??
                (otherUser?['status'] == 'online'),
          );
        }).toList();

        emit(state.copyWith(
            isConversationsLoading: false, conversations: parsedConvs));
      },
    );
  }

  Future<void> _onLoadMessages(
    LoadMessagesRequested event,
    Emitter<ChatState> emit,
  ) async {
    // Leave previous room if any
    if (state.activeRoomChatId != null) {
      _service.leaveConversation(state.activeRoomChatId!);
    }

    final updatedConvs = state.conversations.map((c) {
      if (c.id == event.chatId) {
        return c.copyWith(unreadCount: 0);
      }
      return c;
    }).toList();

    emit(state.copyWith(
      isMessagesLoading: true,
      activeRoomChatId: event.chatId,
      activeRoomMessages: const [],
      isPartnerTyping: false,
      conversations: updatedConvs,
    ));

    // Join room
    _service.joinConversation(event.chatId);
    _service.markAsRead(event.chatId);

    final result = await _service.getMessages(chatId: event.chatId);

    result.fold(
      (failure) => emit(state.copyWith(
          isMessagesLoading: false, errorMessage: failure.message)),
      (list) {
        final parsedMsgs = list.map((item) {
          final msg = item as Map<String, dynamic>;
          final senderId = msg['senderId']?.toString() ?? '';
          return AppChatMessage(
            id: msg['_id']?.toString() ?? '',
            conversationId: msg['conversationId']?.toString() ?? event.chatId,
            senderId: senderId,
            text: msg['text']?.toString() ?? '',
            attachments: List<String>.from(msg['attachments'] ?? []),
            readBy: List<String>.from(
                msg['readBy']?.map((e) => e.toString()) ?? []),
            createdAt: DateTime.tryParse(msg['createdAt']?.toString() ?? '') ??
                DateTime.now(),
            isMe: senderId == event.currentUserId,
          );
        }).toList();

        // Sort messages chronologically (oldest to newest)
        parsedMsgs.sort((a, b) => a.createdAt.compareTo(b.createdAt));

        emit(state.copyWith(
            isMessagesLoading: false, activeRoomMessages: parsedMsgs));
      },
    );
  }

  Future<void> _onSendMessage(
    SendMessageRequested event,
    Emitter<ChatState> emit,
  ) async {
    // Generate optimistic message
    final optimisticMsg = AppChatMessage(
      id: 'optimistic_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: event.chatId,
      senderId: event.currentUserId,
      text: event.text,
      attachments: const [],
      readBy: List<String>.from([event.currentUserId]),
      createdAt: DateTime.now(),
      isMe: true,
    );

    // Render message immediately
    emit(state.copyWith(
      activeRoomMessages: [...state.activeRoomMessages, optimisticMsg],
    ));

    // Send through WebSocket with Acknowledgement
    final ack = await _service.sendMessage(
      conversationId: event.chatId,
      text: event.text,
    );

    // Replace optimistic message with actual validated server message
    final finalMessages = state.activeRoomMessages.map((m) {
      if (m.id == optimisticMsg.id) {
        return AppChatMessage(
          id: ack['messageId']?.toString() ?? optimisticMsg.id,
          conversationId: event.chatId,
          senderId: event.currentUserId,
          text: event.text,
          attachments: const [],
          readBy: List<String>.from([event.currentUserId]),
          createdAt: DateTime.tryParse(ack['createdAt']?.toString() ?? '') ??
              optimisticMsg.createdAt,
          isMe: true,
        );
      }
      return m;
    }).toList();

    // Update conversation last message in list
    final updatedConvs = state.conversations.map((c) {
      if (c.id == event.chatId) {
        return c.copyWith(
          lastMessageText: event.text,
          lastMessageTime: DateTime.now(),
        );
      }
      return c;
    }).toList();

    emit(state.copyWith(
      activeRoomMessages: finalMessages,
      conversations: updatedConvs,
    ));
  }

  Future<void> _onStartDirectChat(
    StartDirectChatRequested event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(isConversationsLoading: true));

    final result = await _service.getOrCreateDirectChat(event.recipientId);

    result.fold(
      (failure) {
        emit(state.copyWith(isConversationsLoading: false));
        showGlobalToast(message: failure.message, status: 'error');
      },
      (chat) {
        emit(state.copyWith(isConversationsLoading: false));
        final chatId = chat['_id']?.toString() ?? '';

        // Navigate to active chat screen
        if (event.context.mounted) {
          event.context.push(
            '/chat-room',
            extra: {
              'chatId': chatId,
              'recipientName': event.recipientName,
              'recipientId': event.recipientId,
            },
          );
        }
      },
    );
  }

  void _onRealtimeMessageReceived(
    RealtimeMessageReceived event,
    Emitter<ChatState> emit,
  ) {
    final msg = event.message;
    final chatId = msg['conversationId']?.toString() ?? '';
    final senderId = msg['senderId']?.toString() ?? '';
    final text = msg['text']?.toString() ?? '';

    final newMsg = AppChatMessage(
      id: msg['_id']?.toString() ?? '',
      conversationId: chatId,
      senderId: senderId,
      text: text,
      attachments: List<String>.from(msg['attachments'] ?? []),
      readBy: const [],
      createdAt: DateTime.tryParse(msg['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      isMe: senderId == event.currentUserId,
    );

    // If the active chat room is open, append message and mark as read
    if (state.activeRoomChatId == chatId) {
      _service.markAsRead(chatId);
      emit(state.copyWith(
        activeRoomMessages: [...state.activeRoomMessages, newMsg],
      ));
    } else if (senderId != event.currentUserId) {
      // Tapping message alert from outside the active conversation slides down the floating banner
      NotificationService.instance.triggerChatNotification(
        message: msg,
        currentUserId: event.currentUserId,
      );
    }

    // Update conversations list items dynamically
    final updatedConvs = state.conversations.map((c) {
      if (c.id == chatId) {
        final isUnread =
            state.activeRoomChatId != chatId && senderId != event.currentUserId;
        return c.copyWith(
          lastMessageText: text,
          lastMessageTime: newMsg.createdAt,
          unreadCount: isUnread ? c.unreadCount + 1 : 0,
        );
      }
      return c;
    }).toList();

    emit(state.copyWith(conversations: updatedConvs));
  }

  void _onRealtimePresenceStatusChanged(
    RealtimePresenceStatusChanged event,
    Emitter<ChatState> emit,
  ) {
    final data = event.presence;
    final userId = data['userId']?.toString() ?? '';
    final status = data['status']?.toString() ?? 'offline';
    final isOnline = status == 'online';

    final updatedConvs = state.conversations.map((c) {
      if (c.recipientId == userId) {
        return c.copyWith(isRecipientOnline: isOnline);
      }
      return c;
    }).toList();

    emit(state.copyWith(conversations: updatedConvs));
  }

  void _onRealtimeTypingStatusChanged(
    RealtimeTypingStatusChanged event,
    Emitter<ChatState> emit,
  ) {
    final data = event.typing;
    final chatId = data['conversationId']?.toString() ?? '';
    final isTyping = data['isTyping'] as bool? ?? false;

    if (state.activeRoomChatId == chatId) {
      emit(state.copyWith(isPartnerTyping: isTyping));
    }
  }

  void _onSendTypingStatus(
    SendTypingStatusRequested event,
    Emitter<ChatState> emit,
  ) {
    _service.sendTypingStatus(
      conversationId: event.chatId,
      isTyping: event.isTyping,
    );
  }

  void _onMarkMessagesAsRead(
    MarkMessagesAsReadRequested event,
    Emitter<ChatState> emit,
  ) {
    _service.markAsRead(event.chatId);

    final updatedConvs = state.conversations.map((c) {
      if (c.id == event.chatId) {
        return c.copyWith(unreadCount: 0);
      }
      return c;
    }).toList();

    emit(state.copyWith(conversations: updatedConvs));
  }

  void _onRealtimeMessagesRead(
    RealtimeMessagesRead event,
    Emitter<ChatState> emit,
  ) {
    final data = event.readInfo;
    final chatId = data['conversationId']?.toString() ?? '';
    final readerId = data['readBy']?.toString() ?? '';

    // If active chat is open, map all messages from sender as read by readerId
    if (state.activeRoomChatId == chatId) {
      final updatedMsgs = state.activeRoomMessages.map((m) {
        if (!m.readBy.contains(readerId)) {
          return AppChatMessage(
            id: m.id,
            conversationId: m.conversationId,
            senderId: m.senderId,
            text: m.text,
            attachments: m.attachments,
            readBy: [...m.readBy, readerId],
            createdAt: m.createdAt,
            isMe: m.isMe,
          );
        }
        return m;
      }).toList();
      emit(state.copyWith(activeRoomMessages: updatedMsgs));
    }
  }

  void _onDisconnectChat(
    DisconnectChatRequested event,
    Emitter<ChatState> emit,
  ) {
    _cancelStreamSubscriptions();
    _service.disconnectSocket();
    emit(const ChatState());
  }

  void _cancelStreamSubscriptions() {
    _msgSub?.cancel();
    _presenceSub?.cancel();
    _typingSub?.cancel();
    _readSub?.cancel();
  }

  @override
  Future<void> close() {
    _cancelStreamSubscriptions();
    _service.disconnectSocket();
    return super.close();
  }
}
