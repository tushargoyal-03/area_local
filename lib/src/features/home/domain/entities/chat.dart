import 'package:equatable/equatable.dart';

enum MessageType { text, image, video, voice, system }

enum ConversationType { direct, group, event }

extension MessageTypeX on MessageType {
  static MessageType fromString(String? value) {
    switch (value) {
      case 'image':
        return MessageType.image;
      case 'video':
        return MessageType.video;
      case 'voice':
        return MessageType.voice;
      case 'system':
        return MessageType.system;
      default:
        return MessageType.text;
    }
  }

  String get preview {
    switch (this) {
      case MessageType.image:
        return '📷 Photo';
      case MessageType.video:
        return '🎥 Video';
      case MessageType.voice:
        return '🎙 Voice message';
      default:
        return '';
    }
  }
}

extension ConversationTypeX on ConversationType {
  static ConversationType fromString(String? value) {
    switch (value) {
      case 'group':
        return ConversationType.group;
      case 'event':
        return ConversationType.event;
      default:
        return ConversationType.direct;
    }
  }
}

class AppConversation extends Equatable {
  final String id;
  final ConversationType type;
  final List<String> participants;
  final String? lastMessageText;
  final String? lastMessagePreview;
  final String? lastMessageType;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final String recipientName;
  final String? recipientAvatar;
  final String recipientId;
  final bool isRecipientOnline;
  // Group-only fields
  final String? title;
  final String? imageUrl;
  // Rich member data (populated from participantProfiles aggregation)
  final List<Map<String, dynamic>> memberProfiles;
  final List<String> admins;

  const AppConversation({
    required this.id,
    this.type = ConversationType.direct,
    required this.participants,
    this.lastMessageText,
    this.lastMessagePreview,
    this.lastMessageType,
    this.lastMessageTime,
    this.unreadCount = 0,
    required this.recipientName,
    this.recipientAvatar,
    required this.recipientId,
    this.isRecipientOnline = false,
    this.title,
    this.imageUrl,
    this.memberProfiles = const [],
    this.admins = const [],
  });

  String get displayName => title?.isNotEmpty ?? false ? title! : recipientName;
  String? get displayAvatar =>
      imageUrl?.isNotEmpty ?? false ? imageUrl : recipientAvatar;

  AppConversation copyWith({
    String? id,
    ConversationType? type,
    List<String>? participants,
    String? lastMessageText,
    String? lastMessagePreview,
    String? lastMessageType,
    DateTime? lastMessageTime,
    int? unreadCount,
    String? recipientName,
    String? recipientAvatar,
    String? recipientId,
    bool? isRecipientOnline,
    String? title,
    String? imageUrl,
    List<Map<String, dynamic>>? memberProfiles,
    List<String>? admins,
  }) {
    return AppConversation(
      id: id ?? this.id,
      type: type ?? this.type,
      participants: participants ?? this.participants,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      recipientName: recipientName ?? this.recipientName,
      recipientAvatar: recipientAvatar ?? this.recipientAvatar,
      recipientId: recipientId ?? this.recipientId,
      isRecipientOnline: isRecipientOnline ?? this.isRecipientOnline,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      memberProfiles: memberProfiles ?? this.memberProfiles,
      admins: admins ?? this.admins,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        participants,
        lastMessageText,
        lastMessagePreview,
        lastMessageType,
        lastMessageTime,
        unreadCount,
        recipientName,
        recipientAvatar,
        recipientId,
        isRecipientOnline,
        title,
        imageUrl,
        memberProfiles,
        admins,
      ];
}

class AppChatMessage extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final MessageType type;
  final String text;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final int? durationSeconds;
  final int? fileSize;
  final String? mimeType;
  final List<String> attachments;
  final List<String> readBy;
  final DateTime createdAt;
  final bool isMe;
  final bool isFailed;

  final String? replyToId;
  final String? replyToPreview;
  final String? replyToSenderName;

  const AppChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.type = MessageType.text,
    required this.text,
    this.mediaUrl,
    this.thumbnailUrl,
    this.durationSeconds,
    this.fileSize,
    this.mimeType,
    required this.attachments,
    required this.readBy,
    required this.createdAt,
    this.isMe = false,
    this.isFailed = false,
    this.replyToId,
    this.replyToPreview,
    this.replyToSenderName,
  });

  bool get isOptimistic => id.startsWith('optimistic_');

  @override
  List<Object?> get props => [
        id,
        conversationId,
        senderId,
        type,
        text,
        mediaUrl,
        thumbnailUrl,
        durationSeconds,
        fileSize,
        mimeType,
        attachments,
        readBy,
        createdAt,
        isMe,
        isFailed,
        replyToId,
        replyToPreview,
        replyToSenderName,
      ];
}
