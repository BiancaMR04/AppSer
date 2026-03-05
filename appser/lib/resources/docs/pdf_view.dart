import 'package:appser/presentation/widgets/app_background.dart';
import 'package:appser/presentation/widgets/app_back_app_bar.dart';
import 'package:appser/presentation/widgets/app_bottom_nav_bar.dart';
import 'package:appser/presentation/widgets/app_card_container.dart';
import 'package:appser/presentation/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:provider/provider.dart';

import '../../presentation/controllers/pdf_viewer_controller.dart';
import '../../screens/user_tracking_service.dart';

class PdfViewerScreen extends StatefulWidget {
  final String pdfPath;
  final String downloadPath; // Caminho para o download do arquivo (PDF ou DOCX)
  final String pdfTitle;

  final String? sessaoId;
  final String? itemId;
  final bool isSupplementary;

  const PdfViewerScreen({
    super.key,
    required this.pdfPath,
    required this.downloadPath,
    required this.pdfTitle,
    this.sessaoId,
    this.itemId,
    this.isSupplementary = false,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String localPath = '';
  bool _isPdfViewed = false;

  late final PdfViewerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = context.read<PdfViewerController>();
    _downloadPdf(widget.pdfPath);
  }

  Future<void> _downloadPdf(String pdfPath) async {
    try {
      final path = await _controller.downloadPdfToLocalPath(pdfPath: pdfPath);
      setState(() {
        localPath = path;
      });
    } catch (e) {
      debugPrint('Erro ao baixar o PDF: $e');
    }
  }

  Future<void> _onPdfViewed() async {
    if (!_isPdfViewed) {
      final sessaoId = widget.sessaoId;
      final itemId = widget.itemId;
      if (sessaoId != null && itemId != null) {
        await UserTrackingService.registrarTarefaCompleta(
          sessaoId: sessaoId,
          tipo: 'pdf',
          itemId: itemId,
          isSupplementary: widget.isSupplementary,
          title: widget.pdfTitle,
          path: widget.pdfPath,
          mode: 'open',
        );
      }
      setState(() {
        _isPdfViewed = true;
      });
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
    return widget.pdfTitle;
  }

  @override
  Widget build(BuildContext context) {
    final appBarTitleText = _appBarTitleText();
    final showBodyTitle = appBarTitleText != widget.pdfTitle;

    return AppScaffold(
      extendBodyBehindAppBar: false,
      extendBody: false,
      appBar: AppBackAppBar(
        titleText: appBarTitleText,
        iconColor: Colors.grey,
      ),
      body: AppBackground(
        child: LayoutBuilder(
          builder: (context, constraints) {
            const horizontalPadding = 16.0;
            const verticalPadding = 12.0;

            final maxWidth = constraints.maxWidth - (horizontalPadding * 2);
            final viewerWidth = (maxWidth * 0.98)
                .clamp(0.0, maxWidth.isFinite ? maxWidth : double.infinity);

            final computedHeight = constraints.maxHeight * 0.74;
            final cappedHeight = computedHeight > 620.0 ? 620.0 : computedHeight;
            final maxAllowedHeight = (constraints.maxHeight - 24)
                .clamp(0.0, constraints.maxHeight.isFinite ? constraints.maxHeight : double.infinity);
            final viewerHeight = cappedHeight > maxAllowedHeight
                ? maxAllowedHeight
                : cappedHeight;

            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showBodyTitle) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Text(
                          widget.pdfTitle,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF232323),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    localPath.isNotEmpty
                        ? SizedBox(
                            width: viewerWidth,
                            height: viewerHeight,
                            child: AppCardContainer(
                              clipContent: true,
                              child: PDFView(
                                filePath: localPath,
                                backgroundColor: Colors.white,
                                fitEachPage: true,
                                fitPolicy: FitPolicy.BOTH,
                                onRender: (_) {
                                  _onPdfViewed();
                                },
                              ),
                            ),
                          )
                        : const CircularProgressIndicator(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(),
    );
  }
}
