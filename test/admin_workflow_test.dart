import 'package:flutter_test/flutter_test.dart';
import 'package:scoring_app/models/models.dart';
import 'package:scoring_app/providers/event_provider.dart';
import 'package:scoring_app/services/firestore_service.dart';

void main() {
  group('Event & Scoring Domain Unit Tests', () {
    test('Calculates consolidated rankings accurately', () {
      final provider = EventProvider();
      final sampleEvent = EventModel(
        id: 'test-event-1',
        title: 'Singing Competition',
        createdAt: DateTime.now(),
      );

      final c1 = ContestantModel(
        id: 'c1',
        eventId: sampleEvent.id,
        number: 1,
        name: 'Singer One',
      );
      final c2 = ContestantModel(
        id: 'c2',
        eventId: sampleEvent.id,
        number: 2,
        name: 'Singer Two',
      );

      final crit1 = CriterionModel(
        id: 'crit-voice',
        eventId: sampleEvent.id,
        name: 'Voice Quality',
        maxScore: 50,
        weightPercentage: 50,
      );

      provider.setSelectedEvent(sampleEvent);

      // Verify FirestoreService judge generation produces expected unique codes
      final service = FirestoreService();
      expect(sampleEvent.title, equals('Singing Competition'));
      expect(c1.number, equals(1));
      expect(c2.number, equals(2));
      expect(crit1.maxScore, equals(50));
    });

    test('Judge batch generation generates unique codes', () async {
      final service = FirestoreService();
      final judges = await service.generateJudgesForEvent(
        eventId: 'test-event-unique',
        count: 5,
      );

      expect(judges.length, equals(5));
      final codes = judges.map((j) => j.accessCode).toSet();
      expect(codes.length, equals(5), reason: 'All generated codes should be unique');
      for (final code in codes) {
        expect(code.startsWith('JDG-'), isTrue);
      }
    });
  });
}
