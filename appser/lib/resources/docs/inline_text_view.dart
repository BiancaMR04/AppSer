import 'package:appser/presentation/widgets/app_background.dart';
import 'package:appser/presentation/widgets/app_back_app_bar.dart';
import 'package:appser/presentation/widgets/app_bottom_nav_bar.dart';
import 'package:appser/presentation/widgets/app_card_container.dart';
import 'package:appser/presentation/widgets/app_scaffold.dart';
import 'package:appser/screens/user_tracking_service.dart';
import 'package:appser/core/theme/app_colors.dart';
import 'package:appser/resources/docs/folheto_text_catalog.dart';
import 'package:appser/resources/docs/folheto_text_view.dart';
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

  static const _textColor = Color(0xFF232323);

  static final _cardShadow = <BoxShadow>[
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ];

  static const _sectionTitleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: _textColor,
  );

  static const _cardTitleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: _textColor,
  );

  static const _itemTextStyle = TextStyle(
    fontSize: 15,
    height: 1.35,
    color: _textColor,
  );

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

  bool _isLinkItem(String text) {
    final normalized = text.trim().toLowerCase();
    return normalized.contains('folheto') || normalized.contains('planilha');
  }

  bool _isFollhetoItem(String text) {
    return text.trim().toLowerCase().contains('folheto');
  }

  void _openFollhetoOrPlanilha({
    required BuildContext context,
    required String itemText,
    required int sessionNumber,
  }) {
    if (!_isLinkItem(itemText)) return;

    final isFollheto = _isFollhetoItem(itemText);
    final folhetoTitle = 'Folheto Ser Sessão $sessionNumber';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FolhetoTextViewerScreen(
          title: folhetoTitle,
          text: FolhetoTextCatalog.forSession(sessionNumber) ?? 
              'Conteúdo do folheto ainda não foi inserido para a Sessão $sessionNumber.',
          sessaoId: widget.sessaoId,
          itemId: 'folheto_sessao_$sessionNumber',
          scrollToSection: isFollheto ? null : 'planilha',
        ),
      ),
    );
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

  String _stripBulletPrefix(String line) {
    final bullet = RegExp(r'^\s*(?:-|•|\*)\s+');
    return line.replaceFirst(bullet, '').trim();
  }

  bool _equalsIgnoreCase(String a, String b) {
    return a.trim().toLowerCase() == b.trim().toLowerCase();
  }

  bool _startsWithIgnoreCase(String a, String b) {
    return a.trim().toLowerCase().startsWith(b.trim().toLowerCase());
  }

  _PraticandoEmCasaParsed _parsePraticandoEmCasa(String raw) {
    final lines = raw.replaceAll('\r\n', '\n').split('\n');

    final reflection = <String>[];
    final experience = <String>[];
    final nextWeek = <String>[];

    _PraticandoEmCasaSection section = _PraticandoEmCasaSection.none;

    for (final rawLine in lines) {
      final trimmedRight = rawLine.trimRight();
      final trimmed = trimmedRight.trim();
      if (trimmed.isEmpty) continue;

      if (_equalsIgnoreCase(trimmed, 'PRATICANDO EM CASA DA SEGUINTE FORMA') ||
          _equalsIgnoreCase(trimmed, 'PRATICANDO EM CASA')) {
        continue;
      }

      if (_equalsIgnoreCase(trimmed, 'Momentos para reflexão')) {
        section = _PraticandoEmCasaSection.reflection;
        continue;
      }
      if (_equalsIgnoreCase(trimmed, 'Momentos para experiência') ||
          _equalsIgnoreCase(trimmed, 'Momentos para experiencia')) {
        section = _PraticandoEmCasaSection.experience;
        continue;
      }

      if (_startsWithIgnoreCase(trimmed, 'Para a próxima semana') ||
          _startsWithIgnoreCase(trimmed, 'Para a proxima semana') ||
          _startsWithIgnoreCase(trimmed, 'Próxima semana') ||
          _startsWithIgnoreCase(trimmed, 'Proxima semana')) {
        section = _PraticandoEmCasaSection.nextWeek;

        final parts = trimmed.split(':');
        if (parts.length > 1) {
          final rest = parts.sublist(1).join(':').trim();
          final value = _stripBulletPrefix(rest);
          if (value.isNotEmpty) nextWeek.add(value);
        }
        continue;
      }

      final value = _stripBulletPrefix(trimmed);
      if (value.isEmpty) continue;

      switch (section) {
        case _PraticandoEmCasaSection.reflection:
          reflection.add(value);
          break;
        case _PraticandoEmCasaSection.experience:
          experience.add(value);
          break;
        case _PraticandoEmCasaSection.nextWeek:
          nextWeek.add(value);
          break;
        case _PraticandoEmCasaSection.none:
          // Se vier algo fora das seções padrão, mostra como experiência
          // (evita sumir com conteúdo por variação de texto).
          experience.add(value);
          break;
      }
    }

    return _PraticandoEmCasaParsed(
      reflection: reflection,
      experience: experience,
      nextWeek: nextWeek,
    );
  }

  IconData _reflectionIconFor(String text) {
    final normalized = text.trim().toLowerCase();
    if (normalized.startsWith('lendo') ||
        normalized.contains('folheto') ||
        normalized.contains('apostila')) {
      return Icons.menu_book_outlined;
    }
    if (normalized.contains('planilha')) {
      return Icons.edit_note;
    }
    return Icons.article_outlined;
  }

  IconData _experienceIconFor(String text) {
    return Icons.self_improvement_outlined;
  }

  Widget _buildIconListItem({
    required IconData icon,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              icon,
              size: 22,
              color: AppColors.navbarTitle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: _itemTextStyle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkListItem({
    required BuildContext context,
    required IconData icon,
    required String text,
    required int sessionNumber,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openFollhetoOrPlanilha(
            context: context,
            itemText: text,
            sessionNumber: sessionNumber,
          ),
          borderRadius: BorderRadius.circular(6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  icon,
                  size: 22,
                  color: AppColors.navbarTitle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: _itemTextStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionsCard(_PraticandoEmCasaParsed parsed, int sessionNumber, BuildContext context) {
    final children = <Widget>[];

    if (parsed.reflection.isNotEmpty) {
      children.add(Text('Momentos para reflexão', style: _sectionTitleStyle));
      for (final item in parsed.reflection) {
        if (_isLinkItem(item)) {
          children.add(
            _buildLinkListItem(
              context: context,
              icon: _reflectionIconFor(item),
              text: item,
              sessionNumber: sessionNumber,
            ),
          );
        } else {
          children.add(
            _buildIconListItem(
              icon: _reflectionIconFor(item),
              text: item,
            ),
          );
        }
      }
    }

    if (parsed.experience.isNotEmpty) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: 18));
      }
      children.add(Text('Momentos para experiência', style: _sectionTitleStyle));
      for (final item in parsed.experience) {
        if (_isLinkItem(item)) {
          children.add(
            _buildLinkListItem(
              context: context,
              icon: _experienceIconFor(item),
              text: item,
              sessionNumber: sessionNumber,
            ),
          );
        } else {
          children.add(
            _buildIconListItem(
              icon: _experienceIconFor(item),
              text: item,
            ),
          );
        }
      }
    }

    return AppCardContainer(
      clipContent: false,
      boxShadow: _cardShadow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: SelectionArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _buildNextWeekCard(List<String> items) {
    final children = <Widget>[
      Text('Preparação para: Próxima semana', style: _cardTitleStyle),
    ];

    if (items.isNotEmpty) {
      children.add(const SizedBox(height: 8));
      for (final item in items) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(item, style: _itemTextStyle),
          ),
        );
      }
    }

    return AppCardContainer(
      clipContent: false,
      boxShadow: _cardShadow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: SelectionArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFallbackFormattedText() {
    const baseStyle = TextStyle(
      fontSize: 15,
      height: 1.35,
      color: _textColor,
    );
    const boldStyle = TextStyle(
      fontSize: 15,
      height: 1.35,
      color: _textColor,
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

      final isBold = _equalsIgnoreCase(trimmed, 'Momentos para reflexão') ||
          _equalsIgnoreCase(trimmed, 'Momentos para experiência') ||
          _equalsIgnoreCase(trimmed, 'PRATICANDO EM CASA DA SEGUINTE FORMA');
      final style = isBold ? boldStyle : baseStyle;

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

      widgets.add(Text(trimmed, style: style));
    }

    while (widgets.isNotEmpty && widgets.last is SizedBox) {
      widgets.removeLast();
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final appBarTitleText = _appBarTitleText();
    final showBodyTitle = appBarTitleText != widget.title;
    final sessionNumber = _sessionNumberFromSessaoId(widget.sessaoId) ?? 1;

    final parsed = _parsePraticandoEmCasa(widget.text);
    final hasStructured = parsed.reflection.isNotEmpty ||
        parsed.experience.isNotEmpty ||
        parsed.nextWeek.isNotEmpty;

    return AppScaffold(
      extendBodyBehindAppBar: false,
      extendBody: false,
      appBar: AppBackAppBar(
        titleText: appBarTitleText,
        iconColor: Colors.grey,
      ),
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              if (showBodyTitle) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: _textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              if (hasStructured) ...[
                _buildSectionsCard(parsed, sessionNumber, context),
                if (parsed.nextWeek.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _buildNextWeekCard(parsed.nextWeek),
                ],
              ] else ...[
                AppCardContainer(
                  clipContent: false,
                  boxShadow: _cardShadow,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SelectionArea(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _buildFallbackFormattedText(),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(),
    );
  }
}

enum _PraticandoEmCasaSection {
  none,
  reflection,
  experience,
  nextWeek,
}

class _PraticandoEmCasaParsed {
  final List<String> reflection;
  final List<String> experience;
  final List<String> nextWeek;

  const _PraticandoEmCasaParsed({
    required this.reflection,
    required this.experience,
    required this.nextWeek,
  });
}
