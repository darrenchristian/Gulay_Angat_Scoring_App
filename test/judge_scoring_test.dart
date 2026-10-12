import 'package:flutter_test/flutter_test.dart';
import 'package:scoring_app/models/models.dart';

void main() {
  group('Judge Scoring & Model Tests', () {
    test('JudgeModel serialization and access code format', () {
      final judge = JudgeModel(
        id: 'judge-1',
        eventId: 'event-101',
        judgeNumber: 1,
        accessCode: 'JDG-8X2M',
        name: 'Judge #1',
        isActive: true,
        createdAt: DateTime.now(),
      );

      final map = judge.toMap();
      expect(map['accessCode'], equals('JDG-8X2M'));
      expect(map['judgeNumber'], equals(1));
      expect(map['isActive'], isTrue);
      expect(judge.accessCode.startsWith('JDG-'), isTrue);
    });

    test('Score submission total score and validation', () {
      final submission = ScoreSubmissionModel(
        id: 'cont-1_judge-1',
        eventId: 'event-101',
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

      final total = submission.criteriaScores.values.reduce((a, b) => a + b);
      expect(total, equals(90.0));
      expect(submission.isSubmitted, isTrue);
      expect(submission.remarks, equals('Outstanding performance!'));
    });
  });
}
