import 'package:cloud_firestore/cloud_firestore.dart';

class CloudStore {
  CloudStore._();
  static final instance = CloudStore._();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _stateRef(String uid) =>
      _db.collection('users').doc(uid).collection('app').doc('state');

  Future<Map<String, dynamic>?> loadState(String uid) async {
    final snapshot = await _stateRef(uid).get();
    return snapshot.data();
  }

  Future<void> saveState(String uid, Map<String, dynamic> data) =>
      _stateRef(uid).set({...data, 'cloudUpdatedAt': FieldValue.serverTimestamp()});
}
