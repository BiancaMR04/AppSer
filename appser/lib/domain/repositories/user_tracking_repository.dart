abstract class UserTrackingRepository {
  Future<void> registrarClique({
    required String sessaoId,
    required String tipo,
    required String itemId,
  });

  Future<void> registrarDataInicioSeNaoExistir();

  Future<List<int>> sessoesDesbloqueadas();

  Future<void> registrarFinalizacaoSessao(String sessaoId);

  Future<void> registrarTarefaCompleta({
    required String sessaoId,
    required String tipo,
    required String itemId,
    required bool isSupplementary,
    String? title,
    String? path,
    int? durationSeconds,
    String mode = 'auto',
  });

  Future<void> registrarTarefaParcial({
    required String sessaoId,
    required String tipo,
    required String itemId,
    required bool isSupplementary,
    required int positionSeconds,
    int? durationSeconds,
    String? title,
    String? path,
  });
}
