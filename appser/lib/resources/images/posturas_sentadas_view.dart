import 'package:appser/presentation/widgets/app_background.dart';
import 'package:appser/presentation/widgets/app_back_app_bar.dart';
import 'package:appser/presentation/widgets/app_bottom_nav_bar.dart';
import 'package:appser/presentation/widgets/app_card_container.dart';
import 'package:appser/presentation/widgets/app_scaffold.dart';
import 'package:appser/screens/user_tracking_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PosturasSentadasViewerScreen extends StatefulWidget {
  final String title;

  final String? sessaoId;
  final String? itemId;
  final bool isSupplementary;

  const PosturasSentadasViewerScreen({
    super.key,
    required this.title,
    this.sessaoId,
    this.itemId,
    this.isSupplementary = false,
  });

  @override
  State<PosturasSentadasViewerScreen> createState() =>
      _PosturasSentadasViewerScreenState();
}

class _PosturasSentadasViewerScreenState
    extends State<PosturasSentadasViewerScreen> {
  bool _loggedOpen = false;

  static const _assetSemiLotus = 'assets/Sessao2--Imagem1.png';
  static const _assetCadeira = 'assets/Sessao2--Imagem2.png';
  static const _assetZafu = 'assets/Sessao2--Imagem3.png';

  static const _textColor = Color(0xFF232323);

  static const _captionStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: _textColor,
  );

  @override
  void initState() {
    super.initState();
    _logOpenOnce();
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
        path: _assetSemiLotus,
        mode: 'open',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PosturasSentadas: erro ao registrar abertura: $e');
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final appBarTitleText = _appBarTitleText();
    final showBodyTitle = appBarTitleText != widget.title;

    Widget imageWithCaption({
      required String assetPath,
      required String caption,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.asset(
            assetPath,
            width: double.infinity,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              if (kDebugMode) {
                debugPrint('Unable to load asset: $assetPath ($error)');
              }
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Não foi possível carregar a imagem:\n$assetPath',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: _textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            caption,
            textAlign: TextAlign.center,
            style: _captionStyle,
          ),
        ],
      );
    }

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
              AppCardContainer(
                clipContent: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      imageWithCaption(
                        assetPath: _assetSemiLotus,
                        caption: 'SEMI LOTUS',
                      ),
                      const SizedBox(height: 18),
                      imageWithCaption(
                        assetPath: _assetCadeira,
                        caption: 'CADEIRA',
                      ),
                      const SizedBox(height: 18),
                      imageWithCaption(
                        assetPath: _assetZafu,
                        caption: 'ZAFU/BANQUINHO',
                      ),
                    ],
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
