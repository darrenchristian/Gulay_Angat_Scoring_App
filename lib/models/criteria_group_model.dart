import 'package:cloud_firestore/cloud_firestore.dart';

class CriteriaGroupModel {
  final String id;
  final String eventId;
  final String name;
  final String description;
  final bool affectsOverallScore; // true = contributes to final event title; false = standalone / special award
  final double weightPercentage; // percentage towards final score (e.g. 40.0%)
  final int order; // display order sequence
  final bool isLocked; // true = category is locked from judge scoring; false = open

  CriteriaGroupModel({
    required this.id,
    required this.eventId,
    required this.name,
    this.description = '',
    this.affectsOverallScore = true,
    this.weightPercentage = 0.0,
    this.order = 0,
    this.isLocked = false,
  });

  CriteriaGroupModel copyWith({
    String? id,
    String? eventId,
    String? name,
    String? description,
    bool? affectsOverallScore,
    double? weightPercentage,
    int? order,
    bool? isLocked,
  }) {
    return CriteriaGroupModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      name: name ?? this.name,
      description: description ?? this.description,
      affectsOverallScore: affectsOverallScore ?? this.affectsOverallScore,
      weightPercentage: weightPercentage ?? this.weightPercentage,
      order: order ?? this.order,
      isLocked: isLocked ?? this.isLocked,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'name': name,
      'description': description,
      'affectsOverallScore': affectsOverallScore,
      'weightPercentage': weightPercentage,
      'order': order,
      'isLocked': isLocked,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory CriteriaGroupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CriteriaGroupModel.fromMap(doc.id, data);
  }

  factory CriteriaGroupModel.fromMap(String id, Map<String, dynamic> map) {
    return CriteriaGroupModel(
      id: id,
      eventId: map['eventId'] as String? ?? '',
      name: map['name'] as String? ?? 'Category',
      description: map['description'] as String? ?? '',
      affectsOverallScore: map['affectsOverallScore'] as bool? ?? true,
      weightPercentage: (map['weightPercentage'] as num?)?.toDouble() ?? 0.0,
      order: (map['order'] as num?)?.toInt() ?? 0,
      isLocked: map['isLocked'] as bool? ?? false,
    );
  }
}
