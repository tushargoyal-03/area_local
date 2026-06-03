import 'dart:io';
import 'package:area_connect/src/imports/imports.dart';
import 'package:mime/mime.dart';
import 'package:dio/dio.dart' as dio;

class UsersService {
  UsersService._();
  static final UsersService instance = UsersService._();

  FutureEither<Map<String, dynamic>> uploadAvatar(File file) async {
    try {
      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
      final fileName = file.path.split('/').last;

      final formData = dio.FormData.fromMap({
        'file': await dio.MultipartFile.fromFile(
          file.path,
          filename: fileName,
          contentType: dio.DioMediaType.parse(mimeType),
        ),
      });

      final result = await DioService.instance.post(
        'users/me/avatar',
        data: formData,
      );

      return result.flatMap((response) {
        try {
          final responseData = response.data as Map<String, dynamic>;
          return right(responseData['data'] as Map<String, dynamic>);
        } catch (e) {
          return left(
              ServerFailure('Failed to parse avatar upload response: $e'));
        }
      });
    } catch (e) {
      return left(ServerFailure('Failed to upload avatar: $e'));
    }
  }

  FutureEither<Map<String, dynamic>> getMe() async {
    final result = await DioService.instance.get('users/me');
    return result.flatMap((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        return right(responseData['data'] as Map<String, dynamic>);
      } catch (e) {
        return left(ServerFailure('Failed to get current user: $e'));
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
    return result.flatMap((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        return right(responseData['data'] as Map<String, dynamic>);
      } catch (e) {
        return left(ServerFailure('Failed to update profile: $e'));
      }
    });
  }

  FutureEither<void> updateLocation(List<double> coordinates) async {
    final result = await DioService.instance.patch(
      'users/location',
      data: {'coordinates': coordinates},
    );
    return result.map((_) {});
  }

  FutureEither<List<dynamic>> getNearbyUsers({
    double? lng,
    double? lat,
    double? radiusInKm,
    int page = 1,
    int limit = 20,
  }) async {
    final Map<String, dynamic> queryParameters = {'page': page, 'limit': limit};
    if (lng != null) queryParameters['lng'] = lng;
    if (lat != null) queryParameters['lat'] = lat;
    if (radiusInKm != null) queryParameters['radiusInKm'] = radiusInKm;

    final result = await DioService.instance.get(
      'users/nearby',
      queryParameters: queryParameters,
    );

    return result.flatMap((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        return right(responseData['data'] as List<dynamic>);
      } catch (e) {
        return left(ServerFailure('Failed to load nearby users: $e'));
      }
    });
  }

  FutureEither<Map<String, dynamic>> getPublicProfile(String userId) async {
    final result = await DioService.instance.get('users/$userId/profile');
    return result.flatMap((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        return right(responseData['data'] as Map<String, dynamic>);
      } catch (e) {
        return left(ServerFailure('Failed to get public profile: $e'));
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

    return result.flatMap((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        final dataObj = responseData['data'];
        if (dataObj is Map) {
          return right((dataObj['results'] as List?) ?? []);
        } else if (dataObj is List) {
          return right(dataObj);
        }
        return right([]);
      } catch (e) {
        return left(ServerFailure('Failed to search users: $e'));
      }
    });
  }
}
