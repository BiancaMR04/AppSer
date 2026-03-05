import 'dart:convert';

import 'package:appser/core/theme/app_colors.dart';
import 'package:appser/presentation/widgets/app_background.dart';
import 'package:appser/presentation/widgets/app_back_app_bar.dart';
import 'package:appser/presentation/widgets/app_bottom_nav_bar.dart';
import 'package:appser/presentation/widgets/app_scaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:http/http.dart' as http;

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
      columns: const [
        'Dia/data',
        'Prática formal (tempo)',
        'Atividade escolhida',
        'Observações/comentários/desafios',
      ],
      rowCount: 10,
    );

    _load();
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
        _error = 'Erro ao carregar o folheto.\n\nArquivo: $source\n\nDetalhes: $e';
        _isLoading = false;
      });
    }
  }

  Future<String> _loadHtml() async {
    if (widget.htmlContent != null) {
      return widget.htmlContent!;
    }

    final path = widget.htmlPath!;
    final ref = FirebaseStorage.instance.ref(path);
    final url = await ref.getDownloadURL();
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

    final safeSessao = (sessaoId == null || sessaoId.isEmpty) ? 'sessao' : sessaoId;
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
              return const {'color': '#232323'};
            },
            onTapUrl: (url) {
              // Mantém o comportamento padrão (não abre automaticamente aqui).
              return false;
            },
          ),
          const SizedBox(height: 18),
          const _SectionTitle('Planilha Notando Gatilhos'),
          const SizedBox(height: 10),
          _EditableTableWidget(controller: _gatilhos),
          const SizedBox(height: 18),
          const _SectionTitle('Planilha de Acompanhamento Diário de Prática'),
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
        color: AppColors.primaryBlue,
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
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
