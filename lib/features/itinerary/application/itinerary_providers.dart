import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../auth/application/auth_providers.dart';
import '../data/itinerary_repository.dart';
import '../data/places_repository.dart';
import '../domain/design_page.dart';
import '../domain/itinerary.dart';
import '../domain/spot.dart';

final placesRepositoryProvider = Provider<PlacesRepository>((ref) {
  return PlacesRepository(http.Client());
});

final itineraryRepositoryProvider = Provider<ItineraryRepository>((ref) {
  return ItineraryRepository(FirebaseFirestore.instance, FirebaseStorage.instance);
});

final myItinerariesProvider = StreamProvider<List<Itinerary>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return const Stream.empty();
  return ref.watch(itineraryRepositoryProvider).watchMyItineraries(user.uid);
});

final itineraryProvider =
    StreamProvider.family<Itinerary, String>((ref, itineraryId) {
  return ref.watch(itineraryRepositoryProvider).watchItinerary(itineraryId);
});

final spotsProvider =
    StreamProvider.family<List<Spot>, String>((ref, itineraryId) {
  return ref.watch(itineraryRepositoryProvider).watchSpots(itineraryId);
});

final pagesProvider =
    StreamProvider.family<List<DesignPage>, String>((ref, itineraryId) {
  return ref.watch(itineraryRepositoryProvider).watchPages(itineraryId);
});
