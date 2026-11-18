import 'package:flutter_test/flutter_test.dart';
import 'package:trainx_app/main.dart';

void main() {
  testWidgets('Student App loads smoke test', (WidgetTester tester) async {
    // Build the app with loggedIn = false and trigger a frame.
    await tester.pumpWidget(const TrainXStudentApp(isLoggedIn: false));

    // Verify that the login screen elements appear.
    expect(find.text('Sign In'), findsWidgets);
  });
}
