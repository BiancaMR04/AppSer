import '../../domain/repositories/storage_url_repository.dart';

class StorageUrlController {
  StorageUrlController({required StorageUrlRepository repository})
      : _repository = repository;

  final StorageUrlRepository _repository;

  Future<String> getDownloadUrl(String path) => _repository.getDownloadUrl(path);
}
