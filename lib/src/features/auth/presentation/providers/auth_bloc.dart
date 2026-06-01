import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';

import 'package:area_connect/src/features/auth/domain/repositories/auth_repository.dart';

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
        if (event.context.mounted) {
          event.context.go(AppRoutes.home);
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
        if (event.context.mounted) {
          event.context.go(AppRoutes.verifyOtp, extra: user.email);
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
            message: 'OTP sent to your email successfully',
            status: 'success');
        if (event.context.mounted) {
          event.context.go(AppRoutes.resetPassword, extra: event.email);
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
        if (event.context.mounted) {
          event.context.go(AppRoutes.login);
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
        if (event.context.mounted) {
          event.context.read<SessionBloc>().add(SessionUserChanged(user));
          event.context.go(AppRoutes.roleSelection);
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
  final BuildContext context;
  final String email;
  final String password;
  const LoginRequested(
      {required this.context, required this.email, required this.password});
}

class SignUpRequested extends AuthEvent {
  final BuildContext context;
  final String name;
  final String email;
  final String password;
  final String role;
  final List<double> coordinates;
  const SignUpRequested({
    required this.context,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    required this.coordinates,
  });
}

class ForgotPasswordRequested extends AuthEvent {
  final BuildContext context;
  final String email;
  const ForgotPasswordRequested({required this.context, required this.email});
}

class VerifyOtpRequested extends AuthEvent {
  final BuildContext context;
  final String otp;
  final String email;
  const VerifyOtpRequested(
      {required this.context, required this.otp, required this.email});
}

class ResendOtpRequested extends AuthEvent {
  final BuildContext context;
  final String email;
  const ResendOtpRequested({required this.context, required this.email});

  @override
  List<Object> get props => [email];
}

class ResetPasswordRequested extends AuthEvent {
  final BuildContext context;
  final String email;
  final String otp;
  final String newPassword;

  const ResetPasswordRequested({
    required this.context,
    required this.email,
    required this.otp,
    required this.newPassword,
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
