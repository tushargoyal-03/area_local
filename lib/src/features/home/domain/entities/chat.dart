import 'package:equatable/equatable.dart';

class AppConversation extends Equatable {
  final String id;
  final List<String> participants;
  final String? lastMessageText;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final String recipientName;
  final String? recipientAvatar;
  final String recipientId;
  final bool isRecipientOnline;

  const AppConversation({
    required this.id,
    required this.participants,
    this.lastMessageText,
    this.lastMessageTime,
    this.unreadCount = 0,
    required this.recipientName,
    this.recipientAvatar,
    required this.recipientId,
    this.isRecipientOnline = false,
  });

  AppConversation copyWith({
    String? id,
    List<String>? participants,
    String? lastMessageText,
    DateTime? lastMessageTime,
    int? unreadCount,
    String? recipientName,
    String? recipientAvatar,
    String? recipientId,
    bool? isRecipientOnline,
  }) {
    return AppConversation(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      recipientName: recipientName ?? this.recipientName,
      recipientAvatar: recipientAvatar ?? this.recipientAvatar,
      recipientId: recipientId ?? this.recipientId,
      isRecipientOnline: isRecipientOnline ?? this.isRecipientOnline,
    );
  }

  @override
  List<Object?> get props => [
        id,
        participants,
        lastMessageText,
        lastMessageTime,
        unreadCount,
        recipientName,
        recipientAvatar,
        recipientId,
        isRecipientOnline,
      ];
}

class AppChatMessage extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final List<String> attachments;
  final List<String> readBy;
  final DateTime createdAt;
  final bool isMe;

  const AppChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.attachments,
    required this.readBy,
    required this.createdAt,
    this.isMe = false,
  });

  @override
  List<Object?> get props => [
        id,
        conversationId,
        senderId,
        text,
        attachments,
        readBy,
        createdAt,
        isMe,
      ];
}
