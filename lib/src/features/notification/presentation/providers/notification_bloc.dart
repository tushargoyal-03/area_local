import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/notification.dart';

// --- Events ---
abstract class NotificationEvent extends Equatable {
  const NotificationEvent();
  @override
  List<Object?> get props => [];
}

class NotificationAdded extends NotificationEvent {
  final AppNotification notification;
  const NotificationAdded(this.notification);
  @override
  List<Object?> get props => [notification];
}

class MarkAllAsReadRequested extends NotificationEvent {
  const MarkAllAsReadRequested();
}

class ClearAllRequested extends NotificationEvent {
  const ClearAllRequested();
}

class ToggleReadStatusRequested extends NotificationEvent {
  final String id;
  const ToggleReadStatusRequested(this.id);
  @override
  List<Object?> get props => [id];
}

// --- States ---
class NotificationState extends Equatable {
  final List<AppNotification> notifications;
  final int unreadCount;

  const NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
  });

  NotificationState copyWith({
    List<AppNotification>? notifications,
    int? unreadCount,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  List<Object?> get props => [notifications, unreadCount];
}

// --- BLoC ---
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc() : super(_initialState()) {
    on<NotificationAdded>(_onNotificationAdded);
    on<MarkAllAsReadRequested>(_onMarkAllAsReadRequested);
    on<ClearAllRequested>(_onClearAllRequested);
    on<ToggleReadStatusRequested>(_onToggleReadStatusRequested);
  }

  static NotificationState _initialState() {
    final list = [
      AppNotification(
        id: 'init_1',
        senderId: 'riya_sharma',
        senderName: 'Riya Sharma',
        message: 'liked your activity post "Need a pickleball partner"',
        type: NotificationType.like,
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
        isRead: false,
        relatedId: 'post_pickleball',
      ),
      AppNotification(
        id: 'init_2',
        senderId: 'karan_singh',
        senderName: 'Karan Singh',
        message: 'is interested in your pickleball activity',
        type: NotificationType.like,
        timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
        isRead: false,
        relatedId: 'post_pickleball',
      ),
      AppNotification(
        id: 'init_3',
        senderId: 'meera_patel',
        senderName: 'Meera Patel',
        message: 'commented: "Joining! Bringing my friend too"',
        type: NotificationType.newPost,
        timestamp: DateTime.now().subtract(const Duration(minutes: 22)),
        isRead: false,
        relatedId: 'post_pickleball',
      ),
    ];
    return NotificationState(
      notifications: list,
      unreadCount: list.where((n) => !n.isRead).length,
    );
  }

  void _onNotificationAdded(
    NotificationAdded event,
    Emitter<NotificationState> emit,
  ) {
    // Prevent duplicates by checking if the notification id already exists
    if (state.notifications.any((element) => element.id == event.notification.id)) {
      return;
    }
    final updatedList = [event.notification, ...state.notifications];
    final newUnread = updatedList.where((n) => !n.isRead).length;
    emit(state.copyWith(
      notifications: updatedList,
      unreadCount: newUnread,
    ));
  }

  void _onMarkAllAsReadRequested(
    MarkAllAsReadRequested event,
    Emitter<NotificationState> emit,
  ) {
    final updatedList = state.notifications.map((n) => n.copyWith(isRead: true)).toList();
    emit(state.copyWith(
      notifications: updatedList,
      unreadCount: 0,
    ));
  }

  void _onClearAllRequested(
    ClearAllRequested event,
    Emitter<NotificationState> emit,
  ) {
    emit(const NotificationState());
  }

  void _onToggleReadStatusRequested(
    ToggleReadStatusRequested event,
    Emitter<NotificationState> emit,
  ) {
    final updatedList = state.notifications.map((n) {
      if (n.id == event.id) {
        return n.copyWith(isRead: !n.isRead);
      }
      return n;
    }).toList();
    final newUnread = updatedList.where((n) => !n.isRead).length;
    emit(state.copyWith(
      notifications: updatedList,
      unreadCount: newUnread,
    ));
  }
}
