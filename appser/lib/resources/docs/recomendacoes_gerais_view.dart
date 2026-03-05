import 'package:appser/presentation/widgets/app_background.dart';
import 'package:appser/presentation/widgets/app_back_app_bar.dart';
import 'package:appser/presentation/widgets/app_bottom_nav_bar.dart';
import 'package:appser/presentation/widgets/app_card_container.dart';
import 'package:appser/presentation/widgets/app_scaffold.dart';
import 'package:appser/resources/docs/recomendacoes_gerais_catalog.dart';
import 'package:flutter/material.dart';

class RecomendacoesGeraisView extends StatelessWidget {
  const RecomendacoesGeraisView({super.key});

  static const _textColor = Color(0xFF232323);

  static bool _isWelcomeLine(String line) {
    final normalized = line.trim().toLowerCase();
    return normalized.contains('bem vindo') && normalized.startsWith('ol');
  }

  static bool _isGeneralGuidanceLine(String line) {
    return line.trim().toLowerCase() == 'orientações gerais:';
  }

  static List<Widget> _buildFormatted(String raw) {
    const baseStyle = TextStyle(
      fontSize: 14,
      height: 1.35,
      color: _textColor,
    );
    const boldStyle = TextStyle(
      fontSize: 14,
      height: 1.35,
      color: _textColor,
      fontWeight: FontWeight.w700,
    );

    final lines = raw.replaceAll('\r\n', '\n').split('\n');
    final widgets = <Widget>[];

    for (final rawLine in lines) {
      final trimmedRight = rawLine.trimRight();
      final trimmed = trimmedRight.trim();

      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 10));
        continue;
      }

      final isBold = _isWelcomeLine(trimmed) || _isGeneralGuidanceLine(trimmed);
      widgets.add(Text(trimmed, style: isBold ? boldStyle : baseStyle));
    }

    while (widgets.isNotEmpty && widgets.last is SizedBox) {
      widgets.removeLast();
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const AppBackAppBar(titleText: 'Recomendações gerais'),
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            children: [
              AppCardContainer(
                clipContent: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: SelectionArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _buildFormatted(recomendacoesGeraisText),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(),
    );
  }
}
