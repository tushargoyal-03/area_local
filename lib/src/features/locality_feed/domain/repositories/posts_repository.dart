import 'dart:io';
import 'package:area_connect/src/utils/utils.dart';
import '../entities/post.dart';

abstract class PostsRepository {
  FutureEither<List<AppPost>> getNearbyFeed({
    double? lng,
    double? lat,
    double? radiusInKm,
    int page = 1,
    int limit = 20,
    String? currentUserId,
    String? type,
    String? category,
  });

  FutureEither<AppPost> createPost({
    required String category,
    required String title,
    required String content,
    required List<double> coordinates,
    List<String> mediaUrls = const [],
    int? maxParticipants,
    String? eventTime,
  });

  FutureEither<String> uploadImage(File file);

  FutureEither<AppPost> toggleInterest({
    required String postId,
    required String currentUserId,
  });

  FutureEither<PostComment> addComment({
    required String postId,
    required String content,
  });

  FutureEither<List<PostComment>> getComments({
    required String postId,
  });

  FutureEither<void> deletePost({required String postId});
}
