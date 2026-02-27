import '../../domain/repositories/storage_url_repository.dart';
import '../datasources/storage_url_firebase_storage_datasource.dart';

class StorageUrlRepositoryImpl implements StorageUrlRepository {
  StorageUrlRepositoryImpl({required StorageUrlFirebaseStorageDataSource dataSource})
      : _dataSource = dataSource;

  final StorageUrlFirebaseStorageDataSource _dataSource;

  @override
  Future<String> getDownloadUrl(String path) => _dataSource.getDownloadUrl(path);
}
