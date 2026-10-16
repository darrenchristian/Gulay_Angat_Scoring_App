import 'package:flutter_test/flutter_test.dart';
import 'package:scoring_app/models/models.dart';

void main() {
  group('Contestant Elimination Tests', () {
    test('ContestantModel default isEliminated is false', () {
      final contestant = ContestantModel(
        id: 'c1',
        eventId: 'event-1',
        number: 1,
        name: 'Maria Clara',
        representation: 'Barangay 1',
      );

      expect(contestant.isEliminated, isFalse);
    });

    test('ContestantModel backward compatibility with legacy Firestore data', () {
      // Legacy Firestore map without 'isEliminated'
      final legacyMap = {
        'eventId': 'event-1',
        'number': 2,
        'name': 'Juan dela Cruz',
        'representation': 'Barangay 2',
        'bio': 'Test bio',
      };

      final contestant = ContestantModel.fromMap('c2', legacyMap);
      expect(contestant.id, equals('c2'));
      expect(contestant.name, equals('Juan dela Cruz'));
      expect(contestant.isEliminated, isFalse);
    });

    test('ContestantModel serialization with isEliminated true', () {
      final contestant = ContestantModel(
        id: 'c3',
        eventId: 'event-1',
        number: 3,
        name: 'Jane Doe',
        representation: 'District 3',
        isEliminated: true,
      );

      final map = contestant.toMap();
      expect(map['isEliminated'], isTrue);

      final restored = ContestantModel.fromMap('c3', map);
      expect(restored.id, equals('c3'));
      expect(restored.isEliminated, isTrue);
    });

    test('ContestantModel copyWith isEliminated toggle', () {
      final contestant = ContestantModel(
        id: 'c4',
        eventId: 'event-1',
        number: 4,
        name: 'Alex Smith',
        representation: 'District 4',
      );

      expect(contestant.isEliminated, isFalse);

      final eliminated = contestant.copyWith(isEliminated: true);
      expect(eliminated.isEliminated, isTrue);
      expect(eliminated.name, equals('Alex Smith'));

      final reactivated = eliminated.copyWith(isEliminated: false);
      expect(reactivated.isEliminated, isFalse);
    });

    test('Sorting logic places active contestants first and eliminated at bottom', () {
      final c1 = ContestantModel(
        id: 'c1',
        eventId: 'event-1',
        number: 1,
        name: 'Contestant 1',
        representation: 'R1',
        isEliminated: true, // eliminated #1
      );
      final c2 = ContestantModel(
        id: 'c2',
        eventId: 'event-1',
        number: 2,
        name: 'Contestant 2',
        representation: 'R2',
        isEliminated: false, // active #2
      );
      final c3 = ContestantModel(
        id: 'c3',
        eventId: 'event-1',
        number: 3,
        name: 'Contestant 3',
        representation: 'R3',
        isEliminated: false, // active #3
      );
      final c4 = ContestantModel(
        id: 'c4',
        eventId: 'event-1',
        number: 4,
        name: 'Contestant 4',
        representation: 'R4',
        isEliminated: true, // eliminated #4
      );

      final list = [c1, c2, c3, c4];
      final sorted = List<ContestantModel>.from(list)
        ..sort((a, b) {
          if (a.isEliminated != b.isEliminated) {
            return a.isEliminated ? 1 : -1;
          }
          return a.number.compareTo(b.number);
        });

      // Active contestants first (#2, #3), eliminated at bottom (#1, #4)
      expect(sorted[0].id, equals('c2'));
      expect(sorted[0].isEliminated, isFalse);
      expect(sorted[1].id, equals('c3'));
      expect(sorted[1].isEliminated, isFalse);
      expect(sorted[2].id, equals('c1'));
      expect(sorted[2].isEliminated, isTrue);
      expect(sorted[3].id, equals('c4'));
      expect(sorted[3].isEliminated, isTrue);
    });
  });
}
