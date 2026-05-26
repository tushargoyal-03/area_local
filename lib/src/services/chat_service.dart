import 'dart:async';
import 'package:area_connect/src/imports/imports.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  io.Socket? _socket;
  io.Socket? get socket => _socket;

  // Real-time Streams
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _typingController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _presenceController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _readController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onMessageReceived =>
      _messageController.stream;
  Stream<Map<String, dynamic>> get onTypingStatusChanged =>
      _typingController.stream;
  Stream<Map<String, dynamic>> get onPresenceStatusChanged =>
      _presenceController.stream;
  Stream<Map<String, dynamic>> get onMessagesRead => _readController.stream;

  // --- HTTP Endpoints ---

  /// Retrieve the list of active chat conversations.
  FutureEither<List<dynamic>> getConversations() async {
    final result = await DioService.instance.get('chat/conversations');
    return result.map((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        return responseData['data'] as List<dynamic>;
      } catch (e) {
        throw Exception('Failed to load conversations: $e');
      }
    });
  }

  /// Retrieve messages for a specific conversation ID.
  FutureEither<List<dynamic>> getMessages({
    required String chatId,
    int page = 1,
    int limit = 30,
  }) async {
    final result = await DioService.instance.get(
      'chat/messages/$chatId',
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );
    return result.map((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        return responseData['data'] as List<dynamic>;
      } catch (e) {
        throw Exception('Failed to load messages: $e');
      }
    });
  }

  /// Retrieve or create a direct chat conversation with a specific neighbor.
  FutureEither<Map<String, dynamic>> getOrCreateDirectChat(
      String recipientId) async {
    final result = await DioService.instance.post(
      'chat/direct',
      data: {
        'recipientId': recipientId,
      },
    );
    return result.map((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        return responseData['data'] as Map<String, dynamic>;
      } catch (e) {
        throw Exception('Failed to get/create direct chat: $e');
      }
    });
  }

  /// Quickly start a conversation with a neighbor and send a default '👋 Hi!' message
  FutureEither<Map<String, dynamic>> sayHi(String recipientId) async {
    final result = await DioService.instance.post(
      'chat/say-hi',
      data: {
        'recipientId': recipientId,
      },
    );
    return result.map((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        return responseData['data'] as Map<String, dynamic>;
      } catch (e) {
        throw Exception('Failed to say hi: $e');
      }
    });
  }

  // --- WebSockets Gateway ---

  /// Initialize and connect to the real-time NestJS ChatGateway.
  Future<void> connectSocket() async {
    final tokenRes = await SecureStorageService.instance.read('access_token');
    final token = tokenRes.fold((_) => null, (t) => t);

    if (token == null || token.isEmpty) {
      return;
    }

    // Clean up existing socket if any
    disconnectSocket();

    // Clean up base URL for socket client (remove /api/ suffix if present)
    var socketUrl = AppConfig.baseUrl;
    if (socketUrl.endsWith('/api/')) {
      socketUrl = socketUrl.substring(0, socketUrl.length - 4);
    } else if (socketUrl.endsWith('/api')) {
      socketUrl = socketUrl.substring(0, socketUrl.length - 4);
    }

    _socket = io.io(
      '${socketUrl}chat', // Namespace matches @WebSocketGateway(namespace: 'chat')
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth(
              {'token': token}) // Matches client.handshake.auth?.token check
          .build(),
    );

    // Dynamic Connection Listeners
    _socket?.onConnect((_) {});

    _socket?.onDisconnect((_) {});

    _socket?.on('connection_acknowledged', (data) {});

    // Real-Time Inbox Updates
    _socket?.on('receive_message', (data) {
      if (data is Map<String, dynamic>) {
        _messageController.add(data);
      } else if (data != null) {
        _messageController.add(Map<String, dynamic>.from(data));
      }
    });

    // Pulsing Typing Indications
    _socket?.on('typing_status', (data) {
      if (data is Map<String, dynamic>) {
        _typingController.add(data);
      } else if (data != null) {
        _typingController.add(Map<String, dynamic>.from(data));
      }
    });

    // Neighbor Presence Indications
    _socket?.on('presence_status', (data) {
      if (data is Map<String, dynamic>) {
        _presenceController.add(data);
      } else if (data != null) {
        _presenceController.add(Map<String, dynamic>.from(data));
      }
    });

    // Message Read Indication broadcasts
    _socket?.on('messages_read', (data) {
      if (data is Map<String, dynamic>) {
        _readController.add(data);
      } else if (data != null) {
        _readController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.connect();
  }

  /// Close the WebSocket connection gracefully.
  void disconnectSocket() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  /// Join a conversation chat room.
  void joinConversation(String conversationId) {
    _socket?.emit('join_conversation', {
      'conversationId': conversationId,
    });
  }

  /// Leave a conversation chat room.
  void leaveConversation(String conversationId) {
    _socket?.emit('leave_conversation', {
      'conversationId': conversationId,
    });
  }

  /// Send a real-time message to a conversation.
  Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    required String text,
    List<String> attachments = const [],
  }) {
    final completer = Completer<Map<String, dynamic>>();

    _socket?.emitWithAck(
      'send_message',
      {
        'conversationId': conversationId,
        'text': text,
        'attachments': attachments,
      },
      ack: (data) {
        if (data is Map<String, dynamic>) {
          completer.complete(data);
        } else if (data != null) {
          completer.complete(Map<String, dynamic>.from(data));
        } else {
          completer.complete({'status': 'SENT'});
        }
      },
    );

    // Fallback timeout in case acknowledgment is delayed
    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => {
        'status': 'SENT',
        'messageId': DateTime.now().millisecondsSinceEpoch.toString(),
        'createdAt': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Notify the WebSocket server of our online/offline presence status.
  void updatePresenceStatus(bool isOnline) {
    _socket?.emit('presence_status', {
      'status': isOnline ? 'online' : 'offline',
    });
  }

  /// Update typing status for current user.
  void sendTypingStatus({
    required String conversationId,
    required bool isTyping,
  }) {
    _socket?.emit('typing_status', {
      'conversationId': conversationId,
      'isTyping': isTyping,
    });
  }

  /// Mark all messages in a conversation as read by current user.
  void markAsRead(String conversationId) {
    _socket?.emit('mark_read', {
      'conversationId': conversationId,
    });
  }
}
