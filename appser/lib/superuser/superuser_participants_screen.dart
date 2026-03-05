import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:appser/core/theme/app_colors.dart';
import 'package:appser/presentation/widgets/app_background.dart';
import 'package:appser/presentation/widgets/app_scaffold.dart';

import '../presentation/controllers/superuser_controller.dart';

class SuperuserParticipantsScreen extends StatefulWidget {
  const SuperuserParticipantsScreen({super.key});

  @override
  State<SuperuserParticipantsScreen> createState() =>
      _SuperuserParticipantsScreenState();
}

class _SuperuserParticipantsScreenState extends State<SuperuserParticipantsScreen> {
  late Future<List<Map<String, dynamic>>> _usuariosFuture;

  Rect? _shareOriginRect() {
    final renderObject = context.findRenderObject();
    if (renderObject is RenderBox) {
      return renderObject.localToGlobal(Offset.zero) & renderObject.size;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _usuariosFuture = _buscarUsuarios();
  }

  static const Map<String, String> _nomesSessoesAmigaveis = {
    'sessao_0': 'Sessão 0',
    'sessao_1': 'Sessão 1',
    'sessao_2': 'Sessão 2',
    'sessao_3': 'Sessão 3',
    'sessao_4': 'Sessão 4',
    'sessao_5': 'Sessão 5',
    'sessao_6': 'Sessão 6',
    'sessao_7': 'Sessão 7',
    'sessao_8': 'Sessão 8',
  };

  static const Map<String, String> _nomeParaId = {
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

  String _formatarItem(String raw) {
    final semPrefixo = raw.replaceAll(RegExp(r'^(video_|audio_|pdf_)'), '');
    return _nomeParaId.entries
        .firstWhere(
          (entry) =>
              entry.key.toLowerCase().replaceAll(RegExp(r'["\s]'), '') ==
              semPrefixo.toLowerCase().replaceAll(RegExp(r'["\s]'), ''),
          orElse: () => MapEntry(semPrefixo, semPrefixo),
        )
        .value;
  }

  Future<List<Map<String, dynamic>>> _buscarUsuarios() {
    return context.read<SuperuserController>().buscarUsuarios();
  }

  Future<void> _exportarCsv() async {
    if (!mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _BlockingLoadingDialog(message: 'Gerando CSV...'),
    );

    String? path;
    Object? error;
    try {
      path = await context.read<SuperuserController>().exportarParaCsv();
    } catch (e) {
      error = e;
    } finally {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }

    if (!mounted) return;
    if (error != null || path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível exportar o CSV.')),
      );
      return;
    }

    try {
      await Share.shareXFiles(
        [XFile(path)],
        text: 'Relatório MBRP (CSV)',
        sharePositionOrigin: _shareOriginRect(),
      );
    } catch (_) {
      // Se o share falhar, ainda mostramos o caminho do arquivo.
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('CSV gerado. Arquivo: $path')),
    );
  }

  void _tentarNovamente() {
    setState(() {
      _usuariosFuture = _buscarUsuarios();
    });
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final tileTheme = baseTheme.copyWith(
      dividerColor: Colors.transparent,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: AppColors.primaryBlue,
        secondary: AppColors.primaryBlue,
      ),
    );

    return AppScaffold(
      appBar: AppBar(
        title: const Text(
          'Participantes',
          style:
              TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
        ),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportarCsv,
            tooltip: 'Exportar CSV',
          )
        ],
      ),
      body: Stack(
        children: [
          AppBackground(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _usuariosFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Não foi possível carregar os participantes.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton(
                            onPressed: _tentarNovamente,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final usuarios = snapshot.data!;

                if (usuarios.isEmpty) {
                  return const Center(child: Text('Nenhum participante encontrado.'));
                }

                return ListView.builder(
                  itemCount: usuarios.length,
                  itemBuilder: (context, index) {
                    final usuario = usuarios[index];
                    final nome = (usuario['nome'] ?? 'Sem nome').toString();
                    final cpf = (usuario['cpf'] ?? 'Sem CPF').toString();

                    final sessoes = (usuario['sessoes'] as Map<String, dynamic>?) ??
                        <String, dynamic>{};

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 2,
                      color: Colors.white,
                      surfaceTintColor: Colors.transparent,
                      child: Theme(
                        data: tileTheme,
                        child: ExpansionTile(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          collapsedShape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          backgroundColor: Colors.transparent,
                          collapsedBackgroundColor: Colors.transparent,
                          iconColor: AppColors.primaryBlue,
                          collapsedIconColor: AppColors.primaryBlue,
                          tilePadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          title: Text(
                            '$nome ($cpf)',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          children: sessoes.entries.map((sessaoEntry) {
                            final sessaoId = sessaoEntry.key;
                            final dadosSessao = (sessaoEntry.value as Map<String, dynamic>?) ??
                                <String, dynamic>{};

                            final vezesFinalizada =
                                (dadosSessao['vezesFinalizada'] ?? 0).toString();
                            final vezesFinalizadaPorConclusao =
                                (dadosSessao['vezesFinalizadaPorConclusao'] ?? 0)
                                    .toString();

                            final tarefasCompletasTotal =
                                (dadosSessao['tarefasCompletasTotal'] ?? 0)
                                    .toString();
                            final tarefasParciaisTotal =
                                (dadosSessao['tarefasParciaisTotal'] ?? 0)
                                    .toString();

                            final cliques = Map<String, int>.from(
                                (dadosSessao['cliques'] ?? const {}) as Map);
                            final conclusoesPorItemId =
                                (dadosSessao['conclusoesPorItemId']
                                        as Map<String, dynamic>?) ??
                                    <String, dynamic>{};
                            final parciaisPorItemId =
                                (dadosSessao['parciaisPorItemId']
                                        as Map<String, dynamic>?) ??
                                    <String, dynamic>{};

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 1,
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                color: Colors.white,
                                surfaceTintColor: Colors.transparent,
                                child: Theme(
                                  data: tileTheme,
                                  child: ExpansionTile(
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                    collapsedShape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                    backgroundColor: Colors.transparent,
                                    collapsedBackgroundColor: Colors.transparent,
                                    iconColor: AppColors.primaryBlue,
                                    collapsedIconColor: AppColors.primaryBlue,
                                    tilePadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                    title: Text(
                                      '${_nomesSessoesAmigaveis[sessaoId] ?? sessaoId}  |  clique: $vezesFinalizada x  |  conclusão: $vezesFinalizadaPorConclusao x',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Completas: $tarefasCompletasTotal  •  Parciais: $tarefasParciaisTotal',
                                      style: const TextStyle(
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    children: [
                                      if (conclusoesPorItemId.isNotEmpty)
                                        const ListTile(
                                          dense: true,
                                          title: Text(
                                            'Conclusões (por itemId)',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primaryBlue,
                                            ),
                                          ),
                                        ),
                                      for (final entry
                                          in conclusoesPorItemId.entries)
                                        ListTile(
                                          dense: true,
                                          title: Text(_formatarItem(entry.key)),
                                          trailing: Text('${entry.value}x'),
                                        ),
                                      if (parciaisPorItemId.isNotEmpty)
                                        const ListTile(
                                          dense: true,
                                          title: Text(
                                            'Parciais (por itemId)',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primaryBlue,
                                            ),
                                          ),
                                        ),
                                      for (final entry in parciaisPorItemId.entries)
                                        ListTile(
                                          dense: true,
                                          title: Text(_formatarItem(entry.key)),
                                          trailing: Text('${entry.value}x'),
                                        ),
                                      if (cliques.isNotEmpty)
                                        const ListTile(
                                          dense: true,
                                          title: Text(
                                            'Cliques (legado)',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primaryBlue,
                                            ),
                                          ),
                                        ),
                                      for (final entry in cliques.entries)
                                        ListTile(
                                          dense: true,
                                          title: Text(_formatarItem(entry.key)),
                                          trailing: Text('${entry.value}x'),
                                        ),
                                      if (conclusoesPorItemId.isEmpty &&
                                          parciaisPorItemId.isEmpty &&
                                          cliques.isEmpty)
                                        ListTile(
                                          title: Text(
                                            jsonEncode(dadosSessao),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                    ],
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
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockingLoadingDialog extends StatelessWidget {
  const _BlockingLoadingDialog({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.6),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
