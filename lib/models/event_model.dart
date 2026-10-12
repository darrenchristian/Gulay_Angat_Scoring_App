import 'package:cloud_firestore/cloud_firestore.dart';

enum EventStatus {
  draft,
  active,
  completed;

  String get displayName {
    switch (this) {
      case EventStatus.draft:
        return 'Draft';
      case EventStatus.active:
        return 'Live / Open';
      case EventStatus.completed:
        return 'Completed';
    }
  }

  static EventStatus fromString(String? value) {
    switch (value) {
      case 'active':
        return EventStatus.active;
      case 'completed':
        return EventStatus.completed;
      default:
        return EventStatus.draft;
    }
  }
}

class EventModel {
  final String id;
  final String title;
  final String description;
  final EventStatus status;
  final int judgeCount;
  final List<String> assignedJudgeIds;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? scoresResetAt;
  final Map<String, DateTime> judgeResetAt;

  EventModel({
    required this.id,
    required this.title,
    this.description = '',
    this.status = EventStatus.draft,
    this.judgeCount = 0,
    this.assignedJudgeIds = const [],
    required this.createdAt,
    this.updatedAt,
    this.scoresResetAt,
    this.judgeResetAt = const {},
  });

  bool get isActive => status == EventStatus.active;
  bool get isDraft => status == EventStatus.draft;
  bool get isCompleted => status == EventStatus.completed;

  /// Strictly returns the count of linked global judges.
  int get effectiveJudgeCount => assignedJudgeIds.length;

  /// Checks whether a score submission is still valid (not older than an Admin reset).
  bool isScoreValidAfterReset(ScoreSubmissionModelForCheck? score, {
    required String judgeId,
    required DateTime? submittedAt,
    required DateTime updatedAt,
  }) {
    final scoreTime = submittedAt ?? updatedAt;
    if (scoresResetAt != null && scoreTime.isBefore(scoresResetAt!)) {
      return false;
    }
    final perJudgeReset = judgeResetAt[judgeId];
    if (perJudgeReset != null && scoreTime.isBefore(perJudgeReset)) {
      return false;
    }
    return true;
  }

  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    EventStatus? status,
    int? judgeCount,
    List<String>? assignedJudgeIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? scoresResetAt,
    Map<String, DateTime>? judgeResetAt,
  }) {
    final updatedAssigned = assignedJudgeIds ?? this.assignedJudgeIds;
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      judgeCount: updatedAssigned.length,
      assignedJudgeIds: updatedAssigned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      scoresResetAt: scoresResetAt ?? this.scoresResetAt,
      judgeResetAt: judgeResetAt ?? this.judgeResetAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'status': status.name,
      'judgeCount': assignedJudgeIds.length,
      'assignedJudgeIds': assignedJudgeIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
      if (scoresResetAt != null) 'scoresResetAt': Timestamp.fromDate(scoresResetAt!),
      if (judgeResetAt.isNotEmpty)
        'judgeResetAt': {
          for (final entry in judgeResetAt.entries)
            entry.key: Timestamp.fromDate(entry.value),
        },
    };
  }

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return EventModel.fromMap(doc.id, data);
  }

  factory EventModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    final rawJudgeIds = map['assignedJudgeIds'];
    final List<String> parsedJudgeIds = rawJudgeIds is Iterable
        ? rawJudgeIds.map((e) => e.toString()).toList()
        : <String>[];

    final rawJudgeReset = map['judgeResetAt'];
    final Map<String, DateTime> parsedJudgeReset = {};
    if (rawJudgeReset is Map) {
      rawJudgeReset.forEach((k, v) {
        if (v != null) {
          parsedJudgeReset[k.toString()] = parseDate(v);
        }
      });
    }

    return EventModel(
      id: id,
      title: map['title'] as String? ?? 'Untitled Event',
      description: map['description'] as String? ?? '',
      status: EventStatus.fromString(map['status'] as String?),
      judgeCount: parsedJudgeIds.length,
      assignedJudgeIds: parsedJudgeIds,
      createdAt: parseDate(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? parseDate(map['updatedAt']) : null,
      scoresResetAt: map['scoresResetAt'] != null ? parseDate(map['scoresResetAt']) : null,
      judgeResetAt: parsedJudgeReset,
    );
  }
}

typedef ScoreSubmissionModelForCheck = Object;
