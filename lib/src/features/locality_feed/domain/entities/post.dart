import 'package:equatable/equatable.dart';

class AppPost extends Equatable {
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
