import 'package:flutter_test/flutter_test.dart';

import 'package:area_connect/src/app.dart';

void main() {
  testWidgets('App should build', (WidgetTester tester) async {
    // Build our app and trigger a frame.

    await tester.pumpWidget(const App());

    // Verify that our base app builds successfully.
    expect(find.byType(App), findsOneWidget);
  });
}
