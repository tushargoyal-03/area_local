import 'package:area_connect/src/imports/imports.dart';

class SocietiesService {
  SocietiesService._();
  static final SocietiesService instance = SocietiesService._();

  /// Fetch the list of societies the current user belongs to.
  FutureEither<List<dynamic>> getMySocieties() async {
    final result = await DioService.instance.get('societies/my');
    return result.flatMap((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        final data = responseData['societies'] ?? responseData['data'];
        if (data is List) {
          return right(data);
        }
        return right(const []);
      } catch (e) {
        return left(ServerFailure('Failed to load my societies: $e'));
      }
    });
  }

  /// Create a new society. The authenticated user becomes the creator/admin.
  ///
  /// Backend: `POST /societies`
  /// Body: name, description?, address, city, coordinates [lng, lat]
  FutureEither<Map<String, dynamic>> createSociety({
    required String name,
    required String address,
    required String city,
    required List<double> coordinates, // [lng, lat]
    String? description,
  }) async {
    final Map<String, dynamic> data = {
      'name': name,
      'address': address,
      'city': city,
      'coordinates': coordinates,
    };
    if (description != null && description.isNotEmpty) {
      data['description'] = description;
    }

    final result = await DioService.instance.post(
      'societies',
      data: data,
    );

    return result.flatMap((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        return right(responseData['data'] as Map<String, dynamic>);
      } catch (e) {
        return left(ServerFailure('Failed to create society: $e'));
      }
    });
  }

  /// Discover verified societies near a given location.
  ///
  /// Backend: `GET /societies/nearby`
  FutureEither<List<dynamic>> getNearbySocieties({
    required double lng,
    required double lat,
    double radiusInKm = 5,
    int page = 1,
    int limit = 20,
  }) async {
    final result = await DioService.instance.get(
      'societies/nearby',
      queryParameters: {
        'lng': lng,
        'lat': lat,
        'radiusInKm': radiusInKm,
        'page': page,
        'limit': limit,
      },
    );

    return result.flatMap((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        final data = responseData['societies'] ?? responseData['data'];
        if (data is List) {
          return right(data);
        }
        return right(const []);
      } catch (e) {
        return left(ServerFailure('Failed to load nearby societies: $e'));
      }
    });
  }

  /// Request to join a society as a resident.
  ///
  /// Backend: `POST /societies/:id/join-request`
  FutureEither<Map<String, dynamic>> requestToJoin({
    required String societyId,
    String? message,
  }) async {
    final Map<String, dynamic> data = {};
    if (message != null && message.isNotEmpty) data['message'] = message;

    final result = await DioService.instance.post(
      'societies/$societyId/join-request',
      data: data,
    );

    return result.flatMap((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        return right(
            responseData['data'] as Map<String, dynamic>? ?? responseData);
      } catch (e) {
        return left(ServerFailure('Failed to send join request: $e'));
      }
    });
  }

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

    return result.flatMap((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        final posts = responseData['posts'];
        if (posts is List) {
          return right(posts);
        }
        return right(const []);
      } catch (e) {
        return left(ServerFailure('Failed to load society feed: $e'));
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

    return result.flatMap((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        return right(responseData['data'] as Map<String, dynamic>);
      } catch (e) {
        return left(ServerFailure('Failed to create society post: $e'));
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
        'pollOptions': options.map((text) => {'text': text}).toList(),
      },
    );

    return result.flatMap((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        return right(responseData['data'] as Map<String, dynamic>);
      } catch (e) {
        return left(ServerFailure('Failed to create poll: $e'));
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

    return result.flatMap((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        return right(responseData['data'] as Map<String, dynamic>);
      } catch (e) {
        return left(ServerFailure('Failed to cast vote: $e'));
      }
    });
  }

  FutureEither<Map<String, dynamic>> likePost(String postId) async {
    final result =
        await DioService.instance.post('societies/posts/$postId/like');
    return result.flatMap((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        return right(responseData['data'] as Map<String, dynamic>);
      } catch (e) {
        return left(ServerFailure('Failed to like post: $e'));
      }
    });
  }

  FutureEither<Map<String, dynamic>> upvoteComplaint(String postId) async {
    final result =
        await DioService.instance.post('societies/complaints/$postId/upvote');
    return result.flatMap((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        return right(responseData['data'] as Map<String, dynamic>);
      } catch (e) {
        return left(ServerFailure('Failed to upvote complaint: $e'));
      }
    });
  }

  FutureEither<List<dynamic>> getJoinRequests({
    required String societyId,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final Map<String, dynamic> query = {
      'page': page,
      'limit': limit,
    };
    if (status != null) query['status'] = status;

    final result = await DioService.instance.get(
      'societies/$societyId/join-requests',
      queryParameters: query,
    );

    return result.flatMap((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        final data = responseData['joinRequests'] ??
            responseData['requests'] ??
            responseData['data'];
        if (data is List) {
          return right(data);
        }
        return right(const []);
      } catch (e) {
        return left(ServerFailure('Failed to load join requests: $e'));
      }
    });
  }

  FutureEither<Map<String, dynamic>> approveJoinRequest({
    required String societyId,
    required String requestId,
  }) async {
    final result = await DioService.instance.post(
      'societies/$societyId/join-requests/$requestId/approve',
    );
    return result.flatMap((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        return right(responseData['data'] as Map<String, dynamic>);
      } catch (e) {
        return left(ServerFailure('Failed to approve join request: $e'));
      }
    });
  }

  FutureEither<Map<String, dynamic>> rejectJoinRequest({
    required String societyId,
    required String requestId,
  }) async {
    final result = await DioService.instance.post(
      'societies/$societyId/join-requests/$requestId/reject',
    );
    return result.flatMap((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        return right(responseData['data'] as Map<String, dynamic>);
      } catch (e) {
        return left(ServerFailure('Failed to reject join request: $e'));
      }
    });
  }
}
