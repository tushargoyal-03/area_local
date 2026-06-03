import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';

import 'package:area_connect/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:area_connect/src/features/auth/domain/entities/user.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;

  AuthBloc({required AuthRepository repository})
      : _repository = repository,
        super(const AuthState.initial()) {
    on<LoginRequested>(_onLoginRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<ForgotPasswordRequested>(_onForgotPasswordRequested);
    on<VerifyOtpRequested>(_onVerifyOtpRequested);
    on<ResendOtpRequested>(_onResendOtpRequested);
    on<ResetPasswordRequested>(_onResetPasswordRequested);
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final result =
        await _repository.login(email: event.email, password: event.password);

    result.fold(
      (failure) {
        emit(state.copyWith(isLoading: false));
        showGlobalToast(message: failure.message, status: 'error');
      },
      (user) {
        emit(state.copyWith(isLoading: false));
        if (event.onSuccess != null) {
          event.onSuccess!();
        }
      },
    );
  }

  Future<void> _onSignUpRequested(
    SignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final result = await _repository.signUp(
      name: event.name,
      email: event.email,
      password: event.password,
      role: event.role,
      coordinates: event.coordinates,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(isLoading: false));
        showGlobalToast(message: failure.message, status: 'error');
      },
      (user) {
        emit(state.copyWith(isLoading: false));
        if (event.onSuccess != null) {
          event.onSuccess!(user);
        }
      },
    );
  }

  Future<void> _onForgotPasswordRequested(
    ForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final result = await _repository.forgotPassword(email: event.email);

    result.fold(
      (failure) {
        emit(state.copyWith(isLoading: false));
        showGlobalToast(message: failure.message, status: 'error');
      },
      (success) {
        emit(state.copyWith(isLoading: false));
        showGlobalToast(
            message: 'OTP sent to your email successfully', status: 'success');
        if (event.onSuccess != null) {
          event.onSuccess!();
        }
      },
    );
  }

  Future<void> _onResetPasswordRequested(
    ResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final result = await _repository.resetPassword(
      email: event.email,
      otp: event.otp,
      newPassword: event.newPassword,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(isLoading: false));
        showGlobalToast(message: failure.message, status: 'error');
      },
      (_) {
        emit(state.copyWith(isLoading: false));
        showGlobalToast(
            message: 'Password reset successful. Please login.',
            status: 'success');
        if (event.onSuccess != null) {
          event.onSuccess!();
        }
      },
    );
  }

  Future<void> _onVerifyOtpRequested(
    VerifyOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final result =
        await _repository.verifyOtp(otp: event.otp, email: event.email);

    result.fold(
      (failure) {
        emit(state.copyWith(isLoading: false));
        showGlobalToast(message: failure.message, status: 'error');
      },
      (user) {
        emit(state.copyWith(isLoading: false));
        showGlobalToast(
            message: 'OTP verified successfully', status: 'success');
        if (event.onSuccess != null) {
          event.onSuccess!(user);
        }
      },
    );
  }

  Future<void> _onResendOtpRequested(
    ResendOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final result = await _repository.resendOtp(email: event.email);

    result.fold(
      (failure) {
        emit(state.copyWith(isLoading: false));
        showGlobalToast(message: failure.message, status: 'error');
      },
      (_) {
        emit(state.copyWith(isLoading: false));
        showGlobalToast(
            message: 'Verification code resent successfully',
            status: 'success');
      },
    );
  }
}

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object> get props => [];
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  final VoidCallback? onSuccess;
  const LoginRequested(
      {required this.email, required this.password, this.onSuccess});
}

class SignUpRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String role;
  final List<double> coordinates;
  final void Function(AppUser user)? onSuccess;
  const SignUpRequested({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    required this.coordinates,
    this.onSuccess,
  });
}

class ForgotPasswordRequested extends AuthEvent {
  final String email;
  final VoidCallback? onSuccess;
  const ForgotPasswordRequested({required this.email, this.onSuccess});
}

class VerifyOtpRequested extends AuthEvent {
  final String otp;
  final String email;
  final void Function(AppUser user)? onSuccess;
  const VerifyOtpRequested(
      {required this.otp, required this.email, this.onSuccess});
}

class ResendOtpRequested extends AuthEvent {
  final String email;
  const ResendOtpRequested({required this.email});

  @override
  List<Object> get props => [email];
}

class ResetPasswordRequested extends AuthEvent {
  final String email;
  final String otp;
  final String newPassword;
  final VoidCallback? onSuccess;

  const ResetPasswordRequested({
    required this.email,
    required this.otp,
    required this.newPassword,
    this.onSuccess,
  });

  @override
  List<Object> get props => [email, otp, newPassword];
}

class AuthState extends Equatable {
  final bool isLoading;
  const AuthState({required this.isLoading});
  const AuthState.initial() : isLoading = false;
  AuthState copyWith({bool? isLoading}) {
    return AuthState(isLoading: isLoading ?? this.isLoading);
  }

  @override
  List<Object?> get props => [isLoading];
}
