import 'package:appser/presentation/widgets/app_bottom_nav_bar.dart';
import 'package:appser/presentation/widgets/app_back_app_bar.dart';
import 'package:appser/presentation/widgets/app_scaffold.dart';
import 'package:appser/resources/audios/audio_player.dart';
import 'package:appser/resources/docs/pdf_view.dart';
import 'package:appser/resources/videos/video_player.dart';
import 'package:appser/screens/user_tracking_service.dart';
import 'package:appser/services/practice_resume_service.dart';
import 'package:appser/sessions/session_catalog.dart';
import 'package:flutter/material.dart';

import 'package:appser/core/theme/app_colors.dart';
import 'package:appser/presentation/widgets/app_elevated_row_button.dart';
import 'package:appser/sessions/widgets/session_header.dart';

class SessionContentScreen extends StatelessWidget {
  final int sessionNumber;

  const SessionContentScreen({super.key, required this.sessionNumber});

  @override
  Widget build(BuildContext context) {
    final items = SessionCatalog.contentItemsFor(sessionNumber);
    final String sessionId = 'sessao_$sessionNumber';

    const dividerColor = Color(0xFF10707E);

    String displayTitle(String raw) {
      return raw.replaceFirst(RegExp(r'^\s*\d+\.\s*'), '').trim();
    }

    String iconAssetFor(SessionContentItem item) {
      switch (item.type) {
        case SessionContentType.audio:
          return 'assets/som.png';
        case SessionContentType.video:
          return 'assets/video.png';
        case SessionContentType.pdf:
          if (item.itemId == 'praticando_em_casa') return 'assets/pessoam.png';
          return 'assets/livro.png';
      }
    }

    return AppScaffold(
      backgroundColor: const Color.fromARGB(255, 234, 242, 242),
      appBar: AppBackAppBar(titleText: 'Sessão $sessionNumber'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SessionHeader(
              title: 'Sessão $sessionNumber',
              titleStyle: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, thickness: 1, color: dividerColor),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Material(
                        color: Colors.white,
                        child: InkWell(
                          onTap: () async {
                            await PracticeResumeService.setTarget(
                              sessionNumber: sessionNumber,
                              itemId: item.itemId,
                            );

                            await UserTrackingService.registrarClique(
                              sessaoId: sessionId,
                              tipo: _trackingTypeFor(item.type),
                              itemId: item.itemId,
                            );

                            final Widget destination;
                            switch (item.type) {
                              case SessionContentType.audio:
                                destination = AudioPlayerScreen(
                                  audioPath: item.path,
                                  audioTitle: item.viewerTitle,
                                  sessaoId: sessionId,
                                  itemId: item.itemId,
                                  isSupplementary: false,
                                );
                                break;
                              case SessionContentType.video:
                                destination = VideoPlayerScreen(
                                  videoPath: item.path,
                                  videoTitle: item.viewerTitle,
                                  sessaoId: sessionId,
                                  itemId: item.itemId,
                                  isSupplementary: false,
                                );
                                break;
                              case SessionContentType.pdf:
                                destination = PdfViewerScreen(
                                  pdfPath: item.path,
                                  downloadPath: item.downloadPath ?? item.path,
                                  pdfTitle: item.viewerTitle,
                                  sessaoId: sessionId,
                                  itemId: item.itemId,
                                  isSupplementary: false,
                                );
                                break;
                            }

                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => destination),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Image.asset(
                                  iconAssetFor(item),
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
                                if (item.duration.trim().isNotEmpty)
                                  Text(
                                    item.duration,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black54,
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

  static String _trackingTypeFor(SessionContentType type) {
    switch (type) {
      case SessionContentType.audio:
        return 'audio';
      case SessionContentType.video:
        return 'video';
      case SessionContentType.pdf:
        return 'pdf';
    }
  }
}
