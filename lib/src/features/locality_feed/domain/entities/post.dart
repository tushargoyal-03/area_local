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
  final String authorRole;
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

  // New fields
  final String status; // OPEN / FULL / CLOSED / EXPIRED
  final String postType; // activity / general / society / business
  final int? maxParticipants;
  final int acceptedParticipantsCount;
  final int interestedCount; // server-side count
  final DateTime? eventTime;
  final double? rankScore;

  const AppPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    this.authorRole = 'User',
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
    this.status = 'OPEN',
    this.postType = 'activity',
    this.maxParticipants,
    this.acceptedParticipantsCount = 0,
    this.interestedCount = 0,
    this.eventTime,
    this.rankScore,
  });

  AppPost copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    String? authorRole,
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
    String? status,
    String? postType,
    int? maxParticipants,
    int? acceptedParticipantsCount,
    int? interestedCount,
    DateTime? eventTime,
    double? rankScore,
  }) {
    return AppPost(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      authorRole: authorRole ?? this.authorRole,
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
      status: status ?? this.status,
      postType: postType ?? this.postType,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      acceptedParticipantsCount:
          acceptedParticipantsCount ?? this.acceptedParticipantsCount,
      interestedCount: interestedCount ?? this.interestedCount,
      eventTime: eventTime ?? this.eventTime,
      rankScore: rankScore ?? this.rankScore,
    );
  }

  @override
  List<Object?> get props => [
        id,
        authorId,
        authorName,
        authorAvatar,
        authorRole,
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
        status,
        postType,
        maxParticipants,
        acceptedParticipantsCount,
        interestedCount,
        eventTime,
        rankScore,
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
