import 'dart:async';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/firestore_service.dart';

class ContestantRankResult {
  final ContestantModel contestant;
  final double averageScore;
  final double totalScore;
  final int submittedJudgeCount;
  final int rank;
  final Map<String, double> perJudgeScores; // judgeId -> score
  final Map<String, double> perCriteriaAverages; // criterionId -> average
  final Map<String, double> perGroupAverages; // groupId -> group average score
  final Map<String, int> perGroupJudgeCounts; // groupId -> number of judges who scored this group
  final int scoredCategoryCount; // number of contributing categories with at least 1 judge submission

  ContestantRankResult({
    required this.contestant,
    required this.averageScore,
    required this.totalScore,
    required this.submittedJudgeCount,
    required this.rank,
    required this.perJudgeScores,
    required this.perCriteriaAverages,
    this.perGroupAverages = const {},
    this.perGroupJudgeCounts = const {},
    this.scoredCategoryCount = 0,
  });
}

class EventProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  EventModel? _selectedEvent;
  List<CriteriaGroupModel> _criteriaGroups = [];
  List<CriterionModel> _criteria = [];
  List<ContestantModel> _contestants = [];
  List<JudgeModel> _judges = [];
  List<ScoreSubmissionModel> _scores = [];
  bool _hasLoadedJudges = false;

  StreamSubscription? _eventSub;
  StreamSubscription? _criteriaGroupsSub;
  StreamSubscription? _criteriaSub;
  StreamSubscription? _contestantsSub;
  StreamSubscription? _judgesSub;
  StreamSubscription? _scoresSub;

  EventModel? get selectedEvent => _selectedEvent;
  List<CriteriaGroupModel> get criteriaGroups => _criteriaGroups;
  List<CriterionModel> get criteria => _criteria;
  List<ContestantModel> get contestants => _contestants;
  List<JudgeModel> get judges => _judges;
  List<ScoreSubmissionModel> get scores => _scores;

  void setSelectedEvent(EventModel? event) {
    _selectedEvent = event;
    _cancelSubscriptions();
    _criteriaGroups = [];
    _criteria = [];
    _contestants = [];
    _judges = [];
    _scores = [];
    _hasLoadedJudges = false;

    if (event != null) {
      _listenToEventData(event.id);
    }
    notifyListeners();
  }

  void _listenToEventData(String eventId) {
    _eventSub = _firestoreService.getEventStream(eventId).listen((ev) {
      if (ev != null) {
        _selectedEvent = ev;
        _cleanupOrphanedScoresIfNeeded(eventId);
        notifyListeners();
      }
    });

    _criteriaGroupsSub = _firestoreService.getCriteriaGroupsStream(eventId).listen((groups) {
      _criteriaGroups = groups;
      notifyListeners();
    });

    _criteriaSub = _firestoreService.getCriteriaStream(eventId).listen((data) {
      _criteria = data;
      notifyListeners();
    });

    _contestantsSub = _firestoreService.getContestantsStream(eventId).listen((data) {
      _contestants = data;
      notifyListeners();
    });

    _judgesSub = _firestoreService.getJudgesStream(eventId).listen((data) {
      _judges = data;
      _hasLoadedJudges = true;
      _cleanupOrphanedScoresIfNeeded(eventId);
      notifyListeners();
    });

    _scoresSub = _firestoreService.getScoresStream(eventId).listen((data) {
      _scores = data;
      _cleanupOrphanedScoresIfNeeded(eventId);
      notifyListeners();
    });
  }

  bool _isScoreValidForEvent(ScoreSubmissionModel score) {
    final ev = _selectedEvent;
    if (ev == null) return true;
    return ev.isScoreValidAfterReset(
      score,
      judgeId: score.judgeId,
      submittedAt: score.submittedAt,
      updatedAt: score.updatedAt,
    );
  }

  void _cleanupOrphanedScoresIfNeeded(String eventId) {
    if (!_hasLoadedJudges || _scores.isEmpty) {
      return;
    }
    final validJudgeIds = _judges.map((j) => j.id).toSet();
    final orphanedOrStale = _scores
        .where((s) =>
            !validJudgeIds.contains(s.judgeId) || !_isScoreValidForEvent(s))
        .toList();
    if (orphanedOrStale.isNotEmpty) {
      _firestoreService.deleteScoresByIds(
        eventId,
        orphanedOrStale.map((s) => s.id).toList(),
      );
    }
  }

  void _cancelSubscriptions() {
    _eventSub?.cancel();
    _criteriaGroupsSub?.cancel();
    _criteriaSub?.cancel();
    _contestantsSub?.cancel();
    _judgesSub?.cancel();
    _scoresSub?.cancel();
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }

  /// Calculates a single judge's score for a specific criteria group.
  /// Standardized to a 100-point scale based on criteria weight percentages within the group.
  static double calculateJudgeGroupScore(
    ScoreSubmissionModel sub,
    List<CriterionModel> groupCriteria,
  ) {
    if (groupCriteria.isEmpty) return 0.0;

    double totalWeight = 0.0;
    double weightedSum = 0.0;
    for (final c in groupCriteria) {
      final scoreVal = sub.criteriaScores[c.id] ?? 0.0;
      final max = c.maxScore > 0 ? c.maxScore : 100.0;
      final pct = (scoreVal / max) * 100.0;
      weightedSum += pct * (c.weightPercentage / 100.0);
      totalWeight += c.weightPercentage;
    }

    if (totalWeight > 0) {
      // Normalize to 100 if weights inside group sum to e.g. 100
      return double.parse(((weightedSum / totalWeight) * 100.0).toStringAsFixed(2));
    } else {
      // Fallback: simple average if no weights are defined yet
      double sum = 0.0;
      for (final c in groupCriteria) {
        final scoreVal = sub.criteriaScores[c.id] ?? 0.0;
        final max = c.maxScore > 0 ? c.maxScore : 100.0;
        sum += (scoreVal / max) * 100.0;
      }
      return double.parse((sum / groupCriteria.length).toStringAsFixed(2));
    }
  }

  double _calculateJudgeGroupScore(
    ScoreSubmissionModel sub,
    List<CriterionModel> groupCriteria,
  ) =>
      calculateJudgeGroupScore(sub, groupCriteria);

  // ------------------ OVERALL LEADERBOARD ------------------ //
  /// Returns the Overall Event Leaderboard.
  /// If criteria groups exist and have groups set to affect overall score,
  /// it weights group scores by group weight percentage.
  /// Otherwise, falls back to legacy sum/average of criteria scores.
  List<ContestantRankResult> getLeaderboard() {
    if (_contestants.isEmpty) return [];

    final Set<String> linkedJudgeIds = _judges.map((j) => j.id).toSet();
    final List<ContestantRankResult> results = [];

    // Check if we have active contributing groups
    final contributingGroups = _criteriaGroups
        .where((g) => g.affectsOverallScore && g.weightPercentage > 0)
        .toList();
    final double totalGroupWeight = contributingGroups.fold(0.0, (sum, g) => sum + g.weightPercentage);
    final bool useGroupWeighting = contributingGroups.isNotEmpty && totalGroupWeight > 0;

    for (final contestant in _contestants) {
      final contestantScores = _scores
          .where((s) =>
              s.contestantId == contestant.id &&
              s.isSubmitted &&
              linkedJudgeIds.contains(s.judgeId) &&
              _isScoreValidForEvent(s))
          .toList();

      final int submittedCount = contestantScores.length;
      final Map<String, double> perJudgeScores = {};
      final Map<String, List<double>> criteriaAccumulator = {};
      final Map<String, double> perGroupAverages = {};

      // Compute criteria-level averages
      for (final sub in contestantScores) {
        sub.criteriaScores.forEach((criterionId, scoreVal) {
          criteriaAccumulator.putIfAbsent(criterionId, () => []).add(scoreVal);
        });
      }
      final Map<String, double> perCriteriaAverages = {};
      criteriaAccumulator.forEach((criterionId, values) {
        if (values.isNotEmpty) {
          final avg = values.reduce((a, b) => a + b) / values.length;
          perCriteriaAverages[criterionId] = double.parse(avg.toStringAsFixed(2));
        }
      });

      final Map<String, int> perGroupJudgeCounts = {};
      // Compute group-level averages for all groups (for breakdown)
      for (final grp in _criteriaGroups) {
        final grpCriteria = _criteria.where((c) => c.groupId == grp.id).toList();
        final grpSubs = contestantScores
            .where((s) => s.isCategorySubmitted(grp.id, grpCriteria))
            .toList();
        perGroupJudgeCounts[grp.id] = grpSubs.length;
        if (grpCriteria.isNotEmpty && grpSubs.isNotEmpty) {
          double groupSum = 0.0;
          for (final sub in grpSubs) {
            groupSum += _calculateJudgeGroupScore(sub, grpCriteria);
          }
          perGroupAverages[grp.id] = double.parse((groupSum / grpSubs.length).toStringAsFixed(2));
        } else {
          perGroupAverages[grp.id] = 0.0;
        }
      }

      int scoredContributingCategories = 0;
      for (final grp in contributingGroups) {
        if ((perGroupJudgeCounts[grp.id] ?? 0) > 0) {
          scoredContributingCategories++;
        }
      }

      double sumTotal = 0.0;

      if (useGroupWeighting) {
        // Cumulative weighted calculation across contributing groups.
        // Each category contributes its exact share of the total event weight.
        // Unscored categories contribute 0.0, preventing a single high-scored category
        // from artificially leapfrogging contestants with multiple scored categories.
        for (final sub in contestantScores) {
          double judgeOverall = 0.0;
          for (final grp in contributingGroups) {
            final grpCriteria = _criteria.where((c) => c.groupId == grp.id).toList();
            if (sub.isCategorySubmitted(grp.id, grpCriteria)) {
              final judgeGrpScore = _calculateJudgeGroupScore(sub, grpCriteria);
              judgeOverall += judgeGrpScore * (grp.weightPercentage / 100.0);
            }
          }
          final cumulativeScore = totalGroupWeight > 0
              ? (judgeOverall / (totalGroupWeight / 100.0))
              : judgeOverall;
          perJudgeScores[sub.judgeId] = double.parse(cumulativeScore.toStringAsFixed(2));
          sumTotal += cumulativeScore;
        }
      } else {
        // Legacy calculation: raw points sum
        for (final sub in contestantScores) {
          perJudgeScores[sub.judgeId] = sub.totalScore;
          sumTotal += sub.totalScore;
        }
      }

      final double averageScore = submittedCount > 0 ? (sumTotal / submittedCount) : 0.0;

      results.add(
        ContestantRankResult(
          contestant: contestant,
          averageScore: double.parse(averageScore.toStringAsFixed(2)),
          totalScore: double.parse(sumTotal.toStringAsFixed(2)),
          submittedJudgeCount: submittedCount,
          rank: 0,
          perJudgeScores: perJudgeScores,
          perCriteriaAverages: perCriteriaAverages,
          perGroupAverages: perGroupAverages,
          perGroupJudgeCounts: perGroupJudgeCounts,
          scoredCategoryCount: scoredContributingCategories,
        ),
      );
    }

    // Sort by averageScore descending
    results.sort((a, b) => b.averageScore.compareTo(a.averageScore));

    // Assign 1-indexed ranks
    final List<ContestantRankResult> rankedList = [];
    for (int i = 0; i < results.length; i++) {
      final item = results[i];
      rankedList.add(
        ContestantRankResult(
          contestant: item.contestant,
          averageScore: item.averageScore,
          totalScore: item.totalScore,
          submittedJudgeCount: item.submittedJudgeCount,
          rank: i + 1,
          perJudgeScores: item.perJudgeScores,
          perCriteriaAverages: item.perCriteriaAverages,
          perGroupAverages: item.perGroupAverages,
          perGroupJudgeCounts: item.perGroupJudgeCounts,
          scoredCategoryCount: item.scoredCategoryCount,
        ),
      );
    }

    return rankedList;
  }

  // ------------------ SPECIAL AWARD / GROUP LEADERBOARD ------------------ //
  /// Returns the Standings for a specific Criteria Group (e.g. "Best in Swimsuit").
  List<ContestantRankResult> getGroupLeaderboard(String groupId) {
    if (_contestants.isEmpty) return [];

    final groupCriteria = _criteria.where((c) => c.groupId == groupId).toList();
    final Set<String> linkedJudgeIds = _judges.map((j) => j.id).toSet();
    final List<ContestantRankResult> results = [];

    for (final contestant in _contestants) {
      final contestantScores = _scores
          .where((s) =>
              s.contestantId == contestant.id &&
              s.isSubmitted &&
              linkedJudgeIds.contains(s.judgeId) &&
              _isScoreValidForEvent(s) &&
              s.isCategorySubmitted(groupId, groupCriteria))
          .toList();

      final int submittedCount = contestantScores.length;
      final Map<String, double> perJudgeScores = {};
      final Map<String, List<double>> criteriaAccumulator = {};
      double sumTotal = 0.0;

      for (final sub in contestantScores) {
        final judgeScore = _calculateJudgeGroupScore(sub, groupCriteria);
        perJudgeScores[sub.judgeId] = judgeScore;
        sumTotal += judgeScore;

        for (final c in groupCriteria) {
          final scoreVal = sub.criteriaScores[c.id] ?? 0.0;
          criteriaAccumulator.putIfAbsent(c.id, () => []).add(scoreVal);
        }
      }

      final Map<String, double> perCriteriaAverages = {};
      criteriaAccumulator.forEach((criterionId, values) {
        if (values.isNotEmpty) {
          final avg = values.reduce((a, b) => a + b) / values.length;
          perCriteriaAverages[criterionId] = double.parse(avg.toStringAsFixed(2));
        }
      });

      final double averageScore = submittedCount > 0 ? (sumTotal / submittedCount) : 0.0;

      results.add(
        ContestantRankResult(
          contestant: contestant,
          averageScore: double.parse(averageScore.toStringAsFixed(2)),
          totalScore: double.parse(sumTotal.toStringAsFixed(2)),
          submittedJudgeCount: submittedCount,
          rank: 0,
          perJudgeScores: perJudgeScores,
          perCriteriaAverages: perCriteriaAverages,
          perGroupAverages: {groupId: averageScore},
          perGroupJudgeCounts: {groupId: submittedCount},
          scoredCategoryCount: submittedCount > 0 ? 1 : 0,
        ),
      );
    }

    // Sort descending by group average
    results.sort((a, b) => b.averageScore.compareTo(a.averageScore));

    final List<ContestantRankResult> rankedList = [];
    for (int i = 0; i < results.length; i++) {
      final item = results[i];
      rankedList.add(
        ContestantRankResult(
          contestant: item.contestant,
          averageScore: item.averageScore,
          totalScore: item.totalScore,
          submittedJudgeCount: item.submittedJudgeCount,
          rank: i + 1,
          perJudgeScores: item.perJudgeScores,
          perCriteriaAverages: item.perCriteriaAverages,
          perGroupAverages: item.perGroupAverages,
          perGroupJudgeCounts: item.perGroupJudgeCounts,
          scoredCategoryCount: item.scoredCategoryCount,
        ),
      );
    }

    return rankedList;
  }
}
