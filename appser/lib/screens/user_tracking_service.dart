import '../presentation/controllers/user_tracking_controller.dart';

class UserTrackingService {
  // Adapter: mantém API estável (static) sem mudar chamadas existentes.
  // A implementação agora delega para o slice (controller/repository/datasource).
  static UserTrackingController? _controller;

  static void bind(UserTrackingController controller) {
    _controller ??= controller;
  }

  static UserTrackingController get _bound {
    final controller = _controller;
    if (controller == null) {
      throw StateError(
        'UserTrackingService não foi inicializado. Chame UserTrackingService.bind() no bootstrap.',
      );
    }
    return controller;
  }

  static Future<void> registrarClique({
    required String sessaoId,
    required String tipo,
    required String itemId,
  }) async {
    return _bound.registrarClique(
      sessaoId: sessaoId,
      tipo: tipo,
      itemId: itemId,
    );
  }

  static Future<void> registrarDataInicioSeNaoExistir() async {
    return _bound.registrarDataInicioSeNaoExistir();
  }

  static Future<List<int>> sessoesDesbloqueadas() async {
    return _bound.sessoesDesbloqueadas();
  }

  static Future<void> registrarFinalizacaoSessao(String sessaoId) async {
    return _bound.registrarFinalizacaoSessao(sessaoId);
  }

  static Future<void> registrarTarefaCompleta({
    required String sessaoId,
    required String tipo,
    required String itemId,
    required bool isSupplementary,
    String? title,
    String? path,
    int? durationSeconds,
    String mode = 'auto',
  }) async {
    return _bound.registrarTarefaCompleta(
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

  static Future<void> registrarTarefaParcial({
    required String sessaoId,
    required String tipo,
    required String itemId,
    required bool isSupplementary,
    required int positionSeconds,
    int? durationSeconds,
    String? title,
    String? path,
  }) async {
    return _bound.registrarTarefaParcial(
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
