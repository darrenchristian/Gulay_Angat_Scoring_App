import 'package:cloud_firestore/cloud_firestore.dart';

class JudgeModel {
  final String id;
  final String eventId; // Optional legacy field; global judges are linked via EventModel.assignedJudgeIds
  final int judgeNumber;
  final String accessCode; // The unique ID used to log in (e.g. JDG-XXXX)
  final String name;
  final bool isActive;
  final DateTime createdAt;

  JudgeModel({
    required this.id,
    this.eventId = '',
    required this.judgeNumber,
    required this.accessCode,
    this.name = '',
    this.isActive = true,
    required this.createdAt,
  });

  String get displayName => name.isNotEmpty ? name : 'Judge #$judgeNumber';

  JudgeModel copyWith({
    String? id,
    String? eventId,
    int? judgeNumber,
    String? accessCode,
    String? name,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return JudgeModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      judgeNumber: judgeNumber ?? this.judgeNumber,
      accessCode: accessCode ?? this.accessCode,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'judgeNumber': judgeNumber,
      'accessCode': accessCode.toUpperCase().trim(),
      'name': name,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory JudgeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return JudgeModel.fromMap(doc.id, data);
  }

  factory JudgeModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return JudgeModel(
      id: id,
      eventId: map['eventId'] as String? ?? '',
      judgeNumber: (map['judgeNumber'] as num?)?.toInt() ?? 1,
      accessCode: (map['accessCode'] as String? ?? '').toUpperCase().trim(),
      name: map['name'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
      createdAt: parseDate(map['createdAt']),
    );
  }
}
