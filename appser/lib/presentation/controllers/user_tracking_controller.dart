import '../../domain/repositories/user_tracking_repository.dart';

class UserTrackingController {
  UserTrackingController({required UserTrackingRepository repository})
      : _repository = repository;

  final UserTrackingRepository _repository;

  Future<void> registrarClique({
    required String sessaoId,
    required String tipo,
    required String itemId,
  }) {
    return _repository.registrarClique(
      sessaoId: sessaoId,
      tipo: tipo,
      itemId: itemId,
    );
  }

  Future<void> registrarDataInicioSeNaoExistir() {
    return _repository.registrarDataInicioSeNaoExistir();
  }

  Future<List<int>> sessoesDesbloqueadas() {
    return _repository.sessoesDesbloqueadas();
  }

  Future<void> registrarFinalizacaoSessao(String sessaoId) {
    return _repository.registrarFinalizacaoSessao(sessaoId);
  }
  
  Future<void> registrarTarefaCompleta({
    required String sessaoId,
    required String tipo,
    required String itemId,
    required bool isSupplementary,
    String? title,
    String? path,
    int? durationSeconds,
    String mode = 'auto',
  }) {
    return _repository.registrarTarefaCompleta(
      sessaoId: sessaoId,
      tipo: tipo,
      itemId: itemId,
      isSupplementary: isSupplementary,
      title: title,
      path: path,
      durationSeconds: durationSeconds,
      mode: mode,
    );
  }
  
  Future<void> registrarTarefaParcial({
    required String sessaoId,
    required String tipo,
    required String itemId,
    required bool isSupplementary,
    required int positionSeconds,
    int? durationSeconds,
    String? title,
    String? path,
  }) {
    return _repository.registrarTarefaParcial(
      sessaoId: sessaoId,
      tipo: tipo,
      itemId: itemId,
      isSupplementary: isSupplementary,
      positionSeconds: positionSeconds,
      durationSeconds: durationSeconds,
      title: title,
      path: path,
    );
  }
}
