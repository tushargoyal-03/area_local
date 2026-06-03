import 'package:area_connect/src/features/activity_details/presentation/pages/activity_page.dart';
import 'package:area_connect/src/features/activity_details/presentation/pages/interested_users_screen.dart';
import 'package:area_connect/src/features/auth/presentation/screens/verify_otp_screen.dart';
import 'package:area_connect/src/features/create_activity/presentation/pages/create_actvity.dart';
import 'package:area_connect/src/features/locality_feed/presentation/pages/locality_feed_page.dart';
import 'package:area_connect/src/features/nearby_discovery/presentation/pages/nearby_discovery_screen.dart';
import 'package:area_connect/src/features/notification/presentation/pages/notification_screen.dart';
import 'package:area_connect/src/features/society_feed/presentation/pages/society_feed_screen.dart';
import 'package:area_connect/src/features/society_feed/presentation/pages/create_society_screen.dart';
import 'package:area_connect/src/features/business/presentation/pages/business_promotions_screen.dart';
import 'package:area_connect/src/features/business/presentation/pages/create_promotion_screen.dart';
import 'package:area_connect/src/features/business/presentation/pages/saved_offers_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:area_connect/src/routing/global_navigator.dart';
import 'package:area_connect/src/routing/app_routes.dart';
import 'package:area_connect/src/features/society_requests/presentation/pages/society_requests_screen.dart';

import 'package:area_connect/src/features/auth/presentation/screens/login_screen.dart';
import 'package:area_connect/src/features/auth/presentation/screens/signup_screen.dart';
import 'package:area_connect/src/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:area_connect/src/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:area_connect/src/features/auth/presentation/screens/role_selection_screen.dart';
import 'package:area_connect/src/features/home/presentation/screens/chat_room_screen.dart';
import 'package:area_connect/src/features/home/presentation/screens/new_group_screen.dart';
import 'package:area_connect/src/features/home/presentation/screens/group_info_screen.dart';

import 'package:area_connect/src/features/locality_feed/domain/entities/post.dart';

import 'package:area_connect/src/features/home/presentation/screens/home_page.dart';
import 'package:area_connect/src/features/onboarding/presentation/screens/onboarding_page.dart';
import 'package:area_connect/src/features/user_profile/presentation/pages/search_users_screen.dart';
import 'package:area_connect/src/features/user_profile/presentation/pages/edit_profile_screen.dart';
import 'package:area_connect/src/features/user_profile/presentation/pages/view_profile_screen.dart';
import 'package:area_connect/src/features/splash/presentation/screens/splash_screen.dart';

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutes.splash,
  routes: <RouteBase>[
    GoRoute(
      path: AppRoutes.splash,
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
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
      path: AppRoutes.resetPassword,
      name: 'resetPassword',
      builder: (context, state) {
        final email = (state.extra as String?) ?? '';
        return ResetPasswordScreen(email: email);
      },
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
          conversationType: params['conversationType'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/new-group',
      name: 'newGroup',
      builder: (context, state) => const NewGroupScreen(),
    ),
    GoRoute(
      path: '/group-info',
      name: 'groupInfo',
      builder: (context, state) {
        if (state.extra == null) {
          return const HomeDashboardScreen();
        }
        final params = state.extra as Map<String, dynamic>;
        return GroupInfoScreen(
          conversationId: params['conversationId'] as String,
          groupName: params['groupName'] as String,
          groupImageUrl: params['groupImageUrl'] as String?,
          members:
              List<Map<String, dynamic>>.from(params['members'] as List? ?? []),
          currentUserId: params['currentUserId'] as String,
          isAdmin: params['isAdmin'] as bool? ?? false,
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
    GoRoute(
      path: AppRoutes.createSociety,
      name: 'createSociety',
      builder: (context, state) => const CreateSocietyScreen(),
    ),
    GoRoute(
      path: AppRoutes.businessPromotions,
      name: 'businessPromotions',
      builder: (context, state) => const BusinessPromotionsScreen(),
    ),
    GoRoute(
      path: AppRoutes.createPromotion,
      name: 'createPromotion',
      builder: (context, state) => const CreatePromotionScreen(),
    ),
    GoRoute(
      path: AppRoutes.savedOffers,
      name: 'savedOffers',
      builder: (context, state) => const SavedOffersScreen(),
    ),
    GoRoute(
      path: AppRoutes.searchUsers,
      name: 'searchUsers',
      builder: (context, state) => const SearchUsersScreen(),
    ),
    GoRoute(
      path: AppRoutes.editProfile,
      name: 'editProfile',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '${AppRoutes.viewProfile}/:id',
      name: 'viewProfile',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ViewProfileScreen(userId: id);
      },
    ),
    GoRoute(
      path: AppRoutes.interestedUsers,
      name: 'interestedUsers',
      builder: (context, state) {
        final params = state.extra as Map<String, dynamic>?;
        if (params == null) return const HomeDashboardScreen();
        return InterestedUsersScreen(
          postId: params['postId'] as String,
          postTitle: params['postTitle'] as String? ?? 'Activity',
        );
      },
    ),
    GoRoute(
      path: '/society-requests/:id',
      name: 'societyRequests',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return SocietyRequestsScreen(societyId: id);
      },
    ),
  ],
);
