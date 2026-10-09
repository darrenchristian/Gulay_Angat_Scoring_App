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

    if (event != null) {
      _listenToEventData(event.id);
    } else {
      _criteria = [];
      _contestants = [];
      _judges = [];
      _scores = [];
    }
    notifyListeners();
  }

  void _listenToEventData(String eventId) {
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
      notifyListeners();
    });

    _scoresSub = _firestoreService.getScoresStream(eventId).listen((data) {
      _scores = data;
      notifyListeners();
    });
  }

  void _cancelSubscriptions() {
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

    final List<ContestantRankResult> results = [];

    for (final contestant in _contestants) {
      // Find all submissions for this contestant
      final contestantScores = _scores.where((s) => s.contestantId == contestant.id && s.isSubmitted).toList();

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
