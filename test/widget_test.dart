import 'package:flutter_test/flutter_test.dart';
import 'package:scoring_app/main.dart';

void main() {
  testWidgets('App smoke test renders navigation root or pending screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ScoringApp(firebaseReady: false));
    expect(find.text('Firebase Connection Pending'), findsOneWidget);
  });
}
