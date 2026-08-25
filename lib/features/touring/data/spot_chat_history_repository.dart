import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/chat_message_record.dart';

/// アカウント×スポットごとのAIチャット履歴をFirestoreに保存・取得する。
class SpotChatHistoryRepository {
  SpotChatHistoryRepository(this._firestore);

  final FirebaseFirestore _firestore;

  static String chatKey({required String itineraryId, required String spotId}) {
    return '${itineraryId}_$spotId';
  }

  CollectionReference<Map<String, dynamic>> _messagesRef({
    required String uid,
    required String chatKey,
  }) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('spot_chats')
        .doc(chatKey)
        .collection('messages');
  }

  Future<List<ChatMessageRecord>> getMessages({
    required String uid,
    required String chatKey,
  }) async {
    final snapshot =
        await _messagesRef(uid: uid, chatKey: chatKey).orderBy('createdAt').get();
    return snapshot.docs.map(ChatMessageRecord.fromFirestore).toList();
  }

  Future<void> addMessage({
    required String uid,
    required String chatKey,
    required String role,
    required String text,
    required bool visible,
  }) {
    return _messagesRef(uid: uid, chatKey: chatKey).add(
      ChatMessageRecord(
        id: '',
        role: role,
        text: text,
        visible: visible,
        createdAt: DateTime.now(),
      ).toMap(),
    );
  }
}
