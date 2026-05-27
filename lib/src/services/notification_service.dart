import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:area_connect/src/imports/imports.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize native notification plugin settings for Android and iOS
  Future<void> init() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // --- Firebase Messaging Listeners ---

    // 1. Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground message received: ${message.messageId}');
      final notification = message.notification;
      final data = message.data;
      if (notification != null) {
        final title = notification.title ?? '';
        final body = notification.body ?? '';
        final type = data['type']?.toString() ?? 'System';

        showForegroundBanner(
          title: title,
          message: body,
          type: type,
          onTap: () {
            _handleNotificationPayloadRedirect(data);
          },
        );

        showSystemNotification(
          id: message.hashCode,
          title: title,
          body: body,
          payload: jsonEncode(data),
        );
      }
    });

    // 2. Listen for clicks when the app is in the background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM message clicked from background: ${message.messageId}');
      _handleNotificationPayloadRedirect(message.data);
    });

    // 3. Check if app was opened from a terminated state via a notification
    FirebaseMessaging.instance.getInitialMessage().then((initialMessage) {
      if (initialMessage != null) {
        debugPrint(
            'FCM message clicked from terminated: ${initialMessage.messageId}');
        Future.delayed(const Duration(seconds: 1), () {
          _handleNotificationPayloadRedirect(initialMessage.data);
        });
      }
    });

    _isInitialized = true;
  }

  /// Request permissions for iOS and Android 13+
  Future<void> requestPermissions() async {
    // 1. Request local notification permissions
    final iosPlugin =
        _localNotificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // 2. Request FCM permissions explicitly
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  /// Callback when a system notification is tapped by the user
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    try {
      final Map<String, dynamic> data = jsonDecode(payload);
      _handleNotificationPayloadRedirect(data);
    } catch (e) {
      debugPrint('Error handling local notification tap: $e');
    }
  }

  /// Centralized logic to route a notification payload to the correct feature screen
  void _handleNotificationPayloadRedirect(Map<String, dynamic> data) {
    try {
      final typeStr = data['type']?.toString();
      final relatedId =
          data['relatedId']?.toString() ?? data['postId']?.toString();
      final senderName = data['senderName']?.toString();
      final senderId =
          data['senderId']?.toString() ?? data['actorId']?.toString();

      final context = rootContext;
      if (context == null) {
        debugPrint('Could not redirect: rootContext is null');
        return;
      }

      if ((typeStr == 'chat' || typeStr == 'CHAT') && relatedId != null) {
        context.push(
          AppRoutes.chatRoom,
          extra: {
            'chatId': relatedId,
            'recipientName': senderName ?? 'Neighbor',
            'recipientId': senderId ?? '',
          },
        );
      } else {
        // For Likes and Posts, redirect to notifications center
        context.push(AppRoutes.notification);
      }
    } catch (e) {
      debugPrint('Error routing notification payload: $e');
    }
  }

  /// Trigger a native platform-level system alert
  Future<void> showSystemNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await init();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'area_connect_alerts',
      'Area Connect Alerts',
      channelDescription:
          'Real-time notifications for nearby posts, likes, and chats',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.show(
      notificationDetails: platformDetails,
      id: id,
      title: title,
      body: body,
      payload: payload,
    );
  }

  /// Present a premium customized floating foreground banner that slides down
  void showForegroundBanner({
    required String title,
    required String message,
    required String type,
    required VoidCallback onTap,
  }) {
    final context = rootContext;
    if (context == null) return;

    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    late final ToastBar toast;
    toast = ToastBar(
      position: ToastPosition.top,
      autoDismiss: true,
      toastDuration: const Duration(seconds: 4),
      builder: (context) {
        return Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () {
              toast.remove();
              onTap();
            },
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cs.surfaceContainerHighest.withValues(alpha: 0.96),
                    cs.surfaceContainerLow.withValues(alpha: 0.96),
                  ],
                ),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: cs.primary.withValues(alpha: 0.15),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      type == 'chat'
                          ? IconsaxPlusBold.message
                          : type == 'like'
                              ? IconsaxPlusBold.heart
                              : IconsaxPlusBold.location,
                      size: 20.sp,
                      color: cs.primary,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: tt.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontSize: 11.5.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12.sp,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    toast.show(context);
  }

  /// Hook to connect to the active WebSockets instance and bind live events
  void setupSocketListeners(io.Socket socket, String currentUserId) {
    // 1. Live Chat Message Alerts
    socket.on('receive_message', (data) {
      if (data is! Map<String, dynamic>) return;

      final senderId = data['senderId']?.toString();
      // Ignore if user is the sender of the message
      if (senderId == currentUserId) return;

      // Realtime notification trigger for chat message.
      // Note: Triggered from ChatBloc to prevent showing alert when the chat room is active.
    });

    // 2. Live Posts Like Alerts
    socket.on('post_liked', (data) {
      if (data is! Map<String, dynamic>) return;

      final authorId = data['postAuthorId']?.toString();
      final likedBy = data['likedBy']?.toString() ?? 'Neighbor';
      final title = data['postTitle']?.toString() ?? 'your activity';
      final postId = data['postId']?.toString() ?? '';

      // Only notify if we are the author
      if (authorId == currentUserId) {
        triggerLikeNotification(
          senderName: likedBy,
          postTitle: title,
          postId: postId,
        );
      }
    });

    // 3. Live Nearby Posts Published Alerts
    socket.on('new_post_nearby', (data) {
      if (data is! Map<String, dynamic>) return;

      final authorId = data['authorId']?.toString();
      final authorName = data['authorName']?.toString() ?? 'Neighbor';
      final title = data['title']?.toString() ?? '';
      final postId = data['id']?.toString() ?? '';

      // Do not notify the person who posted it
      if (authorId != currentUserId) {
        triggerNewPostNotification(
          senderName: authorName,
          postTitle: title,
          postId: postId,
        );
      }
    });
  }

  /// Display and dispatch a Chat Message notification
  void triggerChatNotification({
    required Map<String, dynamic> message,
    required String currentUserId,
  }) {
    final senderId = message['senderId']?.toString() ?? '';
    final senderName = message['senderName']?.toString() ?? 'Neighbor';
    final text = message['text']?.toString() ?? 'Sent a message';
    final chatId = message['conversationId']?.toString() ?? '';

    if (senderId == currentUserId) return;

    final context = rootContext;
    if (context == null) return;

    final appNotif = AppNotification(
      id: message['_id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      recipientId: currentUserId,
      type: 'chat',
      title: senderName,
      message: 'Sent you a message: "$text"',
      isRead: false,
      relatedId: chatId,
      createdAt: DateTime.now().toIso8601String(),
    );

    // Dispatch globally to NotificationBloc to add in notification feed
    context.read<NotificationBloc>().add(NotificationAdded(appNotif));

    // Show top foreground banner
    showForegroundBanner(
      title: senderName,
      message: text,
      type: 'chat',
      onTap: () {
        context.push(
          AppRoutes.chatRoom,
          extra: {
            'chatId': chatId,
            'recipientName': senderName,
            'recipientId': senderId,
          },
        );
      },
    );

    // Show system notification
    showSystemNotification(
      id: chatId.hashCode,
      title: senderName,
      body: text,
      payload: jsonEncode({
        'type': 'chat',
        'relatedId': chatId,
        'senderName': senderName,
        'senderId': senderId,
      }),
    );
  }

  /// Display and dispatch a Like notification
  void triggerLikeNotification({
    required String senderName,
    required String postTitle,
    required String postId,
  }) {
    final context = rootContext;
    if (context == null) return;

    final appNotif = AppNotification(
      id: 'like_${DateTime.now().millisecondsSinceEpoch}',
      recipientId: '',
      type: 'like',
      title: senderName,
      message: 'liked your activity post "$postTitle"',
      isRead: false,
      relatedId: postId,
      createdAt: DateTime.now().toIso8601String(),
    );

    context.read<NotificationBloc>().add(NotificationAdded(appNotif));

    showForegroundBanner(
      title: 'Activity Liked',
      message: '$senderName liked your post: "$postTitle"',
      type: 'like',
      onTap: () {
        context.push(AppRoutes.notification);
      },
    );

    showSystemNotification(
      id: postId.hashCode,
      title: 'Activity Liked',
      body: '$senderName liked your post "$postTitle"',
      payload: jsonEncode({
        'type': 'like',
        'relatedId': postId,
      }),
    );
  }

  /// Display and dispatch a New Post Published notification
  void triggerNewPostNotification({
    required String senderName,
    required String postTitle,
    required String postId,
  }) {
    final context = rootContext;
    if (context == null) return;

    final appNotif = AppNotification(
      id: 'post_${DateTime.now().millisecondsSinceEpoch}',
      recipientId: '',
      type: 'System',
      title: senderName,
      message: 'created a new activity "$postTitle" near you',
      isRead: false,
      relatedId: postId,
      createdAt: DateTime.now().toIso8601String(),
    );

    context.read<NotificationBloc>().add(NotificationAdded(appNotif));

    showForegroundBanner(
      title: 'New Activity Nearby',
      message: '$senderName posted: "$postTitle"',
      type: 'System',
      onTap: () {
        context.push(AppRoutes.notification);
      },
    );

    showSystemNotification(
      id: postId.hashCode,
      title: 'New Activity Nearby',
      body: '$senderName created a new post: "$postTitle"',
      payload: jsonEncode({
        'type': 'newPost',
        'relatedId': postId,
      }),
    );
  }

  /// Request push notification permissions and register/sync the device token with NestJS backend
  Future<void> registerDeviceFCMToken() async {
    try {
      // 1. Request notification permissions from Firebase Messaging
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('FCM Notification permission denied by user.');
        return;
      }

      // 2. Fetch the registration token
      final token = await messaging.getToken();
      if (token == null) {
        debugPrint('FCM Token is null. Skipping backend registration.');
        return;
      }

      debugPrint('Retrieved FCM Token: $token');

      // 3. Fetch platform metadata
      final String platform =
          Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'web');

      // 4. Retrieve deviceId (using existing DeviceInfoService if possible)
      String? deviceId;
      final deviceRes = await DeviceInfoService.instance.getFullDeviceInfo();
      deviceRes.fold(
        (_) => null,
        (info) {
          if (Platform.isAndroid) {
            deviceId = info['id']?.toString();
          } else if (Platform.isIOS) {
            deviceId = info['identifierForVendor']?.toString();
          }
        },
      );

      // 5. Retrieve appVersion
      String? appVersion;
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        appVersion = packageInfo.version;
      } catch (e) {
        debugPrint('Failed to retrieve package/app version: $e');
      }

      // 6. Register token with backend
      final registerRes =
          await NotificationsService.instance.registerDeviceToken(
        token: token,
        platform: platform,
        deviceId: deviceId,
        appVersion: appVersion,
      );

      registerRes.fold(
        (failure) => debugPrint(
            'Failed to register device token on backend: ${failure.message}'),
        (_) =>
            debugPrint('FCM device token registered successfully on backend!'),
      );
    } catch (e) {
      debugPrint('Error registering FCM token: $e');
    }
  }

  /// Unregister/remove the FCM device token from the NestJS backend
  Future<void> removeDeviceFCMToken() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final token = await messaging.getToken();
      if (token == null) {
        debugPrint('FCM Token is null. Skipping backend removal.');
        return;
      }

      // 1. Remove from backend
      final removeRes =
          await NotificationsService.instance.removeDeviceToken(token);
      removeRes.fold(
        (failure) => debugPrint(
            'Failed to remove device token from backend: ${failure.message}'),
        (_) =>
            debugPrint('FCM device token removed successfully from backend!'),
      );

      // 2. Delete the token locally on device (critical for iOS)
      await messaging.deleteToken();
      debugPrint('FCM token deleted locally on device.');
    } catch (e) {
      debugPrint('Error removing FCM token: $e');
    }
  }
}
