import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../domain/canvas_element.dart';
import '../domain/design_page.dart';
import '../domain/itinerary.dart';
import '../domain/spot.dart';
import '../domain/timeline_template.dart';

/// 招待しようとしたメールアドレスのユーザーが見つからなかった場合の例外。
class CollaboratorNotFoundException implements Exception {
  const CollaboratorNotFoundException();

  @override
  String toString() => '指定されたメールアドレスのユーザーが見つかりません。';
}

class ItineraryRepository {
  ItineraryRepository(this._firestore, this._storage);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _itinerariesRef =>
      _firestore.collection('itineraries');

  CollectionReference<Map<String, dynamic>> _spotsRef(String itineraryId) =>
      _itinerariesRef.doc(itineraryId).collection('spots');

  CollectionReference<Map<String, dynamic>> _pagesRef(String itineraryId) =>
      _itinerariesRef.doc(itineraryId).collection('pages');

  /// 自分がオーナー、または共同編集者になっているしおりを結合して返す。
  Stream<List<Itinerary>> watchMyItineraries(String uid) {
    final controller = StreamController<List<Itinerary>>.broadcast();

    Map<String, Itinerary> owned = {};
    Map<String, Itinerary> collaborating = {};
    var ownedReady = false;
    var collaboratingReady = false;

    void emit() {
      if (!ownedReady || !collaboratingReady) return;
      final merged = <String, Itinerary>{...owned, ...collaborating};
      final list = merged.values.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      controller.add(list);
    }

    final ownedSub = _itinerariesRef
        .where('ownerId', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) {
      owned = {
        for (final doc in snapshot.docs) doc.id: Itinerary.fromFirestore(doc),
      };
      ownedReady = true;
      emit();
    }, onError: controller.addError);

    final collaboratingSub = _itinerariesRef
        .where('collaboratorIds', arrayContains: uid)
        .snapshots()
        .listen((snapshot) {
      collaborating = {
        for (final doc in snapshot.docs) doc.id: Itinerary.fromFirestore(doc),
      };
      collaboratingReady = true;
      emit();
    }, onError: controller.addError);

    controller.onCancel = () {
      ownedSub.cancel();
      collaboratingSub.cancel();
    };

    return controller.stream;
  }

  Stream<Itinerary> watchItinerary(String itineraryId) {
    return _itinerariesRef
        .doc(itineraryId)
        .snapshots()
        .map((doc) => Itinerary.fromFirestore(doc));
  }

  Stream<List<Spot>> watchSpots(String itineraryId) {
    return _spotsRef(itineraryId)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Spot.fromFirestore).toList());
  }

  Future<String> createItinerary({
    required String title,
    required String memo,
    required String ownerId,
  }) async {
    final doc = await _itinerariesRef.add(
      Itinerary(
        id: '',
        title: title,
        memo: memo,
        ownerId: ownerId,
        collaboratorIds: const [],
        collaboratorEmails: const [],
        hasCover: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ).toCreateMap(ownerId: ownerId),
    );
    // 表紙ページをあらかじめ1枚用意しておく。IDを固定することで重複作成を防ぐ。
    await _pagesRef(doc.id).doc('cover').set(
      DesignPage(
        id: '',
        order: -1,
        elements: const [],
        isCover: true,
        backgroundColor: null,
        useTemplate: false,
        template: TimelineTemplateData.empty(),
      ).toMap(),
    );
    return doc.id;
  }

  Future<void> updateItinerary({
    required String itineraryId,
    required String title,
    required String memo,
  }) {
    return _itinerariesRef.doc(itineraryId).update(
          Itinerary(
            id: itineraryId,
            title: title,
            memo: memo,
            ownerId: '',
            collaboratorIds: const [],
            collaboratorEmails: const [],
            hasCover: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ).toUpdateMap(),
        );
  }

  Future<void> updateHasCover({
    required String itineraryId,
    required bool hasCover,
  }) {
    return _itinerariesRef.doc(itineraryId).update({
      'hasCover': hasCover,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteItinerary(String itineraryId) async {
    final spots = await _spotsRef(itineraryId).get();
    final pages = await _pagesRef(itineraryId).get();
    final batch = _firestore.batch();
    for (final doc in spots.docs) {
      batch.delete(doc.reference);
    }
    for (final doc in pages.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_itinerariesRef.doc(itineraryId));
    await batch.commit();
  }

  Future<void> addSpot({
    required String itineraryId,
    required String name,
    required String address,
    required String openingHours,
    required String memo,
    required int order,
  }) {
    return _spotsRef(itineraryId).add(
      Spot(
        id: '',
        name: name,
        address: address,
        openingHours: openingHours,
        memo: memo,
        order: order,
      ).toMap(),
    );
  }

  Future<void> deleteSpot({
    required String itineraryId,
    required String spotId,
  }) {
    return _spotsRef(itineraryId).doc(spotId).delete();
  }

  /// 表紙ページがまだ存在しない場合に作成する（旧バージョンで作成されたしおり向け）。
  Future<void> ensureCoverPage(String itineraryId) async {
    // IDを固定（'cover'）することで、複数回呼ばれても表紙ページが重複作成されないようにする。
    final coverRef = _pagesRef(itineraryId).doc('cover');
    final existing = await coverRef.get();
    if (existing.exists) return;
    await coverRef.set(
      DesignPage(
        id: '',
        order: -1,
        elements: const [],
        isCover: true,
        backgroundColor: null,
        useTemplate: false,
        template: TimelineTemplateData.empty(),
      ).toMap(),
    );
  }

  Stream<List<DesignPage>> watchPages(String itineraryId) {
    return _pagesRef(itineraryId)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(DesignPage.fromFirestore).toList());
  }

  /// ページを末尾に追加する（表紙は除いた本文ページとして扱う）。
  Future<void> addPage(String itineraryId) async {
    final existing = await _pagesRef(itineraryId)
        .where('isCover', isEqualTo: false)
        .get();
    await _pagesRef(itineraryId).add(
      DesignPage(
        id: '',
        order: existing.docs.length,
        elements: const [],
        isCover: false,
        backgroundColor: null,
        useTemplate: false,
        template: TimelineTemplateData.empty(),
      ).toMap(),
    );
  }

  Future<void> deletePage({
    required String itineraryId,
    required String pageId,
  }) {
    return _pagesRef(itineraryId).doc(pageId).delete();
  }

  /// ページ並び替え後の順序を一括反映する（表紙を除いた本文ページのみ対象）。
  Future<void> reorderPages({
    required String itineraryId,
    required List<String> orderedPageIds,
  }) async {
    final batch = _firestore.batch();
    for (var i = 0; i < orderedPageIds.length; i++) {
      batch.update(_pagesRef(itineraryId).doc(orderedPageIds[i]), {
        'order': i,
      });
    }
    await batch.commit();
  }

  Future<void> updatePageElements({
    required String itineraryId,
    required String pageId,
    required List<CanvasElement> elements,
  }) {
    return _pagesRef(itineraryId).doc(pageId).update({
      'elements': elements.map((e) => e.toMap()).toList(),
    });
  }

  Future<void> updatePageBackgroundColor({
    required String itineraryId,
    required String pageId,
    required int? backgroundColor,
  }) {
    return _pagesRef(itineraryId).doc(pageId).update({
      'backgroundColor': backgroundColor,
    });
  }

  Future<void> updatePageTemplate({
    required String itineraryId,
    required String pageId,
    required bool useTemplate,
    required TimelineTemplateData template,
  }) {
    return _pagesRef(itineraryId).doc(pageId).update({
      'useTemplate': useTemplate,
      'template': template.toMap(),
    });
  }

  /// 画像をFirebase Storageにアップロードし、ダウンロードURLを返す。
  Future<String> uploadPageImage({
    required String itineraryId,
    required File file,
  }) async {
    final fileName =
        '${DateTime.now().microsecondsSinceEpoch}_${file.uri.pathSegments.last}';
    final ref = _storage.ref('itinerary_images/$itineraryId/$fileName');
    final task = await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return task.ref.getDownloadURL();
  }

  /// メールアドレスを指定して共同編集者を招待する。
  /// 対象のメールアドレスで登録済みのユーザーが存在しない場合は例外を投げる。
  Future<void> addCollaboratorByEmail({
    required String itineraryId,
    required String email,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final userQuery = await _firestore
        .collection('users')
        .where('email', isEqualTo: normalizedEmail)
        .limit(1)
        .get();
    if (userQuery.docs.isEmpty) {
      throw const CollaboratorNotFoundException();
    }
    final uid = userQuery.docs.first.id;

    final itineraryRef = _itinerariesRef.doc(itineraryId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(itineraryRef);
      final data = snapshot.data() as Map<String, dynamic>;
      final ids = List<String>.from(data['collaboratorIds'] as List? ?? []);
      final emails =
          List<String>.from(data['collaboratorEmails'] as List? ?? []);
      if (ids.contains(uid)) return;
      ids.add(uid);
      emails.add(normalizedEmail);
      transaction.update(itineraryRef, {
        'collaboratorIds': ids,
        'collaboratorEmails': emails,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> removeCollaborator({
    required String itineraryId,
    required String uid,
  }) async {
    final itineraryRef = _itinerariesRef.doc(itineraryId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(itineraryRef);
      final data = snapshot.data() as Map<String, dynamic>;
      final ids = List<String>.from(data['collaboratorIds'] as List? ?? []);
      final emails =
          List<String>.from(data['collaboratorEmails'] as List? ?? []);
      final index = ids.indexOf(uid);
      if (index == -1) return;
      ids.removeAt(index);
      emails.removeAt(index);
      transaction.update(itineraryRef, {
        'collaboratorIds': ids,
        'collaboratorEmails': emails,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
