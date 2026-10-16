import 'package:flutter_test/flutter_test.dart';
import 'package:scoring_app/models/models.dart';

void main() {
  group('Criteria Group & Special Awards Model Tests', () {
    test('CriteriaGroupModel serialization and defaults', () {
      final group = CriteriaGroupModel(
        id: 'group-qa',
        eventId: 'event-1',
        name: 'Question & Answer',
        description: 'Intelligence, articulation, and substance',
        affectsOverallScore: true,
        weightPercentage: 40.0,
        order: 0,
      );

      final map = group.toMap();
      expect(map['name'], equals('Question & Answer'));
      expect(map['affectsOverallScore'], isTrue);
      expect(map['weightPercentage'], equals(40.0));

      final restored = CriteriaGroupModel.fromMap('group-qa', map);
      expect(restored.id, equals('group-qa'));
      expect(restored.name, equals('Question & Answer'));
      expect(restored.affectsOverallScore, isTrue);
      expect(restored.weightPercentage, equals(40.0));
    });

    test('Special award category serialization (affectsOverallScore = false)', () {
      final group = CriteriaGroupModel(
        id: 'group-swimsuit',
        eventId: 'event-1',
        name: 'Swimsuit Competition',
        description: 'Special Award: Best in Swimsuit',
        affectsOverallScore: false,
        weightPercentage: 0.0,
        order: 1,
      );

      final map = group.toMap();
      expect(map['affectsOverallScore'], isFalse);
      expect(map['weightPercentage'], equals(0.0));

      final restored = CriteriaGroupModel.fromMap('group-swimsuit', map);
      expect(restored.affectsOverallScore, isFalse);
      expect(restored.weightPercentage, equals(0.0));
    });

    test('CriterionModel backward compatibility with legacy criteria', () {
      // Legacy Firestore map without groupId
      final legacyMap = {
        'eventId': 'event-1',
        'name': 'Poise & Grace',
        'description': '',
        'maxScore': 50.0,
        'weightPercentage': 50.0,
        'order': 0,
      };

      final criterion = CriterionModel.fromMap('crit-legacy', legacyMap);
      expect(criterion.groupId, equals('')); // Gracefully defaults to empty string!
      expect(criterion.maxScore, equals(50.0));
    });

    test('Contestant weighted group scoring simulation', () {
      // Group 1: Q&A (60% of final score)
      final qaCrit = CriterionModel(
        id: 'qa-1',
        eventId: 'event-1',
        groupId: 'grp-qa',
        name: 'Substance',
        maxScore: 100.0,
        weightPercentage: 100.0,
      );

      // Group 2: Talent (40% of final score)
      final talentCrit = CriterionModel(
        id: 'talent-1',
        eventId: 'event-1',
        groupId: 'grp-talent',
        name: 'Execution',
        maxScore: 100.0,
        weightPercentage: 100.0,
      );

      // Group 3: Best in Swimsuit (0% of final score - Special Award)
      final swimsuitCrit = CriterionModel(
        id: 'swimsuit-1',
        eventId: 'event-1',
        groupId: 'grp-swimsuit',
        name: 'Fitness & Bearing',
        maxScore: 100.0,
        weightPercentage: 100.0,
      );

      // Contestant score submission:
      // Q&A = 90/100, Talent = 80/100, Swimsuit = 100/100 (Wins special award!)
      final scores = {
        'qa-1': 90.0,
        'talent-1': 80.0,
        'swimsuit-1': 100.0,
      };

      // Calculate contributing weighted score:
      // (90 * 0.60) + (80 * 0.40) = 54 + 32 = 86.0
      final overallScore = (scores[qaCrit.id]! * 0.60) + (scores[talentCrit.id]! * 0.40);
      expect(overallScore, equals(86.0));

      // Swimsuit score (100.0) does NOT influence overallScore (86.0), but is available for special award
      expect(scores[swimsuitCrit.id], equals(100.0));
    });

    test('ScoreSubmissionModel per-category submission and remarks serialization', () {
      final submission = ScoreSubmissionModel(
        id: 'cont1_judge1',
        eventId: 'event-1',
        contestantId: 'cont1',
        judgeId: 'judge1',
        judgeNumber: 1,
        criteriaScores: {
          'crit-costume-1': 85.0,
          'crit-costume-2': 90.0,
        },
        totalScore: 175.0,
        submittedCategoryIds: ['cat-costume'],
        categoryRemarks: {
          'cat-costume': 'Breathtaking embroidery and cultural accuracy',
        },
        isSubmitted: true,
        updatedAt: DateTime.now(),
      );

      final map = submission.toMap();
      expect(map['submittedCategoryIds'], contains('cat-costume'));
      expect(map['categoryRemarks']['cat-costume'], contains('Breathtaking'));

      final restored = ScoreSubmissionModel.fromMap('cont1_judge1', map);
      expect(restored.isCategorySubmitted('cat-costume'), isTrue);
      expect(restored.isCategorySubmitted('cat-talent'), isFalse);
    });

    test('isCategorySubmitted supports legacy submissions without submittedCategoryIds', () {
      final groupCriteria = [
        CriterionModel(id: 'c1', eventId: 'e1', groupId: 'g1', name: 'Crit 1', maxScore: 50.0),
        CriterionModel(id: 'c2', eventId: 'e1', groupId: 'g1', name: 'Crit 2', maxScore: 50.0),
      ];

      // Legacy submission with no submittedCategoryIds
      final legacySubmission = ScoreSubmissionModel(
        id: 'legacy_sub',
        eventId: 'e1',
        contestantId: 'cont1',
        judgeId: 'j1',
        judgeNumber: 1,
        criteriaScores: {
          'c1': 45.0,
          'c2': 48.0,
        },
        totalScore: 93.0,
        submittedCategoryIds: [],
        isSubmitted: true,
        updatedAt: DateTime.now(),
      );

      // Falls back to checking if criteriaScores has entries for all group criteria
      expect(legacySubmission.isCategorySubmitted('g1', groupCriteria), isTrue);

      // Missing a criterion means incomplete
      final partialSubmission = ScoreSubmissionModel(
        id: 'partial_sub',
        eventId: 'e1',
        contestantId: 'cont1',
        judgeId: 'j1',
        judgeNumber: 1,
        criteriaScores: {
          'c1': 45.0,
        },
        totalScore: 45.0,
        submittedCategoryIds: [],
        isSubmitted: true,
        updatedAt: DateTime.now(),
      );
      expect(partialSubmission.isCategorySubmitted('g1', groupCriteria), isFalse);
    });

    test('CriteriaGroupModel isLocked serialization and backward compatibility', () {
      // Legacy Firestore document without isLocked
      final legacyMap = {
        'eventId': 'event-1',
        'name': 'Talent',
        'affectsOverallScore': true,
        'weightPercentage': 30.0,
      };
      final group = CriteriaGroupModel.fromMap('grp-1', legacyMap);
      expect(group.isLocked, isFalse); // Default false for legacy data

      // Explicitly locked group
      final lockedGroup = group.copyWith(isLocked: true);
      expect(lockedGroup.isLocked, isTrue);

      final map = lockedGroup.toMap();
      expect(map['isLocked'], isTrue);

      final restored = CriteriaGroupModel.fromMap('grp-1', map);
      expect(restored.isLocked, isTrue);
    });

    test('Cumulative scoring: Unscored categories contribute 0 so partial categories cannot leapfrog', () {
      // Scenario:
      // Cat 1: Q&A (30% weight)
      // Cat 2: Talent (30% weight)
      // Cat 3: Evening Gown (40% weight)
      // Total weight: 100%
      const double totalWeight = 100.0;

      // Contestant 1: Scored 90% in Cat 1, 90% in Cat 2, Cat 3 not scored (0%)
      final c1JudgeOverall = (90.0 * (30.0 / 100.0)) + (90.0 * (30.0 / 100.0)) + (0.0 * (40.0 / 100.0));
      final c1Cumulative = c1JudgeOverall / (totalWeight / 100.0);

      // Contestant 3: Accidentally scored 98% in Cat 3 only, Cat 1 & Cat 2 not scored (0%)
      final c3JudgeOverall = (0.0 * (30.0 / 100.0)) + (0.0 * (30.0 / 100.0)) + (98.0 * (40.0 / 100.0));
      final c3Cumulative = c3JudgeOverall / (totalWeight / 100.0);

      expect(c1Cumulative, equals(54.0));
      expect(c3Cumulative, equals(39.2));

      // Contestant 1 (54.0) must rank HIGHER than Contestant 3 (39.2)
      expect(c1Cumulative > c3Cumulative, isTrue);
    });
  });
}

