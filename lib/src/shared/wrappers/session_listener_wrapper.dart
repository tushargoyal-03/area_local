import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';

class SessionListenerWrapper extends StatefulWidget {
  final Widget child;
  const SessionListenerWrapper({super.key, required this.child});

  @override
  State<SessionListenerWrapper> createState() => _SessionListenerWrapperState();
}

class _SessionListenerWrapperState extends State<SessionListenerWrapper> {
  bool _isFirstLoad = true;

  @override
  void dispose() {
    PresenceManager.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SessionBloc, SessionState>(
      listenWhen: (prev, next) => prev.status != next.status,
      listener: (context, state) {
        if (state.status != SessionStatus.unknown) {
          FlutterNativeSplash.remove();

          if (state.status == SessionStatus.authenticated) {
            PresenceManager.instance.init();
          } else if (state.status == SessionStatus.unauthenticated) {
            PresenceManager.instance.dispose();
          }

          // If this is the first session load (app startup),
          // let the SplashScreen handle the navigation after its delay!
          if (_isFirstLoad) {
            _isFirstLoad = false;
            return;
          }

          if (state.status == SessionStatus.authenticated) {
            appRouter.go(AppRoutes.home);
          } else if (state.status == SessionStatus.unauthenticated) {
            appRouter.go(AppRoutes.onboarding);
          }
        }
      },
      child: widget.child,
    );
  }
}
