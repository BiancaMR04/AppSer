import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/repositories/user_tracking_repository.dart';
import '../datasources/user_tracking_firestore_datasource.dart';

class UserTrackingRepositoryImpl implements UserTrackingRepository {
  UserTrackingRepositoryImpl({
    required FirebaseAuth auth,
    required UserTrackingFirestoreDataSource dataSource,
  })  : _auth = auth,
        _dataSource = dataSource;

  final FirebaseAuth _auth;
  final UserTrackingFirestoreDataSource _dataSource;

  @override
  Future<void> registrarClique({
    required String sessaoId,
    required String tipo,
    required String itemId,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final campo = 'cliques.${tipo}_$itemId';

    // Garante que o documento da sessão existe
    await _dataSource.ensureSessionDocExists(uid: uid, sessaoId: sessaoId);

    // Incrementa o contador do item clicado
    await _dataSource.updateSession(
      uid: uid,
      sessaoId: sessaoId,
      data: {
        campo: FieldValue.increment(1),
      },
    );

    // Verifica se todos os itens obrigatórios foram clicados pelo menos 1 vez
    final snapshot = await _dataSource.getSession(uid: uid, sessaoId: sessaoId);
    final cliques = snapshot.data()?['cliques'] as Map<String, dynamic>? ?? {};

    final itensObrigatoriosPorSessao = {
      'sessao_1': [
        'checkin',
        'preparacao_pratica_uva',
        'pratica_uva',
        'oque_e_mindfulness',
        'posturas_copy',
        'escaneamento_corporal',
        'praticando_em_casa',
        'checkout'
      ],
      'sessao_2': [
        'checkin',
        'escaneamento_automassagem',
        'cinco_desafios',
        'andando_na_rua',
        'sofrimento_duplo',
        'montanha',
        'praticando_em_casa',
        'checkout'
      ],
      'sessao_3': [
        'checkin',
        'consciencia_ouvir',
        'caminhada_mindfulness',
        'respiracao',
        'parar_teoria',
        'parar_audio',
        'praticando_em_casa',
        'checkout'
      ],
      'sessao_4': [
        'checkin',
        'consciencia_ver',
        'meditacao_sentada',
        'lista_gatilhos',
        'falso_refugio',
        'parar_situacao',
        'checkout',
        'praticando_em_casa'
      ],
      'sessao_5': [
        'checkin',
        'meditacao_sentada',
        'poema_casa_hospedes',
        'discussao_aceitacao_emocoes',
        'revisao_cinco_desafios',
        'movimentos_copy',
        'movimentos_mindfulness',
        'praticando_em_casa',
        'checkout'
      ],
      'sessao_6': [
        'checkin',
        'pratica_pensamentos',
        'ras',
        'cadeira_reatividade',
        'parar_audio',
        'praticando_em_casa',
        'checkout'
      ],
      'sessao_7': [
        'checkin',
        'bondade_amorosa',
        'lista_atividades_diarias',
        'visualizacao_fortalecedoras',
        'funil_exaustao',
        'parar_audio',
        'praticando_em_casa',
        'checkout'
      ],
      'sessao_8': [
        'checkin',
        'poema_suporte_estrategias',
        'pratica_pedra',
        'praticando_em_casa',
        'checkout'
      ],
    };

    final itensObrigatorios = itensObrigatoriosPorSessao[sessaoId] ?? [];

    final counts = itensObrigatorios.map((item) {
      return cliques[item] ??
          cliques['video_$item'] ??
          cliques['audio_$item'] ??
          cliques['pdf_$item'] ??
          0;
    }).toList();

    final menorClique = counts.isEmpty
        ? 0
        : counts.reduce((a, b) => a < b ? a : b);

    // Verifica quantas vezes já foi finalizada
    final vezesFinalizada = snapshot.data()?['vezesFinalizada'] ?? 0;

    // Se todos os itens têm mais cliques do que a contagem de finalizações, registrar nova finalização
    if (menorClique > vezesFinalizada) {
      await registrarFinalizacaoSessao(sessaoId);
    }

    // Mantém os prints existentes (sem mudança de comportamento)
    // ignore: avoid_print
    print('Cliques atuais: $cliques');
    // ignore: avoid_print
    print('Menor clique entre os itens: $menorClique');
    // ignore: avoid_print
    print('Vezes finalizada atual: $vezesFinalizada');
  }

  @override
  Future<void> registrarDataInicioSeNaoExistir() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await _dataSource.getUser(uid);

    if (!snapshot.exists || snapshot.data()?['dataInicio'] == null) {
      await _dataSource.setUserMerge(uid, {
        'dataInicio': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Future<List<int>> sessoesDesbloqueadas() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    final doc = await _dataSource.getUser(uid);
    final dataInicio = doc.data()?['dataInicio']?.toDate();

    if (dataInicio == null) return [];

    final agora = DateTime.now();
    final diasPassados = agora.difference(dataInicio).inDays;

    List<int> desbloqueadas = [];
    for (int i = 0; i <= 8; i++) {
      if (i == 0 || diasPassados >= (i - 1) * 7) {
        desbloqueadas.add(i);
      }
    }
    return desbloqueadas;
  }

  @override
  Future<void> registrarFinalizacaoSessao(String sessaoId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _dataSource.ensureSessionDocExists(uid: uid, sessaoId: sessaoId);

    await _dataSource.updateSession(
      uid: uid,
      sessaoId: sessaoId,
      data: {
        'vezesFinalizada': FieldValue.increment(1),
      },
    );
  }

  @override
  Future<void> registrarTarefaCompleta({
    required String sessaoId,
    required String tipo,
    required String itemId,
    required bool isSupplementary,
    String? title,
    String? path,
    int? durationSeconds,
    String mode = 'auto',
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _dataSource.ensureSessionDocExists(uid: uid, sessaoId: sessaoId);

    await _dataSource.addTaskEvent(
      uid: uid,
      data: {
        'eventType': 'task_complete',
        'createdAt': FieldValue.serverTimestamp(),
        'sessaoId': sessaoId,
        'tipo': tipo,
        'itemId': itemId,
        'isSupplementary': isSupplementary,
        'title': title,
        'path': path,
        'durationSeconds': durationSeconds,
        'mode': mode,
      },
    );

    await _dataSource.updateSession(
      uid: uid,
      sessaoId: sessaoId,
      data: {
        'conclusoesPorItemId.$itemId': FieldValue.increment(1),
        'conclusoesPorTipoItem.${tipo}_$itemId': FieldValue.increment(1),
        'tarefasCompletasTotal': FieldValue.increment(1),
      },
    );

    if (isSupplementary) return;

    final snapshot = await _dataSource.getSession(uid: uid, sessaoId: sessaoId);
    final conclusoesPorItemId =
        snapshot.data()?['conclusoesPorItemId'] as Map<String, dynamic>? ?? {};
    final vezesFinalizadaPorConclusao =
        snapshot.data()?['vezesFinalizadaPorConclusao'] ?? 0;

    final itensObrigatoriosPorSessao = {
      'sessao_1': [
        'checkin',
        'preparacao_pratica_uva',
        'pratica_uva',
        'oque_e_mindfulness',
        'posturas_copy',
        'escaneamento_corporal',
        'praticando_em_casa',
        'checkout'
      ],
      'sessao_2': [
        'checkin',
        'escaneamento_automassagem',
        'cinco_desafios',
        'andando_na_rua',
        'sofrimento_duplo',
        'montanha',
        'praticando_em_casa',
        'checkout'
      ],
      'sessao_3': [
        'checkin',
        'consciencia_ouvir',
        'caminhada_mindfulness',
        'respiracao',
        'parar_teoria',
        'parar_audio',
        'praticando_em_casa',
        'checkout'
      ],
      'sessao_4': [
        'checkin',
        'consciencia_ver',
        'meditacao_sentada',
        'lista_gatilhos',
        'falso_refugio',
        'parar_situacao',
        'checkout',
        'praticando_em_casa'
      ],
      'sessao_5': [
        'checkin',
        'meditacao_sentada',
        'poema_casa_hospedes',
        'discussao_aceitacao_emocoes',
        'revisao_cinco_desafios',
        'movimentos_copy',
        'movimentos_mindfulness',
        'praticando_em_casa',
        'checkout'
      ],
      'sessao_6': [
        'checkin',
        'pratica_pensamentos',
        'ras',
        'cadeira_reatividade',
        'parar_audio',
        'praticando_em_casa',
        'checkout'
      ],
      'sessao_7': [
        'checkin',
        'bondade_amorosa',
        'lista_atividades_diarias',
        'visualizacao_fortalecedoras',
        'funil_exaustao',
        'parar_audio',
        'praticando_em_casa',
        'checkout'
      ],
      'sessao_8': [
        'checkin',
        'poema_suporte_estrategias',
        'pratica_pedra',
        'praticando_em_casa',
        'checkout'
      ],
    };

    final itensObrigatorios = itensObrigatoriosPorSessao[sessaoId] ?? [];
    final counts = itensObrigatorios
        .map((id) => (conclusoesPorItemId[id] ?? 0) as num)
        .map((n) => n.toInt())
        .toList();

    final menorConclusao =
        counts.isEmpty ? 0 : counts.reduce((a, b) => a < b ? a : b);

    if (menorConclusao > vezesFinalizadaPorConclusao) {
      await _dataSource.updateSession(
        uid: uid,
        sessaoId: sessaoId,
        data: {
          'vezesFinalizadaPorConclusao': FieldValue.increment(1),
        },
      );
    }
  }

  @override
  Future<void> registrarTarefaParcial({
    required String sessaoId,
    required String tipo,
    required String itemId,
    required bool isSupplementary,
    required int positionSeconds,
    int? durationSeconds,
    String? title,
    String? path,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _dataSource.ensureSessionDocExists(uid: uid, sessaoId: sessaoId);

    final minute = positionSeconds ~/ 60;

    await _dataSource.addTaskEvent(
      uid: uid,
      data: {
        'eventType': 'task_partial',
        'createdAt': FieldValue.serverTimestamp(),
        'sessaoId': sessaoId,
        'tipo': tipo,
        'itemId': itemId,
        'isSupplementary': isSupplementary,
        'title': title,
        'path': path,
        'positionSeconds': positionSeconds,
        'positionMinute': minute,
        'durationSeconds': durationSeconds,
      },
    );

    await _dataSource.updateSession(
      uid: uid,
      sessaoId: sessaoId,
      data: {
        'parciaisPorItemId.$itemId': FieldValue.increment(1),
        'parciaisPorTipoItem.${tipo}_$itemId': FieldValue.increment(1),
        'tarefasParciaisTotal': FieldValue.increment(1),
      },
    );
  }
}
