import 'package:equatable/equatable.dart';

class SocietyJoinRequest extends Equatable {
  final String id;
  final String status;
  final String message;
  final String createdAt;
  final String userId;
  final String displayName;
  final String avatarUrl;

  const SocietyJoinRequest({
    required this.id,
    required this.status,
    required this.message,
    required this.createdAt,
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
  });

  factory SocietyJoinRequest.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    return SocietyJoinRequest(
      id: json['_id'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      message: json['message'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      userId: user['userId'] as String? ?? '',
      displayName: user['displayName'] as String? ?? 'User',
      avatarUrl: user['avatarUrl'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
        id,
        status,
        message,
        createdAt,
        userId,
        displayName,
        avatarUrl,
      ];
}
