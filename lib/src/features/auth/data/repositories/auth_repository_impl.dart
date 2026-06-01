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
        role: userData['role'] ?? 'User',
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

      final user = AppUser(
        id: userData['id']?.toString() ?? '',
        email: userData['email'] ?? email,
        name: userData['name'] ?? '',
        role: userData['role'] ?? 'User',
      );

      return right(user);
    });
  }

  @override
  FutureEither<AppUser> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
    required List<double> coordinates,
  }) async {
    final result = await _authService.signUp(
      name: name,
      email: email,
      password: password,
      role: role,
      coordinates: coordinates,
    );

    return result.flatMap((userData) {
      if (userData == null) {
        return left(
            const ServerFailure('Sign up failed: User record corrupted'));
      }

      final user = AppUser(
        id: userData['id']?.toString() ?? '',
        email: userData['email'] ?? email,
        name: name,
        role: userData['role'] ?? 'User',
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

      final user = AppUser(
        id: userData['id']?.toString() ?? '',
        email: userData['email'] ?? '',
        name: userData['name'] ?? '',
        photoUrl: userData['photoUrl'],
        role: userData['role'] ?? 'User',
      );

      return right(user);
    });
  }

  @override
  FutureEither<void> resendOtp({required String email}) {
    return _authService.resendOtp(email: email);
  }

  @override
  FutureEither<AppUser> updateRole({required String role}) async {
    final result = await _authService.updateRole(role: role);

    return result.flatMap((userData) {
      if (userData == null) {
        return left(const ServerFailure('Role upgrade failed'));
      }

      final user = AppUser(
        id: userData['id']?.toString() ?? '',
        email: userData['email'] ?? '',
        name: userData['name'] ?? '',
        role: userData['role'] ?? role,
      );

      return right(user);
    });
  }

  @override
  FutureEither<void> forgotPassword({required String email}) {
    return _authService.forgotPassword(email: email);
  }

  @override
  FutureEither<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) {
    return _authService.resetPassword(
        email: email, otp: otp, newPassword: newPassword);
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
        id: userData['id']?.toString() ?? '',
        email: userData['email'] ?? '',
        name: userData['name'],
        photoUrl: userData['photoUrl'],
        role: userData['role'] ?? 'User',
      );
    });
  }
}
