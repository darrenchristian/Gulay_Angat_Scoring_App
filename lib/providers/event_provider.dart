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
  final Map<String, double> perJudgeScores; // judgeId -> totalScore
  final Map<String, double> perCriteriaAverages; // criterionId -> average

  ContestantRankResult({
    required this.contestant,
    required this.averageScore,
    required this.totalScore,
    required this.submittedJudgeCount,
    required this.rank,
    required this.perJudgeScores,
    required this.perCriteriaAverages,
  });
}

class EventProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  EventModel? _selectedEvent;
  List<CriterionModel> _criteria = [];
  List<ContestantModel> _contestants = [];
  List<JudgeModel> _judges = [];
  List<ScoreSubmissionModel> _scores = [];
  bool _hasLoadedJudges = false;

  StreamSubscription? _eventSub;
  StreamSubscription? _criteriaSub;
  StreamSubscription? _contestantsSub;
  StreamSubscription? _judgesSub;
  StreamSubscription? _scoresSub;

  EventModel? get selectedEvent => _selectedEvent;
  List<CriterionModel> get criteria => _criteria;
  List<ContestantModel> get contestants => _contestants;
  List<JudgeModel> get judges => _judges;
  List<ScoreSubmissionModel> get scores => _scores;

  void setSelectedEvent(EventModel? event) {
    _selectedEvent = event;
    _cancelSubscriptions();
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

  // Real-time consolidated ranking calculations
  List<ContestantRankResult> getLeaderboard() {
    if (_contestants.isEmpty) return [];

    final Set<String> linkedJudgeIds = _judges.map((j) => j.id).toSet();
    final List<ContestantRankResult> results = [];

    for (final contestant in _contestants) {
      // Find all submissions for this contestant strictly from currently linked judges
      // and not older than an Admin score reset
      final contestantScores = _scores
          .where((s) =>
              s.contestantId == contestant.id &&
              s.isSubmitted &&
              linkedJudgeIds.contains(s.judgeId) &&
              _isScoreValidForEvent(s))
          .toList();

      final Map<String, double> perJudgeScores = {};
      final Map<String, List<double>> criteriaAccumulator = {};

      double sumTotal = 0.0;

      for (final sub in contestantScores) {
        perJudgeScores[sub.judgeId] = sub.totalScore;
        sumTotal += sub.totalScore;

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

      final int submittedCount = contestantScores.length;
      final double averageScore = submittedCount > 0 ? sumTotal / submittedCount : 0.0;

      results.add(
        ContestantRankResult(
          contestant: contestant,
          averageScore: double.parse(averageScore.toStringAsFixed(2)),
          totalScore: double.parse(sumTotal.toStringAsFixed(2)),
          submittedJudgeCount: submittedCount,
          rank: 0, // Assigned after sorting
          perJudgeScores: perJudgeScores,
          perCriteriaAverages: perCriteriaAverages,
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
        ),
      );
    }

    return rankedList;
  }
}
