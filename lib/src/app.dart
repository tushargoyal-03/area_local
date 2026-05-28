import 'package:area_connect/src/imports/core_imports.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final current = _buildMaterialApp(context);
    return ScreenUtilWrapper(child: current);
  }

  Widget _buildMaterialApp(BuildContext context) {
    return MaterialApp.router(
      title: 'area_connect',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(primaryColorHex: '#6750A4'),
      darkTheme: buildDarkTheme(primaryColorHex: '#6750A4'),
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
      builder: (context, child) {
        Widget current = child!;
        current = SkeletonWrapper(child: current);
        current = SessionListenerWrapper(child: current);
        current = Listener(
          onPointerDown: (_) =>
              PresenceManager.instance.handleUserInteraction(),
          onPointerMove: (_) =>
              PresenceManager.instance.handleUserInteraction(),
          behavior: HitTestBehavior.translucent,
          child: current,
        );
        return current;
      },
    );
  }
}
