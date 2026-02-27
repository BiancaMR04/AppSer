import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';

class UserTrackingFirestoreDataSource {
  UserTrackingFirestoreDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> userDoc(String uid) {
    return _firestore.collection(FirestorePaths.usersCollection).doc(uid);
  }

  DocumentReference<Map<String, dynamic>> sessionDoc({
    required String uid,
    required String sessaoId,
  }) {
    final path =
        '${FirestorePaths.usersCollection}/$uid/${FirestorePaths.sessoesSubcollection}/$sessaoId';
    return _firestore.doc(path);
  }

  CollectionReference<Map<String, dynamic>> taskEventsCollection(String uid) {
    return userDoc(uid).collection(FirestorePaths.taskEventsSubcollection);
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(String uid) {
    return userDoc(uid).get();
  }

  Future<void> setUserMerge(String uid, Map<String, dynamic> data) {
    return userDoc(uid).set(data, SetOptions(merge: true));
  }

  Future<void> ensureSessionDocExists({
    required String uid,
    required String sessaoId,
  }) {
    return sessionDoc(uid: uid, sessaoId: sessaoId)
        .set({}, SetOptions(merge: true));
  }

  Future<void> updateSession({
    required String uid,
    required String sessaoId,
    required Map<String, dynamic> data,
  }) {
    return sessionDoc(uid: uid, sessaoId: sessaoId).update(data);
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getSession({
    required String uid,
    required String sessaoId,
  }) {
    return sessionDoc(uid: uid, sessaoId: sessaoId).get();
  }

  Future<void> addTaskEvent({
    required String uid,
    required Map<String, dynamic> data,
  }) {
    return taskEventsCollection(uid).add(data);
  }
}
