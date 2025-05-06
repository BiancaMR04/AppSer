import 'package:appser/screens/authentication.dart';
import 'package:appser/services/authetication_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class SuperuserDashboard extends StatefulWidget {
  const SuperuserDashboard({super.key});

  @override
  State<SuperuserDashboard> createState() => _SuperuserDashboardState();
}

class _SuperuserDashboardState extends State<SuperuserDashboard> {
  final _firestore = FirebaseFirestore.instance;

  final nomesSessoesAmigaveis = {
    'sessao_1': 'Sessão 1',
    'sessao_2': 'Sessão 2',
    'sessao_3': 'Sessão 3',
    'sessao_4': 'Sessão 4',
    'sessao_5': 'Sessão 5',
    'sessao_6': 'Sessão 6',
    'sessao_7': 'Sessão 7',
    'sessao_8': 'Sessão 8',
  };

  static const Map<String, String> nomeParaId = {
    'checkin': 'Check-in',
    'preparacao_pratica_uva':
        'Preparação para o exercício "Prática da Uva Passa"',
    'pratica_uva': 'Prática da Uva Passa',
    'oque_e_mindfulness': 'O que é Mindfulness',
    'posturas_copy': 'Posturas copy',
    'escaneamento_corporal': 'Escaneamento corporal',
    'praticando_em_casa': 'Praticando em Casa',
    'checkout': 'Check-out',
    'escaneamento_automassagem': 'Escaneamento com automassagem',
    'cinco_desafios': 'Cinco desafios',
    'andando_na_rua': 'Andando na rua',
    'sofrimento_duplo': 'Primeiro e segundo sofrimento',
    'montanha': 'Montanha',
    'consciencia_ouvir': 'Consciência de ouvir',
    'caminhada_mindfulness': 'Caminhada mindfulness',
    'respiracao': 'Respiração',
    'parar_teoria': 'Parar Teoria',
    'parar_audio': 'Parar Áudio',
    'consciencia_ver': 'Consciência de Ver',
    'meditacao_sentada': 'Meditação Sentada',
    'lista_gatilhos': 'Lista de gatilhos',
    'falso_refugio': 'Falso Refúgio',
    'parar_situacao': 'Parar na situação desafiadora',
    'poema_casa_hospedes': 'Poema "A Casa de Hóspedes"',
    'discussao_aceitacao_emocoes': 'Discussão sobre aceitação e emoções',
    'revisao_cinco_desafios': 'Revendo os Cinco desafios da Sessão 2',
    'movimentos_copy': 'Movimentos Copy',
    'movimentos_mindfulness': 'Movimentos Mindfulness',
    'pratica_pensamentos': 'Prática dos Pensamentos',
    'ras': 'Te Recebo Aceito Solto (RAS)',
    'cadeira_reatividade': 'Cadeira da reatividade',
    'bondade_amorosa': 'Prática Bondade Amorosa',
    'lista_atividades_diarias': 'Lista de atividades diárias',
    'visualizacao_fortalecedoras': 'Visualização Atividades Fortalecedoras',
    'funil_exaustao': 'Funil da exaustão',
    'poema_suporte_estrategias':
        'Poema + Suporte e estratégias para prática continuada',
    'pratica_pedra': 'Prática da pedra',
  };

  String formatarItem(String raw) {
    String semPrefixo = raw.replaceAll(RegExp(r'^(video_|audio_|pdf_)'), '');
    return nomeParaId.entries
        .firstWhere(
          (entry) =>
              entry.key.toLowerCase().replaceAll(RegExp(r'["\s]'), '') ==
              semPrefixo.toLowerCase().replaceAll(RegExp(r'["\s]'), ''),
          orElse: () => MapEntry(semPrefixo, semPrefixo),
        )
        .value;
  }

  Future<List<Map<String, dynamic>>> buscarUsuarios() async {
    final usuariosSnapshot = await _firestore.collection('users').get();
    List<Map<String, dynamic>> usuarios = [];

    for (var doc in usuariosSnapshot.docs) {
      final userData = doc.data();
      final sessoesSnapshot = await doc.reference.collection('sessoes').get();

      Map<String, dynamic> sessoes = {};
      for (var sessaoDoc in sessoesSnapshot.docs) {
        final sessaoData = sessaoDoc.data();
        sessoes[sessaoDoc.id] = {
          'vezesFinalizada': sessaoData['vezesFinalizada'] ?? 0,
          'cliques': Map<String, int>.from(sessaoData['cliques'] ?? {}),
        };
      }

      usuarios.add({
        'nome': userData['nome'] ?? 'Sem nome',
        'cpf': userData['cpf'] ?? 'Sem CPF',
        'sessoes': sessoes,
      });
    }

    return usuarios;
  }

Future<void> _logout() async {
  await FirebaseAuth.instance.signOut();

}

  Future<void> exportarParaExcel() async {
    final usuarios = await buscarUsuarios();
    final excel = Excel.createExcel();
    final sheet = excel['Relatório'];

    // Cabeçalho
    sheet.appendRow([
      TextCellValue('Nome'),
      TextCellValue('CPF'),
      TextCellValue('Sessão'),
      TextCellValue('Atividade'),
      TextCellValue('Cliques'),
      TextCellValue('Sessões Finalizadas'),
    ]);

    for (var usuario in usuarios) {
      final nome = usuario['nome'];
      final cpf = usuario['cpf'];
      final sessoes = usuario['sessoes'] as Map<String, dynamic>;

      for (var sessaoEntry in sessoes.entries) {
        final sessaoId = sessaoEntry.key;
        final dadosSessao = sessaoEntry.value;
        final vezesFinalizada = dadosSessao['vezesFinalizada'] ?? 0;
        final cliques = Map<String, int>.from(dadosSessao['cliques']);

        for (var cliqueEntry in cliques.entries) {
          sheet.appendRow([
            TextCellValue(nome),
            TextCellValue(cpf),
            TextCellValue(nomesSessoesAmigaveis[sessaoId] ?? sessaoId),
            TextCellValue(formatarItem(cliqueEntry.key)),
            TextCellValue('${cliqueEntry.value}'),
            TextCellValue('$vezesFinalizada'),
          ]);
        }
      }
    }

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/relatorio_mbrp.xlsx';
    final file = File(path);
    final fileBytes = excel.encode();
    await file.writeAsBytes(fileBytes!);

    await Share.shareXFiles([XFile(path)], text: 'Relatório MBRP em Excel');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        title: const Text(
          'Painel do Superusuário',
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 70, 148, 166)),
        ),
        backgroundColor: Color.fromARGB(0, 70, 148, 166),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: exportarParaExcel,
            tooltip: 'Exportar para Excel',
          ),
            IconButton(
              icon: const Icon(Icons.logout,
                  color: Color.fromARGB(255, 0, 129, 71)),
              onPressed: _logout,
              tooltip: 'Sair',
            ),
        ],
      ),
      body: Stack(
        children: [
          // FUNDO (imagem ou cor)
          Positioned.fill(
            child: Image.asset(
              'assets/Registrar.png',
              fit: BoxFit.cover,
            ),
          ),

          FutureBuilder<List<Map<String, dynamic>>>(
              future: buscarUsuarios(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final usuarios = snapshot.data!;

                return ListView.builder(
                  itemCount: usuarios.length,
                  itemBuilder: (context, index) {
                    final usuario = usuarios[index];

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      elevation: 4,
                      color: const Color(0xFFEFF9F7), // tom claro de verde/azul
                      child: Theme(
                        data: Theme.of(context)
                            .copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          collapsedShape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          tilePadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          title: Text(
                            '${usuario['nome']} (${usuario['cpf']})',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          children: (usuario['sessoes'] as Map<String, dynamic>)
                              .entries
                              .map((sessaoEntry) {
                            final sessaoId = sessaoEntry.key;
                            final dadosSessao = sessaoEntry.value;
                            final cliques =
                                Map<String, int>.from(dadosSessao['cliques']);

                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                      dividerColor: Colors.transparent),
                                  child: ExpansionTile(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    collapsedShape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    tilePadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                    title: Text(
                                      '${nomesSessoesAmigaveis[sessaoId] ?? sessaoId} - Finalizada ${dadosSessao['vezesFinalizada']}x',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.normal),
                                    ),
                                    children: cliques.entries.map((entry) {
                                      return ListTile(
                                        title: Text(formatarItem(entry.key)),
                                        trailing: Text('${entry.value}x'),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                );
              }),
        ],
      ),
    );
  }
}
