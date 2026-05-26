import 'package:area_connect/src/utils/utils.dart';
import 'package:area_connect/src/services/posts_service.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/posts_repository.dart';

class PostsRepositoryImpl implements PostsRepository {
  final PostsService _service = PostsService.instance;

  @override
  FutureEither<List<AppPost>> getNearbyFeed({
    required double lng,
    required double lat,
    double radiusInKm = 5,
    int page = 1,
    int limit = 20,
    String? currentUserId,
  }) async {
    final result = await _service.getNearbyFeed(
      lng: lng,
      lat: lat,
      radiusInKm: radiusInKm,
      page: page,
      limit: limit,
    );

    return result.map((list) {
      return list.map((item) {
        final post = item as Map<String, dynamic>;
        final author = post['author'] as Map<String, dynamic>?;
        
        final interested = List<String>.from(
          (post['interestedUsers'] as List<dynamic>?)?.map((e) => e.toString()) ?? [],
        );

        return AppPost(
          id: post['_id']?.toString() ?? '',
          authorId: author?['userId']?.toString() ?? post['authorId']?.toString() ?? '',
          authorName: author?['displayName']?.toString() ?? 'Neighbor',
          authorAvatar: author?['avatarUrl']?.toString(),
          category: post['category']?.toString() ?? 'General',
          title: post['title']?.toString() ?? '',
          content: post['content']?.toString() ?? '',
          mediaUrls: List<String>.from(post['mediaUrls'] ?? []),
          coordinates: List<double>.from(post['location']?['coordinates'] ?? [lng, lat]),
          interestedUsers: interested,
          commentsCount: post['commentsCount'] ?? 0,
          sharesCount: post['sharesCount'] ?? 0,
          createdAt: DateTime.tryParse(post['createdAt']?.toString() ?? '') ?? DateTime.now(),
          isInterested: currentUserId != null && interested.contains(currentUserId),
        );
      }).toList();
    });
  }

  @override
  FutureEither<AppPost> createPost({
    required String category,
    required String title,
    required String content,
    required List<double> coordinates,
  }) async {
    final result = await _service.createPost(
      category: category,
      title: title,
      content: content,
      coordinates: coordinates,
    );

    return result.map((post) {
      return AppPost(
        id: post['_id']?.toString() ?? '',
        authorId: post['authorId']?.toString() ?? '',
        authorName: 'You',
        category: post['category']?.toString() ?? category,
        title: post['title']?.toString() ?? title,
        content: post['content']?.toString() ?? content,
        mediaUrls: List<String>.from(post['mediaUrls'] ?? []),
        coordinates: List<double>.from(post['location']?['coordinates'] ?? coordinates),
        interestedUsers: const [],
        commentsCount: 0,
        sharesCount: 0,
        createdAt: DateTime.tryParse(post['createdAt']?.toString() ?? '') ?? DateTime.now(),
        isInterested: false,
      );
    });
  }

  @override
  FutureEither<AppPost> toggleInterest({
    required String postId,
    required String currentUserId,
  }) async {
    final result = await _service.toggleInterest(postId);

    return result.map((data) {
      // Returns { isInterested: boolean, count: number }
      final isInterested = data['isInterested'] as bool? ?? false;
      final count = data['count'] as int? ?? 0;

      // Create a skeleton post with updated interest flags
      // Which will be mapped / updated in state inside Bloc
      return AppPost(
        id: postId,
        authorId: '',
        authorName: '',
        category: '',
        title: '',
        content: '',
        mediaUrls: const [],
        coordinates: const [],
        interestedUsers: List<String>.generate(
          count,
          (i) => (i == 0 && isInterested) ? currentUserId : 'other_user',
        ),
        commentsCount: 0,
        sharesCount: 0,
        createdAt: DateTime.now(),
        isInterested: isInterested,
      );
    });
  }

  @override
  FutureEither<PostComment> addComment({
    required String postId,
    required String content,
  }) async {
    final result = await _service.addComment(postId: postId, content: content);

    return result.map((data) {
      // Safely extract the comment map (under 'data', 'comment', or direct root)
      Map<String, dynamic> comment = data;
      if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
        comment = data['data'] as Map<String, dynamic>;
      } else if (data.containsKey('comment') && data['comment'] is Map<String, dynamic>) {
        comment = data['comment'] as Map<String, dynamic>;
      }

      return PostComment(
        id: comment['_id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        authorId: comment['authorId']?.toString() ?? '',
        authorName: 'You',
        content: comment['content']?.toString() ?? content,
        createdAt: DateTime.tryParse(comment['createdAt']?.toString() ?? '') ?? DateTime.now(),
      );
    });
  }

  @override
  FutureEither<List<PostComment>> getComments({required String postId}) async {
    final result = await _service.getComments(postId);

    return result.map((list) {
      return list.map((item) {
        final comment = item as Map<String, dynamic>;
        final author = comment['author'] as Map<String, dynamic>?;
        return PostComment(
          id: comment['_id']?.toString() ?? '',
          authorId: author?['userId']?.toString() ?? comment['authorId']?.toString() ?? '',
          authorName: author?['displayName']?.toString() ?? 'Neighbor',
          authorAvatar: author?['avatarUrl']?.toString(),
          content: comment['content']?.toString() ?? '',
          createdAt: DateTime.tryParse(comment['createdAt']?.toString() ?? '') ?? DateTime.now(),
        );
      }).toList();
    });
  }

  @override
  FutureEither<void> deletePost({required String postId}) {
    return _service.deletePost(postId);
  }
}
