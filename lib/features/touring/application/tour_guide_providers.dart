import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/spot_chat_history_repository.dart';
import '../data/tour_guide_repository.dart';

final tourGuideRepositoryProvider = Provider<TourGuideRepository>((ref) {
  return TourGuideRepository();
});

final spotChatHistoryRepositoryProvider = Provider<SpotChatHistoryRepository>((ref) {
  return SpotChatHistoryRepository(FirebaseFirestore.instance);
});
