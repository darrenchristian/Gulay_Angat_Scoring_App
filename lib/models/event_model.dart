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
  final DateTime createdAt;
  final DateTime? updatedAt;

  EventModel({
    required this.id,
    required this.title,
    this.description = '',
    this.status = EventStatus.draft,
    this.judgeCount = 3,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isActive => status == EventStatus.active;
  bool get isDraft => status == EventStatus.draft;
  bool get isCompleted => status == EventStatus.completed;

  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    EventStatus? status,
    int? judgeCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      judgeCount: judgeCount ?? this.judgeCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'status': status.name,
      'judgeCount': judgeCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
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

    return EventModel(
      id: id,
      title: map['title'] as String? ?? 'Untitled Event',
      description: map['description'] as String? ?? '',
      status: EventStatus.fromString(map['status'] as String?),
      judgeCount: (map['judgeCount'] as num?)?.toInt() ?? 3,
      createdAt: parseDate(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? parseDate(map['updatedAt']) : null,
    );
  }
}
