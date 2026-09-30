import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Item-level Firestore storage. Firestore's local persistence queues writes
/// while offline, so independent items from Android/Web no longer overwrite
/// the entire app snapshot.
class CloudStore {
  CloudStore._();
  static final instance = CloudStore._();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _legacy(String uid) =>
      _db.collection('users').doc(uid).collection('app').doc('state');
  CollectionReference<Map<String, dynamic>> _items(String uid, String kind) =>
      _db.collection('users').doc(uid).collection(kind);
  DocumentReference<Map<String, dynamic>> _settings(String uid) =>
      _db.collection('users').doc(uid).collection('app').doc('settings');
  CollectionReference<Map<String, dynamic>> _deletions(String uid) =>
      _db.collection('users').doc(uid).collection('deletions');

  static const kinds = <String>[
    'tasks','wants','futures','goals','milestones','inbox','trash'
  ];

  Future<Map<String, dynamic>?> loadLegacyState(String uid) async =>
      (await _legacy(uid).get()).data();

  Future<Map<String, dynamic>> loadItemState(String uid) async {
    final result = <String, dynamic>{};
    for (final kind in kinds) {
      final snap = await _items(uid, kind).get();
      result[kind] = snap.docs.map((d) => d.data()).toList();
    }
    final settings = (await _settings(uid).get()).data();
    if (settings != null) {
      result['themeMode'] = settings['themeMode'];
      result['rememberMeta'] = settings['rememberMeta'] ?? <String,dynamic>{};
    }
    return result;
  }

  Future<bool> hasItemData(String uid) async {
    for (final kind in kinds) {
      final snap = await _items(uid, kind).limit(1).get();
      if (snap.docs.isNotEmpty) return true;
    }
    return false;
  }

  Future<void> saveItemState(String uid, Map<String, dynamic> state) async {
    // Individual set() calls intentionally use Firestore's offline queue.
    for (final kind in kinds) {
      final values = (state[kind] as List? ?? const []);
      for (final raw in values) {
        final data = Map<String, dynamic>.from(raw as Map);
        final id = '${data['id']}';
        if (id.isEmpty) continue;
        await _items(uid, kind).doc(id).set({
          ...data,
          'cloudUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }
    await _settings(uid).set({
      'themeMode': state['themeMode'],
      'rememberMeta': state['rememberMeta'] ?? <String,dynamic>{},
      'schemaVersion': 2,
      'cloudUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  StreamSubscription<void> watchItemState(String uid, void Function(Map<String,dynamic>) onData) {
    final latest=<String,dynamic>{};
    final ready=<String>{};
    final controller=StreamController<void>();
    final subs=<StreamSubscription<QuerySnapshot<Map<String,dynamic>>>>[];
    StreamSubscription<QuerySnapshot<Map<String,dynamic>>>? deletionSub;

    void emit(String kind,QuerySnapshot<Map<String,dynamic>> snap){
      latest[kind]=snap.docs.map((d)=>d.data()).toList();
      ready.add(kind);
      if(ready.length==kinds.length)onData(Map<String,dynamic>.from(latest));
    }

    for(final kind in kinds){
      subs.add(_items(uid,kind).snapshots().listen((snap)=>emit(kind,snap)));
    }
    deletionSub=_deletions(uid).snapshots().listen((snap){
      latest['deletions']=snap.docs.map((d)=>d.data()).toList();
      if(ready.length==kinds.length)onData(Map<String,dynamic>.from(latest));
    });
    controller.onCancel=()async{
      for(final s in subs){await s.cancel();}
      await deletionSub?.cancel();
    };
    return controller.stream.listen((_){});
  }

  Future<void> saveItem(String uid,String kind,Map<String,dynamic> raw) async {
    final data=Map<String,dynamic>.from(raw);
    final id='${data['id']}';
    if(id.isEmpty)return;
    await _items(uid,kind).doc(id).set({
      ...data,
      'cloudUpdatedAt':FieldValue.serverTimestamp(),
    },SetOptions(merge:true));
  }

  Future<void> saveSettings(String uid,Map<String,dynamic> state) async {
    await _settings(uid).set({
      'themeMode':state['themeMode'],
      'rememberMeta':state['rememberMeta']??<String,dynamic>{},
      'schemaVersion':3,
      'cloudUpdatedAt':FieldValue.serverTimestamp(),
    },SetOptions(merge:true));
  }

  Future<void> deleteItem(String uid, String kind, String id) async {
    final tombstoneId='${kind}_${id}';
    await _deletions(uid).doc(tombstoneId).set({
      'kind':kind,
      'itemId':id,
      'deletedAt':FieldValue.serverTimestamp(),
    },SetOptions(merge:true));
    await _items(uid, kind).doc(id).delete();
  }

  /// One-time migration from the old all-in-one app/state document.
  Future<Map<String, dynamic>?> migrateLegacyIfNeeded(String uid) async {
    if (await hasItemData(uid)) return null;
    final legacy = await loadLegacyState(uid);
    if (legacy == null) return null;
    await saveItemState(uid, legacy);
    return legacy;
  }
}
