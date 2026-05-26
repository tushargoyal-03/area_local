import 'package:area_connect/src/features/activity_details/presentation/pages/activity_page.dart';
import 'package:area_connect/src/features/auth/presentation/screens/verify_otp_screen.dart';
import 'package:area_connect/src/features/create_activity/presentation/pages/create_actvity.dart';
import 'package:area_connect/src/features/locality_feed/presentation/pages/locality_feed_page.dart';
import 'package:area_connect/src/features/nearby_discovery/presentation/pages/nearby_discovery_screen.dart';
import 'package:area_connect/src/features/notification/presentation/pages/notification_screen.dart';
import 'package:area_connect/src/features/society_feed/presentation/pages/society_feed_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:area_connect/src/routing/global_navigator.dart';
import 'package:area_connect/src/routing/app_routes.dart';

import 'package:area_connect/src/features/auth/presentation/screens/login_screen.dart';
import 'package:area_connect/src/features/auth/presentation/screens/signup_screen.dart';
import 'package:area_connect/src/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:area_connect/src/features/auth/presentation/screens/role_selection_screen.dart';
import 'package:area_connect/src/features/home/presentation/screens/chat_room_screen.dart';

import 'package:area_connect/src/features/locality_feed/domain/entities/post.dart';

import 'package:area_connect/src/features/home/presentation/screens/home_page.dart';
import 'package:area_connect/src/features/onboarding/presentation/screens/onboarding_page.dart';

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutes.onboarding,
  routes: <RouteBase>[
    GoRoute(
      path: AppRoutes.onboarding,
      name: 'onboarding',
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(
      path: AppRoutes.login,
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.signup,
      name: 'signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      name: 'forgotPassword',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
        path: AppRoutes.verifyOtp,
        name: 'verifyOtp',
        builder: (context, state) {
          final signupId = (state.extra as String?) ?? '';
          return VerifyOtpScreen(signupId: signupId);
        }),
    GoRoute(
      path: AppRoutes.roleSelection,
      name: 'roleSelection',
      builder: (context, state) => const RoleSelectionScreen(),
    ),
    GoRoute(
      path: AppRoutes.chatRoom,
      name: 'chatRoom',
      builder: (context, state) {
        final params = state.extra as Map<String, dynamic>?;
        if (params == null) {
          // extra is null (e.g. during hot reload) — show home instead of crashing
          return const HomeDashboardScreen();
        }
        return ChatRoomScreen(
          chatId: params['chatId'] as String,
          recipientName: params['recipientName'] as String,
          recipientId: params['recipientId'] as String,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (context, state) => const HomeDashboardScreen(),
    ),
    GoRoute(
      path: AppRoutes.localityFeed,
      name: 'localityFeed',
      builder: (context, state) => const LocalityFeedPage(),
    ),
    GoRoute(
      path: AppRoutes.activity,
      name: 'activity',
      builder: (context, state) {
        final post = state.extra as AppPost?;
        if (post == null) {
          return const HomeDashboardScreen();
        }
        return ActivityDetailScreen(post: post);
      },
    ),
    GoRoute(
      path: AppRoutes.createActivity,
      name: 'createActivity',
      builder: (context, state) => const CreateActivityScreen(),
    ),
    GoRoute(
      path: AppRoutes.notification,
      name: 'notification',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: AppRoutes.nearbyDiscovery,
      name: 'nearbyDiscovery',
      builder: (context, state) => const NearbyDiscoveryScreen(),
    ),
    GoRoute(
      path: AppRoutes.societyFeed,
      name: 'societyFeed',
      builder: (context, state) => const SocietyFeedScreen(),
    ),
  ],
);
