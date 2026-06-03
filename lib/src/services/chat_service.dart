import 'dart:async';
import 'dart:io';
import 'package:area_connect/src/imports/imports.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:mime/mime.dart';
import 'package:dio/dio.dart' as dio;

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
  final StreamController<Map<String, dynamic>> _conversationUpdatedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _messageDeletedController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onMessageReceived =>
      _messageController.stream;
  Stream<Map<String, dynamic>> get onTypingStatusChanged =>
      _typingController.stream;
  Stream<Map<String, dynamic>> get onPresenceStatusChanged =>
      _presenceController.stream;
  Stream<Map<String, dynamic>> get onMessagesRead => _readController.stream;
  Stream<Map<String, dynamic>> get onConversationUpdated =>
      _conversationUpdatedController.stream;
  Stream<Map<String, dynamic>> get onMessageDeleted =>
      _messageDeletedController.stream;

  // --- HTTP Endpoints ---

  FutureEither<List<dynamic>> getConversations({
    String? type,
    String? search,
    int page = 1,
    int limit = 20,
    String? cursor,
  }) async {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (type != null) params['type'] = type;
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (cursor != null) params['cursor'] = cursor;

    final result = await DioService.instance.get(
      'chat/conversations',
      queryParameters: params,
    );
    return result.flatMap((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        return right(responseData['data'] as List<dynamic>);
      } catch (e) {
        return left(ServerFailure('Failed to load conversations: $e'));
      }
    });
  }

  FutureEither<List<dynamic>> getMessages({
    required String chatId,
    int page = 1,
    int limit = 30,
    String? cursor,
  }) async {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (cursor != null) params['cursor'] = cursor;

    final result = await DioService.instance.get(
      'chat/messages/$chatId',
      queryParameters: params,
    );
    return result.flatMap((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        return right(responseData['data'] as List<dynamic>);
      } catch (e) {
        return left(ServerFailure('Failed to load messages: $e'));
      }
    });
  }

  FutureEither<Map<String, dynamic>> getOrCreateDirectChat(
      String recipientId) async {
    final result = await DioService.instance.post(
      'chat/direct',
      data: {'recipientId': recipientId},
    );
    return result.flatMap((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        return right(responseData['data'] as Map<String, dynamic>);
      } catch (e) {
        return left(ServerFailure('Failed to get/create direct chat: $e'));
      }
    });
  }

  FutureEither<Map<String, dynamic>> sayHi(String recipientId) async {
    final result = await DioService.instance.post(
      'chat/say-hi',
      data: {'recipientId': recipientId},
    );
    return result.flatMap((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        return right(responseData['data'] as Map<String, dynamic>);
      } catch (e) {
        return left(ServerFailure('Failed to say hi: $e'));
      }
    });
  }

  // --- Group Chat ---

  FutureEither<Map<String, dynamic>> createGroup({
    String? title,
    String? imageUrl,
    required List<String> participantIds,
  }) async {
    final data = <String, dynamic>{'participantIds': participantIds};
    if (title != null && title.isNotEmpty) data['title'] = title;
    if (imageUrl != null && imageUrl.isNotEmpty) data['imageUrl'] = imageUrl;

    final result = await DioService.instance.post('chat/groups', data: data);
    return result.flatMap((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        return right(responseData['data'] as Map<String, dynamic>);
      } catch (e) {
        return left(ServerFailure('Failed to create group: $e'));
      }
    });
  }

  FutureEither<Map<String, dynamic>> addGroupMembers({
    required String groupId,
    required List<String> memberIds,
  }) async {
    final result = await DioService.instance.post(
      'chat/groups/$groupId/members',
      data: {'memberIds': memberIds},
    );
    return result.flatMap((response) {
      try {
        return right(response.data as Map<String, dynamic>);
      } catch (e) {
        return left(ServerFailure('Failed to add members: $e'));
      }
    });
  }

  // --- Block / Report ---

  FutureEither<Map<String, dynamic>> blockUser(String userId) async {
    final result = await DioService.instance.post('users/$userId/block');
    return result.flatMap((response) {
      try {
        return right(response.data as Map<String, dynamic>);
      } catch (e) {
        return left(ServerFailure('Failed to block user: $e'));
      }
    });
  }

  FutureEither<Map<String, dynamic>> unblockUser(String userId) async {
    final result = await DioService.instance.delete('users/$userId/block');
    return result.flatMap((response) {
      try {
        return right(response.data as Map<String, dynamic>);
      } catch (e) {
        return left(ServerFailure('Failed to unblock user: $e'));
      }
    });
  }

  FutureEither<Map<String, dynamic>> reportUser({
    required String userId,
    required String reason,
    String? details,
    String? conversationId,
    String? messageId,
  }) async {
    final data = <String, dynamic>{'reason': reason};
    if (details != null && details.isNotEmpty) data['details'] = details;
    if (conversationId != null) data['conversationId'] = conversationId;
    if (messageId != null) data['messageId'] = messageId;

    final result = await DioService.instance.post(
      'reports/users/$userId',
      data: data,
    );
    return result.flatMap((response) {
      try {
        return right(response.data as Map<String, dynamic>);
      } catch (e) {
        return left(ServerFailure('Failed to report user: $e'));
      }
    });
  }

  // --- Message / Conversation Actions ---

  FutureEither<Map<String, dynamic>> deleteMessage(String messageId) async {
    final result = await DioService.instance.delete('chat/messages/$messageId');
    return result.flatMap((r) {
      try {
        return right(r.data as Map<String, dynamic>);
      } catch (e) {
        return left(ServerFailure('Failed to delete message: $e'));
      }
    });
  }

  FutureEither<Map<String, dynamic>> deleteConversation(
      String conversationId) async {
    final result =
        await DioService.instance.delete('chat/conversations/$conversationId');
    return result.flatMap((r) {
      try {
        return right(r.data as Map<String, dynamic>);
      } catch (e) {
        return left(ServerFailure('Failed to delete conversation: $e'));
      }
    });
  }

  FutureEither<Map<String, dynamic>> removeGroupMember(
      {required String groupId, required String userId}) async {
    final result = await DioService.instance
        .delete('chat/groups/$groupId/members/$userId');
    return result.flatMap((r) {
      try {
        return right(r.data as Map<String, dynamic>);
      } catch (e) {
        return left(ServerFailure('Failed to remove member: $e'));
      }
    });
  }

  FutureEither<Map<String, dynamic>> leaveGroup(String groupId) async {
    final result = await DioService.instance.post('chat/groups/$groupId/leave');
    return result.flatMap((r) {
      try {
        return right(r.data as Map<String, dynamic>);
      } catch (e) {
        return left(ServerFailure('Failed to leave group: $e'));
      }
    });
  }

  FutureEither<Map<String, dynamic>> deleteGroup(String groupId) async {
    final result = await DioService.instance.delete('chat/groups/$groupId');
    return result.flatMap((r) {
      try {
        return right(r.data as Map<String, dynamic>);
      } catch (e) {
        return left(ServerFailure('Failed to delete group: $e'));
      }
    });
  }

  // --- Media Upload ---

  FutureEither<Map<String, dynamic>> getMediaUploadUrl({
    required String fileName,
    required String mimeType,
    required int fileSize,
    required String mediaType,
  }) async {
    final result = await DioService.instance.post(
      'media/chat/upload-url',
      data: {
        'fileName': fileName,
        'mimeType': mimeType,
        'fileSize': fileSize,
        'mediaType': mediaType,
      },
    );
    return result.flatMap((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        return right(responseData['data'] as Map<String, dynamic>);
      } catch (e) {
        return left(ServerFailure('Failed to get upload URL: $e'));
      }
    });
  }

  /// Upload file to the signed URL and return the final mediaUrl.
  Future<String?> uploadFileToUrl({
    required String uploadUrl,
    required String mediaUrl,
    required File file,
    required String mimeType,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      await Dio().put<void>(
        uploadUrl,
        data: bytes,
        options: Options(
          headers: {
            'Content-Type': mimeType,
            'Content-Length': bytes.length.toString(),
          },
        ),
      );
      return mediaUrl;
    } catch (e) {
      if (e is DioException) {
      } else {}
      return null;
    }
  }

  FutureEither<Map<String, dynamic>> updateGroupImage({
    required String groupId,
    required File file,
  }) async {
    try {
      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
      final fileName = file.path.split('/').last;

      final formData = dio.FormData.fromMap({
        'file': await dio.MultipartFile.fromFile(
          file.path,
          filename: fileName,
          contentType: dio.DioMediaType.parse(mimeType),
        ),
      });

      final result = await DioService.instance.post(
        'chat/groups/$groupId/image',
        data: formData,
      );

      return result.flatMap((response) {
        try {
          final responseData = response.data as Map<String, dynamic>;
          return right(responseData['data'] as Map<String, dynamic>);
        } catch (e) {
          return left(
              ServerFailure('Failed to parse group image response: $e'));
        }
      });
    } catch (e) {
      return left(ServerFailure('Failed to upload group image: $e'));
    }
  }

  // --- WebSockets Gateway ---

  Future<void> connectSocket() async {
    final tokenRes = await SecureStorageService.instance.read('access_token');
    final token = tokenRes.fold((_) => null, (t) => t);

    if (token == null || token.isEmpty) return;

    disconnectSocket();

    var socketUrl = AppConfig.baseUrl;
    if (socketUrl.endsWith('/api/')) {
      socketUrl = socketUrl.substring(0, socketUrl.length - 4);
    } else if (socketUrl.endsWith('/api')) {
      socketUrl = socketUrl.substring(0, socketUrl.length - 4);
    }

    _socket = io.io(
      '${socketUrl}chat',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    _socket?.onConnect((_) {
      updatePresenceStatus(true);
    });

    _socket?.on('receive_message', (data) {
      if (data is Map<String, dynamic>) {
        _messageController.add(data);
      } else if (data != null) {
        _messageController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('typing_status', (data) {
      if (data is Map<String, dynamic>) {
        _typingController.add(data);
      } else if (data != null) {
        _typingController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('presence_status', (data) {
      if (data is Map<String, dynamic>) {
        _presenceController.add(data);
      } else if (data != null) {
        _presenceController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('messages_read', (data) {
      if (data is Map<String, dynamic>) {
        _readController.add(data);
      } else if (data != null) {
        _readController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('conversation_updated', (data) {
      if (data is Map<String, dynamic>) {
        _conversationUpdatedController.add(data);
      } else if (data != null) {
        _conversationUpdatedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('message_deleted', (data) {
      if (data is Map<String, dynamic>) {
        _messageDeletedController.add(data);
      } else if (data != null) {
        _messageDeletedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.connect();
  }

  void disconnectSocket() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void joinConversation(String conversationId) {
    _socket?.emit('join_conversation', {'conversationId': conversationId});
  }

  void leaveConversation(String conversationId) {
    _socket?.emit('leave_conversation', {'conversationId': conversationId});
  }

  Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    String? text,
    String type = 'text',
    String? mediaUrl,
    String? thumbnailUrl,
    int? durationSeconds,
    int? fileSize,
    String? mimeType,
    String? replyToId,
  }) {
    final completer = Completer<Map<String, dynamic>>();

    final payload = <String, dynamic>{
      'conversationId': conversationId,
      'type': type,
    };
    if (text != null && text.isNotEmpty) payload['text'] = text;
    if (mediaUrl != null) payload['mediaUrl'] = mediaUrl;
    if (thumbnailUrl != null) payload['thumbnailUrl'] = thumbnailUrl;
    if (durationSeconds != null) payload['durationSeconds'] = durationSeconds;
    if (fileSize != null) payload['fileSize'] = fileSize;
    if (mimeType != null) payload['mimeType'] = mimeType;
    if (replyToId != null) payload['replyToId'] = replyToId;

    _socket?.emitWithAck(
      'send_message',
      payload,
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

    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => {
        'status': 'SENT',
        'messageId': DateTime.now().millisecondsSinceEpoch.toString(),
        'createdAt': DateTime.now().toIso8601String(),
      },
    );
  }

  void updatePresenceStatus(bool isOnline) {
    _socket?.emit('presence_status', {
      'status': isOnline ? 'online' : 'offline',
    });
  }

  void sendTypingStatus({
    required String conversationId,
    required bool isTyping,
  }) {
    _socket?.emit('typing_status', {
      'conversationId': conversationId,
      'isTyping': isTyping,
    });
  }

  void markAsRead(String conversationId) {
    _socket?.emit('mark_read', {'conversationId': conversationId});
  }

  void deleteMessageViaSocket(
      {required String messageId, required String conversationId}) {
    _socket?.emit('delete_message',
        {'messageId': messageId, 'conversationId': conversationId});
  }
}
