import '../../imports/imports.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/locality_feed/data/repositories/posts_repository_impl.dart';

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
        BlocProvider<ChatBloc>(
            create: (_) => ChatBloc()),
      ],
      child: child,
    );
  }
}
