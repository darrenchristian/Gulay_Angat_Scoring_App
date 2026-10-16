import 'package:cloud_firestore/cloud_firestore.dart';

class CriterionModel {
  final String id;
  final String eventId;
  final String groupId; // links criterion to its CriteriaGroupModel (empty string = default/ungrouped)
  final String name;
  final String description;
  final double maxScore;
  final double weightPercentage;
  final int order;

  CriterionModel({
    required this.id,
    required this.eventId,
    this.groupId = '',
    required this.name,
    this.description = '',
    this.maxScore = 100.0,
    this.weightPercentage = 100.0,
    this.order = 0,
  });

  CriterionModel copyWith({
    String? id,
    String? eventId,
    String? groupId,
    String? name,
    String? description,
    double? maxScore,
    double? weightPercentage,
    int? order,
  }) {
    return CriterionModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      description: description ?? this.description,
      maxScore: maxScore ?? this.maxScore,
      weightPercentage: weightPercentage ?? this.weightPercentage,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'groupId': groupId,
      'name': name,
      'description': description,
      'maxScore': maxScore,
      'weightPercentage': weightPercentage,
      'order': order,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory CriterionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CriterionModel.fromMap(doc.id, data);
  }

  factory CriterionModel.fromMap(String id, Map<String, dynamic> map) {
    return CriterionModel(
      id: id,
      eventId: map['eventId'] as String? ?? '',
      groupId: map['groupId'] as String? ?? '',
      name: map['name'] as String? ?? 'Criterion',
      description: map['description'] as String? ?? '',
      maxScore: (map['maxScore'] as num?)?.toDouble() ?? 100.0,
      weightPercentage: (map['weightPercentage'] as num?)?.toDouble() ?? 100.0,
      order: (map['order'] as num?)?.toInt() ?? 0,
    );
  }
}
