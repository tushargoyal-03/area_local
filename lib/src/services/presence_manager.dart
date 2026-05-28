import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:area_connect/src/services/chat_service.dart';

class PresenceManager with WidgetsBindingObserver {
  PresenceManager._();
  static final PresenceManager instance = PresenceManager._();

  final ChatService _chatService = ChatService.instance;

  Timer? _idleTimer;
  bool _isOnline = false;
  bool _isInitialized = false;

  // Configuration: 5 minutes idle timeout duration
  static const Duration _idleDuration = Duration(minutes: 5);

  /// Initialize and start tracking presence.
  void init() {
    if (_isInitialized) return;
    WidgetsBinding.instance.addObserver(this);
    _isInitialized = true;

    // Set initial status to online
    setOnline();
  }

  /// Stop tracking and dispose of resources.
  void dispose() {
    if (!_isInitialized) return;
    WidgetsBinding.instance.removeObserver(this);
    _idleTimer?.cancel();
    _isInitialized = false;
    _isOnline = false;
  }

  /// Explicitly mark the current user as online.
  void setOnline() {
    if (!_isInitialized) return;
    _idleTimer?.cancel();
    _startIdleTimer();

    if (!_isOnline) {
      _isOnline = true;
      _chatService.updatePresenceStatus(true);
      debugPrint('[PresenceManager] Status updated: ONLINE');
    }
  }

  /// Explicitly mark the current user as offline.
  void setOffline() {
    if (!_isInitialized) return;
    _idleTimer?.cancel();
    if (_isOnline) {
      _isOnline = false;
      _chatService.updatePresenceStatus(false);
      debugPrint('[PresenceManager] Status updated: OFFLINE');
    }
  }

  /// Resets the inactivity timer on user interaction.
  void handleUserInteraction() {
    if (!_isInitialized) return;
    if (!_isOnline) {
      setOnline();
    } else {
      _idleTimer?.cancel();
      _startIdleTimer();
    }
  }

  void _startIdleTimer() {
    _idleTimer = Timer(_idleDuration, () {
      debugPrint(
          '[PresenceManager] Idle timeout reached. Setting user offline.');
      setOffline();
    });
  }

  // --- WidgetsBindingObserver Lifecycle Hooks ---
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('[PresenceManager] App lifecycle changed to: $state');
    switch (state) {
      case AppLifecycleState.resumed:
        // App enters foreground -> set user online
        setOnline();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // App is backgrounded or terminated -> set user offline immediately
        setOffline();
        break;
      case AppLifecycleState.hidden:
        // iOS/Android specific hidden state (PIP mode or system drawer down)
        setOffline();
        break;
    }
  }
}
