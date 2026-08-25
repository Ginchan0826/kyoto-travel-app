import 'package:cloud_firestore/cloud_firestore.dart';

/// スポットチャットの1メッセージ（Firestoreに永続化する）。
/// [visible] が false のものは画面には表示しない裏側のやり取り
/// （初回の自動生成トリガー用メッセージなど）で、AIの文脈維持のためだけに保持する。
class ChatMessageRecord {
  const ChatMessageRecord({
    required this.id,
    required this.role,
    required this.text,
    required this.visible,
    required this.createdAt,
  });

  final String id;
  final String role; // 'user' または 'model'
  final String text;
  final bool visible;
  final DateTime createdAt;

  bool get isUser => role == 'user';

  factory ChatMessageRecord.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return ChatMessageRecord(
      id: doc.id,
      role: data['role'] as String? ?? 'user',
      text: data['text'] as String? ?? '',
      visible: data['visible'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'text': text,
      'visible': visible,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
