import 'package:equatable/equatable.dart';

class SocietyPost extends Equatable {
  final String id;
  final String societyId;
  final String authorId;
  final String type; // notice, poll, complaint, event
  final String title;
  final String? content;
  final List<String> attachments;
  final int likesCount;
  final int commentsCount;
  final String? eventDate;
  final String createdAt;
  final List<PollOption>? pollOptions;
  final int? totalVotes;
  final int? userVotedOptionIndex; // From backend's _userVote if any

  // Author details via $lookup
  final String authorName;
  final String authorAvatar;

  const SocietyPost({
    required this.id,
    required this.societyId,
    required this.authorId,
    required this.type,
    required this.title,
    this.content,
    this.attachments = const [],
    required this.likesCount,
    required this.commentsCount,
    this.eventDate,
    required this.createdAt,
    this.pollOptions,
    this.totalVotes,
    this.userVotedOptionIndex,
    required this.authorName,
    required this.authorAvatar,
  });

  factory SocietyPost.fromJson(Map<String, dynamic> json) {
    final authorMap = json['author'] as Map<String, dynamic>? ?? {};

    List<PollOption>? options;
    int tVotes = 0;
    if (json['pollOptions'] != null) {
      options = (json['pollOptions'] as List)
          .map((e) => PollOption.fromJson(e))
          .toList();
      for (final o in options) {
        tVotes += o.votes;
      }
    }

    return SocietyPost(
      id: json['_id'] ?? '',
      societyId: json['societyId'] ?? '',
      authorId: authorMap['userId'] ?? json['authorId'] ?? '',
      type: (json['type'] as String?)?.toLowerCase() ?? 'notice',
      title: json['title'] ?? '',
      content: json['content'],
      attachments: List<String>.from(json['attachments'] ?? []),
      likesCount: json['likesCount'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
      eventDate: json['eventDate'],
      createdAt: json['createdAt'] ?? DateTime.now().toIso8601String(),
      pollOptions: options,
      totalVotes: options != null ? tVotes : null,
      userVotedOptionIndex: json['userVotedOptionIndex'],
      authorName: authorMap['displayName'] ?? 'Neighbor',
      authorAvatar: authorMap['avatarUrl'] ?? '',
    );
  }

  SocietyPost copyWith({
    String? id,
    String? societyId,
    String? authorId,
    String? type,
    String? title,
    String? content,
    List<String>? attachments,
    int? likesCount,
    int? commentsCount,
    String? eventDate,
    String? createdAt,
    List<PollOption>? pollOptions,
    int? totalVotes,
    int? userVotedOptionIndex,
    String? authorName,
    String? authorAvatar,
  }) {
    return SocietyPost(
      id: id ?? this.id,
      societyId: societyId ?? this.societyId,
      authorId: authorId ?? this.authorId,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      attachments: attachments ?? this.attachments,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      eventDate: eventDate ?? this.eventDate,
      createdAt: createdAt ?? this.createdAt,
      pollOptions: pollOptions ?? this.pollOptions,
      totalVotes: totalVotes ?? this.totalVotes,
      userVotedOptionIndex: userVotedOptionIndex ?? this.userVotedOptionIndex,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
    );
  }

  @override
  List<Object?> get props => [
        id,
        societyId,
        authorId,
        type,
        title,
        content,
        attachments,
        likesCount,
        commentsCount,
        eventDate,
        createdAt,
        pollOptions,
        totalVotes,
        userVotedOptionIndex,
        authorName,
        authorAvatar
      ];
}

class PollOption extends Equatable {
  final String text;
  final int votes;

  const PollOption({required this.text, required this.votes});

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      text: json['text'] ?? '',
      votes: json['voteCount'] ?? json['votes'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [text, votes];
}
