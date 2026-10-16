import 'package:cloud_firestore/cloud_firestore.dart';
import 'criterion_model.dart';

class ScoreSubmissionModel {
  final String id;
  final String eventId;
  final String contestantId;
  final String judgeId;
  final int judgeNumber;
  final Map<String, double> criteriaScores; // criterionId -> score value
  final double totalScore;
  final String remarks;
  final List<String> submittedCategoryIds; // List of groupId strings explicitly submitted
  final Map<String, String> categoryRemarks; // groupId -> remarks for that category
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
    this.submittedCategoryIds = const [],
    this.categoryRemarks = const {},
    this.isSubmitted = false,
    this.submittedAt,
    required this.updatedAt,
    this.isPendingSync = false,
  });

  static String generateId({required String contestantId, required String judgeId}) {
    return '${contestantId}_$judgeId';
  }

  /// Checks if a specific criteria group has been submitted.
  /// Falls back to checking if all group criteria have recorded scores for legacy data.
  bool isCategorySubmitted(String groupId, [List<CriterionModel>? groupCriteria]) {
    if (submittedCategoryIds.contains(groupId)) {
      return true;
    }
    if (isSubmitted && groupCriteria != null && groupCriteria.isNotEmpty) {
      return groupCriteria.every((c) => criteriaScores.containsKey(c.id));
    }
    return false;
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
    List<String>? submittedCategoryIds,
    Map<String, String>? categoryRemarks,
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
      submittedCategoryIds: submittedCategoryIds ?? this.submittedCategoryIds,
      categoryRemarks: categoryRemarks ?? this.categoryRemarks,
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
      'submittedCategoryIds': submittedCategoryIds,
      'categoryRemarks': categoryRemarks,
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

    // Safely parse submittedCategoryIds
    final rawCategories = map['submittedCategoryIds'] as List<dynamic>? ?? [];
    final List<String> parsedCategories = rawCategories.map((e) => e.toString()).toList();

    // Safely parse categoryRemarks
    final rawCatRemarks = map['categoryRemarks'] as Map<dynamic, dynamic>? ?? {};
    final Map<String, String> parsedCatRemarks = {};
    rawCatRemarks.forEach((key, value) {
      parsedCatRemarks[key.toString()] = value.toString();
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
      submittedCategoryIds: parsedCategories,
      categoryRemarks: parsedCatRemarks,
      isSubmitted: map['isSubmitted'] as bool? ?? false,
      submittedAt: map['submittedAt'] != null ? parseDate(map['submittedAt']) : null,
      updatedAt: parseDate(map['updatedAt']),
      isPendingSync: isPendingSync,
    );
  }
}
