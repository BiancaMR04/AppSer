import '../../domain/repositories/storage_url_repository.dart';
import '../datasources/storage_url_firebase_storage_datasource.dart';

class StorageUrlRepositoryImpl implements StorageUrlRepository {
  StorageUrlRepositoryImpl({required StorageUrlFirebaseStorageDataSource dataSource})
      : _dataSource = dataSource;

  final StorageUrlFirebaseStorageDataSource _dataSource;
  final Map<String, String> _cachedUrls = <String, String>{};
  final Map<String, Future<String>> _inFlightRequests =
      <String, Future<String>>{};

  @override
  Future<String> getDownloadUrl(String path) {
    final normalizedPath = path.trim();
    if (normalizedPath.isEmpty) {
      return Future.value('');
    }

    final cached = _cachedUrls[normalizedPath];
    if (cached != null) {
      return Future.value(cached);
    }

    final inFlight = _inFlightRequests[normalizedPath];
    if (inFlight != null) {
      return inFlight;
    }

    final request = _dataSource.getDownloadUrl(normalizedPath).then((url) {
      _cachedUrls[normalizedPath] = url;
      return url;
    }).whenComplete(() {
      _inFlightRequests.remove(normalizedPath);
    });

    _inFlightRequests[normalizedPath] = request;
    return request;
  }
}
