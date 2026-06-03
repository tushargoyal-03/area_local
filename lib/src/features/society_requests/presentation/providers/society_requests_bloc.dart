import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';
import 'package:area_connect/src/features/society_requests/domain/entities/society_join_request.dart';

// Events
abstract class SocietyRequestsEvent extends Equatable {
  const SocietyRequestsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSocietyRequests extends SocietyRequestsEvent {
  final String societyId;
  const LoadSocietyRequests({required this.societyId});

  @override
  List<Object?> get props => [societyId];
}

class ApproveSocietyRequest extends SocietyRequestsEvent {
  final String societyId;
  final String requestId;
  const ApproveSocietyRequest({
    required this.societyId,
    required this.requestId,
  });

  @override
  List<Object?> get props => [societyId, requestId];
}

class RejectSocietyRequest extends SocietyRequestsEvent {
  final String societyId;
  final String requestId;
  const RejectSocietyRequest({
    required this.societyId,
    required this.requestId,
  });

  @override
  List<Object?> get props => [societyId, requestId];
}

// State
class SocietyRequestsState extends Equatable {
  final bool isLoading;
  final String? error;
  final List<SocietyJoinRequest> requests;

  const SocietyRequestsState({
    this.isLoading = false,
    this.error,
    this.requests = const [],
  });

  SocietyRequestsState copyWith({
    bool? isLoading,
    String? error,
    List<SocietyJoinRequest>? requests,
  }) {
    return SocietyRequestsState(
      isLoading: isLoading ?? this.isLoading,
      error:
          error, // Can reset error by passing null explicitly, handled via logic usually, but here we'll just assign it
      requests: requests ?? this.requests,
    );
  }

  @override
  List<Object?> get props => [isLoading, error, requests];
}

// BLoC
class SocietyRequestsBloc
    extends Bloc<SocietyRequestsEvent, SocietyRequestsState> {
  SocietyRequestsBloc() : super(const SocietyRequestsState()) {
    on<LoadSocietyRequests>(_onLoadRequests);
    on<ApproveSocietyRequest>(_onApproveRequest);
    on<RejectSocietyRequest>(_onRejectRequest);
  }

  Future<void> _onLoadRequests(
    LoadSocietyRequests event,
    Emitter<SocietyRequestsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    // Fetch all requests by not specifying status or specifying both
    final result = await SocietiesService.instance.getJoinRequests(
      societyId: event.societyId,
      status: 'PENDING,REJECTED,APPROVED',
    );

    result.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, error: failure.message)),
      (data) {
        final requests = data
            .map((json) =>
                SocietyJoinRequest.fromJson(json as Map<String, dynamic>))
            .toList();
        emit(state.copyWith(isLoading: false, requests: requests));
      },
    );
  }

  Future<void> _onApproveRequest(
    ApproveSocietyRequest event,
    Emitter<SocietyRequestsState> emit,
  ) async {
    final result = await SocietiesService.instance.approveJoinRequest(
      societyId: event.societyId,
      requestId: event.requestId,
    );

    result.fold(
      (failure) {
        showGlobalToast(
          message: 'Failed to approve: ${failure.message}',
          status: 'error',
        );
      },
      (data) {
        showGlobalToast(
          message: 'Request approved',
          status: 'success',
        );
        // Update local state
        final updatedRequests = state.requests.map((r) {
          if (r.id == event.requestId) {
            return SocietyJoinRequest(
              id: r.id,
              status: 'APPROVED',
              message: r.message,
              createdAt: r.createdAt,
              userId: r.userId,
              displayName: r.displayName,
              avatarUrl: r.avatarUrl,
            );
          }
          return r;
        }).toList();
        emit(state.copyWith(requests: updatedRequests));
      },
    );
  }

  Future<void> _onRejectRequest(
    RejectSocietyRequest event,
    Emitter<SocietyRequestsState> emit,
  ) async {
    final result = await SocietiesService.instance.rejectJoinRequest(
      societyId: event.societyId,
      requestId: event.requestId,
    );

    result.fold(
      (failure) {
        showGlobalToast(
          message: 'Failed to reject: ${failure.message}',
          status: 'error',
        );
      },
      (data) {
        showGlobalToast(
          message: 'Request rejected',
          status: 'success',
        );
        // Update local state
        final updatedRequests = state.requests.map((r) {
          if (r.id == event.requestId) {
            return SocietyJoinRequest(
              id: r.id,
              status: 'REJECTED',
              message: r.message,
              createdAt: r.createdAt,
              userId: r.userId,
              displayName: r.displayName,
              avatarUrl: r.avatarUrl,
            );
          }
          return r;
        }).toList();
        emit(state.copyWith(requests: updatedRequests));
      },
    );
  }
}
