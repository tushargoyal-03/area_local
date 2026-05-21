import 'dart:async';
import 'package:area_connect/src/imports/imports.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  // In-memory session for mock backend
  Map<String, dynamic>? _currentUser;
  final StreamController<Map<String, dynamic>?> _authStateController =
      StreamController<Map<String, dynamic>?>.broadcast();

  /// Stream of auth state changes. Emits the current user map or null.
  Stream<Map<String, dynamic>?> get authStateChanges =>
      _authStateController.stream;

  FutureEither<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    final result = await DioService.instance.post(
      'api/auth/login',
      data: {
        'emailOrPhone': email,
        'password': password,
      },
    );

    return result.map((response) {
      final responseData = response.data as Map<String, dynamic>;

      _currentUser = responseData['user'] ?? responseData;
      _authStateController.add(_currentUser);

      // Save tokens if needed in SecureStorageService
      // await SecureStorageService.instance.write(
      //   key: 'access_token',
      //   value: responseData['accessToken'] ?? '',
      // );
      // await SecureStorageService.instance.write(
      //   key: 'refresh_token',
      //   value: responseData['refreshToken'] ?? '',
      // );
      return _currentUser;
    });
  }

  FutureEither<Map<String, dynamic>?> signUp({
    required String name,
    required String email,
    required String password,
    required List<double> coordinates,
  }) async {
    final result = await DioService.instance.post(
      'api/auth/register',
      data: {
        'displayName': name,
        'emailOrPhone': email,
        'password': password,
        'coordinates': [77.5946, 12.9716],
      },
    );

    return result.map((response) {
      final responseData = response.data as Map<String, dynamic>;

      _currentUser = responseData['user'] ?? responseData;
      _authStateController.add(_currentUser);

      // Save tokens if needed in SecureStorageService
      return _currentUser;
    });
  }

  FutureEither<void> forgotPassword({required String email}) async {
    return runTask(() async {
      await Future<void>.delayed(const Duration(seconds: 1));
    }, requiresNetwork: true);
  }

  FutureEither<void> logout() async {
    return runTask(() async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      _currentUser = null;
      _authStateController.add(null);
    });
  }

  FutureEither<Map<String, dynamic>?> verifyOtp({
    required String otp,
    required String email,
  }) async {
    return runTask(() async {
      final result = await DioService.instance.post(
        'api/auth/verify-otp',
        data: {
          'emailOrPhone': email,
          'otp': otp,
        },
      );

      return result.fold(
        (failure) => throw failure,
        (response) {
          final responseData = response.data as Map<String, dynamic>;

          _currentUser =
              responseData['user'] as Map<String, dynamic>? ?? responseData;

          _authStateController.add(_currentUser);

          return _currentUser;
        },
      );
    });
  }

  FutureEither<Map<String, dynamic>?> getCurrentUser() async {
    return runTask(() async {
      return _currentUser;
    });
  }

  void dispose() {
    _authStateController.close();
  }
}
