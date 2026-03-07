import 'dart:math' as math;

import 'package:appser/core/constants/firestore_paths.dart';
import 'package:appser/core/theme/app_colors.dart';
import 'package:appser/presentation/widgets/app_background.dart';
import 'package:appser/presentation/widgets/app_back_app_bar.dart';
import 'package:appser/presentation/widgets/app_bottom_nav_bar.dart';
import 'package:appser/presentation/widgets/app_elevated_row_button.dart';
import 'package:appser/presentation/widgets/app_scaffold.dart';
import 'package:appser/resources/audios/audio_player.dart';
import 'package:appser/resources/docs/inline_text_view.dart';
import 'package:appser/resources/docs/folheto_text_catalog.dart';
import 'package:appser/resources/docs/folheto_text_view.dart';
import 'package:appser/resources/docs/pdf_view.dart';
import 'package:appser/resources/images/image_view.dart';
import 'package:appser/resources/images/multi_image_view.dart';
import 'package:appser/resources/docs/recomendacoes_gerais_view.dart';
import 'package:appser/resources/videos/video_player.dart';
import 'package:appser/resources/videos/welcome_video_player.dart';
import 'package:appser/screens/home/widgets/session_titles.dart';
import 'package:appser/screens/user_tracking_service.dart';
import 'package:appser/services/practice_resume_service.dart';
import 'package:appser/sessions/session_catalog.dart';
import 'package:appser/sessions/session_content_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

Widget _assetIcon(
  String assetPath, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.contain,
  Color? color,
}) {
  final normalized = assetPath.toLowerCase();
  if (normalized.endsWith('.svg')) {
    return SvgPicture.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      colorFilter:
          color == null ? null : ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  return Image.asset(
    assetPath,
    width: width,
    height: height,
    fit: fit,
    filterQuality: FilterQuality.high,
    color: color,
  );
}

class SessionHubScreen extends StatefulWidget {
  final int sessionNumber;

  const SessionHubScreen({super.key, required this.sessionNumber});

  @override
  State<SessionHubScreen> createState() => _SessionHubScreenState();
}

class _SessionHubScreenState extends State<SessionHubScreen> {
  late Future<double> _completionProgress;

  @override
  void initState() {
    super.initState();
    _completionProgress = _fetchCompletionProgress();
  }

  void _refreshCompletionProgress() {
    setState(() {
      _completionProgress = _fetchCompletionProgress();
    });
  }

  Future<double> _fetchCompletionProgress() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 0.0;

    try {
      final sessionId = 'sessao_${widget.sessionNumber}';
      final doc = await FirebaseFirestore.instance
          .collection(FirestorePaths.usersCollection)
          .doc(uid)
          .collection(FirestorePaths.sessoesSubcollection)
          .doc(sessionId)
          .get();

      final itemIds = SessionCatalog.contentItemsFor(widget.sessionNumber)
          .map((e) => e.itemId)
          .toList();
      final totalTasks = itemIds.length;

      final conclusoesPorItemId =
          doc.data()?['conclusoesPorItemId'] as Map<String, dynamic>? ??
              const <String, dynamic>{};

      var completedTasks = 0;
      for (final id in itemIds) {
        final count = conclusoesPorItemId[id];
        if (count is num && count.toInt() > 0) completedTasks++;
      }

      return totalTasks == 0
          ? 0.0
          : (completedTasks / totalTasks).clamp(0.0, 1.0);
    } catch (_) {
      return 0.0;
    }
  }

  Future<void> _resumeNextPracticeInThisSession(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              SessionContentScreen(sessionNumber: widget.sessionNumber),
        ),
      );
      _refreshCompletionProgress();
      return;
    }

    final sessionNumber = widget.sessionNumber;
    final sessionId = 'sessao_$sessionNumber';

    Map<String, dynamic> conclusoesPorItemId = const <String, dynamic>{};
    try {
      final doc = await FirebaseFirestore.instance
          .collection(FirestorePaths.usersCollection)
          .doc(uid)
          .collection(FirestorePaths.sessoesSubcollection)
          .doc(sessionId)
          .get();
      conclusoesPorItemId =
          doc.data()?['conclusoesPorItemId'] as Map<String, dynamic>? ??
              const <String, dynamic>{};
    } catch (_) {
      // best-effort
    }

    final items = SessionCatalog.contentItemsFor(sessionNumber);
    SessionContentItem? next;
    for (final item in items) {
      final v = conclusoesPorItemId[item.itemId];
      final done = v is num && v.toInt() > 0;
      if (!done) {
        next = item;
        break;
      }
    }

    if (next == null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SessionContentScreen(sessionNumber: sessionNumber),
        ),
      );
      _refreshCompletionProgress();
      return;
    }

    await PracticeResumeService.setTarget(
      sessionNumber: sessionNumber,
      itemId: next.itemId,
    );

    final Widget destination;
    switch (next.type) {
      case SessionContentType.audio:
        destination = AudioPlayerScreen(
          audioPath: next.path,
          audioTitle: next.viewerTitle,
          sessaoId: sessionId,
          itemId: next.itemId,
          isSupplementary: false,
        );
        break;
      case SessionContentType.video:
        destination = VideoPlayerScreen(
          videoPath: next.path,
          videoTitle: next.viewerTitle,
          sessaoId: sessionId,
          itemId: next.itemId,
          isSupplementary: false,
        );
        break;
      case SessionContentType.pdf:
        destination = PdfViewerScreen(
          pdfPath: next.path,
          downloadPath: next.downloadPath ?? next.path,
          pdfTitle: next.viewerTitle,
          sessaoId: sessionId,
          itemId: next.itemId,
          isSupplementary: false,
        );
        break;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
    _refreshCompletionProgress();
  }

  @override
  Widget build(BuildContext context) {
    final sessionNumber = widget.sessionNumber;

    return AppScaffold(
      appBar: AppBackAppBar(
        titleText: 'Sessão $sessionNumber',
        backgroundColor: Colors.transparent,
      ),
      body: AppBackground(
        child: SafeArea(
          child: FutureBuilder<double>(
            future: _completionProgress,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text('Erro ao carregar progresso: ${snapshot.error}'),
                );
              }

              final completionProgress = snapshot.data ?? 0.0;

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: MediaQuery.sizeOf(context).width < 380 ? 16 : 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    _SessionHubMainCard(
                      completionProgress: completionProgress,
                      onResume: () {
                        _resumeNextPracticeInThisSession(context);
                      },
                    ),
                    const SizedBox(height: 16),
                    _SupportShortcutsRow(
                      onOpenWelcome: () {
                        const videoPath = 'videos/sessao0/Boas-vindas.mp4';
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WelcomeVideoPlayerScreen(
                              videoPath: videoPath,
                              videoTitle: 'Boas-Vindas',
                              sessaoId: 'sessao_0',
                              itemId: 'boas_vindas',
                              isSupplementary: false,
                            ),
                          ),
                        );
                      },
                      onOpenRecommendations: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RecomendacoesGeraisView(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sessão $sessionNumber: ${homeSessionTitleFor(sessionNumber)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF202020),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _UnifiedTasksList(
                      sessionNumber: sessionNumber,
                      onAfterTaskReturn: _refreshCompletionProgress,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(),
    );
  }
}

class _UnifiedTasksList extends StatelessWidget {
  final int sessionNumber;
  final VoidCallback onAfterTaskReturn;

  const _UnifiedTasksList({
    required this.sessionNumber,
    required this.onAfterTaskReturn,
  });

  @override
  Widget build(BuildContext context) {
    final content = SessionCatalog.contentItemsFor(sessionNumber);
    final materials = SessionCatalog.materialItemsFor(sessionNumber);
    final sessionId = 'sessao_$sessionNumber';

    const dividerColor = Color(0xFF10707E);

    String displayTitle(String raw) {
      return raw.replaceFirst(RegExp(r'^\s*\d+\.\s*'), '').trim();
    }

    String iconAssetForContent(SessionContentItem item) {
      switch (item.type) {
        case SessionContentType.audio:
          return 'assets/som.svg';
        case SessionContentType.video:
          return 'assets/video.svg';
        case SessionContentType.pdf:
          if (item.itemId == 'praticando_em_casa') return 'assets/pessoam.png';
          return 'assets/livro.png';
      }
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    final stream = uid == null
        ? null
        : FirebaseFirestore.instance
            .collection(FirestorePaths.usersCollection)
            .doc(uid)
            .collection(FirestorePaths.sessoesSubcollection)
            .doc(sessionId)
            .snapshots();

    Widget buildSection({
      required List<Widget> rows,
    }) {
      return Container(
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
          child: Column(children: rows),
        ),
      );
    }

    Widget buildList(Map<String, dynamic> conclusoesPorItemId) {
      bool isCompleted(String itemId) {
        final v = conclusoesPorItemId[itemId];
        return v is num && v.toInt() > 0;
      }

      Widget? trailingForContent(SessionContentItem item) {
        final duration = item.duration.trim();
        final done = isCompleted(item.itemId);

        if (duration.isEmpty && !done) return null;

        final children = <Widget>[];
        if (duration.isNotEmpty) {
          children.add(
            Text(
              duration,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFFC7CBCC),
              ),
            ),
          );
        }
        if (done) {
          if (children.isNotEmpty) children.add(const SizedBox(width: 8));
          children.add(
            const Icon(
              Icons.check_circle,
              size: 18,
              color: Color(0xFF10707E),
            ),
          );
        }

        return Row(mainAxisSize: MainAxisSize.min, children: children);
      }

      final contentRows = <Widget>[];
      for (var i = 0; i < content.length; i++) {
        final item = content[i];

        final iconColor = switch (item.type) {
          SessionContentType.audio => const Color(0xFF2F7888),
          SessionContentType.video => const Color(0xFF2F7888),
          SessionContentType.pdf => null,
        };

        final row = _SessionRectRow(
          iconAsset: iconAssetForContent(item),
          iconColor: iconColor,
          title: displayTitle(item.title),
          trailing: trailingForContent(item),
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
                if (sessionNumber == 1 && item.itemId == 'praticando_em_casa') {
                  destination = const InlineTextViewerScreen(
                    title: 'Praticando em Casa',
                    text: 'PRATICANDO EM CASA DA SEGUINTE FORMA\n'
                        'Momentos para reflexão\n'
                        '- Lendo a apostila\n'
                        '- Completando a planilha\n'
                        '\n'
                        'Momentos para experiência\n'
                        '- Trazendo mindfulness para a vida diária (refeições)\n'
                        '- Praticando escaneamento corporal 1x ao dia\n'
                        '\n'
                        'Próxima semana: trazer 5 livros (tamanhos variados)',
                    sessaoId: 'sessao_1',
                    itemId: 'praticando_em_casa',
                    isSupplementary: false,
                  );
                } else {
                  destination = PdfViewerScreen(
                    pdfPath: item.path,
                    downloadPath: item.downloadPath ?? item.path,
                    pdfTitle: item.viewerTitle,
                    sessaoId: sessionId,
                    itemId: item.itemId,
                    isSupplementary: false,
                  );
                }
                break;
            }

            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => destination),
            );
            onAfterTaskReturn();
          },
        );

        contentRows.add(row);
        if (i != content.length - 1) {
          contentRows
              .add(const Divider(height: 1, thickness: 1, color: dividerColor));
        }
      }

      final materialRows = <Widget>[];
      for (var i = 0; i < materials.length; i++) {
        final item = materials[i];
        final row = _SessionRectRow(
          iconAsset: 'assets/livro.png',
          title: displayTitle(item.title),
          onTap: () async {
            final normalizedTitle = displayTitle(item.title).toLowerCase();
            final normalizedPdfTitle =
                displayTitle(item.pdfTitle).toLowerCase();
            final pathLower = item.pdfPath.toLowerCase();

            final isImagePath = pathLower.endsWith('.png') ||
                pathLower.endsWith('.jpg') ||
                pathLower.endsWith('.jpeg') ||
                pathLower.endsWith('.webp') ||
                pathLower.startsWith('assets/');

            final isTripleImageBodyScanSession1 = sessionNumber == 1 &&
                pathLower.endsWith('docs/materiaisum/primeirap.png');

            final isHtmlPath =
                pathLower.endsWith('.html') || pathLower.endsWith('.htm');
            final isFolhetoCandidate =
                normalizedTitle.contains('folheto ser') ||
                    normalizedPdfTitle.contains('folheto ser') ||
                    isHtmlPath;

            final folhetoText = isFolhetoCandidate
                ? FolhetoTextCatalog.forSession(sessionNumber)
                : null;

            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) {
                  if (isFolhetoCandidate && folhetoText != null) {
                    return FolhetoTextViewerScreen(
                      title: item.pdfTitle,
                      text: folhetoText,
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
            onAfterTaskReturn();
          },
        );

        materialRows.add(row);
        if (i != materials.length - 1) {
          materialRows
              .add(const Divider(height: 1, thickness: 1, color: dividerColor));
        }
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (contentRows.isNotEmpty) buildSection(rows: contentRows),
          if (contentRows.isNotEmpty) const SizedBox(height: 14),
          const Text(
            'Material de Apoio',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xFF202020),
            ),
          ),
          const SizedBox(height: 6),
          if (materialRows.isNotEmpty) buildSection(rows: materialRows),
        ],
      );
    }

    if (stream == null) {
      return buildList(const <String, dynamic>{});
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        final conclusoesPorItemId = snapshot.data
                ?.data()?['conclusoesPorItemId'] as Map<String, dynamic>? ??
            const <String, dynamic>{};
        return buildList(conclusoesPorItemId);
      },
    );
  }

  static IconData _iconFor(SessionContentType type) {
    switch (type) {
      case SessionContentType.audio:
        return Icons.headset;
      case SessionContentType.video:
        return Icons.play_circle_filled;
      case SessionContentType.pdf:
        return Icons.article;
    }
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

class _SessionHubMainCard extends StatelessWidget {
  final VoidCallback onResume;
  final double completionProgress;

  const _SessionHubMainCard({
    required this.onResume,
    required this.completionProgress,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (completionProgress * 100).round();

    return Container(
      constraints: const BoxConstraints(minHeight: 210),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/back.png'),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final isNarrow = maxWidth < 380;

          final logoHeight = isNarrow ? 106.0 : 118.0;
          final ringSize = isNarrow ? 136.0 : 152.0;
          final buttonMaxWidth = isNarrow ? 182.0 : 205.0;
          final ringTopPadding = isNarrow ? 22.0 : 28.0;

          final resumeButton = ElevatedButton(
            onPressed: onResume,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF60BFCD),
              foregroundColor: Colors.white,
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.12),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 15,
              ),
            ),
            child: const Text('Retomar prática'),
          );

          final progressRing = SizedBox(
            width: ringSize,
            height: ringSize,
            child: _ProgressRing(
              progress: completionProgress,
              centerText: "$percent%",
              labelText: "Tarefas Concluídas",
            ),
          );

          final progressRingLowered = Padding(
            padding: EdgeInsets.only(top: ringTopPadding),
            child: progressRing,
          );

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        left: 14,
                        top: isNarrow ? 18 : 20,
                      ),
                      child: Image.asset(
                        'assets/logo.png',
                        height: logoHeight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: buttonMaxWidth),
                      child:
                          SizedBox(width: double.infinity, child: resumeButton),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              progressRingLowered,
            ],
          );
        },
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  final double progress;
  final String centerText;
  final String labelText;

  const _ProgressRing({
    required this.progress,
    required this.centerText,
    required this.labelText,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ProgressRingPainter(progress: progress),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              centerText,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF232323),
                height: 1.0,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              labelText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: AppColors.textDark.withOpacity(0.85),
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;

  const _ProgressRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final p = progress.clamp(0.0, 1.0);
    final stroke = 10.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    const remainderColor = Color(0xFFAAE0C7);
    const progressColor = Color(0xFF10707E);

    const startAngle = -math.pi / 2;

    final bgPaint = Paint()
      ..color = remainderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, math.pi * 2, false, bgPaint);

    if (p <= 0) {
      return;
    }

    final sweep = math.pi * 2 * p;

    final fgPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweep, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _SupportShortcutsRow extends StatelessWidget {
  final VoidCallback onOpenWelcome;
  final VoidCallback onOpenRecommendations;

  const _SupportShortcutsRow({
    required this.onOpenWelcome,
    required this.onOpenRecommendations,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ShortcutCard(
            title: 'Boas vindas ao\nProjeto SER',
            iconAsset: 'assets/meditacao.svg',
            color: const Color(0xFFAFD1D0),
            onTap: onOpenWelcome,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ShortcutCard(
            title: 'Recomendações\ngerais',
            iconAsset: 'assets/pedra.svg',
            color: AppColors.shortcutRecommendationsBg,
            onTap: onOpenRecommendations,
          ),
        ),
      ],
    );
  }
}

class _SessionRectRow extends StatelessWidget {
  final String iconAsset;
  final Color? iconColor;
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SessionRectRow({
    required this.iconAsset,
    this.iconColor,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              _assetIcon(iconAsset, width: 22, height: 22, color: iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  final String title;
  final String iconAsset;
  final Color color;
  final VoidCallback onTap;

  const _ShortcutCard({
    required this.title,
    required this.iconAsset,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 92,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _assetIcon(iconAsset, width: 26, height: 26),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF202020),
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
