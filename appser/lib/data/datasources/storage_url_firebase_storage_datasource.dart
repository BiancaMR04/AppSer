import 'package:firebase_storage/firebase_storage.dart';

class StorageUrlFirebaseStorageDataSource {
  StorageUrlFirebaseStorageDataSource(this._storage);

  final FirebaseStorage _storage;

  Future<String> getDownloadUrl(String path) async {
    final ref = _storage.ref(path);
    return ref.getDownloadURL();
  }
}
