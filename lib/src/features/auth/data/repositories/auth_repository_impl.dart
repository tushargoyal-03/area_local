import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';

import 'package:area_connect/src/features/auth/domain/entities/user.dart';
import 'package:area_connect/src/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthService _authService = AuthService.instance;

  @override
  Stream<AppUser?> get onAuthStateChanged {
    return _authService.authStateChanges.map((userData) {
      if (userData == null) return null;
      return AppUser(
        id: userData['id'] ?? '',
        email: userData['email'] ?? '',
        name: userData['name'],
        photoUrl: userData['photoUrl'],
      );
    });
  }

  @override
  FutureEither<AppUser> login({
    required String email,
    required String password,
  }) async {
    final result = await _authService.login(email: email, password: password);

    return result.flatMap((userData) {
      if (userData == null) {
        return left(const ServerFailure('Login failed: User record not found'));
      }

      final data = userData['user'] ?? userData;
      final user = AppUser(
        id: data['id'].toString(),
        email: data['email'] ?? email,
        name: data['name'],
      );

      return right(user);
    });
  }

  @override
  FutureEither<AppUser> signUp({
    required String name,
    required String email,
    required String password,
    required List<double> coordinates,
  }) async {
    final result = await _authService.signUp(
      name: name,
      email: email,
      password: password,
      coordinates: coordinates,
    );

    return result.flatMap((userData) {
      if (userData == null) {
        return left(
            const ServerFailure('Sign up failed: User record corrupted'));
      }

      final data = userData['user'] ?? userData;
      final user = AppUser(
        id: data['id'].toString(),
        email: data['email'] ?? email,
        name: name,
      );

      return right(user);
    });
  }

  @override
  FutureEither<AppUser> verifyOtp({
    required String otp,
    required String email,
  }) async {
    final result = await _authService.verifyOtp(otp: otp, email: email);

    return result.flatMap((userData) {
      if (userData == null) {
        return left(const ServerFailure('OTP verification failed'));
      }
      final data = userData['user'] ?? userData;
      final user = AppUser(
        id: data['id'].toString(),
        email: data['email'] ?? '',
        name: data['name'],
        photoUrl: data['photoUrl'],
      );

      return right(user);
    });
  }

  @override
  FutureEither<void> forgotPassword({required String email}) {
    return _authService.forgotPassword(email: email);
  }

  @override
  FutureEither<void> logout() {
    return _authService.logout();
  }

  @override
  FutureEither<AppUser?> checkAuthState() async {
    final result = await _authService.getCurrentUser();

    return result.map((userData) {
      if (userData == null) return null;

      return AppUser(
        id: userData['id'],
        email: userData['email'] ?? '',
        name: userData['name'],
        photoUrl: userData['photoUrl'],
      );
    });
  }
}
