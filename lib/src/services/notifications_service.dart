import 'package:area_connect/src/imports/imports.dart';

class NotificationsService {
  NotificationsService._();
  static final NotificationsService instance = NotificationsService._();

  FutureEither<List<dynamic>> getNotifications({
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
      'notifications',
      queryParameters: query,
    );

    return result.map((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        return responseData['notifications'] as List<dynamic>;
      } catch (e) {
        throw Exception('Failed to load notifications: $e');
      }
    });
  }

  FutureEither<void> markAsRead(String notificationId) async {
    final result =
        await DioService.instance.patch('notifications/$notificationId/read');
    return result.map((_) {});
  }

  FutureEither<void> markAllAsRead() async {
    final result = await DioService.instance.post('notifications/read-all');
    return result.map((_) {});
  }
}
