import 'package:cloud_firestore/cloud_firestore.dart';

/// 観光名所のマスタデータ（現在地周辺表示用）。
/// Google検索（Places API）から取得した情報を元に登録する。
class TouristSpot {
  const TouristSpot({
    required this.id,
    required this.name,
    required this.address,
    required this.openingHours,
    required this.memo,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String name;
  final String address;
  final String openingHours;
  final String memo;
  final double latitude;
  final double longitude;

  factory TouristSpot.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return TouristSpot(
      id: doc.id,
      name: data['name'] as String? ?? '',
      address: data['address'] as String? ?? '',
      openingHours: data['openingHours'] as String? ?? '',
      memo: data['memo'] as String? ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'openingHours': openingHours,
      'memo': memo,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
