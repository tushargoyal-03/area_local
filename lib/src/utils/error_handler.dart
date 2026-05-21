import 'package:dio/dio.dart';

class AppErrorHandler {
  static String format(dynamic error) {
    if (error is String) return error;

    if (error is DioException) {
      try {
        final response = error.response;
        if (response != null && response.data != null) {
          final data = response.data;
          if (data is Map<String, dynamic>) {
            // Check common custom backend error response keys
            if (data.containsKey('message') && data['message'] != null) {
              return data['message'].toString();
            }
            if (data.containsKey('error') && data['error'] != null) {
              return data['error'].toString();
            }
            if (data.containsKey('msg') && data['msg'] != null) {
              return data['msg'].toString();
            }
          }
        }
      } catch (_) {}

      // Fallback for custom DioException types
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timed out. Please check your internet and try again.';
        case DioExceptionType.badResponse:
          return 'Server error. Please try again later.';
        case DioExceptionType.cancel:
          return 'Request was cancelled.';
        case DioExceptionType.connectionError:
          return 'Unable to reach the server. Please check your network connection.';
        default:
          return error.message ?? 'A network error occurred';
      }
    }

    try {
      if (error?.message != null) return error.message;
      if (error?.toString() != null) return error.toString();
    } catch (_) {}

    return 'An unexpected error occurred';
  }
}
