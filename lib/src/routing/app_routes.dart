/// Centralized route path constants for GoRouter.
///
/// Use these variables instead of raw strings throughout the app.
/// Example: `context.go(AppRoutes.onboarding)` instead of `context.go('/')`.
abstract final class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String home = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String verifyOtp = '/verify-otp';
  static const String localityFeed = '/locality-feed';
  static const String activity = '/activity';
  static const String createActivity = '/create-activity';
  static const String notification = '/notification';
  static const String nearbyDiscovery = '/nearby-discovery';
  static const String societyFeed = '/society-feed';
  static const String createSociety = '/create-society';
  static const String roleSelection = '/role-selection';
  static const String chatRoom = '/chat-room';
  static const String searchUsers = '/search-users';
  static const String editProfile = '/edit-profile';
  static const String viewProfile = '/view-profile';
  static const String interestedUsers = '/activity-interested';
  static const String businessPromotions = '/business-promotions';
  static const String createPromotion = '/create-promotion';
  static const String savedOffers = '/saved-offers';
}
