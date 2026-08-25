import 'package:cloud_firestore/cloud_firestore.dart';

class Spot {
  const Spot({
    required this.id,
    required this.name,
    required this.address,
    required this.openingHours,
    required this.memo,
    required this.order,
  });

  final String id;
  final String name;
  final String address;
  final String openingHours;
  final String memo;
  final int order;

  factory Spot.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Spot(
      id: doc.id,
      name: data['name'] as String? ?? '',
      address: data['address'] as String? ?? '',
      openingHours: data['openingHours'] as String? ?? '',
      memo: data['memo'] as String? ?? '',
      order: data['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'openingHours': openingHours,
      'memo': memo,
      'order': order,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
