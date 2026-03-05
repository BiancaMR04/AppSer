import 'package:appser/core/theme/app_colors.dart';
import 'package:appser/presentation/widgets/app_background.dart';
import 'package:appser/presentation/widgets/app_back_app_bar.dart';
import 'package:appser/presentation/widgets/app_bottom_nav_bar.dart';
import 'package:appser/presentation/widgets/app_scaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../screens/user_tracking_service.dart';

class FolhetoTextViewerScreen extends StatefulWidget {
  final String title;
  final String text;

  final String? sessaoId;
  final String? itemId;

  const FolhetoTextViewerScreen({
    super.key,
    required this.title,
    required this.text,
    this.sessaoId,
    this.itemId,
  });

  @override
  State<FolhetoTextViewerScreen> createState() => _FolhetoTextViewerScreenState();
}

class _FolhetoTextViewerScreenState extends State<FolhetoTextViewerScreen> {
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
      rowCount: 4,
    );

    _acompanhamento = _EditableTableController(
      tableKey: 'planilha_acompanhamento_diario',
      columns: const [
        'Dia/data',
        'Prática formal com áudio: Quanto tempo praticou?',
        'Mindfulness em atividades diárias: qual atividade escolheu?',
        'Observações/comentários/desafios (aversão, desejos, sonolência, inquietação, dúvida)',
      ],
      rowCount: 4,
    );

    _loadSavedTables();
    _logOpenOnce();
  }

  int? _effectiveSessionNumber() {
    final raw = widget.sessaoId?.trim();
    if (raw == null || raw.isEmpty) return null;
    final match = RegExp(r'^(?:sessao_)?(\d+)$', caseSensitive: false)
        .firstMatch(raw);
    if (match == null) return null;
    return int.tryParse(match.group(1) ?? '');
  }

  String _appBarTitleText() {
    final n = _effectiveSessionNumber();
    if (n != null && n > 0) {
      return 'Sessão $n';
    }
    return widget.title;
  }

  bool get _showGatilhosTable {
    // No material atual:
    // - Sessão 1 tem apenas acompanhamento diário.
    // - Sessão 2 tem gatilhos + acompanhamento.
    return _effectiveSessionNumber() == 2;
  }

  @override
  void dispose() {
    _gatilhos.dispose();
    _acompanhamento.dispose();
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

    final safeSessao = (sessaoId == null || sessaoId.isEmpty) ? 'sessao' : sessaoId;
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
    final displayText = _sanitizeText(widget.text);
    final hasText = displayText.trim().isNotEmpty;
    final appBarTitleText = _appBarTitleText();
    final showBodyTitle = appBarTitleText != widget.title;

    return AppScaffold(
      extendBodyBehindAppBar: false,
      extendBody: false,
      appBar: AppBackAppBar(
        titleText: appBarTitleText,
        iconColor: Colors.grey,
      ),
      body: AppBackground(
        child: ListView(
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
            if (hasText) ...[
              SelectionArea(
                child: _StyledFolhetoText(text: displayText),
              ),
              const SizedBox(height: 18),
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
              const _SectionTitle('Planilha Notando Gatilhos'),
              const SizedBox(height: 10),
              _EditableTableWidget(controller: _gatilhos),
              const SizedBox(height: 18),
            ],
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
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(),
    );
  }

  String _sanitizeText(String raw) {
    // Muitos textos exportados incluem a “tabela” como texto.
    // Como as tabelas editáveis aparecem logo abaixo, removemos qualquer seção
    // de planilha (gatilhos/acompanhamento) do texto.
    final normalized = raw.replaceAll('\r\n', '\n');
    final lines = normalized.split('\n');

    bool isPlanilhaHeader(String line) {
      final u = line.trim().toUpperCase();
      if (!u.startsWith('PLANILHA')) return false;
      return u.contains('GATILHOS') || u.contains('ACOMPANHAMENTO');
    }

    final cutLineIndex = lines.indexWhere(isPlanilhaHeader);
    if (cutLineIndex == -1) return normalized.trim();

    return lines.take(cutLineIndex).join('\n').trim();
  }
}

class _StyledFolhetoText extends StatelessWidget {
  final String text;

  const _StyledFolhetoText({required this.text});

  static const List<String> _boldPhrases = <String>[
    'escaneamento corporal:',
    'mindfulness na atividade diária:',
    'complete o diário de práticas:',
  ];

  static const String _centeredSession1Title =
      'MINDFULNESS, PILOTO AUTOMÁTICO E REATIVIDADE';

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

  bool _endsQuote(String line) {
    final trimmed = line.trimRight();
    return trimmed.endsWith('”') || trimmed.endsWith('”.') || trimmed.endsWith('"') || trimmed.endsWith('".');
  }

  String? _stripListPrefix(String line) {
    // Detecta linhas no estilo lista e remove o prefixo.
    // Exemplos:
    // - "1. Texto" / "1) Texto"
    // - "a. Texto" / "b) Texto"
    // - "- Texto" / "• Texto" / "* Texto"
    final trimmed = line.trimLeft();

    final bullet = RegExp(r'^(?:[-•*])\s+').firstMatch(trimmed);
    if (bullet != null) {
      return trimmed.substring(bullet.end).trimRight();
    }

    final numbered = RegExp(r'^(?:\d{1,3}|[A-Za-z])(?:[\.|\)])\s+').firstMatch(trimmed);
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
    final lines = text.replaceAll('\r\n', '\n').split('\n');

    final children = <Widget>[];
    var inQuote = false;
    var expectAuthorLine = false;

    for (final rawLine in lines) {
      final line = rawLine.trimRight();
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        children.add(const SizedBox(height: 10));
        continue;
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
              color: AppColors.primaryBlue,
            ),
          ),
        );
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
              color: AppColors.primaryBlue,
            ),
          ),
        );
        continue;
      }

      final bulletText = _stripListPrefix(trimmed);
      if (bulletText != null && bulletText.isNotEmpty) {
        children.add(
          Text.rich(
            _buildInlineBoldSpan(
              '• ${bulletText.trim()}',
              const TextStyle(
                fontSize: 15,
                height: 1.4,
                color: Color(0xFF232323),
              ),
            ),
          ),
        );
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
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
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
            final usable = (availableWidth - (horizontalMargin * 2) - (columnSpacing * (columnCount - 1)))
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
