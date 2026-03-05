import 'package:appser/presentation/widgets/app_background.dart';
import 'package:appser/presentation/widgets/app_back_app_bar.dart';
import 'package:appser/presentation/widgets/app_bottom_nav_bar.dart';
import 'package:appser/presentation/widgets/app_card_container.dart';
import 'package:appser/presentation/widgets/app_scaffold.dart';
import 'package:appser/screens/user_tracking_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class ImageViewerScreen extends StatefulWidget {
  final String imagePath;
  final String imageTitle;

  final String? sessaoId;
  final String? itemId;
  final bool isSupplementary;

  const ImageViewerScreen({
    super.key,
    required this.imagePath,
    required this.imageTitle,
    this.sessaoId,
    this.itemId,
    this.isSupplementary = false,
  });

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  String? _downloadUrl;
  Object? _error;
  bool _markedViewed = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  bool get _isAssetPath => widget.imagePath.trim().startsWith('assets/');

  Future<void> _bootstrap() async {
    if (_isAssetPath) {
      try {
        await _markViewedOnce();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Erro ao registrar visualização da imagem: $e');
        }
      }
      return;
    }

    try {
      final ref = FirebaseStorage.instance.ref(widget.imagePath);
      final url = await ref.getDownloadURL();
      if (!mounted) return;
      setState(() {
        _downloadUrl = url;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
      });
      return;
    }

    try {
      await _markViewedOnce();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao registrar visualização da imagem: $e');
      }
    }
  }

  Future<void> _markViewedOnce() async {
    if (_markedViewed) return;
    final sessaoId = widget.sessaoId;
    final itemId = widget.itemId;
    if (sessaoId == null || itemId == null) return;

    await UserTrackingService.registrarTarefaCompleta(
      sessaoId: sessaoId,
      tipo: 'pdf',
      itemId: itemId,
      isSupplementary: widget.isSupplementary,
      title: widget.imageTitle,
      path: widget.imagePath,
      mode: 'open',
    );

    if (!mounted) return;
    setState(() {
      _markedViewed = true;
    });
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
    return widget.imageTitle;
  }

  @override
  Widget build(BuildContext context) {
    final appBarTitleText = _appBarTitleText();
    final showBodyTitle = appBarTitleText != widget.imageTitle;

    Widget body;
    if (_error != null) {
      body = Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Erro ao carregar imagem.\n${widget.imagePath}',
          textAlign: TextAlign.center,
        ),
      );
    } else if (_isAssetPath) {
      body = _ImageCard(
        child: Image.asset(
          widget.imagePath,
          fit: BoxFit.contain,
        ),
      );
    } else if (_downloadUrl == null) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = _ImageCard(
        child: Image.network(
          _downloadUrl!,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Não foi possível carregar a imagem.\n${widget.imagePath}',
                textAlign: TextAlign.center,
              ),
            );
          },
        ),
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
                      widget.imageTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF232323),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                Flexible(child: body),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(),
    );
  }
}

class _ImageCard extends StatelessWidget {
  final Widget child;

  const _ImageCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;
        final viewerWidth = (maxWidth * 0.98).clamp(0.0, maxWidth);
        final computedHeight = maxHeight * 0.74;
        final cappedHeight = computedHeight > 620.0 ? 620.0 : computedHeight;
        final maxAllowedHeight = (maxHeight - 24).clamp(0.0, maxHeight);
        final viewerHeight =
            cappedHeight > maxAllowedHeight ? maxAllowedHeight : cappedHeight;

        return SizedBox(
          width: viewerWidth,
          height: viewerHeight,
          child: AppCardContainer(
            clipContent: true,
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: ColoredBox(
                color: Colors.white,
                child: Center(child: child),
              ),
            ),
          ),
        );
      },
    );
  }
}
