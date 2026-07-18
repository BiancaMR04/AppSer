import 'package:appser/presentation/widgets/app_background.dart';
import 'package:appser/presentation/widgets/app_back_app_bar.dart';
import 'package:appser/presentation/widgets/app_bottom_nav_bar.dart';
import 'package:appser/presentation/widgets/app_card_container.dart';
import 'package:appser/presentation/widgets/app_scaffold.dart';
import 'package:appser/presentation/controllers/storage_url_controller.dart';
import 'package:appser/screens/user_tracking_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MultiImageViewerScreen extends StatefulWidget {
  final List<String> imagePaths;
  final String titleLine1;
  final String titleLine2;

  final String? sessaoId;
  final String? itemId;
  final bool isSupplementary;

  const MultiImageViewerScreen({
    super.key,
    required this.imagePaths,
    required this.titleLine1,
    required this.titleLine2,
    this.sessaoId,
    this.itemId,
    required this.isSupplementary,
  });

  @override
  State<MultiImageViewerScreen> createState() => _MultiImageViewerScreenState();
}

class _MultiImageViewerScreenState extends State<MultiImageViewerScreen> {
  List<String?> _urls = const <String?>[];
  Object? _error;
  bool _loggedOpen = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final storageUrlController = context.read<StorageUrlController>();
      final futures = widget.imagePaths
          .map((p) => storageUrlController.getDownloadUrl(p))
          .toList(growable: false);
      final urls = await Future.wait(futures);
      if (!mounted) return;
      setState(() {
        _urls = urls;
      });

      for (final url in urls) {
        if (url == null) continue;
        precacheImage(NetworkImage(url), context);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
      });
      return;
    }

    try {
      await _logOpenOnce();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('MultiImage: erro ao registrar abertura: $e');
      }
    }
  }

  Future<void> _logOpenOnce() async {
    if (_loggedOpen) return;
    _loggedOpen = true;

    final sessaoId = widget.sessaoId;
    final itemId = widget.itemId;
    if (sessaoId == null || itemId == null) return;

    await UserTrackingService.registrarTarefaCompleta(
      sessaoId: sessaoId,
      tipo: 'pdf',
      itemId: itemId,
      isSupplementary: widget.isSupplementary,
      title: '${widget.titleLine1} ${widget.titleLine2}',
      path: widget.imagePaths.isNotEmpty ? widget.imagePaths.first : 'images',
      mode: 'open',
    );
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
    return widget.titleLine2;
  }

  @override
  Widget build(BuildContext context) {
    final appBarTitleText = _appBarTitleText();

    Widget content;
    if (_error != null) {
      content = Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Erro ao carregar imagens.\n${widget.imagePaths.join('\n')}',
          textAlign: TextAlign.center,
        ),
      );
    } else if (_urls.isEmpty) {
      content = const Center(child: CircularProgressIndicator());
    } else {
      content = AppCardContainer(
        clipContent: true,
        child: ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: _urls.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final url = _urls[index];
            if (url == null) {
              return const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return Image.network(
              url,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Não foi possível carregar: ${widget.imagePaths[index]}',
                    textAlign: TextAlign.center,
                  ),
                );
              },
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
              children: [
                const SizedBox(height: 8),
                Text(
                  widget.titleLine1,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF232323),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.titleLine2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF232323),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(child: content),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(),
    );
  }
}
