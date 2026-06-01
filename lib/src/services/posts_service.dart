import 'dart:io';
import 'dart:math';
import 'package:area_connect/src/imports/imports.dart';

class PostsService {
  PostsService._();
  static final PostsService instance = PostsService._();

  /// Retrieve nearby activities feed based on current longitude and latitude coordinates.
  FutureEither<List<dynamic>> getNearbyFeed({
    required double lng,
    required double lat,
    double radiusInKm = 5,
    int page = 1,
    int limit = 20,
  }) async {
    final result = await DioService.instance.get(
      'posts/nearby',
      queryParameters: {
        'lng': lng,
        'lat': lat,
        'radiusInKm': radiusInKm,
        'page': page,
        'limit': limit,
      },
    );

    return result.map((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        final feed = responseData['data'] as List<dynamic>;
        return feed;
      } catch (e) {
        throw Exception('Failed to parse posts feed: $e');
      }
    });
  }

  /// DEV: bypass real storage — return a random picsum placeholder URL.
  FutureEither<Map<String, dynamic>> uploadImage(File file) async {
    final seed = Random().nextInt(9999);
    final url = 'https://picsum.photos/seed/$seed/800/600';
    return Right({'url': url, 'data': null});
  }

  /// Create a new hyperlocal activity post.
  FutureEither<Map<String, dynamic>> createPost({
    required String category,
    required String title,
    required String content,
    required List<double> coordinates, // [lng, lat]
    List<String> mediaUrls = const [],
  }) async {
    final result = await DioService.instance.post(
      'posts/activity',
      data: {
        'category': category,
        'title': title,
        'content': content,
        'coordinates': coordinates,
        'mediaUrls': mediaUrls,
      },
    );

    return result.map((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        return responseData['data'] as Map<String, dynamic>;
      } catch (e) {
        throw Exception('Failed to create post: $e');
      }
    });
  }

  /// Express interest or withdraw interest in an activity.
  FutureEither<Map<String, dynamic>> toggleInterest(String postId) async {
    final result = await DioService.instance.post(
      'posts/$postId/interested',
    );

    return result.map((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        return responseData['data'] as Map<String, dynamic>;
      } catch (e) {
        throw Exception('Failed to toggle interest: $e');
      }
    });
  }

  /// Add a comment to an activity post.
  FutureEither<Map<String, dynamic>> addComment({
    required String postId,
    required String content,
  }) async {
    final result = await DioService.instance.post(
      'posts/$postId/comment',
      data: {
        'content': content,
      },
    );

    return result.map((response) {
      try {
        return response.data as Map<String, dynamic>;
      } catch (e) {
        throw Exception('Failed to add comment: $e');
      }
    });
  }

  /// Retrieve comments for an activity post.
  FutureEither<List<dynamic>> getComments(String postId) async {
    final result = await DioService.instance.get(
      'posts/$postId/comments',
    );

    return result.map((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        final comments = responseData['data'] as List<dynamic>;
        return comments;
      } catch (e) {
        throw Exception('Failed to load comments: $e');
      }
    });
  }

  /// Delete a post (only allowed for post authors or admins).
  FutureEither<void> deletePost(String postId) async {
    final result = await DioService.instance.delete(
      'posts/$postId',
    );

    return result.map((_) {});
  }

  /// Get paginated list of interested users for a post (author only).
  FutureEither<List<dynamic>> getInterestedUsers(
    String postId, {
    int page = 1,
    int limit = 20,
  }) async {
    final result = await DioService.instance.get(
      'posts/$postId/interested-users',
      queryParameters: {'page': page, 'limit': limit},
    );
    return result.map((response) {
      final data = response.data as Map<String, dynamic>;
      return data['data'] as List<dynamic>;
    });
  }

  /// Accept a specific user's interest in the post.
  FutureEither<Map<String, dynamic>> acceptInterest(
      String postId, String userId) async {
    final result = await DioService.instance.post(
      'posts/$postId/interested-users/$userId/accept',
    );
    return result.map((response) {
      final data = response.data as Map<String, dynamic>;
      return data['data'] as Map<String, dynamic>? ?? data;
    });
  }

  /// Reject a specific user's interest in the post.
  FutureEither<Map<String, dynamic>> rejectInterest(
      String postId, String userId) async {
    final result = await DioService.instance.post(
      'posts/$postId/interested-users/$userId/reject',
    );
    return result.map((response) {
      final data = response.data as Map<String, dynamic>;
      return data['data'] as Map<String, dynamic>? ?? data;
    });
  }

  /// Close the post to new interests.
  FutureEither<void> closePost(String postId) async {
    final result = await DioService.instance.patch(
      'posts/$postId/close',
    );
    return result.map((_) {});
  }

  /// Submit a review for another participant of the activity.
  FutureEither<Map<String, dynamic>> submitReview({
    required String postId,
    required String targetUserId,
    required int rating,
    String? comment,
  }) async {
    final Map<String, dynamic> body = {
      'targetUserId': targetUserId,
      'rating': rating,
    };
    if (comment != null && comment.isNotEmpty) body['comment'] = comment;

    final result = await DioService.instance.post(
      'posts/$postId/reviews',
      data: body,
    );
    return result.map((response) {
      final data = response.data as Map<String, dynamic>;
      return data['data'] as Map<String, dynamic>? ?? data;
    });
  }
}
