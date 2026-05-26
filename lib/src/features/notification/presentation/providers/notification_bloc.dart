import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';

// --- Events ---
abstract class NotificationEvent extends Equatable {
  const NotificationEvent();
  @override
  List<Object?> get props => [];
}

class LoadNotifications extends NotificationEvent {
  final String? type; // optional filter
  const LoadNotifications({this.type});
  @override
  List<Object?> get props => [type];
}

class NotificationAdded extends NotificationEvent {
  final AppNotification notification;
  const NotificationAdded(this.notification);
  @override
  List<Object?> get props => [notification];
}

class MarkNotificationAsRead extends NotificationEvent {
  final String notificationId;
  const MarkNotificationAsRead(this.notificationId);
  @override
  List<Object?> get props => [notificationId];
}

class MarkAllNotificationsAsRead extends NotificationEvent {}

// --- State ---
class NotificationState extends Equatable {
  final bool isLoading;
  final List<AppNotification> notifications;
  final String? error;
  final String? filterType; // 'All', 'Activity', etc.

  const NotificationState({
    this.isLoading = false,
    this.notifications = const [],
    this.error,
    this.filterType,
  });

  NotificationState copyWith({
    bool? isLoading,
    List<AppNotification>? notifications,
    String? error,
    String? filterType,
    bool clearError = false,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
      error: clearError ? null : (error ?? this.error),
      filterType: filterType ?? this.filterType,
    );
  }

  @override
  List<Object?> get props => [isLoading, notifications, error, filterType];
}

// --- BLoC ---
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc() : super(const NotificationState()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<MarkNotificationAsRead>(_onMarkAsRead);
    on<MarkAllNotificationsAsRead>(_onMarkAllAsRead);
    on<NotificationAdded>(_onNotificationAdded);
  }

  void _onNotificationAdded(
    NotificationAdded event,
    Emitter<NotificationState> emit,
  ) {
    if (state.notifications
        .any((element) => element.id == event.notification.id)) {
      return;
    }
    final updatedList = [event.notification, ...state.notifications];
    emit(state.copyWith(
      notifications: updatedList,
    ));
  }

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(
        isLoading: true, filterType: event.type, clearError: true));

    final typeParam =
        (event.type != null && event.type != 'All') ? event.type : null;
    final result =
        await NotificationsService.instance.getNotifications(type: typeParam);

    result.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, error: failure.message)),
      (data) {
        final List<AppNotification> notifs = (data)
            .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
            .toList();
        emit(state.copyWith(isLoading: false, notifications: notifs));
      },
    );
  }

  Future<void> _onMarkAsRead(
    MarkNotificationAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    // Optimistic update
    final updated = state.notifications.map((n) {
      if (n.id == event.notificationId) return n.copyWith(isRead: true);
      return n;
    }).toList();
    emit(state.copyWith(notifications: updated));

    // API call
    final result =
        await NotificationsService.instance.markAsRead(event.notificationId);
    result.fold(
      (failure) {
        // Rollback on failure (for simplicity here, we could just log it)
      },
      (_) {},
    );
  }

  Future<void> _onMarkAllAsRead(
    MarkAllNotificationsAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    // Optimistic update
    final updated =
        state.notifications.map((n) => n.copyWith(isRead: true)).toList();
    emit(state.copyWith(notifications: updated));

    // API call
    final result = await NotificationsService.instance.markAllAsRead();
    result.fold(
      (failure) {
        showGlobalToast(message: failure.message, status: 'error');
      },
      (_) {},
    );
  }
}
