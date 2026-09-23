import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_system_ios/main.dart';

// A small smoke test that verifies, your can at least load/construct its root widget
// what is smoke test? A quick, basic test that verify the core functionality of app, and that the app does not crash upon launch
void main() {
  testWidgets('MyApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(MyApp), findsOneWidget);
  });
}
// The test finishes almost immediately. Flutter disposes the widget tree, but the timer created by SplashScreen is still alive.
//  Flutter’s test framework is detecting a real lifecycle issue. ( resolve the issue by cancelling the timer in dispose )