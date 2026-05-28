import 'dart:async';
import 'dart:io';
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
  final String? typeFilter;
  final String? search;
  const LoadConversationsRequested({
    required this.currentUserId,
    this.typeFilter,
    this.search,
  });

  @override
  List<Object?> get props => [currentUserId, typeFilter, search];
}

class LoadMessagesRequested extends ChatEvent {
  final String chatId;
  final String currentUserId;
  const LoadMessagesRequested(
      {required this.chatId, required this.currentUserId});

  @override
  List<Object?> get props => [chatId, currentUserId];
}

class SendTextMessageRequested extends ChatEvent {
  final String chatId;
  final String text;
  final String currentUserId;
  const SendTextMessageRequested({
    required this.chatId,
    required this.text,
    required this.currentUserId,
  });

  @override
  List<Object?> get props => [chatId, text, currentUserId];
}

// Legacy alias kept for backward compatibility
typedef SendMessageRequested = SendTextMessageRequested;

class SendMediaMessageRequested extends ChatEvent {
  final String chatId;
  final String currentUserId;
  final File file;
  final String messageType; // 'image' | 'video' | 'voice'
  final String mimeType;
  final String? thumbnailPath;
  final int? durationSeconds;

  const SendMediaMessageRequested({
    required this.chatId,
    required this.currentUserId,
    required this.file,
    required this.messageType,
    required this.mimeType,
    this.thumbnailPath,
    this.durationSeconds,
  });

  @override
  List<Object?> get props =>
      [chatId, currentUserId, file.path, messageType, mimeType];
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

class CreateGroupRequested extends ChatEvent {
  final BuildContext context;
  final String currentUserId;
  final String? title;
  final String? imageUrl;
  final List<String> participantIds;
  const CreateGroupRequested({
    required this.context,
    required this.currentUserId,
    this.title,
    this.imageUrl,
    required this.participantIds,
  });

  @override
  List<Object?> get props => [currentUserId, title, participantIds];
}

class BlockUserRequested extends ChatEvent {
  final String targetUserId;
  const BlockUserRequested({required this.targetUserId});

  @override
  List<Object?> get props => [targetUserId];
}

class ReportUserRequested extends ChatEvent {
  final String targetUserId;
  final String reason;
  final String? details;
  final String? conversationId;
  const ReportUserRequested({
    required this.targetUserId,
    required this.reason,
    this.details,
    this.conversationId,
  });

  @override
  List<Object?> get props => [targetUserId, reason, details];
}

class RealtimeMessageReceived extends ChatEvent {
  final Map<String, dynamic> message;
  final String currentUserId;
  const RealtimeMessageReceived(
      {required this.message, required this.currentUserId});

  @override
  List<Object?> get props => [message, currentUserId];
}

class RealtimeConversationUpdated extends ChatEvent {
  final Map<String, dynamic> update;
  const RealtimeConversationUpdated({required this.update});

  @override
  List<Object?> get props => [update];
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
  final String? successMessage;
  final String activeTab; // 'personal' | 'groups' | 'events'
  final bool isSendingMedia;

  const ChatState({
    this.conversations = const [],
    this.activeRoomMessages = const [],
    this.isConversationsLoading = false,
    this.isMessagesLoading = false,
    this.activeRoomChatId,
    this.isPartnerTyping = false,
    this.errorMessage,
    this.successMessage,
    this.activeTab = 'personal',
    this.isSendingMedia = false,
  });

  ChatState copyWith({
    List<AppConversation>? conversations,
    List<AppChatMessage>? activeRoomMessages,
    bool? isConversationsLoading,
    bool? isMessagesLoading,
    String? activeRoomChatId,
    bool? isPartnerTyping,
    String? errorMessage,
    String? successMessage,
    String? activeTab,
    bool? isSendingMedia,
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
      successMessage: successMessage,
      activeTab: activeTab ?? this.activeTab,
      isSendingMedia: isSendingMedia ?? this.isSendingMedia,
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
        successMessage,
        activeTab,
        isSendingMedia,
      ];
}

// --- Bloc ---
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatService _service = ChatService.instance;

  StreamSubscription<Map<String, dynamic>>? _msgSub;
  StreamSubscription<Map<String, dynamic>>? _presenceSub;
  StreamSubscription<Map<String, dynamic>>? _typingSub;
  StreamSubscription<Map<String, dynamic>>? _readSub;
  StreamSubscription<Map<String, dynamic>>? _convUpdatedSub;

  ChatBloc() : super(const ChatState()) {
    on<LoadConversationsRequested>(_onLoadConversations);
    on<LoadMessagesRequested>(_onLoadMessages);
    on<SendTextMessageRequested>(_onSendTextMessage);
    on<SendMediaMessageRequested>(_onSendMediaMessage);
    on<StartDirectChatRequested>(_onStartDirectChat);
    on<CreateGroupRequested>(_onCreateGroup);
    on<BlockUserRequested>(_onBlockUser);
    on<ReportUserRequested>(_onReportUser);
    on<RealtimeMessageReceived>(_onRealtimeMessageReceived);
    on<RealtimeConversationUpdated>(_onRealtimeConversationUpdated);
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

    await _service.connectSocket();

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
    _convUpdatedSub = _service.onConversationUpdated.listen((update) {
      add(RealtimeConversationUpdated(update: update));
    });

    // Determine type filter from tab
    String? typeFilter;
    if (event.typeFilter != null) {
      typeFilter = event.typeFilter;
    } else {
      switch (state.activeTab) {
        case 'groups':
          typeFilter = 'group';
          break;
        case 'events':
          typeFilter = 'event';
          break;
        default:
          typeFilter = 'direct';
      }
    }

    final result = await _service.getConversations(
      type: typeFilter,
      search: event.search,
    );

    result.fold(
      (failure) => emit(state.copyWith(
          isConversationsLoading: false, errorMessage: failure.message)),
      (list) {
        final parsedConvs = _parseConversations(list, event.currentUserId);
        emit(state.copyWith(
            isConversationsLoading: false, conversations: parsedConvs));
      },
    );
  }

  List<AppConversation> _parseConversations(
      List<dynamic> list, String currentUserId) {
    return list.map((item) {
      final conv = item as Map<String, dynamic>;
      final participants = List<String>.from(
          conv['participants']?.map((e) => e.toString()) ?? []);
      final convType = ConversationTypeX.fromString(conv['type']?.toString());

      final otherUser =
          (conv['participantProfiles'] as List<dynamic>?)?.firstWhere(
        (p) => p is Map && p['userId']?.toString() != currentUserId,
        orElse: () => null,
      ) as Map<String, dynamic>?;

      final lastMsg = conv['lastMessage'] as Map<String, dynamic>?;
      final lastPreview = lastMsg?['preview']?.toString();
      final lastMsgType = lastMsg?['type']?.toString();

      return AppConversation(
        id: conv['_id']?.toString() ?? '',
        type: convType,
        participants: participants,
        lastMessageText: lastMsg?['preview']?.toString() ?? '',
        lastMessagePreview: lastPreview,
        lastMessageType: lastMsgType,
        lastMessageTime: DateTime.tryParse(conv['updatedAt']?.toString() ?? ''),
        recipientName: otherUser?['displayName']?.toString() ??
            otherUser?['emailOrPhone']?.toString() ??
            'Neighbor',
        recipientAvatar: otherUser?['avatarUrl']?.toString(),
        recipientId: otherUser?['userId']?.toString() ?? '',
        unreadCount: (conv['unreadCount'] as num?)?.toInt() ?? 0,
        isRecipientOnline: (otherUser?['isOnline'] as bool?) ?? false,
        title: conv['title']?.toString(),
        imageUrl: conv['imageUrl']?.toString(),
      );
    }).toList();
  }

  Future<void> _onLoadMessages(
    LoadMessagesRequested event,
    Emitter<ChatState> emit,
  ) async {
    if (state.activeRoomChatId != null) {
      _service.leaveConversation(state.activeRoomChatId!);
    }

    final updatedConvs = state.conversations.map((c) {
      if (c.id == event.chatId) return c.copyWith(unreadCount: 0);
      return c;
    }).toList();

    emit(state.copyWith(
      isMessagesLoading: true,
      activeRoomChatId: event.chatId,
      activeRoomMessages: const [],
      isPartnerTyping: false,
      conversations: updatedConvs,
    ));

    _service.joinConversation(event.chatId);
    _service.markAsRead(event.chatId);

    final result = await _service.getMessages(chatId: event.chatId);

    result.fold(
      (failure) => emit(state.copyWith(
          isMessagesLoading: false, errorMessage: failure.message)),
      (list) {
        final parsedMsgs = _parseMessages(list, event.currentUserId);
        parsedMsgs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        emit(state.copyWith(
            isMessagesLoading: false, activeRoomMessages: parsedMsgs));
      },
    );
  }

  List<AppChatMessage> _parseMessages(
      List<dynamic> list, String currentUserId) {
    return list.map((item) {
      final msg = item as Map<String, dynamic>;
      final senderId = msg['senderId']?.toString() ?? '';
      return AppChatMessage(
        id: msg['_id']?.toString() ?? '',
        conversationId: msg['conversationId']?.toString() ?? '',
        senderId: senderId,
        type: MessageTypeX.fromString(msg['type']?.toString()),
        text: msg['text']?.toString() ?? '',
        mediaUrl: msg['mediaUrl']?.toString(),
        thumbnailUrl: msg['thumbnailUrl']?.toString(),
        durationSeconds: (msg['durationSeconds'] as num?)?.toInt(),
        fileSize: (msg['fileSize'] as num?)?.toInt(),
        mimeType: msg['mimeType']?.toString(),
        attachments: List<String>.from(msg['attachments'] ?? []),
        readBy:
            List<String>.from(msg['readBy']?.map((e) => e.toString()) ?? []),
        createdAt: DateTime.tryParse(msg['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        isMe: senderId == currentUserId,
      );
    }).toList();
  }

  Future<void> _onSendTextMessage(
    SendTextMessageRequested event,
    Emitter<ChatState> emit,
  ) async {
    final optimisticMsg = AppChatMessage(
      id: 'optimistic_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: event.chatId,
      senderId: event.currentUserId,
      type: MessageType.text,
      text: event.text,
      attachments: const [],
      readBy: [event.currentUserId],
      createdAt: DateTime.now(),
      isMe: true,
    );

    emit(state.copyWith(
      activeRoomMessages: [optimisticMsg, ...state.activeRoomMessages],
    ));

    final ack = await _service.sendMessage(
      conversationId: event.chatId,
      text: event.text,
      type: 'text',
    );

    final finalMessages = state.activeRoomMessages.map((m) {
      if (m.id == optimisticMsg.id) {
        return AppChatMessage(
          id: ack['messageId']?.toString() ?? optimisticMsg.id,
          conversationId: event.chatId,
          senderId: event.currentUserId,
          type: MessageType.text,
          text: event.text,
          attachments: const [],
          readBy: [event.currentUserId],
          createdAt: DateTime.tryParse(ack['createdAt']?.toString() ?? '') ??
              optimisticMsg.createdAt,
          isMe: true,
        );
      }
      return m;
    }).toList();

    final updatedConvs = state.conversations.map((c) {
      if (c.id == event.chatId) {
        return c.copyWith(
          lastMessageText: event.text,
          lastMessagePreview:
              event.text.length > 80 ? event.text.substring(0, 80) : event.text,
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

  Future<void> _onSendMediaMessage(
    SendMediaMessageRequested event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(isSendingMedia: true));

    final fileName = event.file.path.split('/').last;
    final fileStat = await event.file.stat();

    final urlResult = await _service.getMediaUploadUrl(
      fileName: fileName,
      mimeType: event.mimeType,
      fileSize: fileStat.size,
      mediaType: event.messageType,
    );

    await urlResult.fold(
      (failure) async {
        emit(state.copyWith(
          isSendingMedia: false,
          errorMessage: 'Failed to upload media: ${failure.message}',
        ));
      },
      (urlData) async {
        final uploadUrl = urlData['uploadUrl'] as String? ?? '';
        final mediaUrl = urlData['mediaUrl'] as String? ?? '';

        final finalUrl = await _service.uploadFileToUrl(
          uploadUrl: uploadUrl,
          mediaUrl: mediaUrl,
          file: event.file,
          mimeType: event.mimeType,
        );

        if (finalUrl == null) {
          emit(state.copyWith(
            isSendingMedia: false,
            errorMessage: 'Media upload failed',
          ));
          return;
        }

        final optimisticMsg = AppChatMessage(
          id: 'optimistic_${DateTime.now().millisecondsSinceEpoch}',
          conversationId: event.chatId,
          senderId: event.currentUserId,
          type: MessageTypeX.fromString(event.messageType),
          text: '',
          mediaUrl: finalUrl,
          durationSeconds: event.durationSeconds,
          attachments: const [],
          readBy: [event.currentUserId],
          createdAt: DateTime.now(),
          isMe: true,
        );

        emit(state.copyWith(
          isSendingMedia: false,
          activeRoomMessages: [optimisticMsg, ...state.activeRoomMessages],
        ));

        await _service.sendMessage(
          conversationId: event.chatId,
          type: event.messageType,
          mediaUrl: finalUrl,
          durationSeconds: event.durationSeconds,
          fileSize: fileStat.size,
          mimeType: event.mimeType,
        );
      },
    );
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

  Future<void> _onCreateGroup(
    CreateGroupRequested event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(isConversationsLoading: true));

    final result = await _service.createGroup(
      title: event.title,
      imageUrl: event.imageUrl,
      participantIds: event.participantIds,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(isConversationsLoading: false));
        showGlobalToast(message: failure.message, status: 'error');
      },
      (group) {
        emit(state.copyWith(isConversationsLoading: false));
        final chatId = group['_id']?.toString() ?? '';
        final groupTitle = group['title']?.toString() ?? 'Group';

        if (event.context.mounted) {
          Navigator.of(event.context).pop(); // close new group screen
          event.context.push(
            '/chat-room',
            extra: {
              'chatId': chatId,
              'recipientName': groupTitle,
              'recipientId': '',
            },
          );
        }
      },
    );
  }

  Future<void> _onBlockUser(
    BlockUserRequested event,
    Emitter<ChatState> emit,
  ) async {
    final result = await _service.blockUser(event.targetUserId);

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => emit(state.copyWith(successMessage: 'User blocked')),
    );
  }

  Future<void> _onReportUser(
    ReportUserRequested event,
    Emitter<ChatState> emit,
  ) async {
    final result = await _service.reportUser(
      userId: event.targetUserId,
      reason: event.reason,
      details: event.details,
      conversationId: event.conversationId,
    );

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => emit(state.copyWith(successMessage: 'Report submitted')),
    );
  }

  void _onRealtimeMessageReceived(
    RealtimeMessageReceived event,
    Emitter<ChatState> emit,
  ) {
    final msg = event.message;
    final chatId = msg['conversationId']?.toString() ?? '';
    final senderId = msg['senderId']?.toString() ?? '';
    final msgType = MessageTypeX.fromString(msg['type']?.toString());
    final text = msg['text']?.toString() ?? '';

    final newMsg = AppChatMessage(
      id: msg['_id']?.toString() ?? '',
      conversationId: chatId,
      senderId: senderId,
      type: msgType,
      text: text,
      mediaUrl: msg['mediaUrl']?.toString(),
      thumbnailUrl: msg['thumbnailUrl']?.toString(),
      durationSeconds: (msg['durationSeconds'] as num?)?.toInt(),
      fileSize: (msg['fileSize'] as num?)?.toInt(),
      mimeType: msg['mimeType']?.toString(),
      attachments: List<String>.from(msg['attachments'] ?? []),
      readBy: const [],
      createdAt: DateTime.tryParse(msg['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      isMe: senderId == event.currentUserId,
    );

    if (state.activeRoomChatId == chatId) {
      _service.markAsRead(chatId);
      emit(state.copyWith(
        activeRoomMessages: [newMsg, ...state.activeRoomMessages],
      ));
    } else if (senderId != event.currentUserId) {
      NotificationService.instance.triggerChatNotification(
        message: msg,
        currentUserId: event.currentUserId,
      );
    }

    final preview = msgType == MessageType.text
        ? (text.length > 80 ? text.substring(0, 80) : text)
        : msgType.preview;

    final updatedConvs = state.conversations.map((c) {
      if (c.id == chatId) {
        final isUnread =
            state.activeRoomChatId != chatId && senderId != event.currentUserId;
        return c.copyWith(
          lastMessageText: preview,
          lastMessagePreview: preview,
          lastMessageType: msg['type']?.toString(),
          lastMessageTime: newMsg.createdAt,
          unreadCount: isUnread ? c.unreadCount + 1 : 0,
        );
      }
      return c;
    }).toList();

    emit(state.copyWith(conversations: updatedConvs));
  }

  void _onRealtimeConversationUpdated(
    RealtimeConversationUpdated event,
    Emitter<ChatState> emit,
  ) {
    final data = event.update;
    final chatId = data['conversationId']?.toString() ?? '';
    final lastMsg = data['lastMessage'] as Map<String, dynamic>?;
    if (lastMsg == null) return;

    final updatedConvs = state.conversations.map((c) {
      if (c.id == chatId) {
        return c.copyWith(
          lastMessagePreview: lastMsg['preview']?.toString(),
          lastMessageText: lastMsg['preview']?.toString(),
          lastMessageType: lastMsg['type']?.toString(),
          lastMessageTime:
              DateTime.tryParse(lastMsg['createdAt']?.toString() ?? '') ??
                  c.lastMessageTime,
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
    final isOnline = data['status']?.toString() == 'online';

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
      if (c.id == event.chatId) return c.copyWith(unreadCount: 0);
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

    if (state.activeRoomChatId == chatId) {
      final updatedMsgs = state.activeRoomMessages.map((m) {
        if (!m.readBy.contains(readerId)) {
          return AppChatMessage(
            id: m.id,
            conversationId: m.conversationId,
            senderId: m.senderId,
            type: m.type,
            text: m.text,
            mediaUrl: m.mediaUrl,
            thumbnailUrl: m.thumbnailUrl,
            durationSeconds: m.durationSeconds,
            fileSize: m.fileSize,
            mimeType: m.mimeType,
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
    _convUpdatedSub?.cancel();
  }

  @override
  Future<void> close() {
    _cancelStreamSubscriptions();
    _service.disconnectSocket();
    return super.close();
  }
}
