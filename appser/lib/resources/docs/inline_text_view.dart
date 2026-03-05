import 'package:appser/presentation/widgets/app_background.dart';
import 'package:appser/presentation/widgets/app_back_app_bar.dart';
import 'package:appser/presentation/widgets/app_bottom_nav_bar.dart';
import 'package:appser/presentation/widgets/app_card_container.dart';
import 'package:appser/presentation/widgets/app_scaffold.dart';
import 'package:appser/screens/user_tracking_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class InlineTextViewerScreen extends StatefulWidget {
  final String title;
  final String text;

  final String? sessaoId;
  final String? itemId;
  final bool isSupplementary;

  const InlineTextViewerScreen({
    super.key,
    required this.title,
    required this.text,
    this.sessaoId,
    this.itemId,
    required this.isSupplementary,
  });

  @override
  State<InlineTextViewerScreen> createState() => _InlineTextViewerScreenState();
}

class _InlineTextViewerScreenState extends State<InlineTextViewerScreen> {
  bool _loggedOpen = false;

  static const _boldHeadings = <String>{
    'PRATICANDO EM CASA DA SEGUINTE FORMA',
    'Momentos para reflexão',
    'Momentos para experiência',
  };

  @override
  void initState() {
    super.initState();
    _logOpenOnce();
  }

  int? _sessionNumberFromSessaoId(String? sessaoId) {
    if (sessaoId == null) return null;
    final match = RegExp(r'^sessao_(\d+)$').firstMatch(sessaoId.trim());
    final raw = match?.group(1);
    if (raw == null) return null;
    return int.tryParse(raw);
  }

  String _appBarTitleText() {
    final n = _sessionNumberFromSessaoId(widget.sessaoId);
    if (n != null && n > 0) {
      return 'Sessão $n';
    }
    return widget.title;
  }

  Future<void> _logOpenOnce() async {
    if (_loggedOpen) return;
    _loggedOpen = true;

    final sessaoId = widget.sessaoId;
    final itemId = widget.itemId;
    if (sessaoId == null || itemId == null) return;

    try {
      await UserTrackingService.registrarTarefaCompleta(
        sessaoId: sessaoId,
        tipo: 'pdf',
        itemId: itemId,
        isSupplementary: widget.isSupplementary,
        title: widget.title,
        path: 'inline_text',
        mode: 'open',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('InlineText: erro ao registrar abertura: $e');
      }
    }
  }

  List<Widget> _buildFormattedText(BuildContext context) {
    const baseStyle = TextStyle(
      fontSize: 15,
      height: 1.35,
      color: Color(0xFF232323),
    );
    const boldStyle = TextStyle(
      fontSize: 15,
      height: 1.35,
      color: Color(0xFF232323),
      fontWeight: FontWeight.w700,
    );

    final lines = widget.text.split(RegExp(r'\r?\n'));
    final widgets = <Widget>[];

    for (final rawLine in lines) {
      final line = rawLine.trimRight();
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 10));
        continue;
      }

      if (_boldHeadings.contains(trimmed)) {
        widgets.add(Text(trimmed, style: boldStyle));
        continue;
      }

      final bulletMatch = RegExp(r'^\s*-\s+(.*)$').firstMatch(line);
      if (bulletMatch != null) {
        final bulletText = (bulletMatch.group(1) ?? '').trim();
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('•  ', style: baseStyle),
                Expanded(
                  child: Text(
                    bulletText,
                    style: baseStyle,
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      widgets.add(Text(trimmed, style: baseStyle));
    }

    // Remove espaçamentos finais extras.
    while (widgets.isNotEmpty && widgets.last is SizedBox) {
      widgets.removeLast();
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
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
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showBodyTitle) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF232323),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                Flexible(
                  child: AppCardContainer(
                    clipContent: true,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: SelectionArea(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _buildFormattedText(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(),
    );
  }
}
