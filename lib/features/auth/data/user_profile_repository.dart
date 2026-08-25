import 'package:cloud_firestore/cloud_firestore.dart';

/// メールアドレスからユーザーを逆引きできるように、
/// ログイン・登録のたびに users/{uid} を最新化しておく。
class UserProfileRepository {
  UserProfileRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Future<void> ensureUserProfile({
    required String uid,
    required String email,
  }) {
    return _firestore.collection('users').doc(uid).set(
      {
        'email': email.trim().toLowerCase(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// メールアドレスからUIDを検索する。見つからない場合はnull。
  Future<String?> findUidByEmail(String email) async {
    final snapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first.id;
  }
}
