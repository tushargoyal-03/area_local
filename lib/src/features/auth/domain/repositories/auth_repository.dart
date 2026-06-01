import 'package:area_connect/src/utils/utils.dart';
import 'package:area_connect/src/features/auth/domain/entities/user.dart';

abstract class AuthRepository {
  /// Stream of auth state changes. Emits AppUser when authenticated, null when not.
  Stream<AppUser?> get onAuthStateChanged;

  /// Sign in with email and password
  FutureEither<AppUser> login({
    required String email,
    required String password,
  });

  /// Sign up with email, password, and optional name
  FutureEither<AppUser> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
    required List<double> coordinates,
  });

  /// Send a password reset email
  FutureEither<void> forgotPassword({
    required String email,
  });

  /// Reset password using OTP
  FutureEither<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  });

  /// Sign out the current user
  FutureEither<void> logout();

  /// Verify OTP
  FutureEither<AppUser> verifyOtp({required String otp, required String email});

  /// Resend verification OTP code
  FutureEither<void> resendOtp({required String email});

  /// Upgrade user role on the backend
  FutureEither<AppUser> updateRole({required String role});

  /// Check if the user is currently authenticated natively
  FutureEither<AppUser?> checkAuthState();
}
