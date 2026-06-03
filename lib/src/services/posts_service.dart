import 'dart:io';
import 'package:area_connect/src/imports/imports.dart';
import 'package:dio/dio.dart' as dio;
import 'package:mime/mime.dart';

class PostsService {
  PostsService._();
  static final PostsService instance = PostsService._();

  /// Retrieve nearby activities feed based on current longitude and latitude coordinates.
  FutureEither<List<dynamic>> getNearbyFeed({
    double? lng,
    double? lat,
    double? radiusInKm,
    int page = 1,
    int limit = 20,
    String? type,
    String? category,
  }) async {
    final Map<String, dynamic> queryParameters = {'page': page, 'limit': limit};
    if (lng != null) queryParameters['lng'] = lng;
    if (lat != null) queryParameters['lat'] = lat;
    if (radiusInKm != null) queryParameters['radiusInKm'] = radiusInKm;
    if (type != null) queryParameters['type'] = type;
    if (category != null) queryParameters['category'] = category;

    final result = await DioService.instance.get(
      'posts/nearby',
      queryParameters: queryParameters,
    );

    return result.flatMap((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        final feed = responseData['data'] as List<dynamic>;
        return right(feed);
      } catch (e) {
        return left(ServerFailure('Failed to parse posts feed: $e'));
      }
    });
  }

  /// Determine the backend mediaType ('image', 'video', 'voice') from the MIME type.
  String _resolveMediaType(String mimeType) {
    if (mimeType.startsWith('image/')) return 'image';
    if (mimeType.startsWith('video/')) return 'video';
    if (mimeType.startsWith('audio/')) return 'voice';
    return 'image'; // default fallback
  }

  /// Upload a file to the backend via POST /api/media/upload (multipart/form-data).
  /// Returns the response containing { mediaUrl, key }.
  FutureEither<Map<String, dynamic>> uploadImage(File file) async {
    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
    final mediaType = _resolveMediaType(mimeType);
    final fileName = file.path.split('/').last;

    final formData = dio.FormData.fromMap({
      'file': await dio.MultipartFile.fromFile(
        file.path,
        filename: fileName,
        contentType: dio.DioMediaType.parse(mimeType),
      ),
      'mediaType': mediaType,
    });

    final result = await DioService.instance.post(
      'media/upload',
      data: formData,
    );

    return result.map((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        final data = responseData['data'] as Map<String, dynamic>;
        return data;
      } catch (e) {
        throw Exception('Failed to upload file: $e');
      }
    });
  }

  /// Create a new hyperlocal activity post.
  FutureEither<Map<String, dynamic>> createPost({
    required String category,
    required String title,
    required String content,
    required List<double> coordinates, // [lng, lat]
    List<String> mediaUrls = const [],
    int? maxParticipants,
    String? eventTime, // ISO-8601 string
  }) async {
    final Map<String, dynamic> data = {
      'category': category,
      'title': title,
      'content': content,
      'coordinates': coordinates,
      'mediaUrls': mediaUrls,
    };
    if (maxParticipants != null) data['maxParticipants'] = maxParticipants;
    if (eventTime != null) data['eventTime'] = eventTime;

    final result = await DioService.instance.post(
      'posts/activity',
      data: data,
    );

    return result.flatMap((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        return right(responseData['data'] as Map<String, dynamic>);
      } catch (e) {
        return left(ServerFailure('Failed to create post: $e'));
      }
    });
  }

  /// Express interest or withdraw interest in an activity.
  FutureEither<Map<String, dynamic>> toggleInterest(String postId) async {
    final result = await DioService.instance.post(
      'posts/$postId/interested',
    );

    return result.flatMap((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        return right(responseData['data'] as Map<String, dynamic>);
      } catch (e) {
        return left(ServerFailure('Failed to toggle interest: $e'));
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

    return result.flatMap((response) {
      try {
        return right(response.data as Map<String, dynamic>);
      } catch (e) {
        return left(ServerFailure('Failed to add comment: $e'));
      }
    });
  }

  /// Retrieve comments for an activity post.
  FutureEither<List<dynamic>> getComments(String postId) async {
    final result = await DioService.instance.get(
      'posts/$postId/comments',
    );

    return result.flatMap((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        final comments = responseData['data'] as List<dynamic>;
        return right(comments);
      } catch (e) {
        return left(ServerFailure('Failed to load comments: $e'));
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
    return result.flatMap((response) {
      try {
        final data = response.data as Map<String, dynamic>;
        return right(data['data'] as List<dynamic>);
      } catch (e) {
        return left(ServerFailure('Failed to get interested users: $e'));
      }
    });
  }

  /// Accept a specific user's interest in the post.
  FutureEither<Map<String, dynamic>> acceptInterest(
      String postId, String userId) async {
    final result = await DioService.instance.post(
      'posts/$postId/interested-users/$userId/accept',
    );
    return result.flatMap((response) {
      try {
        final data = response.data as Map<String, dynamic>;
        return right(data['data'] as Map<String, dynamic>? ?? data);
      } catch (e) {
        return left(ServerFailure('Failed to accept interest: $e'));
      }
    });
  }

  /// Reject a specific user's interest in the post.
  FutureEither<Map<String, dynamic>> rejectInterest(
      String postId, String userId) async {
    final result = await DioService.instance.post(
      'posts/$postId/interested-users/$userId/reject',
    );
    return result.flatMap((response) {
      try {
        final data = response.data as Map<String, dynamic>;
        return right(data['data'] as Map<String, dynamic>? ?? data);
      } catch (e) {
        return left(ServerFailure('Failed to reject interest: $e'));
      }
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
    return result.flatMap((response) {
      try {
        final data = response.data as Map<String, dynamic>;
        return right(data['data'] as Map<String, dynamic>? ?? data);
      } catch (e) {
        return left(ServerFailure('Failed to submit review: $e'));
      }
    });
  }
}
