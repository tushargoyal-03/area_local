import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../services/secure_storage_service.dart';

class AppConfig {
  AppConfig._();
  static late final Dio dio;

  static String get baseUrl => _getBaseUrl();

  static Future<void> init() async {
    dio = Dio(
      BaseOptions(
        baseUrl: _getBaseUrl(),
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Request Authorization Interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final tokenResult =
              await SecureStorageService.instance.read('access_token');
          tokenResult.fold(
            (_) => null,
            (token) {
              if (token != null && token.trim().isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
              }
            },
          );
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            // Attempt token refresh
            final refreshResult =
                await SecureStorageService.instance.read('refresh_token');
            String? refreshToken;
            refreshResult.fold((_) => null, (token) => refreshToken = token);

            if (refreshToken != null && refreshToken!.trim().isNotEmpty) {
              try {
                // Use a secondary dio instance to avoid infinite interceptor loops
                final refreshDio = Dio(BaseOptions(baseUrl: _getBaseUrl()));
                final response = await refreshDio.post<Map<String, dynamic>>(
                  'auth/refresh',
                  data: {'refreshToken': refreshToken},
                );

                if (response.statusCode == 200 || response.statusCode == 201) {
                  final data = response.data?['data'];
                  final newAccessToken = data['accessToken'];
                  final newRefreshToken = data['refreshToken'];

                  await SecureStorageService.instance
                      .write('access_token', newAccessToken);
                  await SecureStorageService.instance
                      .write('refresh_token', newRefreshToken);

                  // Retry original request with new token
                  e.requestOptions.headers['Authorization'] =
                      'Bearer $newAccessToken';

                  // Need to resolve using the original request options
                  final opts = Options(
                    method: e.requestOptions.method,
                    headers: e.requestOptions.headers,
                  );
                  final cloneReq = await dio.request<void>(
                    e.requestOptions.path,
                    options: opts,
                    data: e.requestOptions.data,
                    queryParameters: e.requestOptions.queryParameters,
                  );
                  return handler.resolve(cloneReq);
                }
              } catch (_) {
                // Refresh failed, clear storage to force login state
                await SecureStorageService.instance.delete('access_token');
                await SecureStorageService.instance.delete('refresh_token');
              }
            }
          }
          return handler.next(e);
        },
      ),
    );

    dio.interceptors.add(
      PrettyDioLogger(
        enabled: true,
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
        maxWidth: 90,
      ),
    );
  }

  static String _getBaseUrl() {
    return dotenv.get('API_BASE_URL', fallback: 'http://localhost:3000/');
  }
}
