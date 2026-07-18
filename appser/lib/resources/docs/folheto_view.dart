import 'dart:convert';

import 'package:appser/core/theme/app_colors.dart';
import 'package:appser/presentation/widgets/app_background.dart';
import 'package:appser/presentation/widgets/app_back_app_bar.dart';
import 'package:appser/presentation/widgets/app_bottom_nav_bar.dart';
import 'package:appser/presentation/widgets/app_scaffold.dart';
import 'package:appser/presentation/controllers/storage_url_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../screens/user_tracking_service.dart';

class FolhetoViewerScreen extends StatefulWidget {
  final String title;

  /// Caminho no Firebase Storage (ex.: `docs/folhetos/sessao2.html`).
  /// Se for nulo, usa [htmlContent].
  final String? htmlPath;

  /// Conteúdo HTML bruto (útil para testes / debug).
  final String? htmlContent;

  final String? sessaoId;
  final String? itemId;

  const FolhetoViewerScreen({
    super.key,
    required this.title,
    this.htmlPath,
    this.htmlContent,
    this.sessaoId,
    this.itemId,
  }) : assert(htmlPath != null || htmlContent != null);

  @override
  State<FolhetoViewerScreen> createState() => _FolhetoViewerScreenState();
}

class _FolhetoViewerScreenState extends State<FolhetoViewerScreen> {
  String? _html;
  bool _isLoading = true;
  String? _error;

  bool _loggedOpen = false;

  late final _EditableTableController _gatilhos;
  late final _EditableTableController _acompanhamento;

  @override
  void initState() {
    super.initState();

    final sessionNumber = _effectiveSessionNumber();

    _gatilhos = _EditableTableController(
      tableKey: 'planilha_notando_gatilhos',
      columns: const [
        'Dia/data',
        'Situação/gatilho',
        'Sensações',
        'Estados de espírito/emoções',
        'Pensamentos',
        'O que fez?',
      ],
      rowCount: 10,
    );

    _acompanhamento = _EditableTableController(
      tableKey: 'planilha_acompanhamento_diario',
      columns: (sessionNumber == 7 || sessionNumber == 8)
          ? const [
              'Dia/data',
              'Prática formal com áudio: Quanto tempo praticou?',
              'PARAR, espaço para respirar',
              'Anotações/comentários',
            ]
          : const [
              'Dia/data',
              'Prática formal (tempo)',
              'Atividade escolhida',
              'Observações/comentários/desafios',
            ],
      rowCount: 10,
    );

    _load();
  }

  int? _effectiveSessionNumber() {
    final raw = widget.sessaoId?.trim();
    if (raw == null || raw.isEmpty) return null;
    final match =
        RegExp(r'^(?:sessao_)?(\d+)$', caseSensitive: false).firstMatch(raw);
    if (match == null) return null;
    return int.tryParse(match.group(1) ?? '');
  }

  bool _openExternalUrl(String url) {
    var normalized = url.replaceAll(RegExp(r'\s+'), '');
    normalized = normalized.replaceAll(
      RegExp(
        r'[\]\[\)\(\}\{\.,;:!\?"\u2019\u2018\u201D\u201C\u00BB\u00AB]+$',
      ),
      '',
    );
    if (normalized.toLowerCase().startsWith('www.')) {
      normalized = 'https://$normalized';
    }
    final uri = Uri.tryParse(normalized);
    if (uri == null) return false;
    launchUrl(uri, mode: LaunchMode.externalApplication);
    return true;
  }

  @override
  void dispose() {
    _gatilhos.dispose();
    _acompanhamento.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final html = await _loadHtml();
      final saved = await _loadSavedTables();

      _gatilhos.loadFromJson(saved[_gatilhos.tableKey]);
      _acompanhamento.loadFromJson(saved[_acompanhamento.tableKey]);

      if (!mounted) return;
      setState(() {
        _html = html;
        _isLoading = false;
      });

      await _logOpenOnce();
    } catch (e, st) {
      debugPrint('Erro ao carregar folheto: $e');
      debugPrint('$st');
      if (!mounted) return;
      setState(() {
        final source = widget.htmlPath ?? 'inline_html';
        _error =
            'Erro ao carregar o folheto.\n\nArquivo: $source\n\nDetalhes: $e';
        _isLoading = false;
      });
    }
  }

  Future<String> _loadHtml() async {
    if (widget.htmlContent != null) {
      return widget.htmlContent!;
    }

    final path = widget.htmlPath!;
    final url = await context.read<StorageUrlController>().getDownloadUrl(path);
    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception('Erro ao baixar HTML: ${response.statusCode}');
    }

    // Alguns exports de HTML (ex.: Google Docs) podem não vir com charset no header.
    // Forçar UTF-8 evita casos de “parece vazio” por decode errado.
    return utf8.decode(response.bodyBytes, allowMalformed: true);
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
      path: widget.htmlPath ?? 'inline_html',
      mode: 'open',
    );

    _loggedOpen = true;
  }

  Future<Map<String, dynamic>> _loadSavedTables() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return <String, dynamic>{};

    final docId = _responseDocId();
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('folheto_respostas')
        .doc(docId)
        .get();

    return doc.data() ?? <String, dynamic>{};
  }

  String _responseDocId() {
    final sessaoId = widget.sessaoId?.trim();
    final itemId = widget.itemId?.trim();

    final safeSessao =
        (sessaoId == null || sessaoId.isEmpty) ? 'sessao' : sessaoId;
    final safeItem = (itemId == null || itemId.isEmpty) ? 'folheto' : itemId;

    // docId não pode ter '/'
    return '${safeSessao}_$safeItem'.replaceAll('/', '_');
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
      _gatilhos.tableKey: _gatilhos.toJson(),
      _acompanhamento.tableKey: _acompanhamento.toJson(),
    };

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
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      extendBodyBehindAppBar: false,
      extendBody: false,
      appBar: AppBackAppBar(
        titleText: widget.title,
        iconColor: Colors.grey,
      ),
      body: AppBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError(context)
                : _buildBody(context),
      ),
      bottomNavigationBar: const AppBottomNavBar(),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error ?? 'Erro ao carregar o folheto.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF232323)),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF60BFCD),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final html = _normalizeHtml(_html ?? '');
    final sessionNumber = _effectiveSessionNumber();

    // Sessão 8: a planilha de acompanhamento precisa aparecer logo após o
    // parágrafo "Existem muitas coisas...", antes das listas de suporte.
    if (sessionNumber == 8) {
      const anchorPrefix = 'Existem muitas coisas que nós não controlamos';
      final anchorIndex = html.indexOf(anchorPrefix);

      String? htmlBefore;
      String? htmlAfter;
      if (anchorIndex != -1) {
        // Tentamos cortar no fim do <p> do parágrafo. Se não existir, cortamos
        // logo após o prefixo (fallback suave).
        final endP = html.indexOf('</p>', anchorIndex);
        final splitAt =
            endP != -1 ? endP + 4 : anchorIndex + anchorPrefix.length;
        htmlBefore = html.substring(0, splitAt);
        htmlAfter = html.substring(splitAt);
      }

      String convertDashBulletsToTopics(String input) {
        // Alguns exports (ex.: Google Docs) trazem listas como parágrafos
        // iniciando com "- ". Para manter visual de "tópico", trocamos por "• ".
        return input
            .replaceAllMapped(
              RegExp(r'(<p[^>]*>)\s*-\s*', caseSensitive: false),
              (m) => '${m.group(1)}• ',
            )
            .replaceAllMapped(
              RegExp(r'(<br\s*/?>)\s*-\s*', caseSensitive: false),
              (m) => '${m.group(1)}• ',
            )
            .replaceAllMapped(
              RegExp(r'\n-\s*'),
              (m) => '\n• ',
            );
      }

      Widget htmlWidget(String content) {
        return HtmlWidget(
          convertDashBulletsToTopics(content),
          textStyle: const TextStyle(
            fontSize: 15,
            height: 1.35,
            color: Color(0xFF232323),
          ),
          customStylesBuilder: (element) {
            final t = element.text.trim();

            bool looksLikeSession8PoemLine(String s) {
              final tt = s.trim();
              if (tt.isEmpty) return false;
              if (tt == 'Gunilla Norris') return false;
              // Heurística: linhas do poema têm frases bem específicas.
              return tt.startsWith('É um paradoxo') ||
                  tt.startsWith('como nós encontramos') ||
                  tt.startsWith('o fato de experienciar') ||
                  tt.startsWith('que nos mantendo em quietude') ||
                  tt.startsWith('Nossas mentes não gostam de paradoxos') ||
                  tt.startsWith('para que possamos manter') ||
                  tt.startsWith('A certeza gera') ||
                  tt.startsWith('Cada um de nós') ||
                  tt.startsWith('Ele sabe que o verão') ||
                  tt.startsWith('Ele sabe que no momento') ||
                  tt.startsWith('Ele sabe que tudo na vida') ||
                  tt.startsWith('em meio às sombras') ||
                  tt.startsWith('Quando nos sentamos em quietude') ||
                  tt.startsWith('Mantendo o silêncio') ||
                  tt.startsWith('Através da nossa boa vontade') ||
                  tt.startsWith('Nós nos tornamos um em união');
            }

            if (t.toUpperCase() == 'TEMA') {
              return const {
                'color': '#45706b',
                'font-weight': '800',
              };
            }

            String normalizeHeading(String s) {
              final noBullet = s
                  .trim()
                  .replaceFirst(RegExp(r'^[•\-–—]\s*'), '')
                  .replaceAll('“', '"')
                  .replaceAll('”', '"')
                  .replaceAll('"', '')
                  .replaceAll(RegExp(r'\s+'), ' ')
                  .toLowerCase();

              return noBullet;
            }

            const session5Headings = {
              'posição da montanha',
              'tirando uma camiseta',
              'tirando uma camiseta ao contrário',
              'colhendo uma fruta',
              'dobrar para frente',
              'posição de descanso final',
            };

            const session8Headings = {
              'projeto ser',
              'medita-nepsis unifesp',
              'formação em mbrp',
              'casa de dharma',
              'centro de estudos budistas',
              'grupo tergar',
            };

            if (session5Headings.contains(normalizeHeading(t))) {
              return const {
                'font-weight': '700',
                'color': '#232323',
              };
            }

            if (session8Headings.contains(normalizeHeading(t))) {
              return const {
                'font-weight': '700',
                'color': '#232323',
              };
            }

            if (sessionNumber == 8) {
              if (t == 'Gunilla Norris') {
                return const {
                  'font-style': 'normal',
                  'color': '#232323',
                };
              }
              if (looksLikeSession8PoemLine(t)) {
                return const {
                  'font-style': 'italic',
                  'color': '#232323',
                };
              }
            }

            return const {'color': '#232323'};
          },
          onTapUrl: (url) {
            return _openExternalUrl(url);
          },
        );
      }

      return SelectionArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            htmlWidget(htmlBefore ?? html),
            const SizedBox(height: 18),
            const _SectionTitle('PLANILHA DE ACOMPANHAMENTO DIÁRIO DE PRÁTICA'),
            const SizedBox(height: 6),
            const Text(
              'Instruções: a cada dia registre suas práticas de meditação, anotando também quaisquer barreiras, observações ou comentários.',
              style: TextStyle(
                fontSize: 14.5,
                height: 1.35,
                color: Color(0xFF232323),
              ),
            ),
            const SizedBox(height: 10),
            _EditableTableWidget(controller: _acompanhamento),
            const SizedBox(height: 18),
            if (htmlAfter != null && htmlAfter.trim().isNotEmpty) ...[
              htmlWidget(htmlAfter),
              const SizedBox(height: 18),
            ],
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Dica: você pode selecionar e copiar o texto acima.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SelectionArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          HtmlWidget(
            html,
            textStyle: const TextStyle(
              fontSize: 15,
              height: 1.35,
              color: Color(0xFF232323),
            ),
            customStylesBuilder: (element) {
              // Mantém o texto legível mesmo quando o HTML traz estilos próprios.
              final t = element.text.trim();
              if (t.toUpperCase() == 'TEMA') {
                return const {
                  'color': '#45706b',
                  'font-weight': '800',
                };
              }

              String normalizeHeading(String s) {
                return s
                    .trim()
                    .replaceAll('“', '"')
                    .replaceAll('”', '"')
                    .replaceAll('"', '')
                    .replaceAll(RegExp(r'\s+'), ' ')
                    .toLowerCase();
              }

              const session5Headings = {
                'posição da montanha',
                'tirando uma camiseta',
                'tirando uma camiseta ao contrário',
                'colhendo uma fruta',
                'dobrar para frente',
                'posição de descanso final',
              };

              if (session5Headings.contains(normalizeHeading(t))) {
                return const {
                  'font-weight': '700',
                  'color': '#232323',
                };
              }

              return const {'color': '#232323'};
            },
            onTapUrl: (url) {
              // Mantém o comportamento padrão (não abre automaticamente aqui).
              return _openExternalUrl(url);
            },
          ),
          const SizedBox(height: 18),
          const _SectionTitle('PLANILHA NOTANDO GATILHOS'),
          const SizedBox(height: 6),
          const Text(
            'Nessa semana preste atenção no que provoca em você a vontade de reagir automaticamente ou de forma impulsiva. Use as questões seguintes para trazer à consciência os detalhes das experiências em que isso acontece.',
            style: TextStyle(
              fontSize: 14.5,
              height: 1.35,
              color: Color(0xFF232323),
            ),
          ),
          const SizedBox(height: 10),
          _EditableTableWidget(controller: _gatilhos),
          const SizedBox(height: 18),
          const _SectionTitle('PLANILHA DE ACOMPANHAMENTO DIÁRIO DE PRÁTICA'),
          const SizedBox(height: 6),
          const Text(
            'Instruções: a cada dia registre suas práticas de meditação, anotando também quaisquer barreiras, observações ou comentários.',
            style: TextStyle(
              fontSize: 14.5,
              height: 1.35,
              color: Color(0xFF232323),
            ),
          ),
          const SizedBox(height: 10),
          _EditableTableWidget(controller: _acompanhamento),
          const SizedBox(height: 18),
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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Dica: você pode selecionar e copiar o texto acima.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _normalizeHtml(String html) {
    // 1) Se vier HTML completo, usa só o <body>.
    final bodyMatch = RegExp(
      r'<body[^>]*>([\s\S]*?)</body>',
      caseSensitive: false,
    ).firstMatch(html);
    final body = bodyMatch?.group(1) ?? html;

    // 2) Remove APENAS as tabelas que correspondem às planilhas editáveis.
    // (Muitos HTMLs exportados usam <table> para layout do documento.)
    final stripped = _stripEditableTablesOnly(body);

    // Fallback: se a remoção deixou o HTML “vazio”, preserva o body original.
    if (stripped.trim().isEmpty) {
      return body;
    }

    return stripped;
  }

  String _stripEditableTablesOnly(String html) {
    final tableRegex = RegExp(r'<table[\s\S]*?</table>', caseSensitive: false);
    final matches = tableRegex.allMatches(html).toList(growable: false);
    if (matches.isEmpty) return html;

    final buffer = StringBuffer();
    var lastIndex = 0;

    bool isTargetTable(String tableHtml) {
      final lower = tableHtml.toLowerCase();

      // Cabeçalhos conhecidos (batendo com as colunas da tabela editável).
      const gatilhosKeys = [
        'dia/data',
        'situação/gatilho',
        'sensações',
        'estados de espírito/emoções',
        'pensamentos',
        'o que fez?',
      ];

      const acompanhamentoKeys = [
        'dia/data',
        'prática formal',
        'atividade escolhida',
        'observações',
      ];

      int containsCount(List<String> keys) {
        var count = 0;
        for (final k in keys) {
          if (lower.contains(k)) count++;
        }
        return count;
      }

      // Exige uma “boa” similaridade para evitar remover tabelas de layout.
      final gatilhosScore = containsCount(gatilhosKeys);
      final acompanhamentoScore = containsCount(acompanhamentoKeys);

      return gatilhosScore >= 4 || acompanhamentoScore >= 3;
    }

    for (final m in matches) {
      buffer.write(html.substring(lastIndex, m.start));

      final tableHtml = html.substring(m.start, m.end);
      if (!isTargetTable(tableHtml)) {
        buffer.write(tableHtml);
      }

      lastIndex = m.end;
    }

    buffer.write(html.substring(lastIndex));
    return buffer.toString();
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

  List<List<String>> toJson() {
    return _controllers
        .map((row) => row.map((c) => c.text).toList(growable: false))
        .toList(growable: false);
  }

  void loadFromJson(dynamic value) {
    if (value is! List) return;

    for (var r = 0; r < _controllers.length; r++) {
      if (r >= value.length) break;
      final rowValue = value[r];
      if (rowValue is! List) continue;

      for (var col = 0; col < _controllers[r].length; col++) {
        if (col >= rowValue.length) break;
        final cell = rowValue[col];
        if (cell is String) {
          _controllers[r][col].text = cell;
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
        border: Border.all(color: Colors.black12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              const Color.fromARGB(255, 245, 245, 245),
            ),
            dataRowMinHeight: 56,
            dataRowMaxHeight: 120,
            columnSpacing: 18,
            columns: controller.columns
                .map(
                  (name) => DataColumn(
                    label: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
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
                          width: 220,
                          child: TextField(
                            controller:
                                controller.controllerAt(rowIndex, colIndex),
                            minLines: 1,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                            ),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
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
        ),
      ),
    );
  }
}
