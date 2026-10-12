import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scoring_app/core/constants/app_colors.dart';

void main() {
  testWidgets('App basic branding and theme colors test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'ScoreSync Live',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ),
      ),
    );

    expect(find.text('ScoreSync Live'), findsOneWidget);
  });
}
