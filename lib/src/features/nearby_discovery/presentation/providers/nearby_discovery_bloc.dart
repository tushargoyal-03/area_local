import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';

// --- Events ---
abstract class NearbyDiscoveryEvent extends Equatable {
  const NearbyDiscoveryEvent();
  @override
  List<Object?> get props => [];
}

class LoadNearbyNeighbors extends NearbyDiscoveryEvent {
  const LoadNearbyNeighbors();
}

class SayHiToNeighbor extends NearbyDiscoveryEvent {
  final String recipientId;
  const SayHiToNeighbor(this.recipientId);
  @override
  List<Object?> get props => [recipientId];
}

// --- State ---
class NearbyDiscoveryState extends Equatable {
  final bool isLoading;
  final List<dynamic> neighbors;
  final String? error;

  const NearbyDiscoveryState({
    this.isLoading = false,
    this.neighbors = const [],
    this.error,
  });

  NearbyDiscoveryState copyWith({
    bool? isLoading,
    List<dynamic>? neighbors,
    String? error,
    bool clearError = false,
  }) {
    return NearbyDiscoveryState(
      isLoading: isLoading ?? this.isLoading,
      neighbors: neighbors ?? this.neighbors,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [isLoading, neighbors, error];
}

// --- BLoC ---
class NearbyDiscoveryBloc
    extends Bloc<NearbyDiscoveryEvent, NearbyDiscoveryState> {
  NearbyDiscoveryBloc() : super(const NearbyDiscoveryState()) {
    on<LoadNearbyNeighbors>(_onLoadNearby);
    on<SayHiToNeighbor>(_onSayHi);
  }

  Future<void> _onLoadNearby(
    LoadNearbyNeighbors event,
    Emitter<NearbyDiscoveryState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await UsersService.instance.getNearbyUsers();

    result.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, error: failure.message)),
      (data) {
        emit(state.copyWith(isLoading: false, neighbors: data));
      },
    );
  }

  Future<void> _onSayHi(
    SayHiToNeighbor event,
    Emitter<NearbyDiscoveryState> emit,
  ) async {
    final result = await ChatService.instance.sayHi(event.recipientId);

    result.fold(
      (failure) {
        showGlobalToast(message: failure.message, status: 'error');
      },
      (data) {
        showGlobalToast(message: 'Wave sent! 👋', status: 'success');
        // A future navigation to chat screen could be triggered here via a listener
      },
    );
  }
}
