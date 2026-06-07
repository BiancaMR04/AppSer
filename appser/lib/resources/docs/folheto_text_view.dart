import 'package:appser/core/theme/app_colors.dart';
import 'package:appser/presentation/widgets/app_background.dart';
import 'package:appser/presentation/widgets/app_back_app_bar.dart';
import 'package:appser/presentation/widgets/app_bottom_nav_bar.dart';
import 'package:appser/presentation/widgets/app_scaffold.dart';
import 'package:appser/presentation/controllers/storage_url_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../screens/user_tracking_service.dart';

class FolhetoTextViewerScreen extends StatefulWidget {
  final String title;
  final String text;

  final String? sessaoId;
  final String? itemId;
  final String? scrollToSection;

  const FolhetoTextViewerScreen({
    super.key,
    required this.title,
    required this.text,
    this.sessaoId,
    this.itemId,
    this.scrollToSection,
  });

  @override
  State<FolhetoTextViewerScreen> createState() =>
      _FolhetoTextViewerScreenState();
}

class _FolhetoTextViewerScreenState extends State<FolhetoTextViewerScreen> {
  bool _loggedOpen = false;
  late ScrollController _scrollController;

  bool get _isSession5GuestHousePoemMaterial {
    return widget.text.toUpperCase().contains('CASA DE HÓSPEDES') &&
        widget.text.toUpperCase().contains('RUMI');
  }

  bool get _isNeedsListMaterial {
    // Material avulso da Sessão 4 (Lista de Necessidades) deve exibir apenas texto,
    // sem planilhas editáveis que pertencem ao folheto.
    return widget.text
        .toUpperCase()
        .contains('LISTA DE NECESSIDADES HUMANAS UNIVERSAIS');
  }

  bool get _isSession7DailyActivitiesMaterial {
    return _effectiveSessionNumber() == 7 &&
        widget.text
            .toUpperCase()
            .contains('PLANILHA DE ATIVIDADES DI\u00C1RIAS');
  }

  void _scrollToSectionIfNeeded() {
    if (widget.scrollToSection == null) return;

    final searchTerm = 'PLANILHA';
    final targetText = widget.text.toUpperCase();
    final index = targetText.indexOf(searchTerm);

    if (index < 0) return; // Seção não encontrada

    // Estima a posição (aproximadamente 60 pixels por linha de texto)
    final estimatedLineCount = targetText.substring(0, index).split('\n').length;
    final estimatedOffset = estimatedLineCount * 60.0;

    _scrollController.animateTo(
      estimatedOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  static const String _planilhaNotandoGatilhosDescricao =
      'Nessa semana preste atenção no que provoca em você a vontade de reagir automaticamente ou de forma impulsiva. Use as questões seguintes para trazer à consciência os detalhes das experiências em que isso acontece.';

  static const String _situacoesDesafiadorasInstrucao =
      'Instruções: Na coluna da esquerda, liste qualquer situação (pessoas, locais, relacionamentos, emoções, eventos) que aconteça nessa semana que pareça desafiadora ou desencadeadora de gatilhos. Na próxima coluna, escreva o que você notou sobre suas reações, especialmente suas sensações, pensamentos e emoções que podem ser futuras dicas para você usar o PARAR. Na terceira coluna, anote se você fez o PARAR e, na coluna final, escreva sua resposta para essas situações.';

  late final _EditableTableController _gatilhos;
  late final _EditableTableController _situacoesDesafiadoras;
  late final _EditableTableController _cadeiaReatividades;
  late final _EditableTableController _atividadesEstresse;
  late final _EditableTableController _atividadesPrazer;
  late final _EditableTableController _acompanhamento;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSectionIfNeeded());

    final sessionNumber = _effectiveSessionNumber();

    _gatilhos = _EditableTableController(
      tableKey: _tableKeyFor('planilha_notando_gatilhos', sessionNumber),
      columns: const [
        'Dia/data',
        'Situação/gatilho',
        'Sensações',
        'Estados de espírito/emoções',
        'Pensamentos',
        'O que fez?',
      ],
      rowCount: 4,
    );

    _acompanhamento = _EditableTableController(
      tableKey: _tableKeyFor('planilha_acompanhamento_diario', sessionNumber),
      columns: _acompanhamentoColumnsFor(sessionNumber),
      rowCount: 4,
    );

    _situacoesDesafiadoras = _EditableTableController(
      tableKey: _tableKeyFor('planilha_situacoes_desafiadoras', sessionNumber),
      columns: const [
        'Situações de alto risco/gatilhos',
        'Reações (sensações/pensamentos/sentimentos)',
        'Fez o PARAR? (sim/não)',
        'Como você respondeu?',
      ],
      rowCount: 6,
    );

    _cadeiaReatividades = _EditableTableController(
      tableKey: _tableKeyFor('planilha_cadeia_reatividades', sessionNumber),
      columns: const [
        'Situação/gatilho',
        'Reação inicial',
        'Percurso (pensamentos/sensações/emoções/impulsos)',
        'Resposta alternativa possível',
      ],
      rowCount: 3,
    );

    _atividadesEstresse = _EditableTableController(
      tableKey:
          _tableKeyFor('planilha_atividades_diarias_estresse', sessionNumber),
      columns: const [
        'Atividade, Pessoa, Lugar, Situação',
        'Como você se sente?',
      ],
      rowCount: sessionNumber == 7 ? 3 : 5,
    );

    _atividadesPrazer = _EditableTableController(
      tableKey:
          _tableKeyFor('planilha_atividades_diarias_prazer', sessionNumber),
      columns: const [
        'Atividade, Pessoa, Lugar, Situação',
        'Como você se sente?',
      ],
      rowCount: sessionNumber == 7 ? 3 : 5,
    );

    _loadSavedTables();
    _logOpenOnce();
  }

  int? _effectiveSessionNumber() {
    final raw = widget.sessaoId?.trim();
    if (raw == null || raw.isEmpty) return null;
    final match =
        RegExp(r'^(?:sessao_)?(\d+)$', caseSensitive: false).firstMatch(raw);
    if (match == null) return null;
    return int.tryParse(match.group(1) ?? '');
  }

  String _tableKeyFor(String baseKey, int? sessionNumber) {
    // Evita misturar respostas entre sessões diferentes.
    final n = sessionNumber;
    if (n == null || n <= 0) return baseKey;
    return '${baseKey}_sessao_$n';
  }

  List<String> _acompanhamentoColumnsFor(int? sessionNumber) {
    // Sessão 3 tem uma planilha diferente (inclui PARAR).
    if (sessionNumber == 3) {
      return const [
        'Dia/data',
        'Prática formal: Quanto tempo praticou?',
        'PARAR: quantas vezes?',
        'PARAR: em qual atividade?',
        'Anotações/comentários',
      ];
    }

    // Sessão 4 inclui caminhada (andando) + PARAR.
    if (sessionNumber == 4) {
      return const [
        'Dia/data',
        'Prática formal com áudio: Quanto tempo praticou?',
        'PARAR: quantas vezes?',
        'Andando (caminhada mindful): praticou?',
        'Anotações/comentários',
      ];
    }

    // Sessão 5 tem PARAR (quantas vezes + em qual atividade) e Andando.
    if (sessionNumber == 5) {
      return const [
        'Dia/data',
        'Prática formal com áudio: Quanto tempo praticou?',
        'PARAR, espaço para respirar',
        'Andando',
        'Anotações/comentários',
      ];
    }

    // Sessão 6: PARAR (quantas vezes + em que situações) + anotações.
    if (sessionNumber == 6) {
      return const [
        'Dia/data',
        'Prática formal com áudio: Quanto tempo praticou?',
        'PARAR, espaço para respirar',
        'Anotações/comentários',
      ];
    }

    // Sessão 7: mesmo padrão da Sessão 6.
    if (sessionNumber == 7) {
      return const [
        'Dia/data',
        'Prática formal com áudio: Quanto tempo praticou?',
        'PARAR, espaço para respirar',
        'Anotações/comentários',
      ];
    }

    // Sessão 8: mesmo padrão da Sessão 6/7.
    if (sessionNumber == 8) {
      return const [
        'Dia/data',
        'Prática formal com áudio: Quanto tempo praticou?',
        'PARAR, espaço para respirar',
        'Anotações/comentários',
      ];
    }

    // Default (Sessões 1, 2 e demais enquanto não forem customizadas).
    return const [
      'Dia/data',
      'Prática formal com áudio: Quanto tempo praticou?',
      'Mindfulness em atividades diárias: qual atividade escolheu?',
      'Observações/comentários/desafios (aversão, desejos, sonolência, inquietação, dúvida)',
    ];
  }

  String _appBarTitleText() {
    final n = _effectiveSessionNumber();
    if (n != null && n > 0) {
      return 'Sessão $n';
    }
    return widget.title;
  }

  bool get _showGatilhosTable {
    // Mostra a planilha de gatilhos apenas quando o folheto tem essa seção.
    // (Ex.: Sessão 2.)
    if (_isNeedsListMaterial) return false;
    return widget.text.toUpperCase().contains('PLANILHA NOTANDO GATILHOS');
  }

  bool get _showSituacoesDesafiadorasTable {
    if (_isNeedsListMaterial) return false;
    final n = _effectiveSessionNumber();
    if (n == 4) return true;
    return widget.text
        .toUpperCase()
        .contains('USANDO O PARAR EM SITUAÇÕES DESAFIADORAS');
  }

  bool get _showCadeiaReatividadesTable {
    final n = _effectiveSessionNumber();
    // Sessão 6 usa um fluxograma (imagem) no lugar da tabela editável.
    if (n == 6) return false;
    return widget.text
        .toUpperCase()
        .contains('PLANILHA DA CADEIA DE REATIVIDADES');
  }

  bool get _showCadeiaReatividadesFluxograma {
    return _effectiveSessionNumber() == 6;
  }

  bool get _showAtividadesDiariasTables {
    if (_isSession7DailyActivitiesMaterial) return false;
    final n = _effectiveSessionNumber();
    if (n == 7) return true;
    return widget.text.toUpperCase().contains('PLANILHA DE ATIVIDADES DIÁRIAS');
  }

  @override
  void dispose() {
    _gatilhos.dispose();
    _situacoesDesafiadoras.dispose();
    _cadeiaReatividades.dispose();
    _atividadesEstresse.dispose();
    _atividadesPrazer.dispose();
    _acompanhamento.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _logOpenOnce() async {
    if (_loggedOpen) return;

    final sessaoId = widget.sessaoId;
    final itemId = widget.itemId;
    if (sessaoId == null || itemId == null) {
      _loggedOpen = true;
      return;
    }

    await UserTrackingService.registrarTarefaCompleta(
      sessaoId: sessaoId,
      tipo: 'pdf',
      itemId: itemId,
      isSupplementary: true,
      title: widget.title,
      path: 'inline_text',
      mode: 'open',
    );

    _loggedOpen = true;
  }

  String _responseDocId() {
    final sessaoId = widget.sessaoId?.trim();
    final itemId = widget.itemId?.trim();

    final safeSessao =
        (sessaoId == null || sessaoId.isEmpty) ? 'sessao' : sessaoId;
    final safeItem = (itemId == null || itemId.isEmpty) ? 'folheto' : itemId;

    return '${safeSessao}_$safeItem'.replaceAll('/', '_');
  }

  Future<void> _loadSavedTables() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final docId = _responseDocId();
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('folheto_respostas')
          .doc(docId)
          .get();

      final data = doc.data();
      if (data == null) return;

      if (_showGatilhosTable) {
        _gatilhos.loadFromJson(data[_gatilhos.tableKey]);
      }
      if (_showSituacoesDesafiadorasTable) {
        _situacoesDesafiadoras.loadFromJson(
          data[_situacoesDesafiadoras.tableKey],
        );
      }
      if (_showCadeiaReatividadesTable) {
        _cadeiaReatividades.loadFromJson(data[_cadeiaReatividades.tableKey]);
      }
      if (_showAtividadesDiariasTables || _isSession7DailyActivitiesMaterial) {
        _atividadesEstresse.loadFromJson(data[_atividadesEstresse.tableKey]);
        _atividadesPrazer.loadFromJson(data[_atividadesPrazer.tableKey]);
      }
      _acompanhamento.loadFromJson(data[_acompanhamento.tableKey]);

      if (!mounted) return;
      setState(() {});
    } catch (e) {
      // Best-effort: se não carregar, usuário pode preencher e salvar de novo.
      if (kDebugMode) {
        debugPrint('Folheto: erro ao carregar tabelas: $e');
      }
    }
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você precisa estar logado para salvar.')),
      );
      return;
    }

    final docId = _responseDocId();

    final payload = <String, dynamic>{
      'title': widget.title,
      'updatedAt': FieldValue.serverTimestamp(),
      _acompanhamento.tableKey: _acompanhamento.toJson(),
    };

    if (_showGatilhosTable) {
      payload[_gatilhos.tableKey] = _gatilhos.toJson();
    }

    if (_showSituacoesDesafiadorasTable) {
      payload[_situacoesDesafiadoras.tableKey] =
          _situacoesDesafiadoras.toJson();
    }

    if (_showCadeiaReatividadesTable) {
      payload[_cadeiaReatividades.tableKey] = _cadeiaReatividades.toJson();
    }

    if (_showAtividadesDiariasTables || _isSession7DailyActivitiesMaterial) {
      payload[_atividadesEstresse.tableKey] = _atividadesEstresse.toJson();
      payload[_atividadesPrazer.tableKey] = _atividadesPrazer.toJson();
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('folheto_respostas')
          .doc(docId)
          .set(payload, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Respostas salvas.')),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Folheto: erro ao salvar: $e');
      }
      if (!mounted) return;
      final message = kDebugMode
          ? 'Erro ao salvar: $e'
          : 'Erro ao salvar. Verifique sua conexão e tente novamente.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveSessionNumber = _effectiveSessionNumber();
    final displayText = _sanitizeText(
      widget.text,
      sessionNumber: effectiveSessionNumber,
    );
    final hasText = displayText.trim().isNotEmpty;
    final appBarTitleText = _appBarTitleText();
    final showBodyTitle = appBarTitleText != widget.title;

    final showInteractiveTables =
      !_isNeedsListMaterial && !_isSession5GuestHousePoemMaterial;

    const acompanhamentoTitle = 'PLANILHA DE ACOMPANHAMENTO DIÁRIO DE PRÁTICA';
    const acompanhamentoInstrucao =
        'Instruções: a cada dia registre suas práticas de meditação, anotando também quaisquer barreiras, observações ou comentários.';

    final isSession5 = effectiveSessionNumber == 5;
    const session5Anchor = 'POSTURAS E MOVIMENTOS MINDFUL';

    final isSession8 = effectiveSessionNumber == 8;
    const session8AnchorPrefix =
        'Existem muitas coisas que nós não controlamos';

    String? session5TextBefore;
    String? session5TextAfter;
    if (isSession5 && hasText) {
      final lines = displayText.replaceAll('\r\n', '\n').split('\n');
      final anchorIndex = lines.indexWhere((l) => l.trim() == session5Anchor);
      if (anchorIndex != -1) {
        session5TextBefore = lines.take(anchorIndex).join('\n').trim();
        session5TextAfter = lines.skip(anchorIndex).join('\n').trim();
      }
    }

    String? session8TextBefore;
    String? session8TextAfter;
    if (isSession8 && hasText) {
      final lines = displayText.replaceAll('\r\n', '\n').split('\n');
      final anchorIndex = lines.indexWhere(
        (l) => l.trim().startsWith(session8AnchorPrefix),
      );
      if (anchorIndex != -1) {
        // Inclui o parágrafo âncora no "antes" e insere a planilha logo depois.
        session8TextBefore = lines.take(anchorIndex + 1).join('\n').trim();
        session8TextAfter = lines.skip(anchorIndex + 1).join('\n').trim();
      }
    }

    final inlineTextBefore = session5TextBefore ?? session8TextBefore;
    final inlineTextAfter = session5TextAfter ?? session8TextAfter;

    final showAcompanhamentoInline = (isSession5 || isSession8) &&
        inlineTextBefore != null &&
      inlineTextAfter != null &&
      showInteractiveTables;

    return AppScaffold(
      extendBodyBehindAppBar: false,
      extendBody: false,
      appBar: AppBackAppBar(
        titleText: appBarTitleText,
        iconColor: Colors.grey,
      ),
      body: AppBackground(
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            if (showBodyTitle) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF232323),
                  ),
                ),
              ),
            ],
            if (_isSession7DailyActivitiesMaterial) ...[
              _Session7DailyActivitiesWorksheet(
                stressController: _atividadesEstresse,
                pleasureController: _atividadesPrazer,
              ),
              const SizedBox(height: 18),
            ] else if (hasText) ...[
              if (showAcompanhamentoInline) ...[
                if (inlineTextBefore!.trim().isNotEmpty) ...[
                  SelectionArea(
                    child: _StyledFolhetoText(
                      text: inlineTextBefore,
                      sessionNumber: effectiveSessionNumber,
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                const _SectionTitle(acompanhamentoTitle),
                const SizedBox(height: 6),
                const Text(
                  acompanhamentoInstrucao,
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.35,
                    color: Color(0xFF232323),
                  ),
                ),
                const SizedBox(height: 10),
                _EditableTableWidget(controller: _acompanhamento),
                const SizedBox(height: 18),
                SelectionArea(
                  child: _StyledFolhetoText(
                    text: inlineTextAfter!,
                    sessionNumber: effectiveSessionNumber,
                  ),
                ),
                const SizedBox(height: 18),
              ] else ...[
                SelectionArea(
                  child: _StyledFolhetoText(
                    text: displayText,
                    sessionNumber: effectiveSessionNumber,
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ] else ...[
              const Text(
                'Sem conteúdo de texto para exibir nesta sessão.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.35,
                  color: Color(0xFF232323),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
            ],
            if (_showGatilhosTable) ...[
              const _SectionTitle('PLANILHA NOTANDO GATILHOS'),
              const SizedBox(height: 6),
              const Text(
                _planilhaNotandoGatilhosDescricao,
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.35,
                  color: Color(0xFF232323),
                ),
              ),
              const SizedBox(height: 10),
              _EditableTableWidget(controller: _gatilhos),
              const SizedBox(height: 18),
            ],
            if (_showSituacoesDesafiadorasTable) ...[
              const _SectionTitle('USANDO O PARAR EM SITUAÇÕES DESAFIADORAS'),
              const SizedBox(height: 6),
              const Text(
                _situacoesDesafiadorasInstrucao,
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.35,
                  color: Color(0xFF232323),
                ),
              ),
              const SizedBox(height: 10),
              _EditableTableWidget(controller: _situacoesDesafiadoras),
              const SizedBox(height: 18),
            ],
            if (_showCadeiaReatividadesTable) ...[
              const _SectionTitle('Planilha da Cadeia de Reatividades'),
              const SizedBox(height: 10),
              const Text(
                'Pense em situações em que você reagiu no impulso. Registre o gatilho, a reação inicial, o percurso e uma resposta alternativa possível.',
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.35,
                  color: Color(0xFF232323),
                ),
              ),
              const SizedBox(height: 10),
              _EditableTableWidget(controller: _cadeiaReatividades),
              const SizedBox(height: 18),
            ],
            if (_showCadeiaReatividadesFluxograma) ...[
              const _SectionTitle('Planilha da Cadeia de Reatividades'),
              const SizedBox(height: 10),
              const Text(
                'Pense em situações que te levaram a reações precipitadas ou situações em que você agiu por impulso e se arrependeu depois. Escreva o gatilho, a reação inicial que o seguiu e os eventos ao longo de cada percurso possível nos círculos abaixo. Quais são as diferentes maneiras que você pode responder?',
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.35,
                  color: Color(0xFF232323),
                ),
              ),
              const SizedBox(height: 12),
              const _StorageImageSingle(
                  path: 'docs/materiaisseis/fluxograma.png'),
              const SizedBox(height: 18),
            ],
            if (_showAtividadesDiariasTables) ...[
              const _SectionTitle('Planilha de Atividades Diárias'),
              const SizedBox(height: 10),
              if (effectiveSessionNumber == 7) ...[
                const Text(
                  '- Liste atividades, pessoas e situações que você associe com estresse e emoções desafiadoras, ou que aumentem suas dúvidas com relação a si mesmo e descreva como você costuma se sentir quando se envolve nessas atividades.',
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.35,
                    color: Color(0xFF232323),
                  ),
                ),
                const SizedBox(height: 10),
                _EditableTableWidget(controller: _atividadesEstresse),
                const SizedBox(height: 18),
                const Text(
                  '- Liste atividades, pessoas e situações que você associe com prazer e que aumentem a sua autoconfiança. Perceba como costuma se sentir quando se envolve nessas atividades.',
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.35,
                    color: Color(0xFF232323),
                  ),
                ),
                const SizedBox(height: 10),
                _EditableTableWidget(controller: _atividadesPrazer),
                const SizedBox(height: 18),
              ] else ...[
                const Text(
                  'Liste atividades/pessoas/situações ligadas a estresse e, depois, ligadas a prazer/autoconfiança. Observe como você se sente em cada uma.',
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.35,
                    color: Color(0xFF232323),
                  ),
                ),
                const SizedBox(height: 10),
                const _SectionTitle('Estresse e emoções desafiadoras'),
                const SizedBox(height: 10),
                _EditableTableWidget(controller: _atividadesEstresse),
                const SizedBox(height: 18),
                const _SectionTitle('Prazer e autoconfiança'),
                const SizedBox(height: 10),
                _EditableTableWidget(controller: _atividadesPrazer),
                const SizedBox(height: 18),
              ],
            ],
            if (showInteractiveTables &&
                !_isSession7DailyActivitiesMaterial &&
                !showAcompanhamentoInline) ...[
              const _SectionTitle(acompanhamentoTitle),
              const SizedBox(height: 6),
              const Text(
                acompanhamentoInstrucao,
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.35,
                  color: Color(0xFF232323),
                ),
              ),
              const SizedBox(height: 10),
              _EditableTableWidget(controller: _acompanhamento),
              const SizedBox(height: 18),
            ],
            if (showInteractiveTables)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF60BFCD),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Salvar',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(),
    );
  }

  String _sanitizeText(
    String raw, {
    required int? sessionNumber,
  }) {
    // Muitos textos exportados incluem a “tabela” como texto.
    // Como as tabelas editáveis aparecem logo abaixo, removemos apenas o bloco
    // da planilha/tabela do texto — mas preservamos conteúdo que venha depois.
    final normalized = raw.replaceAll('\r\n', '\n');
    final lines = normalized.split('\n');

    bool isTableStart(String line) {
      final u = line.trim().toUpperCase();
      if (u.startsWith('PLANILHA')) {
        return u.contains('GATILHOS') ||
            u.contains('ACOMPANHAMENTO') ||
            u.contains('CADEIA') ||
            u.contains('ATIVIDADES');
      }

      // Sessão 4 pode ter uma “tabela” em texto sem começar com PLANILHA.
      // Só consideramos início se parecer que a tabela foi colada junto.
      if (u.startsWith('USANDO O PARAR EM SITUAÇÕES DESAFIADORAS')) {
        final full = normalized.toUpperCase();
        return full.contains('FEZ O PARAR') ||
            full.contains('SITUAÇÕES DE ALTO RISCO') ||
            full.contains('COMO VOCÊ RESPONDEU');
      }

      return false;
    }

    bool looksLikeTableLine(String line) {
      final t = line.trim();
      if (t.isEmpty) return true;
      final u = t.toUpperCase();

      // Títulos/labels comuns dentro da tabela.
      if (u.startsWith('(CAMPO EDITÁVEL')) return true;
      if (u.startsWith('CAMPO EDITÁVEL')) return true;
      if (u.startsWith('INSTRUÇÕES:')) return true;
      if (u == 'DIA/DATA' || u.startsWith('DIA/')) return true;
      if (u.contains('MINUTOS')) return true;
      if (u.contains('QUANTAS VEZES')) return true;
      if (u.contains('EM QUAL ATIVIDADE')) return true;
      if (u.contains('PRÁTICA FORMAL')) return true;
      if (u.contains('OBSERVAÇÕES') || u.contains('ANOTAÇÕES')) return true;
      if (u.contains('SITUAÇÃO/GATILHO') || u.contains('SITUAÇÕES'))
        return true;
      if (u.contains('REAÇÃO INICIAL')) return true;
      if (u.contains('PERCURSO')) return true;
      if (u.contains('RESPOSTA ALTERNATIVA')) return true;
      if (u.contains('ATIVIDADE, PESSOA, LUGAR, SITUAÇÃO')) return true;
      if (u.startsWith('LISTE ATIVIDADES')) return true;
      if (u.contains('COMO VOCÊ SE SENTE')) return true;
      if (u.contains('SENSAÇÕES') || u.contains('PENSAMENTOS')) return true;
      if (u.contains('ESTADOS DE ESPÍRITO') || u.contains('EMOÇÕES'))
        return true;
      if (u.contains('O QUE FEZ')) return true;
      if (u.contains('FEZ O PARAR')) return true;
      if (u.contains('COMO VOCÊ RESPONDEU')) return true;

      return false;
    }

    final out = <String>[];
    var skippingTable = false;
    var seenTableStart = false;

    for (final line in lines) {
      final trimmed = line.trim();

      // Sessão 4: esse bloco é exibido acima da tabela editável.
      if (sessionNumber == 4) {
        final upper = trimmed.toUpperCase();
        if (upper == 'USANDO O PARAR EM SITUAÇÕES DESAFIADORAS') {
          continue;
        }
        if (trimmed == _situacoesDesafiadorasInstrucao) {
          continue;
        }
      }

      if (!skippingTable) {
        if (isTableStart(line)) {
          skippingTable = true;
          seenTableStart = true;
          continue;
        }
        out.add(line);
        continue;
      }

      // Se aparecer outra planilha em sequência, continua pulando.
      if (isTableStart(line)) {
        continue;
      }

      // Estamos dentro do bloco da tabela. Continua pulando linhas “de tabela”.
      // Quando encontrar uma linha que não pareça tabela, encerramos o skip e
      // voltamos a adicionar o restante do texto.
      if (line.trim() == _planilhaNotandoGatilhosDescricao) {
        continue;
      }

      if (looksLikeTableLine(line)) {
        continue;
      }

      skippingTable = false;
      out.add(line);
    }

    final result = out.join('\n').trim();
    if (!seenTableStart) return normalized.trim();
    return result;
  }
}

class _StyledFolhetoText extends StatelessWidget {
  final String text;
  final int? sessionNumber;

  const _StyledFolhetoText({
    required this.text,
    required this.sessionNumber,
  });

  static const List<String> _boldPhrases = <String>[
    'escaneamento corporal:',
    'mindfulness na atividade diária:',
    'complete o diário de práticas:',
  ];

  static const Set<String> _session5BoldHeadingsNormalized = {
    'posicao da montanha',
    'tirando uma camiseta',
    'tirando uma camiseta ao contrario',
    'colhendo uma fruta',
    'dobrar para frente',
    'posicao de descanso final',
  };

  static const Set<String> _session8BoldHeadingsNormalized = {
    'projeto ser',
    'medita-nepsis unifesp',
    'formacao em mbrp',
    'casa de dharma',
    'centro de estudos budistas',
    'grupo tergar',
  };

  String _normalizeHeading(String s) {
    return s
        .trim()
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('’', "'")
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c')
        .toLowerCase();
  }

  static const Set<String> _session2ChallengeHeadings = {
    'Aversão',
    'Desejos ou vontade',
    'Inquietação ou agitação',
    'Sonolência ou torpor',
    'Dúvida',
  };

  static const String _centeredSession1Title =
      'MINDFULNESS, PILOTO AUTOMÁTICO E REATIVIDADE';

  static const String _session2PosturasIntro =
      'Existem algumas posturas do corpo que podem ser adotadas para fazer as práticas. Veja alguns exemplos:';

  static const String _session2ImagesAnchor12 =
      'Sentado(a) no chão em uma almofada, com as pernas cruzadas:';

  static const String _session2ImagesAnchor34 =
      'Sentado(a) na cadeira ou banco, com as pernas livres e os pés bem apoiados no chão. Se quiser pode colocar algum apoio:';

  static const String _session2ImagesAnchor67 =
      'Deitado(a) na cama ou no chão e, se for o caso, colocar apoios embaixo dos joelhos e pescoço:';

  static const Set<String> _session2VerticalAnchors = {
    _session2ImagesAnchor67,
  };

  static const Map<String, List<String>> _session2ImagesByAnchor = {
    // Sessão 2 usa imagens empacotadas no app (assets). Não usar paths absolutos.
    _session2ImagesAnchor12: [
      'assets/Sessao2--Imagem1.png',
      'assets/Sessao2--Imagem3.png',
    ],
    _session2ImagesAnchor34: [
      'assets/Sessao2--Imagem2.png',
    ],
  };

  static const String _session3ImagesAnchorAmpulheta =
      'PARAR, ESPAÇO PARA RESPIRAR';

  static const Map<String, List<String>> _session3ImagesByAnchor = {
    _session3ImagesAnchorAmpulheta: [
      'docs/materiaistres/Ampulheta.png',
    ],
  };

  static const Map<int, Map<String, List<String>>> _imagesBySessionAndAnchor = {
    2: _session2ImagesByAnchor,
    3: _session3ImagesByAnchor,
    5: _session5ImagesByAnchor,
    6: _session6ImagesByAnchor,
  };

  static const Map<int, Set<String>> _verticalAnchorsBySession = {
    2: _session2VerticalAnchors,
  };

  static String _normalizeAnchorKey(String s) {
    return s.replaceAll('\u00A0', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static const String _session8Book1 =
      'Atenção Plena Mindfulness. Como encontrar paz em um mundo frenético';
  static const String _session8Book2 =
      'Viva bem com a dor e a doença – O método da atenção plena Autor: Vidyamala Burch';
  static const String _session8Book3 =
      'Prevenção de Recaída Baseada em Mindfulness Para Comportamentos Aditivos';
  static const String _session8Book4 =
      'Aonde quer que você vá, é você que está lá: Um guia prático para cultivar a atenção plena na vida diária';
  static const String _session8Book5 =
      'Meditação é mais do que você pensa: Descubra o poder e a importância do mindfulness';
  static const String _session8Book6 = 'Caderno de exercícios de atenção plena';
  static const String _session8Book7 =
      'Manual prático de Mindfulness: um programa de oito semanas para libertar você da depressão, da ansiedade e do estresse emocional';

  static const String _session8App1 = 'MindBell';
  static const String _session8App2 = 'Insight Timer Meditação';
  static const String _session8App3 = 'Headspace';
  static const String _session8App4 = 'Calm';
  static const String _session8App5 = 'Breeth';
  static const String _session8App6 = 'Medito Foundation';
  static const String _session8App7 = 'Lojong: Meditação Mindfulness';

  static final Map<String, _LeftMediaSpec> _session8LeftMediaByTitle = {
    // Livros (capa mais vertical)
    _normalizeAnchorKey(_session8Book1): const _LeftMediaSpec(
      'docs/materiaisoito/livro_atencao-plena.jpg',
      aspectRatio: 2 / 3,
      width: 92,
    ),
    _normalizeAnchorKey(_session8Book2): const _LeftMediaSpec(
      'docs/materiaisoito/livro-Viva bem.jpg',
      aspectRatio: 2 / 3,
      width: 92,
    ),
    _normalizeAnchorKey(_session8Book3): const _LeftMediaSpec(
      'docs/materiaisoito/livro-prevencao-recaida.jpg',
      aspectRatio: 2 / 3,
      width: 92,
    ),
    _normalizeAnchorKey(_session8Book4): const _LeftMediaSpec(
      'docs/materiaisoito/livro-aonde quer que va.jpg',
      aspectRatio: 2 / 3,
      width: 92,
    ),
    _normalizeAnchorKey(_session8Book5): const _LeftMediaSpec(
      'docs/materiaisoito/livro meditacao.jpg',
      aspectRatio: 2 / 3,
      width: 92,
    ),
    _normalizeAnchorKey(_session8Book6): const _LeftMediaSpec(
      'docs/materiaisoito/livro-Caderno de exercícios.jpg',
      aspectRatio: 2 / 3,
      width: 92,
    ),
    _normalizeAnchorKey(_session8Book7): const _LeftMediaSpec(
      'docs/materiaisoito/livro-Manual prático.jpg',
      aspectRatio: 2 / 3,
      width: 92,
    ),

    // Apps (ícone mais quadrado)
    _normalizeAnchorKey(_session8App1): const _LeftMediaSpec(
      'docs/materiaisoito/app-MindBell.png',
      aspectRatio: 1,
      width: 76,
    ),
    _normalizeAnchorKey(_session8App2): const _LeftMediaSpec(
      'docs/materiaisoito/app-Insight.jpg',
      aspectRatio: 1,
      width: 76,
    ),
    _normalizeAnchorKey(_session8App3): const _LeftMediaSpec(
      'docs/materiaisoito/app-Headspace.png',
      aspectRatio: 1,
      width: 76,
    ),
    _normalizeAnchorKey(_session8App4): const _LeftMediaSpec(
      'docs/materiaisoito/app-Calm.jpg',
      aspectRatio: 1,
      width: 76,
    ),
    _normalizeAnchorKey(_session8App5): const _LeftMediaSpec(
      'docs/materiaisoito/app-Breeth.jpg',
      aspectRatio: 1,
      width: 76,
    ),
    _normalizeAnchorKey(_session8App6): const _LeftMediaSpec(
      'docs/materiaisoito/app-Medito Foundation.png',
      aspectRatio: 1,
      width: 76,
    ),
    _normalizeAnchorKey(_session8App7): const _LeftMediaSpec(
      'docs/materiaisoito/app-Lojong.jpg',
      aspectRatio: 1,
      width: 76,
    ),
  };

  static const String _session6ImagesAnchorFluxograma =
      'Pense em situações que te levaram a reações precipitadas ou situações em que você agiu por impulso e se arrependeu depois. Escreva o gatilho, a reação inicial que o seguiu e os eventos ao longo de cada percurso possível nos círculos abaixo. Quais são as diferentes maneiras que você pode responder?';

  static const String _session8PoemTitle = 'POEMA PARADOXO';
  static const String _session8PoemAuthor = 'Gunilla Norris';

  static const Map<String, List<String>> _session6ImagesByAnchor = {
    _session6ImagesAnchorFluxograma: [
      'docs/materiaisseis/fluxograma.png',
    ],
  };

  static const String _session5ImagesAnchorPosicaoMontanha =
      'Posicione os pés na largura do quadril, coluna reta, joelhos destravados, ombros relaxados e cóccix ligeiramente abaixado. Quando você inspirar, levante os braços e quando expirar volte-os para baixo pela lateral observando o peso dos braços, até alcançar os quadris.';

  static const String _session5ImagesAnchorDobrarParaFrente =
      'A partir da posição da montanha, dobre seus joelhos se precisar, e dobre seu corpo para frente, deixando suas mãos penduradas em direção ao chão ou segure os cotovelos opostos, somente deixe o corpo pendurado como uma boneca de pano, enquanto você respira até as costas. Sinta-se livre para dobrar os joelhos o quanto for necessário. Depois de alguns minutos, desenrole seu corpo até ficar de pé. Faça isso bem devagar, uma vértebra de cada vez.';

  static const String _session5ImagesAnchorDescansoFinal =
      'Complete sua pratica de movimentos descansando sua coluna com seus braços ao lado, mas um pouco longe do corpo, palmas das mãos viradas para cima, e os pés caídos para os lados. Permita que o peso do seu corpo fique todo no chão e mantenha sua respiração natural. Fique nesta posição por pelo menos 5 minutos, permanecendo presente e consciente sobre a experiência do seu corpo e sua mente.';

  static const Map<String, List<String>> _session5ImagesByAnchor = {
    'Posi\u00E7\u00E3o da montanha': [
      'assets/postura_posicao-da-montanha.png',
    ],
    'Posi\u00E7\u00E3o de descanso final': [
      'assets/postura_descanso-final.png',
    ],
    'PosiÃ§Ã£o da montanha': [
      'assets/postura_posicao-da-montanha.png',
    ],
    'Dobrar para frente': [
      'assets/postura_dobrar-para-frente.png',
    ],
    'PosiÃ§Ã£o de descanso final': [
      'assets/postura_descanso-final.png',
    ],
    _session5ImagesAnchorPosicaoMontanha: [
      'docs/materiaiscinco/postura_posicao-da-montanha.png',
    ],
    _session5ImagesAnchorDobrarParaFrente: [
      'docs/materiaiscinco/postura_dobrar-para-frente.png',
    ],
    _session5ImagesAnchorDescansoFinal: [
      'docs/materiaiscinco/postura_descanso-final.png',
    ],
  };

  bool _hasLetters(String s) {
    return RegExp(r'[A-Za-zÀ-ÖØ-öø-ÿ]').hasMatch(s);
  }

  bool _isAllCapsTitle(String line) {
    final trimmed = line.trim();
    if (trimmed.length < 5) return false;
    if (!_hasLetters(trimmed)) return false;
    return trimmed == trimmed.toUpperCase();
  }

  bool _isLabelLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return false;
    // Exemplos: "Orientações gerais:", "TEMA"
    if (trimmed == 'TEMA') return false;
    if (trimmed.endsWith(':')) return true;
    return false;
  }

  bool _startsQuote(String line) {
    final trimmed = line.trimLeft();
    return trimmed.startsWith('“') || trimmed.startsWith('"');
  }

  static const String _session3AdaptedLine =
      'Adaptado de Segal, Williams, e Teasdale (2002). Direitos autorais 2002 por The Guilford Press. Reimpresso em Mindfullness-Based Relapse Prevention for Addictive Behaviors: A Clinicican’s Guide por Sarah Bowen, naha Chawla, e G. Alan Marlatt (Guilford Press, 2011).';

  bool _isSession3PararPrefixLine(String trimmed) {
    if (sessionNumber != 3) return false;
    if (trimmed.length < 6) return false;
    final first = trimmed[0];
    if (first != 'P' && first != 'A' && first != 'R') return false;
    final dot = trimmed.indexOf('.');
    if (dot <= 0) return false;

    final prefix = trimmed.substring(0, dot + 1);
    final normalizedPrefix = prefix.replaceAll(RegExp(r'\s+'), ' ').trim();

    const allowed = {
      'P – Parar.',
      'A – Atentar.',
      'R – Respirar.',
      'A – Ampliar.',
      'R – Responder.',
    };

    return allowed.contains(normalizedPrefix);
  }

  Widget _buildSession3PararPrefixRichText(String trimmed) {
    final dot = trimmed.indexOf('.');
    final prefix = trimmed.substring(0, dot + 1);
    final rest = trimmed.substring(dot + 1).trimLeft();

    const baseStyle = TextStyle(
      fontSize: 15,
      height: 1.35,
      color: Color(0xFF232323),
    );

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
              text: prefix,
              style: baseStyle.copyWith(fontWeight: FontWeight.w700)),
          if (rest.isNotEmpty) TextSpan(text: ' $rest', style: baseStyle),
        ],
      ),
    );
  }

  bool _endsQuote(String line) {
    final trimmed = line.trimRight();
    return trimmed.endsWith('”') ||
        trimmed.endsWith('”.') ||
        trimmed.endsWith('"') ||
        trimmed.endsWith('".');
  }

  String? _stripListPrefix(String line) {
    // Detecta linhas no estilo lista e remove o prefixo.
    // Exemplos:
    // - "1. Texto" / "1) Texto"
    // - "a. Texto" / "b) Texto"
    // - "- Texto" / "• Texto" / "* Texto"
    final trimmed = line.trimLeft();

    final bullet = RegExp(r'^(?:[-•*–—])\s*').firstMatch(trimmed);
    if (bullet != null) {
      return trimmed.substring(bullet.end).trimRight();
    }

    final numbered =
        RegExp(r'^(?:\d{1,3}|[A-Za-z])(?:[\.|\)])\s+').firstMatch(trimmed);
    if (numbered != null) {
      return trimmed.substring(numbered.end).trimRight();
    }

    return null;
  }

  TextSpan _buildInlineBoldSpan(String line, TextStyle baseStyle) {
    final boldStyle = baseStyle.copyWith(fontWeight: FontWeight.w700);

    final lower = line.toLowerCase();
    var index = 0;
    final spans = <TextSpan>[];

    while (index < line.length) {
      int? bestStart;
      int? bestEnd;

      for (final phrase in _boldPhrases) {
        final start = lower.indexOf(phrase, index);
        if (start == -1) continue;
        final end = start + phrase.length;
        if (bestStart == null || start < bestStart) {
          bestStart = start;
          bestEnd = end;
        }
      }

      if (bestStart == null || bestEnd == null) {
        spans.add(TextSpan(text: line.substring(index), style: baseStyle));
        break;
      }

      if (bestStart > index) {
        spans.add(
          TextSpan(text: line.substring(index, bestStart), style: baseStyle),
        );
      }

      spans.add(
        TextSpan(text: line.substring(bestStart, bestEnd), style: boldStyle),
      );
      index = bestEnd;
    }

    return TextSpan(children: spans, style: baseStyle);
  }

  @override
  Widget build(BuildContext context) {
    const session4NeedsTitle = 'LISTA DE NECESSIDADES HUMANAS UNIVERSAIS';
    final isSession4NeedsList = sessionNumber == 4 &&
        text.toUpperCase().contains(session4NeedsTitle);
    final isSession5GuestHousePoem = sessionNumber == 5 &&
      text.toUpperCase().contains('CASA DE HÓSPEDES') &&
      text.toUpperCase().contains('RUMI');

    final lines = text.replaceAll('\r\n', '\n').split('\n');

    final children = <Widget>[];
    var inQuote = false;
    var expectAuthorLine = false;
    final injectedImageAnchors = <String>{};

    var inSession8Poem = false;

    var collectingNeedsItems = false;
    var seenNeedsTitle = false;
    final needsItems = <String>[];

    bool isNeedsItemLine(String s) {
      final t = s.trim();
      if (t.isEmpty) return false;
      // Itens da lista são palavras em caixa alta (com acentos).
      if (!RegExp(r'[A-Za-zÀ-ÖØ-öø-ÿ]').hasMatch(t)) return false;
      return t == t.toUpperCase();
    }

    List<List<String>> splitInto3Columns(List<String> items) {
      if (items.isEmpty) return const <List<String>>[[], [], []];

      final total = items.length;
      final base = total ~/ 3;
      final remainder = total % 3;
      final c1 = base + (remainder > 0 ? 1 : 0);
      final c2 = base + (remainder > 1 ? 1 : 0);
      final c3 = total - c1 - c2;

      final col1 = items.take(c1).toList(growable: false);
      final col2 = items.skip(c1).take(c2).toList(growable: false);
      final col3 = items.skip(c1 + c2).take(c3).toList(growable: false);
      return <List<String>>[col1, col2, col3];
    }

    Widget buildNeedsThreeColumns(List<String> items) {
      final cols = splitInto3Columns(items);

      const itemStyle = TextStyle(
        fontSize: 13.5,
        height: 1.2,
        color: Color(0xFF232323),
        fontWeight: FontWeight.w400,
      );

      Widget buildCol(List<String> colItems) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final it in colItems)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(it, style: itemStyle),
              ),
          ],
        );
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: buildCol(cols[0])),
          const SizedBox(width: 12),
          Expanded(child: buildCol(cols[1])),
          const SizedBox(width: 12),
          Expanded(child: buildCol(cols[2])),
        ],
      );
    }

    void flushNeedsItemsIfAny() {
      if (needsItems.isEmpty) {
        collectingNeedsItems = false;
        return;
      }

      children.add(const SizedBox(height: 12));
      children.add(buildNeedsThreeColumns(List.unmodifiable(needsItems)));
      children.add(const SizedBox(height: 12));

      needsItems.clear();
      collectingNeedsItems = false;
    }

    void maybeInjectSessionImages(String normalizedLine) {
      final n = sessionNumber;
      if (n == null) return;

      final byAnchor = _imagesBySessionAndAnchor[n];
      if (byAnchor == null) return;

      final images = byAnchor[normalizedLine];
      if (images == null || images.isEmpty) return;
      if (injectedImageAnchors.contains(normalizedLine)) return;
      injectedImageAnchors.add(normalizedLine);

      final verticalAnchors = _verticalAnchorsBySession[n] ?? const <String>{};

      children.add(const SizedBox(height: 12));

      if (images.length == 1) {
        children.add(_StorageImageSingle(path: images[0]));
      } else if (images.length == 2 &&
          verticalAnchors.contains(normalizedLine)) {
        children.add(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StorageImageSingle(path: images[0]),
              const SizedBox(height: 12),
              _StorageImageSingle(path: images[1]),
            ],
          ),
        );
      } else {
        children.add(
          _StorageImagesRow(
            leftPath: images[0],
            rightPath: images[1],
          ),
        );
      }

      children.add(const SizedBox(height: 12));
    }

    for (var i = 0; i < lines.length; i++) {
      final rawLine = lines[i];
      final line = rawLine.trimRight();
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        if (isSession4NeedsList && collectingNeedsItems) {
          flushNeedsItemsIfAny();
          continue;
        }
        children.add(const SizedBox(height: 10));
        continue;
      }

      if (isSession5GuestHousePoem) {
        final isQuoteStart = _startsQuote(trimmed);
        final isQuoteEnd = _endsQuote(trimmed);

        if (!inQuote && isQuoteStart) {
          inQuote = true;
        }

        if (inQuote) {
          children.add(
            Text(
              trimmed,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
                color: Color(0xFF232323),
                fontStyle: FontStyle.italic,
              ),
            ),
          );

          if (isQuoteEnd) {
            inQuote = false;
            expectAuthorLine = true;
          }
          continue;
        }

        final isPoemaHeading = trimmed.toUpperCase() == 'POEMA';
        final isCasaHospedesHeading =
            _normalizeHeading(trimmed) == 'casa de hospedes';

        children.add(
          Text(
            trimmed,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isPoemaHeading || isCasaHospedesHeading ? 16 : 15,
              height: 1.35,
              color: const Color(0xFF232323),
              fontWeight: isPoemaHeading || isCasaHospedesHeading
                  ? FontWeight.w700
                  : FontWeight.w400,
            ),
          ),
        );

        if (expectAuthorLine) {
          expectAuthorLine = false;
        }
        continue;
      }

      if (isSession4NeedsList) {
        final upper = trimmed.toUpperCase();
        if (!seenNeedsTitle && upper == session4NeedsTitle) {
          seenNeedsTitle = true;
          children.add(
            Text(
              trimmed,
              style: const TextStyle(
                fontSize: 16,
                height: 1.45,
                fontWeight: FontWeight.w800,
                color: AppColors.folhetoTitle,
              ),
            ),
          );
          continue;
        }

        final isItemCandidate =
            seenNeedsTitle && isNeedsItemLine(trimmed) && upper != session4NeedsTitle;

        if (collectingNeedsItems) {
          if (isItemCandidate) {
            needsItems.add(trimmed);
            continue;
          }

          flushNeedsItemsIfAny();
          // Continua o fluxo normal para renderizar a linha atual.
        } else if (isItemCandidate) {
          collectingNeedsItems = true;
          needsItems.add(trimmed);
          continue;
        }
      }

      final normalizedLine = trimmed.replaceAll('\u00A0', ' ').trim();
      final anchorKey = _normalizeAnchorKey(normalizedLine);

      if (sessionNumber == 5 &&
          (_imagesBySessionAndAnchor[5]?.containsKey(anchorKey) ?? false)) {
        maybeInjectSessionImages(anchorKey);
        if (anchorKey == _normalizeAnchorKey('Posi\u00E7\u00E3o da montanha')) {
          injectedImageAnchors.add(
            _normalizeAnchorKey(_session5ImagesAnchorPosicaoMontanha),
          );
        } else if (anchorKey ==
            _normalizeAnchorKey('Posi\u00E7\u00E3o de descanso final')) {
          injectedImageAnchors.add(
            _normalizeAnchorKey(_session5ImagesAnchorDescansoFinal),
          );
        }
        if (anchorKey == _normalizeAnchorKey('PosiÃ§Ã£o da montanha')) {
          injectedImageAnchors.add(
            _normalizeAnchorKey(_session5ImagesAnchorPosicaoMontanha),
          );
        } else if (anchorKey == _normalizeAnchorKey('Dobrar para frente')) {
          injectedImageAnchors.add(
            _normalizeAnchorKey(_session5ImagesAnchorDobrarParaFrente),
          );
        } else if (anchorKey ==
            _normalizeAnchorKey('PosiÃ§Ã£o de descanso final')) {
          injectedImageAnchors.add(
            _normalizeAnchorKey(_session5ImagesAnchorDescansoFinal),
          );
        }
      }

      if (sessionNumber == 8 && trimmed == _session8PoemTitle) {
        inSession8Poem = true;
      }

      // Sessão 8: renderiza capa + bloco do livro em linha.
      if (sessionNumber == 8) {
        final spec = _session8LeftMediaByTitle[anchorKey];
        if (spec != null) {
          final detailLines = <String>[trimmed];

          var j = i + 1;
          while (j < lines.length) {
            final next = lines[j].trimRight();
            final nextTrimmed = next.trim();
            if (nextTrimmed.isEmpty) break;

            // Segurança: evita consumir o início de um próximo livro.
            if (_session8LeftMediaByTitle
                .containsKey(_normalizeAnchorKey(nextTrimmed))) {
              break;
            }

            detailLines.add(nextTrimmed);
            j++;
          }

          children.add(
            _BookWithCover(
              coverPath: spec.path,
              lines: detailLines,
              coverAspectRatio: spec.aspectRatio,
              coverWidth: spec.width,
            ),
          );
          children.add(const SizedBox(height: 12));

          // Pula as linhas que já foram renderizadas no bloco.
          i = j;
          continue;
        }
      }

      final isQuoteStart = _startsQuote(trimmed);
      final isQuoteEnd = _endsQuote(trimmed);

      if (!inQuote && isQuoteStart) {
        inQuote = true;
      }

      if (inQuote) {
        children.add(
          Text(
            trimmed,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
              color: Color(0xFF232323),
              fontStyle: FontStyle.italic,
            ),
          ),
        );

        if (isQuoteEnd) {
          inQuote = false;
          expectAuthorLine = true;
        }
        continue;
      }

      if (expectAuthorLine) {
        children.add(
          Text(
            trimmed,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.35,
              color: Color(0xFF232323),
            ),
          ),
        );
        expectAuthorLine = false;
        maybeInjectSessionImages(normalizedLine);
        continue;
      }

      if (sessionNumber == 8 && inSession8Poem) {
        if (trimmed == _session8PoemAuthor) {
          inSession8Poem = false;
          children.add(
            const Text(
              _session8PoemAuthor,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.35,
                color: Color(0xFF232323),
              ),
            ),
          );
          maybeInjectSessionImages(normalizedLine);
          continue;
        }

        children.add(
          Text(
            trimmed,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
              color: Color(0xFF232323),
              fontStyle: FontStyle.italic,
            ),
          ),
        );
        maybeInjectSessionImages(normalizedLine);
        continue;
      }

      final bulletText = _stripListPrefix(trimmed);
      if (bulletText != null && bulletText.isNotEmpty) {
        final isSession8BoldBullet = sessionNumber == 8 &&
            _session8BoldHeadingsNormalized
                .contains(_normalizeHeading(bulletText.trim()));
        final isSession2ChallengeHeading = sessionNumber == 2 &&
            _session2ChallengeHeadings.contains(bulletText.trim());

        final display = '• ${bulletText.trim()}';

        // Sessão 8: bullets podem conter URLs; nesse caso, linkificamos sem
        // perder o prefixo de tópico.
        if (sessionNumber == 8 && _containsUrl(display)) {
          children.add(_LinkifiedLine(text: display));
          maybeInjectSessionImages(normalizedLine);
          continue;
        }

        if (isSession8BoldBullet) {
          children.add(
            Text(
              display,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
                color: Color(0xFF232323),
                fontWeight: FontWeight.w700,
              ),
            ),
          );
          maybeInjectSessionImages(normalizedLine);
          continue;
        }

        children.add(
          Text.rich(
            _buildInlineBoldSpan(
              display,
              TextStyle(
                fontSize: 15,
                height: 1.4,
                color: isSession2ChallengeHeading
                    ? AppColors.navbarTitle
                    : const Color(0xFF232323),
              ),
            ),
          ),
        );
        maybeInjectSessionImages(normalizedLine);
        continue;
      }

      if (sessionNumber == 8 && _containsUrl(trimmed)) {
        children.add(_LinkifiedLine(text: trimmed));
        maybeInjectSessionImages(normalizedLine);
        continue;
      }

      if (trimmed == 'TEMA') {
        children.add(
          const Text(
            'TEMA',
            style: TextStyle(
              fontSize: 16,
              height: 1.45,
              fontWeight: FontWeight.w800,
              color: AppColors.folhetoTitle,
            ),
          ),
        );
        maybeInjectSessionImages(normalizedLine);
        continue;
      }

      if (sessionNumber == 3 && trimmed == _session3AdaptedLine) {
        children.add(
          const Text(
            _session3AdaptedLine,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.35,
              color: Color(0xFF232323),
              fontStyle: FontStyle.italic,
            ),
          ),
        );
        maybeInjectSessionImages(normalizedLine);
        continue;
      }

      if (_isSession3PararPrefixLine(trimmed)) {
        children.add(_buildSession3PararPrefixRichText(trimmed));
        maybeInjectSessionImages(normalizedLine);
        continue;
      }

      if (trimmed == _centeredSession1Title) {
        children.add(
          Text(
            trimmed,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              height: 1.45,
              fontWeight: FontWeight.w800,
              color: AppColors.folhetoTitle,
            ),
          ),
        );
        maybeInjectSessionImages(normalizedLine);
        continue;
      }

      if (_isAllCapsTitle(trimmed)) {
        children.add(
          Text(
            trimmed,
            style: const TextStyle(
              fontSize: 16,
              height: 1.45,
              fontWeight: FontWeight.w800,
              color: AppColors.folhetoTitle,
            ),
          ),
        );
        maybeInjectSessionImages(normalizedLine);
        continue;
      }

      if (sessionNumber == 5 &&
          _session5BoldHeadingsNormalized
              .contains(_normalizeHeading(trimmed))) {
        children.add(
          Text(
            trimmed,
            style: const TextStyle(
              fontSize: 15,
              height: 1.35,
              color: Color(0xFF232323),
              fontWeight: FontWeight.w700,
            ),
          ),
        );
        maybeInjectSessionImages(normalizedLine);
        continue;
      }

      if (sessionNumber == 8 &&
          _session8BoldHeadingsNormalized
              .contains(_normalizeHeading(trimmed))) {
        children.add(
          Text(
            trimmed,
            style: const TextStyle(
              fontSize: 15,
              height: 1.35,
              color: Color(0xFF232323),
              fontWeight: FontWeight.w700,
            ),
          ),
        );
        maybeInjectSessionImages(normalizedLine);
        continue;
      }

      if (sessionNumber == 2 && trimmed == _session2PosturasIntro) {
        children.add(
          Text.rich(
            _buildInlineBoldSpan(
              trimmed,
              const TextStyle(
                fontSize: 15,
                height: 1.35,
                color: Color(0xFF232323),
              ),
            ),
          ),
        );
        maybeInjectSessionImages(normalizedLine);
        continue;
      }

      if (_isLabelLine(trimmed)) {
        children.add(
          Text(
            trimmed,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF232323),
              height: 1.4,
            ),
          ),
        );
        maybeInjectSessionImages(normalizedLine);
        continue;
      }

      children.add(
        Text.rich(
          _buildInlineBoldSpan(
            trimmed,
            const TextStyle(
              fontSize: 15,
              height: 1.35,
              color: Color(0xFF232323),
            ),
          ),
        ),
      );
      maybeInjectSessionImages(normalizedLine);
    }

    if (isSession4NeedsList && collectingNeedsItems) {
      flushNeedsItemsIfAny();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

bool _containsUrl(String text) {
  final lower = text.toLowerCase();
  return lower.contains('http://') ||
      lower.contains('https://') ||
      lower.contains('www.') ||
      RegExp(
        r'\b(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+(?:[a-z]{2,})(?:/[^\s<>]*)?\b',
        caseSensitive: false,
      ).hasMatch(text);
}

class _LinkifiedLine extends StatefulWidget {
  final String text;

  const _LinkifiedLine({required this.text});

  @override
  State<_LinkifiedLine> createState() => _LinkifiedLineState();

  static final RegExp urlRegex = RegExp(
    r'((?:https?://)\s*[^\s<>]+|(?:www\.)[^\s<>]+|(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+(?:[a-z]{2,})(?:/[^\s<>]*)?)',
    caseSensitive: false,
  );

  static final RegExp whitespaceRegex = RegExp(r'\s+');
  static final RegExp trailingPunctuationRegex = RegExp(
    '[\\]\\[\\)\\(\\}\\{\\.,;:!\\?"\u2019\u2018\u201D\u201C\u00BB\u00AB]+\$',
  );
}

class _LinkifiedLineState extends State<_LinkifiedLine> {
  final List<TapGestureRecognizer> _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
    super.dispose();
  }

  void _resetRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  bool _canJoinNextToken(String currentRawUrl, String nextToken) {
    final current =
        currentRawUrl.replaceAll(_LinkifiedLine.whitespaceRegex, '');
    if (current.endsWith('/') ||
        current.endsWith('://') ||
        current.endsWith('?') ||
        current.endsWith('=') ||
        current.endsWith('&') ||
        current.endsWith('#')) {
      return RegExp(r'^[A-Za-z0-9_\-]+$').hasMatch(nextToken);
    }
    return false;
  }

  int _extendMatchEnd(int start, int initialEnd) {
    var end = initialEnd;
    final text = widget.text;
    while (end < text.length) {
      final spaces =
          _LinkifiedLine.whitespaceRegex.matchAsPrefix(text.substring(end));
      if (spaces == null) break;

      final tokenStart = end + spaces.group(0)!.length;
      if (tokenStart >= text.length) break;

      final tokenMatch =
          RegExp(r'\S+').matchAsPrefix(text.substring(tokenStart));
      if (tokenMatch == null) break;
      final token = tokenMatch.group(0)!;

      final currentRawUrl = text.substring(start, end);
      if (!_canJoinNextToken(currentRawUrl, token)) break;

      end = tokenStart + token.length;
    }
    return end;
  }

  String _sanitizeUrl(String raw) {
    // Remove espaços (ex.: "https:// chat.whatsapp.com/..."),
    // e pontuação final comum que vem colada no texto.
    var u = raw.replaceAll(_LinkifiedLine.whitespaceRegex, '');
    u = u.replaceAll(_LinkifiedLine.trailingPunctuationRegex, '');
    if (u.toLowerCase().startsWith('www.')) {
      u = 'https://$u';
    }
    if (!u.toLowerCase().startsWith('http://') &&
        !u.toLowerCase().startsWith('https://')) {
      u = 'https://$u';
    }
    return u;
  }

  @override
  Widget build(BuildContext context) {
    _resetRecognizers();

    const baseStyle = TextStyle(
      fontSize: 15,
      height: 1.35,
      color: Color(0xFF232323),
    );

    final linkStyle = baseStyle.copyWith(decoration: TextDecoration.underline);

    final text = widget.text;

    final matches =
        _LinkifiedLine.urlRegex.allMatches(text).toList(growable: false);
    if (matches.isEmpty) {
      return Text(text, style: baseStyle);
    }

    final spans = <TextSpan>[];
    var index = 0;

    for (final m in matches) {
      final start = m.start;
      final end = _extendMatchEnd(start, m.end);
      final rawUrl = text.substring(start, end);

      if (start > index) {
        spans.add(
            TextSpan(text: text.substring(index, start), style: baseStyle));
      }

      final toOpen = _sanitizeUrl(rawUrl);
      final uri = Uri.tryParse(toOpen);

      TapGestureRecognizer? recognizer;
      if (uri != null) {
        recognizer = TapGestureRecognizer()
          ..onTap = () {
            launchUrl(uri, mode: LaunchMode.externalApplication);
          };
        _recognizers.add(recognizer);
      }

      spans.add(
        TextSpan(
          text: rawUrl,
          style: linkStyle,
          recognizer: recognizer,
        ),
      );

      index = end;
    }

    if (index < text.length) {
      spans.add(TextSpan(text: text.substring(index), style: baseStyle));
    }

    return Text.rich(TextSpan(children: spans));
  }
}

class _StorageImagesRow extends StatelessWidget {
  final String leftPath;
  final String rightPath;

  const _StorageImagesRow({
    required this.leftPath,
    required this.rightPath,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StorageImageCard(path: leftPath)),
        const SizedBox(width: 12),
        Expanded(child: _StorageImageCard(path: rightPath)),
      ],
    );
  }
}

class _LeftMediaSpec {
  final String path;
  final double aspectRatio;
  final double width;

  const _LeftMediaSpec(
    this.path, {
    required this.aspectRatio,
    required this.width,
  });
}

class _StorageImageSingle extends StatelessWidget {
  final String path;

  const _StorageImageSingle({required this.path});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final targetWidth = maxWidth > 360 ? 360.0 : maxWidth;
        return Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: targetWidth,
            child: _StorageImageCard(path: path),
          ),
        );
      },
    );
  }
}

class _StorageImageCard extends StatefulWidget {
  final String path;
  final double aspectRatio;
  final BoxFit fit;

  const _StorageImageCard({
    required this.path,
    this.aspectRatio = 4 / 3,
    this.fit = BoxFit.contain,
  });

  @override
  State<_StorageImageCard> createState() => _StorageImageCardState();
}

class _StorageImageCardState extends State<_StorageImageCard> {
  Future<String>? _urlFuture;

  bool get _isAssetPath => widget.path.trim().startsWith('assets/');
  bool get _isHttpUrl {
    final p = widget.path.trim().toLowerCase();
    return p.startsWith('http://') || p.startsWith('https://');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isAssetPath || _isHttpUrl) return;
    _urlFuture ??=
      context.read<StorageUrlController>().getDownloadUrl(widget.path);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: ColoredBox(
        color: Colors.white,
        child: AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: _isAssetPath
              ? Image.asset(
                  widget.path,
                  fit: widget.fit,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) {
                    if (kDebugMode) {
                      debugPrint('Erro ao carregar asset: ${widget.path} ($error)');
                    }
                    return const Center(
                      child: Text(
                        'Erro ao carregar imagem',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF232323),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                )
              : _isHttpUrl
                  ? Image.network(
                      widget.path,
                      fit: widget.fit,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (context, error, stackTrace) {
                        if (kDebugMode) {
                          debugPrint(
                              'Erro ao carregar URL: ${widget.path} ($error)');
                        }
                        return const Center(
                          child: Text(
                            'Erro ao carregar imagem',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF232323),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    )
                  : FutureBuilder<String>(
                      future: _urlFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError || !snapshot.hasData) {
                          return const Center(
                            child: Text(
                              'Erro ao carregar imagem',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF232323),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }

                        return Image.network(
                          snapshot.data!,
                          fit: widget.fit,
                          filterQuality: FilterQuality.high,
                        );
                      },
                    ),
        ),
      ),
    );
  }
}

class _BookWithCover extends StatelessWidget {
  final String coverPath;
  final List<String> lines;
  final double coverAspectRatio;
  final double coverWidth;

  const _BookWithCover({
    required this.coverPath,
    required this.lines,
    this.coverAspectRatio = 2 / 3,
    this.coverWidth = 92,
  });

  @override
  Widget build(BuildContext context) {
    final title = lines.isNotEmpty ? lines.first : '';
    final details = lines.length > 1 ? lines.sublist(1) : const <String>[];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: coverWidth,
          child: _StorageImageCard(
            path: coverPath,
            aspectRatio: coverAspectRatio,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF232323),
                ),
              ),
              if (details.isNotEmpty) const SizedBox(height: 4),
              for (final d in details)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    d,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.35,
                      color: Color(0xFF232323),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Session7DailyActivitiesWorksheet extends StatelessWidget {
  final _EditableTableController stressController;
  final _EditableTableController pleasureController;

  const _Session7DailyActivitiesWorksheet({
    required this.stressController,
    required this.pleasureController,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'PLANILHA DE ATIVIDADES DI\u00C1RIAS',
            style: TextStyle(
              fontSize: 20,
              height: 1.25,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 28),
          const _Session7WorksheetPrompt(
            number: '1.',
            parts: [
              _PromptPart('Liste atividades, pessoas e situa\u00E7\u00F5es que voc\u00EA '),
              _PromptPart(
                'associe com o estresse e emo\u00E7\u00F5es desafiadoras, ou que aumentem suas d\u00FAvidas em rela\u00E7\u00E3o a si mesmo.',
                bold: true,
              ),
              _PromptPart(
                ' Descreva como voc\u00EA normalmente se sente quando se envolve nessas atividades.',
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Session7WorksheetTable(controller: stressController),
          const SizedBox(height: 72),
          const _Session7WorksheetPrompt(
            number: '2.',
            parts: [
              _PromptPart('Liste atividades, pessoas e situa\u00E7\u00F5es que voc\u00EA '),
              _PromptPart(
                'associe com prazer e que aumentem a sua autoconfian\u00E7a em rela\u00E7\u00E3o a si mesmo.',
                bold: true,
              ),
              _PromptPart(
                ' Perceba como normalmente se sente quando se envolve nessas atividades.',
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Session7WorksheetTable(controller: pleasureController),
        ],
      ),
    );
  }
}

class _PromptPart {
  final String text;
  final bool bold;

  const _PromptPart(this.text, {this.bold = false});
}

class _Session7WorksheetPrompt extends StatelessWidget {
  final String number;
  final List<_PromptPart> parts;

  const _Session7WorksheetPrompt({
    required this.number,
    required this.parts,
  });

  @override
  Widget build(BuildContext context) {
    const baseStyle = TextStyle(
      fontSize: 18,
      height: 1.28,
      color: Color(0xFF111111),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 30,
          child: Text(number, style: baseStyle),
        ),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: baseStyle,
              children: [
                for (final part in parts)
                  TextSpan(
                    text: part.text,
                    style: part.bold
                        ? const TextStyle(fontWeight: FontWeight.w800)
                        : null,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Session7WorksheetTable extends StatelessWidget {
  final _EditableTableController controller;

  const _Session7WorksheetTable({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Table(
      border: TableBorder.all(color: Colors.black, width: 0.8),
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(1),
      },
      children: [
        const TableRow(
          children: [
            _Session7TableHeader(
              'Atividades, Pessoas, Lugares,\nSitua\u00E7\u00E3o',
            ),
            _Session7TableHeader('Como voc\u00EA se sente?'),
          ],
        ),
        for (var row = 0; row < controller.rowCount; row++)
          TableRow(
            children: [
              _Session7TableCell(
                controller: controller.controllerAt(row, 0),
              ),
              _Session7TableCell(
                controller: controller.controllerAt(row, 1),
              ),
            ],
          ),
      ],
    );
  }
}

class _Session7TableHeader extends StatelessWidget {
  final String text;

  const _Session7TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          height: 1.08,
          fontWeight: FontWeight.w800,
          color: Color(0xFF111111),
        ),
      ),
    );
  }
}

class _Session7TableCell extends StatelessWidget {
  final TextEditingController controller;

  const _Session7TableCell({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: TextField(
        controller: controller,
        maxLines: 1,
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        style: const TextStyle(
          fontSize: 14,
          height: 1.1,
          color: Color(0xFF111111),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.folhetoTitle,
      ),
    );
  }
}

class _EditableTableController {
  final String tableKey;
  final List<String> columns;
  final int rowCount;

  late final List<List<TextEditingController>> _controllers;

  _EditableTableController({
    required this.tableKey,
    required this.columns,
    required this.rowCount,
  }) {
    _controllers = List.generate(
      rowCount,
      (_) => List.generate(columns.length, (_) => TextEditingController()),
    );
  }

  void dispose() {
    for (final row in _controllers) {
      for (final c in row) {
        c.dispose();
      }
    }
  }

  /// Firestore não suporta arrays aninhados, então salvamos como lista de mapas.
  /// Cada linha vira um map: {"c0": "...", "c1": "...", ...}
  List<Map<String, String>> toJson() {
    return List.generate(
      _controllers.length,
      (rowIndex) {
        final row = _controllers[rowIndex];
        final map = <String, String>{};
        for (var colIndex = 0; colIndex < row.length; colIndex++) {
          map['c$colIndex'] = row[colIndex].text;
        }
        return map;
      },
      growable: false,
    );
  }

  void loadFromJson(dynamic value) {
    if (value is! List) return;

    for (var r = 0; r < _controllers.length; r++) {
      if (r >= value.length) break;
      final rowValue = value[r];

      // Formato atual (Firestore-friendly): List<Map<String,String>>
      if (rowValue is Map) {
        for (var col = 0; col < _controllers[r].length; col++) {
          final cell = rowValue['c$col'];
          if (cell is String) {
            _controllers[r][col].text = cell;
          }
        }
        continue;
      }

      // Formato antigo (não deveria existir salvo no Firestore, mas mantemos por segurança): List<List<String>>
      if (rowValue is List) {
        for (var col = 0; col < _controllers[r].length; col++) {
          if (col >= rowValue.length) break;
          final cell = rowValue[col];
          if (cell is String) {
            _controllers[r][col].text = cell;
          }
        }
      }
    }
  }

  TextEditingController controllerAt(int row, int col) {
    return _controllers[row][col];
  }
}

class _EditableTableWidget extends StatelessWidget {
  final _EditableTableController controller;

  const _EditableTableWidget({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columnCount = controller.columns.length;
            final availableWidth = constraints.maxWidth;

            // Sem scroll horizontal: calculamos o tamanho de cada célula para caber.
            const horizontalMargin = 6.0;
            const columnSpacing = 6.0;
            final usable = (availableWidth -
                    (horizontalMargin * 2) -
                    (columnSpacing * (columnCount - 1)))
                .clamp(0.0, double.infinity);
            final cellWidth = (usable / columnCount).clamp(72.0, 400.0);

            return SizedBox(
              width: availableWidth,
              child: DataTable(
                border: TableBorder.all(
                  color: Colors.black,
                  width: 0.6,
                ),
                dividerThickness: 0.6,
                headingRowColor: WidgetStateProperty.all(
                  const Color.fromARGB(255, 245, 245, 245),
                ),
                headingRowHeight: 64,
                dataRowMinHeight: 52,
                dataRowMaxHeight: 96,
                horizontalMargin: horizontalMargin,
                columnSpacing: columnSpacing,
                columns: controller.columns
                    .map(
                      (name) => DataColumn(
                        label: SizedBox(
                          width: cellWidth,
                          child: Text(
                            name,
                            softWrap: true,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: columnCount >= 6 ? 9.5 : 10.5,
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                              color: const Color(0xFF232323),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
                rows: List.generate(
                  controller.rowCount,
                  (rowIndex) {
                    return DataRow(
                      cells: List.generate(
                        controller.columns.length,
                        (colIndex) {
                          return DataCell(
                            SizedBox(
                              width: cellWidth,
                              child: TextField(
                                controller:
                                    controller.controllerAt(rowIndex, colIndex),
                                minLines: 1,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 8,
                                  ),
                                ),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 12.5,
                                  color: const Color(0xFF232323),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
