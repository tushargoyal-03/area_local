import 'package:area_connect/src/imports/imports.dart';

class UsersService {
  UsersService._();
  static final UsersService instance = UsersService._();

  FutureEither<Map<String, dynamic>> getMe() async {
    final result = await DioService.instance.get('users/me');
    return result.map((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        return responseData['data'] as Map<String, dynamic>;
      } catch (e) {
        throw Exception('Failed to get current user: $e');
      }
    });
  }

  FutureEither<Map<String, dynamic>> updateProfile({
    String? displayName,
    String? avatarUrl,
    List<double>? coordinates,
    List<String>? lookingFor,
  }) async {
    final Map<String, dynamic> data = {};
    if (displayName != null) data['displayName'] = displayName;
    if (avatarUrl != null) data['avatarUrl'] = avatarUrl;
    if (coordinates != null) data['coordinates'] = coordinates;
    if (lookingFor != null) data['lookingFor'] = lookingFor;

    final result = await DioService.instance.patch('users/profile', data: data);
    return result.map((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        return responseData['data'] as Map<String, dynamic>;
      } catch (e) {
        throw Exception('Failed to update profile: $e');
      }
    });
  }

  FutureEither<List<dynamic>> getNearbyUsers({
    required double lng,
    required double lat,
    double radiusInKm = 2,
    int page = 1,
    int limit = 20,
  }) async {
    final result = await DioService.instance.get(
      'users/nearby',
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
        return responseData['data'] as List<dynamic>;
      } catch (e) {
        throw Exception('Failed to load nearby users: $e');
      }
    });
  }

  FutureEither<Map<String, dynamic>> getPublicProfile(String userId) async {
    final result = await DioService.instance.get('users/$userId/profile');
    return result.map((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        return responseData['data'] as Map<String, dynamic>;
      } catch (e) {
        throw Exception('Failed to get public profile: $e');
      }
    });
  }
  FutureEither<List<dynamic>> searchUsers({
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    final result = await DioService.instance.get(
      'users/search',
      queryParameters: {
        'q': query,
        'page': page,
        'limit': limit,
      },
    );

    return result.map((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        return responseData['data'] as List<dynamic>;
      } catch (e) {
        throw Exception('Failed to search users: $e');
      }
    });
  }
}
