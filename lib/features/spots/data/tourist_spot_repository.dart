import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/tourist_spot.dart';

class TouristSpotRepository {
  TouristSpotRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _spotsRef =>
      _firestore.collection('tourist_spots');

  Stream<List<TouristSpot>> watchAllSpots() {
    return _spotsRef.snapshots().map(
          (snapshot) =>
              snapshot.docs.map(TouristSpot.fromFirestore).toList(),
        );
  }

  Future<void> addSpot({
    required String name,
    required String address,
    required String openingHours,
    required String memo,
    required double latitude,
    required double longitude,
  }) {
    return _spotsRef.add(
      TouristSpot(
        id: '',
        name: name,
        address: address,
        openingHours: openingHours,
        memo: memo,
        latitude: latitude,
        longitude: longitude,
      ).toMap(),
    );
  }
}
