import 'package:cloud_firestore/cloud_firestore.dart';

class ContestantModel {
  final String id;
  final String eventId;
  final int number;
  final String name;
  final String representation;
  final String bio;
  final String? photoUrl;
  final bool isEliminated;

  ContestantModel({
    required this.id,
    required this.eventId,
    required this.number,
    required this.name,
    this.representation = '',
    this.bio = '',
    this.photoUrl,
    this.isEliminated = false,
  });

  ContestantModel copyWith({
    String? id,
    String? eventId,
    int? number,
    String? name,
    String? representation,
    String? bio,
    String? photoUrl,
    bool? isEliminated,
  }) {
    return ContestantModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      number: number ?? this.number,
      name: name ?? this.name,
      representation: representation ?? this.representation,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      isEliminated: isEliminated ?? this.isEliminated,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'number': number,
      'name': name,
      'representation': representation,
      'bio': bio,
      'photoUrl': photoUrl,
      'isEliminated': isEliminated,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory ContestantModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ContestantModel.fromMap(doc.id, data);
  }

  factory ContestantModel.fromMap(String id, Map<String, dynamic> map) {
    return ContestantModel(
      id: id,
      eventId: map['eventId'] as String? ?? '',
      number: (map['number'] as num?)?.toInt() ?? 1,
      name: map['name'] as String? ?? 'Contestant',
      representation: map['representation'] as String? ?? '',
      bio: map['bio'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      isEliminated: map['isEliminated'] as bool? ?? false,
    );
  }
}
