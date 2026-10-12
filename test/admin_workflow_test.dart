import 'package:flutter_test/flutter_test.dart';
import 'package:scoring_app/models/models.dart';

void main() {
  group('Event & Scoring Domain Unit Tests', () {
    test('EventModel serialization and copyWith works properly', () {
      final now = DateTime.now();
      final event = EventModel(
        id: 'test-event-1',
        title: 'Singing Competition',
        description: 'Annual departmental competition',
        status: EventStatus.active,
        assignedJudgeIds: const ['j1', 'j2', 'j3'],
        createdAt: now,
      );

      final map = event.toMap();
      expect(map['title'], equals('Singing Competition'));
      expect(map['status'], equals('active'));
      expect(map['judgeCount'], equals(3));
      expect(event.effectiveJudgeCount, equals(3));

      final updated = event.copyWith(title: 'Updated Singing Competition', status: EventStatus.completed);
      expect(updated.title, equals('Updated Singing Competition'));
      expect(updated.status, equals(EventStatus.completed));
      expect(updated.id, equals(event.id));
    });

    test('CriterionModel serialization and weight percentage', () {
      final criterion = CriterionModel(
        id: 'crit-voice',
        eventId: 'test-event-1',
        name: 'Voice Quality',
        description: 'Pitch, tone, and control',
        maxScore: 40.0,
        weightPercentage: 40.0,
        order: 1,
      );

      final map = criterion.toMap();
      expect(map['name'], equals('Voice Quality'));
      expect(map['maxScore'], equals(40.0));
      expect(map['weightPercentage'], equals(40.0));
      expect(map['order'], equals(1));
    });

    test('ContestantModel serialization and ordering', () {
      final c1 = ContestantModel(
        id: 'cont-1',
        eventId: 'test-event-1',
        number: 1,
        name: 'Candidate One',
        representation: 'Engineering',
      );

      final map = c1.toMap();
      expect(map['name'], equals('Candidate One'));
      expect(map['number'], equals(1));
      expect(map['representation'], equals('Engineering'));
    });

    test('ScoreSubmissionModel deterministic ID generation and map conversion', () {
      final id = ScoreSubmissionModel.generateId(
        contestantId: 'cont-42',
        judgeId: 'judge-7',
      );
      expect(id, equals('cont-42_judge-7'));

      final submission = ScoreSubmissionModel(
        id: id,
        eventId: 'test-event-1',
        contestantId: 'cont-42',
        judgeId: 'judge-7',
        judgeNumber: 1,
        criteriaScores: {
          'crit-1': 35.0,
          'crit-2': 25.0,
        },
        totalScore: 60.0,
        remarks: 'Great vocal projection',
        isSubmitted: true,
        submittedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final map = submission.toMap();
      expect(map['totalScore'], equals(60.0));
      expect(map['isSubmitted'], isTrue);
      expect(map['criteriaScores']['crit-1'], equals(35.0));
    });
  });
}
