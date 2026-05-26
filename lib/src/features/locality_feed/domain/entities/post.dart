import 'dart:convert';
import 'package:equatable/equatable.dart';

class AppPost extends Equatable {
  Map<String, String> get parsedMeta {
    try {
      if (content.startsWith('{') && content.endsWith('}')) {
        final parsed = jsonDecode(content) as Map<String, dynamic>;
        return {
          'description': parsed['description']?.toString() ?? '',
          'date': parsed['date']?.toString() ?? '',
          'time': parsed['time']?.toString() ?? '',
          'location': parsed['location']?.toString() ?? '',
          'capacity': parsed['capacity']?.toString() ?? '',
        };
      }
    } catch (_) {}

    // Fallback
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final dateStr = 'Today, ${months[createdAt.month - 1]} ${createdAt.day}';
    return {
      'description': content,
      'date': dateStr,
      'time': '6:00 – 8:00 PM',
      'location': 'JLN Sports, V.N.',
      'capacity': '2 people',
    };
  }
  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String category;
  final String title;
  final String content;
  final List<String> mediaUrls;
  final List<double> coordinates; // [lng, lat]
  final List<String> interestedUsers;
  final int commentsCount;
  final int sharesCount;
  final DateTime createdAt;
  final bool isInterested; // Computed for current user
  final double? distanceInMeters;

  const AppPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.category,
    required this.title,
    required this.content,
    required this.mediaUrls,
    required this.coordinates,
    required this.interestedUsers,
    required this.commentsCount,
    required this.sharesCount,
    required this.createdAt,
    this.isInterested = false,
    this.distanceInMeters,
  });

  AppPost copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    String? category,
    String? title,
    String? content,
    List<String>? mediaUrls,
    List<double>? coordinates,
    List<String>? interestedUsers,
    int? commentsCount,
    int? sharesCount,
    DateTime? createdAt,
    bool? isInterested,
    double? distanceInMeters,
  }) {
    return AppPost(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      category: category ?? this.category,
      title: title ?? this.title,
      content: content ?? this.content,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      coordinates: coordinates ?? this.coordinates,
      interestedUsers: interestedUsers ?? this.interestedUsers,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      createdAt: createdAt ?? this.createdAt,
      isInterested: isInterested ?? this.isInterested,
      distanceInMeters: distanceInMeters ?? this.distanceInMeters,
    );
  }

  @override
  List<Object?> get props => [
        id,
        authorId,
        authorName,
        authorAvatar,
        category,
        title,
        content,
        mediaUrls,
        coordinates,
        interestedUsers,
        commentsCount,
        sharesCount,
        createdAt,
        isInterested,
        distanceInMeters,
      ];
}

class PostComment extends Equatable {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String content;
  final DateTime createdAt;

  const PostComment({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.content,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        authorId,
        authorName,
        authorAvatar,
        content,
        createdAt,
      ];
}
