import 'package:cloud_firestore/cloud_firestore.dart';

class Itinerary {
  const Itinerary({
    required this.id,
    required this.title,
    required this.memo,
    required this.ownerId,
    required this.collaboratorIds,
    required this.collaboratorEmails,
    required this.hasCover,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String memo;
  final String ownerId;
  final List<String> collaboratorIds;
  final List<String> collaboratorEmails;
  final bool hasCover;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool isOwner(String uid) => ownerId == uid;

  bool canEdit(String uid) => ownerId == uid || collaboratorIds.contains(uid);

  factory Itinerary.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Itinerary(
      id: doc.id,
      title: data['title'] as String? ?? '',
      memo: data['memo'] as String? ?? '',
      ownerId: data['ownerId'] as String? ?? '',
      collaboratorIds:
          List<String>.from(data['collaboratorIds'] as List? ?? const []),
      collaboratorEmails:
          List<String>.from(data['collaboratorEmails'] as List? ?? const []),
      hasCover: data['hasCover'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toCreateMap({required String ownerId}) {
    return {
      'title': title,
      'memo': memo,
      'ownerId': ownerId,
      'collaboratorIds': <String>[],
      'collaboratorEmails': <String>[],
      'hasCover': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'title': title,
      'memo': memo,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
