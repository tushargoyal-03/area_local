import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';

import 'package:area_connect/src/app.dart';
import 'package:area_connect/src/shared/wrappers/state_wrapper.dart';

void main() {
  testWidgets('App should build', (WidgetTester tester) async {
    // Set realistic screen dimensions to prevent layout overflows in test constraints
    tester.view.physicalSize = const Size(1080, 2220);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Build our app and trigger a frame.

    await tester.pumpWidget(const StateWrapper(child: App()));

    // Verify that our base app builds successfully.
    expect(find.byType(App), findsOneWidget);

    // Settle delayed timers and navigation in SplashScreen
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  });
}
