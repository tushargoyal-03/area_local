import 'dart:async';
import 'dart:convert';
import 'package:area_connect/src/imports/imports.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

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
      'auth/login',
      data: {
        'emailOrPhone': email,
        'password': password,
      },
    );

    return result.fold(
      (failure) async => left<Failure, Map<String, dynamic>?>(failure),
      (response) async {
        try {
          final responseData = response.data as Map<String, dynamic>;
          final innerData = responseData['data'] as Map<String, dynamic>;
          final token = innerData['accessToken'] as String;
          final refresh = innerData['refreshToken'] as String;
          final user = innerData['user'] as Map<String, dynamic>;
          final profile = user['profile'] as Map<String, dynamic>? ?? {};

          await SecureStorageService.instance.write('access_token', token);
          await SecureStorageService.instance.write('refresh_token', refresh);

          _currentUser = {
            'id': user['userId'].toString(),
            'email': user['emailOrPhone'] ?? email,
            'name': profile['displayName'] ??
                user['displayName'] ??
                user['name'] ??
                'User',
            'role': user['role'] ?? 'User',
            'photoUrl': profile['avatarUrl'] ??
                user['avatarUrl'] ??
                user['photoUrl'] ??
                '',
          };

          _authStateController.add(_currentUser);
          return right<Failure, Map<String, dynamic>?>(_currentUser);
        } catch (e) {
          return left<Failure, Map<String, dynamic>?>(
              ServerFailure('Invalid response data format: $e'));
        }
      },
    );
  }

  FutureEither<Map<String, dynamic>?> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
    required List<double> coordinates,
  }) async {
    final result = await DioService.instance.post(
      'auth/register',
      data: {
        'displayName': name,
        'emailOrPhone': email,
        'password': password,
        'role': role,
        'coordinates': coordinates,
      },
    );

    return result.fold(
      (failure) => left<Failure, Map<String, dynamic>?>(failure),
      (response) {
        try {
          final responseData = response.data as Map<String, dynamic>;
          final innerData = responseData['data'] as Map<String, dynamic>;

          _currentUser = {
            'id': innerData['userId'].toString(),
            'email': innerData['emailOrPhone'] ?? email,
            'name': name,
            'role': 'User',
          };

          // Note: OTP is not verified yet, so we don't dispatch authenticated state to controller
          return right<Failure, Map<String, dynamic>?>(_currentUser);
        } catch (e) {
          return left<Failure, Map<String, dynamic>?>(
              ServerFailure('Invalid register response: $e'));
        }
      },
    );
  }

  FutureEither<void> forgotPassword({required String email}) async {
    final result = await DioService.instance.post(
      'auth/forgot-password',
      data: {
        'emailOrPhone': email,
      },
    );
    return result.map((_) {});
  }

  FutureEither<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final result = await DioService.instance.post(
      'auth/reset-password',
      data: {
        'emailOrPhone': email,
        'otp': otp,
        'newPassword': newPassword,
      },
    );
    return result.map((_) {});
  }

  FutureEither<void> logout() async {
    return runTask(() async {
      // Fire-and-forget backend logout
      try {
        await DioService.instance.post('auth/logout');
      } catch (_) {}

      // Wipe all secure storage (more reliable than individual deletes on iOS Keychain)
      await SecureStorageService.instance.deleteAll();
      _currentUser = null;
      _authStateController.add(null);
    });
  }

  FutureEither<Map<String, dynamic>?> verifyOtp({
    required String otp,
    required String email,
  }) async {
    final result = await DioService.instance.post(
      'auth/verify-otp',
      data: {
        'emailOrPhone': email,
        'otp': otp,
      },
    );

    return result.fold(
      (failure) async => left<Failure, Map<String, dynamic>?>(failure),
      (response) async {
        try {
          final responseData = response.data as Map<String, dynamic>;
          final innerData = responseData['data'] as Map<String, dynamic>;
          final token = innerData['accessToken'] as String;
          final refresh = innerData['refreshToken'] as String;
          final user = innerData['user'] as Map<String, dynamic>;
          final profile = user['profile'] as Map<String, dynamic>? ?? {};

          await SecureStorageService.instance.write('access_token', token);
          await SecureStorageService.instance.write('refresh_token', refresh);

          _currentUser = {
            'id': user['userId'].toString(),
            'email': user['emailOrPhone'] ?? email,
            'name': profile['displayName'] ??
                user['displayName'] ??
                user['name'] ??
                'User',
            'role': user['role'] ?? 'User',
            'photoUrl': profile['avatarUrl'] ??
                user['avatarUrl'] ??
                user['photoUrl'] ??
                '',
          };

          _authStateController.add(_currentUser);
          return right<Failure, Map<String, dynamic>?>(_currentUser);
        } catch (e) {
          return left<Failure, Map<String, dynamic>?>(
              ServerFailure('OTP verify parsing failed: $e'));
        }
      },
    );
  }

  FutureEither<void> resendOtp({required String email}) async {
    final result = await DioService.instance.post(
      'auth/resend-otp',
      data: {
        'emailOrPhone': email,
      },
    );

    return result.map((_) {});
  }

  FutureEither<Map<String, dynamic>?> updateRole({required String role}) async {
    final result = await DioService.instance.post(
      'auth/update-role',
      data: {
        'role': role,
      },
    );

    return result.fold(
      (failure) async => left<Failure, Map<String, dynamic>?>(failure),
      (response) async {
        try {
          final responseData = response.data as Map<String, dynamic>;
          final innerData = responseData['data'] as Map<String, dynamic>;
          final token = innerData['accessToken'] as String;
          final refresh = innerData['refreshToken'] as String;
          final user = innerData['user'] as Map<String, dynamic>;
          final profile = user['profile'] as Map<String, dynamic>? ?? {};

          await SecureStorageService.instance.write('access_token', token);
          await SecureStorageService.instance.write('refresh_token', refresh);

          _currentUser = {
            'id': user['userId'].toString(),
            'email': user['emailOrPhone'],
            'name': profile['displayName'] ??
                user['displayName'] ??
                user['name'] ??
                'User',
            'role': user['role'] ?? role,
            'photoUrl': profile['avatarUrl'] ??
                user['avatarUrl'] ??
                user['photoUrl'] ??
                '',
          };

          _authStateController.add(_currentUser);
          return right<Failure, Map<String, dynamic>?>(_currentUser);
        } catch (e) {
          return left<Failure, Map<String, dynamic>?>(
              ServerFailure('Role upgrade parsing failed: $e'));
        }
      },
    );
  }

  Map<String, dynamic> _decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return {};
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final resp = utf8.decode(base64Url.decode(normalized));
      return json.decode(resp) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  FutureEither<Map<String, dynamic>?> getCurrentUser() async {
    return runTask(() async {
      if (_currentUser != null) return _currentUser;

      // Auto-login check by reading token and checking if exists
      final tokenRes = await SecureStorageService.instance.read('access_token');
      final token = tokenRes.fold((_) => null, (t) => t);

      if (token != null && token.isNotEmpty) {
        final payload = _decodeJwt(token);
        if (payload.isNotEmpty) {
          _currentUser = {
            'id': payload['sub']?.toString() ?? 'restored',
            'email': payload['emailOrPhone'] ?? 'restored@example.com',
            'name': payload['displayName'] ?? 'User',
            'role': payload['role'] ?? 'User',
            'photoUrl': payload['avatarUrl'] ?? '',
          };
          _authStateController.add(_currentUser);

          // Fetch fresh profile data in background
          try {
            final result = await DioService.instance.get('users/me');
            result.fold(
              (_) {},
              (response) {
                final responseData = response.data as Map<String, dynamic>;
                final data = responseData['data'] as Map<String, dynamic>;
                final profile = data['profile'] as Map<String, dynamic>? ?? {};

                _currentUser = {
                  'id': data['userId']?.toString() ?? _currentUser!['id'],
                  'email': data['emailOrPhone'] ?? _currentUser!['email'],
                  'name': profile['displayName'] ??
                      data['displayName'] ??
                      _currentUser!['name'],
                  'role': data['role'] ?? _currentUser!['role'],
                  'photoUrl': profile['avatarUrl'] ??
                      data['avatarUrl'] ??
                      _currentUser!['photoUrl'],
                };
                _authStateController.add(_currentUser);
              },
            );
          } catch (_) {}
        }
      }

      return _currentUser;
    });
  }

  void dispose() {
    _authStateController.close();
  }
}
