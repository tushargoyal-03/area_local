import '../../imports/imports.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/locality_feed/data/repositories/posts_repository_impl.dart';

import '../../features/society_feed/presentation/providers/society_feed_bloc.dart';
import '../../features/nearby_discovery/presentation/providers/nearby_discovery_bloc.dart';
import '../../features/user_profile/presentation/providers/user_profile_bloc.dart';
import '../../features/business/presentation/providers/business_bloc.dart';

/// A wrapper to initialize the chosen State Management library.
class StateWrapper extends StatelessWidget {
  final Widget child;

  const StateWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SessionBloc>(
            create: (_) => SessionBloc(repository: AuthRepositoryImpl())),
        BlocProvider<AuthBloc>(
            create: (_) => AuthBloc(repository: AuthRepositoryImpl())),
        BlocProvider<PostsBloc>(
            create: (_) => PostsBloc(repository: PostsRepositoryImpl())),
        BlocProvider<ChatBloc>(create: (_) => ChatBloc()),
        BlocProvider<NotificationBloc>(create: (_) => NotificationBloc()),
        BlocProvider<SocietyFeedBloc>(create: (_) => SocietyFeedBloc()),
        BlocProvider<NearbyDiscoveryBloc>(create: (_) => NearbyDiscoveryBloc()),
        BlocProvider<UserProfileBloc>(create: (_) => UserProfileBloc()),
        BlocProvider<BusinessBloc>(create: (_) => BusinessBloc()),
      ],
      child: child,
    );
  }
}
