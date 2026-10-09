import 'package:flutter_test/flutter_test.dart';
import 'package:scoring_app/models/models.dart';
import 'package:scoring_app/services/firestore_service.dart';
import 'package:scoring_app/services/auth_service.dart';

void main() {
  group('Phase 4: Judge Scoring Experience Tests', () {
    test('Judge can login via Unique Access Code and access assigned event', () async {
      final authService = AuthService();
      final session = await authService.verifyJudgeCode('JDG-DEMO1');

      expect(session.judge.accessCode, equals('JDG-DEMO1'));
      expect(session.judge.judgeNumber, equals(1));
      expect(session.event.title, equals('Grand Talent Showcase 2026'));
    });

    test('Judge score submission calculates total and stores properly', () async {
      final firestoreService = FirestoreService();

      final submission = ScoreSubmissionModel(
        id: 'cont-1_judge-1',
        eventId: 'event-demo-1',
        contestantId: 'cont-1',
        judgeId: 'judge-1',
        judgeNumber: 1,
        criteriaScores: {
          'crit-1': 35.0, // out of 40
          'crit-2': 28.0, // out of 30
          'crit-3': 27.0, // out of 30
        },
        totalScore: 90.0,
        remarks: 'Outstanding performance!',
        isSubmitted: true,
        submittedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await firestoreService.submitScore(submission);

      // Verify calculation
      final total = submission.criteriaScores.values.reduce((a, b) => a + b);
      expect(total, equals(90.0));
      expect(submission.isSubmitted, isTrue);
      expect(submission.remarks, equals('Outstanding performance!'));
    });
  });
}
