abstract interface class StorageUrlRepository {
  Future<String> getDownloadUrl(String path);
}
