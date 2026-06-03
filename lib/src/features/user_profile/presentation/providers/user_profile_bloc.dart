import 'dart:io';
import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';

// --- Events ---
abstract class UserProfileEvent extends Equatable {
  const UserProfileEvent();
  @override
  List<Object?> get props => [];
}

class LoadMyProfile extends UserProfileEvent {}

class LoadPublicProfile extends UserProfileEvent {
  final String userId;
  const LoadPublicProfile(this.userId);
  @override
  List<Object?> get props => [userId];
}

class UpdateProfileRequested extends UserProfileEvent {
  final String? displayName;
  final String? avatarUrl;
  final File? avatarFile;
  final List<double>? coordinates;
  final List<String>? lookingFor;

  const UpdateProfileRequested({
    this.displayName,
    this.avatarUrl,
    this.avatarFile,
    this.coordinates,
    this.lookingFor,
  });

  @override
  List<Object?> get props =>
      [displayName, avatarUrl, avatarFile, coordinates, lookingFor];
}

class SearchUsersRequested extends UserProfileEvent {
  final String query;
  final int page;
  final int limit;

  const SearchUsersRequested({
    required this.query,
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [query, page, limit];
}

class ResetSearch extends UserProfileEvent {}

// --- State ---
class UserProfileState extends Equatable {
  final bool isLoading;
  final bool isUpdating;
  final Map<String, dynamic>? myProfile;
  final Map<String, dynamic>? currentViewedProfile;
  final List<dynamic> searchResults;
  final String? error;
  final bool updateSuccess;

  const UserProfileState({
    this.isLoading = false,
    this.isUpdating = false,
    this.myProfile,
    this.currentViewedProfile,
    this.searchResults = const [],
    this.error,
    this.updateSuccess = false,
  });

  UserProfileState copyWith({
    bool? isLoading,
    bool? isUpdating,
    Map<String, dynamic>? myProfile,
    Map<String, dynamic>? currentViewedProfile,
    List<dynamic>? searchResults,
    String? error,
    bool? updateSuccess,
    bool clearError = false,
  }) {
    return UserProfileState(
      isLoading: isLoading ?? this.isLoading,
      isUpdating: isUpdating ?? this.isUpdating,
      myProfile: myProfile ?? this.myProfile,
      currentViewedProfile: currentViewedProfile ?? this.currentViewedProfile,
      searchResults: searchResults ?? this.searchResults,
      error: clearError ? null : (error ?? this.error),
      updateSuccess: updateSuccess ?? this.updateSuccess,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isUpdating,
        myProfile,
        currentViewedProfile,
        searchResults,
        error,
        updateSuccess,
      ];
}

// --- Bloc ---
class UserProfileBloc extends Bloc<UserProfileEvent, UserProfileState> {
  UserProfileBloc() : super(const UserProfileState()) {
    on<LoadMyProfile>(_onLoadMyProfile);
    on<LoadPublicProfile>(_onLoadPublicProfile);
    on<UpdateProfileRequested>(_onUpdateProfile);
    on<SearchUsersRequested>(_onSearchUsers);
    on<ResetSearch>(_onResetSearch);
  }

  Future<void> _onLoadMyProfile(
    LoadMyProfile event,
    Emitter<UserProfileState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    final result = await UsersService.instance.getMe();

    result.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, error: failure.message)),
      (profile) => emit(state.copyWith(isLoading: false, myProfile: profile)),
    );
  }

  Future<void> _onLoadPublicProfile(
    LoadPublicProfile event,
    Emitter<UserProfileState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    final result = await UsersService.instance.getPublicProfile(event.userId);

    result.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, error: failure.message)),
      (profile) =>
          emit(state.copyWith(isLoading: false, currentViewedProfile: profile)),
    );
  }

  Future<void> _onUpdateProfile(
    UpdateProfileRequested event,
    Emitter<UserProfileState> emit,
  ) async {
    emit(state.copyWith(
        isUpdating: true, clearError: true, updateSuccess: false));

    String? avatarUrl = event.avatarUrl;

    if (event.avatarFile != null) {
      final uploadRes =
          await UsersService.instance.uploadAvatar(event.avatarFile!);
      bool uploadFailed = false;
      String? errorMsg;

      uploadRes.fold(
        (failure) {
          uploadFailed = true;
          errorMsg = failure.message;
        },
        (profile) {
          avatarUrl = profile['avatarUrl']?.toString();
        },
      );

      if (uploadFailed) {
        emit(state.copyWith(isUpdating: false, error: errorMsg));
        showGlobalToast(
            message: errorMsg ?? 'Avatar upload failed', status: 'error');
        return;
      }
    }

    final result = await UsersService.instance.updateProfile(
      displayName: event.displayName,
      avatarUrl: avatarUrl,
      coordinates: event.coordinates,
      lookingFor: event.lookingFor,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(isUpdating: false, error: failure.message));
        showGlobalToast(message: failure.message, status: 'error');
      },
      (profile) {
        emit(state.copyWith(
            isUpdating: false, myProfile: profile, updateSuccess: true));
        showGlobalToast(
            message: 'Profile updated successfully!', status: 'success');
      },
    );
  }

  Future<void> _onSearchUsers(
    SearchUsersRequested event,
    Emitter<UserProfileState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    final result = await UsersService.instance.searchUsers(
      query: event.query,
      page: event.page,
      limit: event.limit,
    );

    result.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, error: failure.message)),
      (results) =>
          emit(state.copyWith(isLoading: false, searchResults: results)),
    );
  }

  void _onResetSearch(
    ResetSearch event,
    Emitter<UserProfileState> emit,
  ) {
    emit(state.copyWith(searchResults: []));
  }
}
