import 'package:area_connect/src/imports/imports.dart';

class SocietiesService {
  SocietiesService._();
  static final SocietiesService instance = SocietiesService._();

  FutureEither<List<dynamic>> getSocietyFeed({
    required String societyId,
    String? type,
    int page = 1,
    int limit = 20,
  }) async {
    final Map<String, dynamic> query = {
      'page': page,
      'limit': limit,
    };
    if (type != null) query['type'] = type;

    final result = await DioService.instance.get(
      'societies/$societyId/feed',
      queryParameters: query,
    );

    return result.map((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        return responseData['posts'] as List<dynamic>;
      } catch (e) {
        throw Exception('Failed to load society feed: $e');
      }
    });
  }

  FutureEither<Map<String, dynamic>> createSocietyPost({
    required String societyId,
    required String type,
    required String title,
    required String content,
    List<String> attachments = const [],
    String? eventDate,
  }) async {
    final Map<String, dynamic> data = {
      'type': type,
      'title': title,
      'content': content,
      'attachments': attachments,
    };
    if (eventDate != null) data['eventDate'] = eventDate;

    final result = await DioService.instance.post(
      'societies/$societyId/posts',
      data: data,
    );

    return result.map((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        return responseData['data'] as Map<String, dynamic>;
      } catch (e) {
        throw Exception('Failed to create society post: $e');
      }
    });
  }

  FutureEither<Map<String, dynamic>> createPoll({
    required String societyId,
    required String title,
    required String content,
    required List<String> options,
  }) async {
    final result = await DioService.instance.post(
      'societies/$societyId/polls',
      data: {
        'title': title,
        'content': content,
        'options': options.map((text) => {'text': text}).toList(),
      },
    );

    return result.map((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        return responseData['data'] as Map<String, dynamic>;
      } catch (e) {
        throw Exception('Failed to create poll: $e');
      }
    });
  }

  FutureEither<Map<String, dynamic>> votePoll({
    required String postId,
    required int optionIndex,
  }) async {
    final result = await DioService.instance.post(
      'societies/polls/$postId/vote',
      data: {
        'optionIndex': optionIndex,
      },
    );

    return result.map((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        return responseData['data'] as Map<String, dynamic>;
      } catch (e) {
        throw Exception('Failed to cast vote: $e');
      }
    });
  }

  FutureEither<Map<String, dynamic>> likePost(String postId) async {
    final result =
        await DioService.instance.post('societies/posts/$postId/like');
    return result.map((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        return responseData['data'] as Map<String, dynamic>;
      } catch (e) {
        throw Exception('Failed to like post: $e');
      }
    });
  }

  FutureEither<Map<String, dynamic>> upvoteComplaint(String postId) async {
    final result =
        await DioService.instance.post('societies/complaints/$postId/upvote');
    return result.map((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        return responseData['data'] as Map<String, dynamic>;
      } catch (e) {
        throw Exception('Failed to upvote complaint: $e');
      }
    });
  }
}
