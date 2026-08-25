import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../data/tourist_spot_repository.dart';
import '../domain/tourist_spot.dart';
import 'location_providers.dart';

final touristSpotRepositoryProvider = Provider<TouristSpotRepository>((ref) {
  return TouristSpotRepository(FirebaseFirestore.instance);
});

final allTouristSpotsProvider = StreamProvider<List<TouristSpot>>((ref) {
  return ref.watch(touristSpotRepositoryProvider).watchAllSpots();
});

class NearbySpot {
  const NearbySpot({required this.spot, required this.distanceMeters});

  final TouristSpot spot;
  final double distanceMeters;
}

/// 現在地から近い順に並べた観光スポット一覧。
final nearbySpotsProvider = FutureProvider<List<NearbySpot>>((ref) async {
  final position = await ref.watch(currentPositionProvider.future);
  final spots = await ref.watch(allTouristSpotsProvider.future);

  final nearby = spots
      .map(
        (spot) => NearbySpot(
          spot: spot,
          distanceMeters: Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            spot.latitude,
            spot.longitude,
          ),
        ),
      )
      .toList()
    ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

  return nearby;
});
