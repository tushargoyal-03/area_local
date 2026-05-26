import 'package:equatable/equatable.dart';

class AppNotification extends Equatable {
  final String id;
  final String recipientId;
  final String type; // Activity, Society, Business, System
  final String title;
  final String message;
  final bool isRead;
  final String? relatedId;
  final String createdAt;

  const AppNotification({
    required this.id,
    required this.recipientId,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    this.relatedId,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['_id']?.toString() ?? '',
      recipientId: json['recipientId']?.toString() ?? '',
      type: json['type']?.toString() ?? 'System',
      title: json['title']?.toString() ?? '',
      message: json['body']?.toString() ?? json['message']?.toString() ?? '',
      isRead: json['readAt'] != null || json['isRead'] == true,
      relatedId:
          (json['data'] is Map ? json['data']['postId']?.toString() : null) ??
              json['relatedId']?.toString(),
      createdAt:
          json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }

  AppNotification copyWith({
    String? id,
    String? recipientId,
    String? type,
    String? title,
    String? message,
    bool? isRead,
    String? relatedId,
    String? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      relatedId: relatedId ?? this.relatedId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, recipientId, type, title, message, isRead, relatedId, createdAt];
}
