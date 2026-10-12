import 'package:cloud_firestore/cloud_firestore.dart';

class ScoreSubmissionModel {
  final String id;
  final String eventId;
  final String contestantId;
  final String judgeId;
  final int judgeNumber;
  final Map<String, double> criteriaScores; // criterionId -> score value
  final double totalScore;
  final String remarks;
  final bool isSubmitted;
  final DateTime? submittedAt;
  final DateTime updatedAt;
  final bool isPendingSync;

  ScoreSubmissionModel({
    required this.id,
    required this.eventId,
    required this.contestantId,
    required this.judgeId,
    required this.judgeNumber,
    required this.criteriaScores,
    required this.totalScore,
    this.remarks = '',
    this.isSubmitted = false,
    this.submittedAt,
    required this.updatedAt,
    this.isPendingSync = false,
  });

  static String generateId({required String contestantId, required String judgeId}) {
    return '${contestantId}_$judgeId';
  }

  ScoreSubmissionModel copyWith({
    String? id,
    String? eventId,
    String? contestantId,
    String? judgeId,
    int? judgeNumber,
    Map<String, double>? criteriaScores,
    double? totalScore,
    String? remarks,
    bool? isSubmitted,
    DateTime? submittedAt,
    DateTime? updatedAt,
    bool? isPendingSync,
  }) {
    return ScoreSubmissionModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      contestantId: contestantId ?? this.contestantId,
      judgeId: judgeId ?? this.judgeId,
      judgeNumber: judgeNumber ?? this.judgeNumber,
      criteriaScores: criteriaScores ?? this.criteriaScores,
      totalScore: totalScore ?? this.totalScore,
      remarks: remarks ?? this.remarks,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      submittedAt: submittedAt ?? this.submittedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPendingSync: isPendingSync ?? this.isPendingSync,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'contestantId': contestantId,
      'judgeId': judgeId,
      'judgeNumber': judgeNumber,
      'criteriaScores': criteriaScores,
      'totalScore': totalScore,
      'remarks': remarks,
      'isSubmitted': isSubmitted,
      'submittedAt': submittedAt != null ? Timestamp.fromDate(submittedAt!) : null,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ScoreSubmissionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ScoreSubmissionModel.fromMap(
      doc.id,
      data,
      isPendingSync: doc.metadata.hasPendingWrites,
    );
  }

  factory ScoreSubmissionModel.fromMap(
    String id,
    Map<String, dynamic> map, {
    bool isPendingSync = false,
  }) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    // Safely parse map of double criteria scores
    final rawScores = map['criteriaScores'] as Map<dynamic, dynamic>? ?? {};
    final Map<String, double> parsedScores = {};
    rawScores.forEach((key, value) {
      if (value is num) {
        parsedScores[key.toString()] = value.toDouble();
      }
    });

    return ScoreSubmissionModel(
      id: id,
      eventId: map['eventId'] as String? ?? '',
      contestantId: map['contestantId'] as String? ?? '',
      judgeId: map['judgeId'] as String? ?? '',
      judgeNumber: (map['judgeNumber'] as num?)?.toInt() ?? 1,
      criteriaScores: parsedScores,
      totalScore: (map['totalScore'] as num?)?.toDouble() ?? 0.0,
      remarks: map['remarks'] as String? ?? '',
      isSubmitted: map['isSubmitted'] as bool? ?? false,
      submittedAt: map['submittedAt'] != null ? parseDate(map['submittedAt']) : null,
      updatedAt: parseDate(map['updatedAt']),
      isPendingSync: isPendingSync,
    );
  }
}
