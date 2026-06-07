import 'package:appser/presentation/widgets/app_bottom_nav_bar.dart';
import 'package:appser/presentation/widgets/app_back_app_bar.dart';
import 'package:appser/presentation/widgets/app_scaffold.dart';
import 'package:appser/resources/docs/folheto_text_catalog.dart';
import 'package:appser/resources/docs/folheto_text_view.dart';
import 'package:appser/resources/docs/material_text_catalog.dart';
import 'package:appser/resources/docs/pdf_view.dart';
import 'package:appser/resources/images/image_view.dart';
import 'package:appser/resources/images/multi_image_view.dart';
import 'package:appser/resources/images/posturas_sentadas_view.dart';
import 'package:appser/sessions/session_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:appser/core/theme/app_colors.dart';
import 'package:appser/sessions/widgets/session_header.dart';

class SessionMaterialScreen extends StatelessWidget {
  final int sessionNumber;

  const SessionMaterialScreen({super.key, required this.sessionNumber});

  @override
  Widget build(BuildContext context) {
    final items = SessionCatalog.materialItemsFor(sessionNumber);
    final String sessionId = 'sessao_$sessionNumber';

    const dividerColor = Color(0xFF10707E);

    String displayTitle(String raw) {
      return raw.replaceFirst(RegExp(r'^\s*\d+\.\s*'), '').trim();
    }

    return AppScaffold(
      backgroundColor: Colors.white,
      appBar: const AppBackAppBar(titleText: 'Material de apoio'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SessionHeader(
              title: 'Sessão $sessionNumber',
              titleStyle: _titleStyleForSession(sessionNumber),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(15),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(
                        height: 1, thickness: 1, color: dividerColor),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Material(
                        color: Colors.white,
                        child: InkWell(
                          onTap: () {
                            final normalizedTitle =
                                displayTitle(item.title).toLowerCase();
                            final normalizedPdfTitle =
                                displayTitle(item.pdfTitle).toLowerCase();
                            final pathLower = item.pdfPath.toLowerCase();

                            final isSession2PosturasSentada =
                              sessionNumber == 2 &&
                                (normalizedTitle.contains('posturas sentada') ||
                                  normalizedPdfTitle.contains('posturas sentada'));

                            final isImagePath = pathLower.endsWith('.png') ||
                                pathLower.endsWith('.jpg') ||
                                pathLower.endsWith('.jpeg') ||
                                pathLower.endsWith('.webp') ||
                                pathLower.startsWith('assets/');

                            final isTripleImageBodyScanSession1 =
                                sessionNumber == 1 &&
                                    pathLower.endsWith(
                                        'docs/materiaisum/primeirap.png');

                            final isHtmlPath = pathLower.endsWith('.html') ||
                                pathLower.endsWith('.htm');
                            final isFolheto = normalizedTitle
                                    .contains('folheto ser') ||
                                normalizedPdfTitle.contains('folheto ser') ||
                                isHtmlPath;

                            final folhetoText = isFolheto
                                ? FolhetoTextCatalog.forSession(sessionNumber)
                                : null;

                            final materialText = MaterialTextCatalog.forMaterial(
                              sessionNumber: sessionNumber,
                              normalizedTitle: normalizedTitle,
                              normalizedPdfTitle: normalizedPdfTitle,
                            );

                            if (kDebugMode) {
                              debugPrint(
                                'Material de apoio: title=${item.title} pdfTitle=${item.pdfTitle} path=${item.pdfPath} isFolheto=$isFolheto hasText=${folhetoText != null}',
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Abrindo: ${(isFolheto || materialText != null) ? 'TEXTO' : (isSession2PosturasSentada ? 'TEXTO+IMG' : (isImagePath ? 'IMAGEM' : 'PDF'))}\n${item.pdfPath}',
                                  ),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) {
                                  if (isSession2PosturasSentada) {
                                    return PosturasSentadasViewerScreen(
                                      title: item.pdfTitle,
                                      sessaoId: sessionId,
                                      itemId: item.pdfPath,
                                      isSupplementary: true,
                                    );
                                  }

                                  if (isFolheto) {
                                    final text = folhetoText ??
                                        'Conteúdo do folheto ainda não foi inserido para a Sessão $sessionNumber.';
                                    return FolhetoTextViewerScreen(
                                      title: item.pdfTitle,
                                      text: text,
                                      sessaoId: sessionId,
                                      itemId: item.title,
                                    );
                                  }

                                  if (materialText != null) {
                                    return FolhetoTextViewerScreen(
                                      title: item.pdfTitle,
                                      text: materialText,
                                      sessaoId: sessionId,
                                      itemId: item.title,
                                    );
                                  }

                                  if (isImagePath) {
                                    if (isTripleImageBodyScanSession1) {
                                      return MultiImageViewerScreen(
                                        imagePaths: const [
                                          'docs/materiaisum/primeirap.png',
                                          'docs/materiaisum/segundap.png',
                                          'docs/materiaisum/terceirap.png',
                                        ],
                                        titleLine1: 'POSIÇÕES DEITADA',
                                        titleLine2: 'Escaneamento corporal',
                                        sessaoId: sessionId,
                                        itemId: item.pdfPath,
                                        isSupplementary: true,
                                      );
                                    }

                                    return ImageViewerScreen(
                                      imagePath: item.pdfPath,
                                      imageTitle: item.pdfTitle,
                                      sessaoId: sessionId,
                                      itemId: item.pdfPath,
                                      isSupplementary: true,
                                    );
                                  }

                                  return PdfViewerScreen(
                                    pdfPath: item.pdfPath,
                                    downloadPath: item.downloadPath,
                                    pdfTitle: item.pdfTitle,
                                    sessaoId: sessionId,
                                    itemId: item.pdfPath,
                                    isSupplementary: true,
                                  );
                                },
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                SvgPicture.asset(
                                  'assets/livro.svg',
                                  width: 22,
                                  height: 22,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    displayTitle(item.title),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(),
    );
  }

  static TextStyle _titleStyleForSession(int sessionNumber) {
    if (sessionNumber == 4) {
      return const TextStyle(
        fontSize: 24,
        color: AppColors.brandTeal,
      );
    }

    return const TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: AppColors.primaryBlue,
    );
  }
}
