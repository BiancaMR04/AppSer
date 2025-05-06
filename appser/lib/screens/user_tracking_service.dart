import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserTrackingService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

static Future<void> registrarClique({
  required String sessaoId,
  required String tipo,
  required String itemId,
}) async {
  final uid = _auth.currentUser?.uid;
  if (uid == null) return;

  final path = 'users/$uid/sessoes/$sessaoId';
  final docRef = _firestore.doc(path);
  final campo = 'cliques.${tipo}_$itemId';

  // Garante que o documento da sessão existe
  await docRef.set({}, SetOptions(merge: true));

  // Incrementa o contador do item clicado
  await docRef.update({
    campo: FieldValue.increment(1),
  });

  // Verifica se todos os itens obrigatórios foram clicados pelo menos 1 vez
  final snapshot = await docRef.get();
  final cliques = snapshot.data()?['cliques'] as Map<String, dynamic>? ?? {};

  final itensObrigatoriosPorSessao = {
  'sessao_1': ['checkin', 'preparacao_pratica_uva', 'pratica_uva', 'oque_e_mindfulness', 'posturas_copy', 'escaneamento_corporal', 'praticando_em_casa', 'checkout'],
  'sessao_2': ['checkin', 'escaneamento_automassagem', 'cinco_desafios', 'andando_na_rua', 'sofrimento_duplo', 'montanha', 'praticando_em_casa', 'checkout'],
  'sessao_3': ['checkin', 'consciencia_ouvir', 'caminhada_mindfulness', 'respiracao', 'parar_teoria', 'parar_audio', 'praticando_em_casa', 'checkout'],
  'sessao_4': ['checkin', 'consciencia_ver', 'meditacao_sentada', 'lista_gatilhos', 'falso_refugio', 'parar_situacao', 'checkout', 'praticando_em_casa'],
  'sessao_5': ['checkin', 'meditacao_sentada', 'poema_casa_hospedes', 'discussao_aceitacao_emocoes', 'revisao_cinco_desafios', 'movimentos_copy', 'movimentos_mindfulness', 'praticando_em_casa', 'checkout'],
  'sessao_6': ['checkin', 'pratica_pensamentos', 'ras', 'cadeira_reatividade', 'parar_audio', 'praticando_em_casa', 'checkout'],
  'sessao_7': ['checkin', 'bondade_amorosa', 'lista_atividades_diarias', 'visualizacao_fortalecedoras', 'funil_exaustao', 'parar_audio', 'praticando_em_casa', 'checkout'],
  'sessao_8': ['checkin', 'poema_suporte_estrategias', 'pratica_pedra', 'praticando_em_casa', 'checkout'],
};


  final itensObrigatorios = itensObrigatoriosPorSessao[sessaoId] ?? [];

  final counts = itensObrigatorios.map((item) {
  return cliques[item] ??
         cliques['video_$item'] ??
         cliques['audio_$item'] ??
         cliques['pdf_$item'] ?? 0;
}).toList();

final menorClique = counts.isEmpty ? 0 : counts.reduce((a, b) => a < b ? a : b);

// Verifica quantas vezes já foi finalizada
final vezesFinalizada = snapshot.data()?['vezesFinalizada'] ?? 0;

// Se todos os itens têm mais cliques do que a contagem de finalizações, registrar nova finalização
if (menorClique > vezesFinalizada) {
  await registrarFinalizacaoSessao(sessaoId);

}
print('Cliques atuais: $cliques');
print('Menor clique entre os itens: $menorClique');
print('Vezes finalizada atual: $vezesFinalizada');

}



  static Future<void> registrarDataInicioSeNaoExistir() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final docRef = _firestore.collection('users').doc(uid);
    final snapshot = await docRef.get();

    if (!snapshot.exists || snapshot.data()?['dataInicio'] == null) {
      await docRef.set({
        'dataInicio': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  static Future<List<int>> sessoesDesbloqueadas() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    final doc = await _firestore.collection('users').doc(uid).get();
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

static Future<void> registrarFinalizacaoSessao(String sessaoId) async {
  final uid = _auth.currentUser?.uid;
  if (uid == null) return;

  final path = 'users/$uid/sessoes/$sessaoId';
  final docRef = _firestore.doc(path);

  await docRef.set({}, SetOptions(merge: true)); // Garante que o doc exista

  await docRef.update({
    'vezesFinalizada': FieldValue.increment(1),
  });
}


}
