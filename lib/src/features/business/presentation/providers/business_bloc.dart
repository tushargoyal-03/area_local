import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';

// --- Events ---
abstract class BusinessEvent extends Equatable {
  const BusinessEvent();
  @override
  List<Object?> get props => [];
}

class LoadNearbyPromotions extends BusinessEvent {
  const LoadNearbyPromotions();
}

class LoadMyPromotions extends BusinessEvent {}

class LoadSavedPromotions extends BusinessEvent {}

class CreatePromotionRequested extends BusinessEvent {
  final String businessName;
  final String title;
  final String description;
  final List<double> coordinates;
  final String? discountCode;
  final String? expiryDate;
  final List<String> mediaUrls;

  const CreatePromotionRequested({
    required this.businessName,
    required this.title,
    required this.description,
    required this.coordinates,
    this.discountCode,
    this.expiryDate,
    this.mediaUrls = const [],
  });

  @override
  List<Object?> get props => [
        businessName,
        title,
        description,
        coordinates,
        discountCode,
        expiryDate,
        mediaUrls
      ];
}

// --- State ---
class BusinessState extends Equatable {
  final bool isLoadingNearby;
  final bool isLoadingMine;
  final bool isLoadingSaved;
  final bool isCreating;
  final List<dynamic> nearbyPromotions;
  final List<dynamic> myPromotions;
  final List<dynamic> savedPromotions;
  final String? error;
  final bool createSuccess;

  const BusinessState({
    this.isLoadingNearby = false,
    this.isLoadingMine = false,
    this.isLoadingSaved = false,
    this.isCreating = false,
    this.nearbyPromotions = const [],
    this.myPromotions = const [],
    this.savedPromotions = const [],
    this.error,
    this.createSuccess = false,
  });

  BusinessState copyWith({
    bool? isLoadingNearby,
    bool? isLoadingMine,
    bool? isLoadingSaved,
    bool? isCreating,
    List<dynamic>? nearbyPromotions,
    List<dynamic>? myPromotions,
    List<dynamic>? savedPromotions,
    String? error,
    bool? createSuccess,
    bool clearError = false,
  }) {
    return BusinessState(
      isLoadingNearby: isLoadingNearby ?? this.isLoadingNearby,
      isLoadingMine: isLoadingMine ?? this.isLoadingMine,
      isLoadingSaved: isLoadingSaved ?? this.isLoadingSaved,
      isCreating: isCreating ?? this.isCreating,
      nearbyPromotions: nearbyPromotions ?? this.nearbyPromotions,
      myPromotions: myPromotions ?? this.myPromotions,
      savedPromotions: savedPromotions ?? this.savedPromotions,
      error: clearError ? null : (error ?? this.error),
      createSuccess: createSuccess ?? this.createSuccess,
    );
  }

  @override
  List<Object?> get props => [
        isLoadingNearby,
        isLoadingMine,
        isLoadingSaved,
        isCreating,
        nearbyPromotions,
        myPromotions,
        savedPromotions,
        error,
        createSuccess,
      ];
}

// --- Bloc ---
class BusinessBloc extends Bloc<BusinessEvent, BusinessState> {
  BusinessBloc() : super(const BusinessState()) {
    on<LoadNearbyPromotions>(_onLoadNearby);
    on<LoadMyPromotions>(_onLoadMine);
    on<LoadSavedPromotions>(_onLoadSaved);
    on<CreatePromotionRequested>(_onCreatePromotion);
  }

  Future<void> _onLoadNearby(
    LoadNearbyPromotions event,
    Emitter<BusinessState> emit,
  ) async {
    emit(state.copyWith(isLoadingNearby: true, clearError: true));
    final result = await BusinessService.instance.getNearbyPromotions();

    result.fold(
      (failure) =>
          emit(state.copyWith(isLoadingNearby: false, error: failure.message)),
      (promotions) => emit(
          state.copyWith(isLoadingNearby: false, nearbyPromotions: promotions)),
    );
  }

  Future<void> _onLoadMine(
    LoadMyPromotions event,
    Emitter<BusinessState> emit,
  ) async {
    emit(state.copyWith(isLoadingMine: true, clearError: true));
    final result = await BusinessService.instance.getMyPromotions();

    result.fold(
      (failure) =>
          emit(state.copyWith(isLoadingMine: false, error: failure.message)),
      (promotions) =>
          emit(state.copyWith(isLoadingMine: false, myPromotions: promotions)),
    );
  }

  Future<void> _onLoadSaved(
    LoadSavedPromotions event,
    Emitter<BusinessState> emit,
  ) async {
    emit(state.copyWith(isLoadingSaved: true, clearError: true));
    final result = await BusinessService.instance.getSavedPromotions();

    result.fold(
      (failure) =>
          emit(state.copyWith(isLoadingSaved: false, error: failure.message)),
      (promotions) => emit(
          state.copyWith(isLoadingSaved: false, savedPromotions: promotions)),
    );
  }

  Future<void> _onCreatePromotion(
    CreatePromotionRequested event,
    Emitter<BusinessState> emit,
  ) async {
    emit(state.copyWith(
        isCreating: true, createSuccess: false, clearError: true));
    final result = await BusinessService.instance.createPromotion(
      businessName: event.businessName,
      title: event.title,
      description: event.description,
      coordinates: event.coordinates,
      discountCode: event.discountCode,
      expiryDate: event.expiryDate,
      mediaUrls: event.mediaUrls,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(isCreating: false, error: failure.message));
        showGlobalToast(message: failure.message, status: 'error');
      },
      (newPromotion) {
        emit(state.copyWith(
          isCreating: false,
          createSuccess: true,
          myPromotions: [newPromotion, ...state.myPromotions],
        ));
        showGlobalToast(
            message: 'Promotion created successfully!', status: 'success');
      },
    );
  }
}
