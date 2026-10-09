import 'package:flutter_test/flutter_test.dart';
import 'package:scoring_app/main.dart';

void main() {
  testWidgets('App smoke test renders login portals', (WidgetTester tester) async {
    await tester.pumpWidget(const ScoringApp(firebaseReady: false));
    await tester.pumpAndSettle();
    expect(find.text('ScoreSync Live'), findsOneWidget);
    expect(find.text('Judge Login'), findsOneWidget);
    expect(find.text('Admin Login'), findsOneWidget);
  });
}
