import 'dart:math' as math;

import 'package:appser/core/constants/firestore_paths.dart';
import 'package:appser/core/constants/session_defaults.dart';
import 'package:appser/core/theme/app_colors.dart';
import 'package:appser/presentation/controllers/home_controller.dart';
import 'package:appser/presentation/widgets/app_background.dart';
import 'package:appser/presentation/widgets/app_bottom_nav_bar.dart';
import 'package:appser/presentation/widgets/app_scaffold.dart';
import 'package:appser/resources/audios/audio_player.dart';
import 'package:appser/resources/docs/folheto_text_catalog.dart';
import 'package:appser/resources/docs/folheto_text_view.dart';
import 'package:appser/resources/docs/pdf_view.dart';
import 'package:appser/resources/docs/recomendacoes_gerais_view.dart';
import 'package:appser/resources/videos/video_player.dart';
import 'package:appser/resources/videos/welcome_video_player.dart';
import 'package:appser/screens/user_tracking_service.dart';
import 'package:appser/screens/home/widgets/session_titles.dart';
import 'package:appser/services/authetication_service.dart';
import 'package:appser/services/practice_resume_service.dart';
import 'package:appser/services/session_unlock_service.dart';
import 'package:appser/sessions/session_catalog.dart';
import 'package:appser/sessions/session_hub_screen.dart';
import 'package:appser/stateChanges.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late Future<_HomeData> _homeData;

  static const _lastOpenedSessionKey = 'home.lastOpenedSessionIndex';

  @override
  void initState() {
    super.initState();
    _homeData = _fetchHomeData();

    // Salvaguarda: se a Home for aberta sem usuário logado,
    // força volta para o gate de autenticação.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) return;
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainPage()),
        (route) => false,
      );
    });
  }

  Future<void> _logoutAndGoToLogin() async {
    try {
      await context.read<AutheticationService>().logout();
    } catch (_) {
      // best-effort
    }

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainPage()),
      (route) => false,
    );
  }

  Future<_HomeData> _fetchHomeData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      // Best-effort: tenta liberar sessões antes de recarregar a Home.
      await context.read<SessionUnlockService>().ensureSessionUnlocks(uid: uid);
    }

    final sessionStatus = await context.read<HomeController>().fetchSessionStatus();
    final stats = await _fetchStats(sessionStatus: sessionStatus);

    return _HomeData(
      sessionStatus: sessionStatus,
      stats: stats,
    );
  }

  void _refreshSessions() {
    setState(() {
      _homeData = _fetchHomeData();
    });
  }

  void _openSession({
    required BuildContext context,
    required int index,
    required Map<String, bool> sessionStatus,
  }) {
    if (!(sessionStatus['session$index'] ?? false)) {
      return;
    }

    _persistLastOpenedSessionIndex(index);

    if (index == 0) {
      const videoPath = 'videos/sessao0/Boas-vindas.mp4';
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const WelcomeVideoPlayerScreen(
            videoPath: videoPath,
            videoTitle: 'Boas-Vindas',
            sessaoId: 'sessao_0',
            itemId: 'boas_vindas',
            isSupplementary: false,
          ),
        ),
      ).then((_) => _refreshSessions());
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionHubScreen(sessionNumber: index),
      ),
    ).then((_) => _refreshSessions());
  }

  Future<void> _persistLastOpenedSessionIndex(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastOpenedSessionKey, index);
    } catch (_) {
      // Best-effort: não falha a navegação.
    }
  }

  Future<int?> _loadLastOpenedSessionIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_lastOpenedSessionKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> _resumeLastPractice({
    required BuildContext context,
    required Map<String, bool> sessionStatus,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _openLastUnlockedSessionHub(
        context: context,
        sessionStatus: sessionStatus,
      );
      return;
    }

    final saved = await PracticeResumeService.loadTarget();
    final resolved = await _resolveNextPracticeTarget(
      uid: uid,
      sessionStatus: sessionStatus,
      preferredSessionNumber: saved?.sessionNumber,
      preferredItemId: saved?.itemId,
    );

    if (resolved == null) {
      _openLastUnlockedSessionHub(
        context: context,
        sessionStatus: sessionStatus,
      );
      return;
    }

    // Atualiza o ponteiro (especialmente quando pulamos uma já concluída).
    await PracticeResumeService.setTarget(
      sessionNumber: resolved.sessionNumber,
      itemId: resolved.item.itemId,
    );

    // Mantém também o lastOpenedSessionIndex (best-effort) para compatibilidade.
    _persistLastOpenedSessionIndex(resolved.sessionNumber);

    await _openContentItem(
      context: context,
      sessionNumber: resolved.sessionNumber,
      item: resolved.item,
    );
  }

  void _openLastUnlockedSessionHub({
    required BuildContext context,
    required Map<String, bool> sessionStatus,
  }) {
    // Fallback simples: abre a última sessão liberada (1..8), senão a 1.
    int? lastUnlocked;
    for (var i = SessionDefaults.totalSessions - 1; i >= 1; i--) {
      if (sessionStatus['session$i'] ?? false) {
        lastUnlocked = i;
        break;
      }
    }

    final index = lastUnlocked ?? 1;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionHubScreen(sessionNumber: index),
      ),
    ).then((_) => _refreshSessions());
  }

  Future<({int sessionNumber, SessionContentItem item})?>
      _resolveNextPracticeTarget({
    required String uid,
    required Map<String, bool> sessionStatus,
    int? preferredSessionNumber,
    String? preferredItemId,
  }) async {
    // Sessões elegíveis: somente 1..8 liberadas.
    final unlockedSessions = <int>[];
    for (var i = 1; i < SessionDefaults.totalSessions; i++) {
      if (sessionStatus['session$i'] ?? false) unlockedSessions.add(i);
    }
    if (unlockedSessions.isEmpty) return null;

    int startSession = unlockedSessions.first;
    if (preferredSessionNumber != null &&
        unlockedSessions.contains(preferredSessionNumber)) {
      startSession = preferredSessionNumber;
    }

    // 1) Tenta retomar a partir do item salvo.
    final fromSaved = await _firstIncompleteInSession(
      uid: uid,
      sessionNumber: startSession,
      startItemId: preferredItemId,
    );
    if (fromSaved != null) {
      return (sessionNumber: startSession, item: fromSaved);
    }

    // 2) Se não achou, procura na mesma sessão desde o começo.
    if (preferredItemId != null) {
      final fromBeginning = await _firstIncompleteInSession(
        uid: uid,
        sessionNumber: startSession,
        startItemId: null,
      );
      if (fromBeginning != null) {
        return (sessionNumber: startSession, item: fromBeginning);
      }
    }

    // 3) Procura nas sessões seguintes desbloqueadas.
    final startIdx = unlockedSessions.indexOf(startSession);
    for (var i = startIdx + 1; i < unlockedSessions.length; i++) {
      final sessionNumber = unlockedSessions[i];
      final item = await _firstIncompleteInSession(
        uid: uid,
        sessionNumber: sessionNumber,
        startItemId: null,
      );
      if (item != null) return (sessionNumber: sessionNumber, item: item);
    }

    return null;
  }

  Future<SessionContentItem?> _firstIncompleteInSession({
    required String uid,
    required int sessionNumber,
    required String? startItemId,
  }) async {
    try {
      final sessionId = 'sessao_$sessionNumber';
      final snap = await FirebaseFirestore.instance
          .collection(FirestorePaths.usersCollection)
          .doc(uid)
          .collection(FirestorePaths.sessoesSubcollection)
          .doc(sessionId)
          .get();

      final conclusoesPorItemId =
          snap.data()?['conclusoesPorItemId'] as Map<String, dynamic>? ??
              const <String, dynamic>{};

      final items = SessionCatalog.contentItemsFor(sessionNumber);
      if (items.isEmpty) return null;

      var startIndex = 0;
      if (startItemId != null) {
        final idx = items.indexWhere((e) => e.itemId == startItemId);
        if (idx >= 0) startIndex = idx;
      }

      for (var i = startIndex; i < items.length; i++) {
        final item = items[i];
        final count = conclusoesPorItemId[item.itemId];
        final done = count is num && count.toInt() > 0;
        if (!done) return item;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _openContentItem({
    required BuildContext context,
    required int sessionNumber,
    required SessionContentItem item,
  }) async {
    final sessionId = 'sessao_$sessionNumber';

    // Tracking: clique de retomada também conta como acesso ao item.
    try {
      await UserTrackingService.registrarClique(
        sessaoId: sessionId,
        tipo: _trackingTypeFor(item.type),
        itemId: item.itemId,
      );
    } catch (_) {
      // best-effort
    }

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

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
    _refreshSessions();
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

  Future<_HomeStats> _fetchStats({
    required Map<String, bool> sessionStatus,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    String? displayName = user?.displayName?.trim();
    if (displayName != null && displayName.isEmpty) displayName = null;

    String? nameFromUserDoc;
    if (uid != null) {
      try {
        await UserTrackingService.registrarDataInicioSeNaoExistir();
      } catch (_) {
        // Best-effort: o binding pode não estar disponível em alguns cenários.
      }

      try {
        final doc = await FirebaseFirestore.instance
            .collection(FirestorePaths.usersCollection)
            .doc(uid)
            .get();
        final raw = doc.data()?['nome'];
        final value = raw?.toString().trim();
        if (value != null && value.isNotEmpty) nameFromUserDoc = value;
      } catch (_) {
        // Best-effort: falha de rede/permissão não quebra a tela.
      }
    }

    final userName = nameFromUserDoc ?? displayName ?? 'Usuário';

    // Métricas (best-effort): baseadas em eventos de tarefa e docs de sessão.
    int streakDays = 0;
    int audioMinutes = 0;
    final completedSessionIndexes = <int>{};

    if (uid != null) {
      // Task events: streak + minutos.
      try {
        final snap = await FirebaseFirestore.instance
            .collection(FirestorePaths.usersCollection)
            .doc(uid)
            .collection(FirestorePaths.taskEventsSubcollection)
            .orderBy('createdAt', descending: true)
            .limit(250)
            .get();

        final days = <DateTime>{};
        int totalAudioSeconds = 0;

        for (final doc in snap.docs) {
          final data = doc.data();
          final createdAt = data['createdAt'];
          if (createdAt is Timestamp) {
            final d = createdAt.toDate();
            days.add(DateTime(d.year, d.month, d.day));
          }

          if (data['eventType'] == 'task_complete' && data['tipo'] == 'audio') {
            final duration = data['durationSeconds'];
            if (duration is num && duration > 0) {
              totalAudioSeconds += duration.toInt();
            }
          }
        }

        audioMinutes = totalAudioSeconds ~/ 60;

        if (days.isNotEmpty) {
          final sorted = days.toList()..sort();
          DateTime cursor = sorted.last;
          streakDays = 1;
          while (days.contains(cursor.subtract(const Duration(days: 1)))) {
            cursor = cursor.subtract(const Duration(days: 1));
            streakDays++;
          }
        }
      } catch (_) {
        // best-effort
      }

      // Sessões concluídas: conta docs com `vezesFinalizadaPorConclusao` > 0.
      try {
        final futures = <Future<DocumentSnapshot<Map<String, dynamic>>>>[];
        for (var i = 1; i <= 8; i++) {
          futures.add(
            FirebaseFirestore.instance
                .collection(FirestorePaths.usersCollection)
                .doc(uid)
                .collection(FirestorePaths.sessoesSubcollection)
                .doc('sessao_$i')
                .get(),
          );
        }

        final docs = await Future.wait(futures);

        var completedTasks = 0;
        var totalTasks = 0;

        for (var i = 0; i < docs.length; i++) {
          final doc = docs[i];
          final raw = doc.data()?['vezesFinalizadaPorConclusao'];
          final value = raw is num ? raw.toInt() : 0;
          if (value > 0) {
            completedSessionIndexes.add(i + 1);
          }

          final sessionNumber = i + 1;
          final itemIds = SessionCatalog.contentItemsFor(sessionNumber)
              .map((e) => e.itemId)
              .toList();
          totalTasks += itemIds.length;

          final conclusoesPorItemId =
              doc.data()?['conclusoesPorItemId'] as Map<String, dynamic>? ??
                  const {};
          for (final id in itemIds) {
            final count = conclusoesPorItemId[id];
            if (count is num && count.toInt() > 0) {
              completedTasks++;
            }
          }
        }

        // Progresso global: tarefas concluídas / total de tarefas.
        final taskProgress =
            totalTasks == 0 ? 0.0 : (completedTasks / totalTasks).clamp(0.0, 1.0);

        final completedSessions = completedSessionIndexes.length;

        return _HomeStats(
          userName: userName,
          streakDays: streakDays,
          audioMinutes: audioMinutes,
          completedSessions: completedSessions,
          completedSessionIndexes: completedSessionIndexes,
          completionProgress: taskProgress,
        );
      } catch (_) {
        // best-effort
      }
    }

    // Fallback: sem uid ou falha ao ler progresso.
    return _HomeStats(
      userName: userName,
      streakDays: streakDays,
      audioMinutes: audioMinutes,
      completedSessions: 0,
      completedSessionIndexes: const <int>{},
      completionProgress: 0.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: AppBackground(
        child: SafeArea(
          child: FutureBuilder<_HomeData>(
            future: _homeData,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text('Erro ao carregar sessões: ${snapshot.error}'),
                );
              }
              final data = snapshot.data;
              if (data == null) {
                return const Center(
                  child: Text('Dados de sessão não disponíveis.'),
                );
              }

              final sessionStatus = data.sessionStatus;
              final stats = data.stats;
              final greetingName = _firstNameOf(stats.userName);

              final screenWidth = MediaQuery.sizeOf(context).width;
              final horizontalPadding = screenWidth < 380 ? 16.0 : 24.0;

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _GreetingBar(
                      greetingName: greetingName,
                      onLogout: _logoutAndGoToLogin,
                    ),
                    const SizedBox(height: 28),
                    _HomeMainCard(
                      onResume: () => _resumeLastPractice(
                        context: context,
                        sessionStatus: sessionStatus,
                      ),
                      completionProgress: stats.completionProgress,
                    ),
                    const SizedBox(height: 16),
                    _SupportShortcutsRow(
                      onOpenWelcome: () => _openSession(
                        context: context,
                        index: 0,
                        sessionStatus: sessionStatus,
                      ),
                      onOpenBooklet: () {
                        final folhetoText =
                            FolhetoTextCatalog.forSession(1) ?? '';
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FolhetoTextViewerScreen(
                              title: 'Folheto Ser Sessão 1',
                              text: folhetoText,
                              sessaoId: 'sessao_1',
                              itemId: 'folheto_ser_sessao_1',
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
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            value: '${stats.streakDays}',
                            label: 'Dias em Sequência',
                            iconAsset: 'assets/sol.svg',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricCard(
                            value: '${stats.audioMinutes}',
                            label: 'Minutos meditados',
                            iconAsset: 'assets/meditacao.svg',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricCard(
                            value: '${stats.completedSessions}',
                            label: 'Medalhas',
                            iconAsset: 'assets/coracao.svg',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SessionsList(
                      sessionStatus: sessionStatus,
                      completedSessionIndexes: stats.completedSessionIndexes,
                      onTapSession: (index) => _openSession(
                        context: context,
                        index: index,
                        sessionStatus: sessionStatus,
                      ),
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

  static String _firstNameOf(String fullName) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return 'Usuário';
    final parts = trimmed.split(RegExp(r'\s+'));
    return parts.isEmpty ? trimmed : parts.first;
  }
}

class _HomeData {
  final Map<String, bool> sessionStatus;
  final _HomeStats stats;

  const _HomeData({
    required this.sessionStatus,
    required this.stats,
  });
}

class _HomeStats {
  final String userName;
  final int streakDays;
  final int audioMinutes;
  final int completedSessions;
  final Set<int> completedSessionIndexes;
  final double completionProgress;

  const _HomeStats({
    required this.userName,
    required this.streakDays,
    required this.audioMinutes,
    required this.completedSessions,
    required this.completedSessionIndexes,
    required this.completionProgress,
  });
}

class _HomeMainCard extends StatelessWidget {
  final VoidCallback onResume;
  final double completionProgress;

  const _HomeMainCard({
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
                      child: SizedBox(width: double.infinity, child: resumeButton),
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

class _HomePdfCarousel extends StatelessWidget {
  final void Function(int sessionNumber) onOpenMaterials;

  const _HomePdfCarousel({required this.onOpenMaterials});

  @override
  Widget build(BuildContext context) {
    final tiles = <_PdfShortcutTileData>[
      _PdfShortcutTileData(
        label: 'Sessão 1',
        color: AppColors.primaryBlue,
        sessionNumber: 1,
      ),
      _PdfShortcutTileData(
        label: 'Sessão 2',
        color: AppColors.brandTeal,
        sessionNumber: 2,
      ),
      _PdfShortcutTileData(
        label: 'Sessão 3',
        color: AppColors.authPrimary,
        sessionNumber: 3,
      ),
      _PdfShortcutTileData(
        label: 'Sessão 4',
        color: AppColors.actionGreen,
        sessionNumber: 4,
      ),
    ];

    return SizedBox(
      height: 92,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final t in tiles) ...[
              _PdfShortcutTile(
                label: t.label,
                color: t.color,
                onTap: () => onOpenMaterials(t.sessionNumber),
              ),
              const SizedBox(width: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _PdfShortcutTileData {
  final String label;
  final Color color;
  final int sessionNumber;

  const _PdfShortcutTileData({
    required this.label,
    required this.color,
    required this.sessionNumber,
  });
}

class _PdfShortcutTile extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PdfShortcutTile({
    required this.label,
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
          width: 120,
          height: 92,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String value;
  final String label;
  final String iconAsset;

  const _MetricCard({
    required this.value,
    required this.label,
    required this.iconAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF202020),
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              _assetIcon(iconAsset, width: 26, height: 26),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF4A6363),
            ),
          ),
        ],
      ),
    );
  }
}

class _GreetingBar extends StatelessWidget {
  final String greetingName;
  final Future<void> Function() onLogout;

  const _GreetingBar({
    required this.greetingName,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Seja bem vindo(a), $greetingName!',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF202020),
            ),
          ),
        ),
        IconButton(
          onPressed: () {
            onLogout();
          },
          icon: const Icon(
            Icons.logout,
            color: Color(0xFF2F7888),
          ),
          tooltip: 'Sair',
        ),
      ],
    );
  }
}

class _SupportShortcutsRow extends StatelessWidget {
  final VoidCallback onOpenWelcome;
  final VoidCallback onOpenBooklet;
  final VoidCallback onOpenRecommendations;

  const _SupportShortcutsRow({
    required this.onOpenWelcome,
    required this.onOpenBooklet,
    required this.onOpenRecommendations,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ShortcutCard(
            title: 'Boas vindas ao\nProjeto',
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
        const SizedBox(width: 12),
        Expanded(
          child: _ShortcutCard(
            title: 'Folheto da\nSessão 1',
            iconAsset: 'assets/livrof.svg',
            color: const Color(0xFFBAE9E9),
            onTap: onOpenBooklet,
          ),
        ),
      ],
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

class _SessionsList extends StatelessWidget {
  final Map<String, bool> sessionStatus;
  final Set<int> completedSessionIndexes;
  final void Function(int index) onTapSession;

  const _SessionsList({
    required this.sessionStatus,
    required this.completedSessionIndexes,
    required this.onTapSession,
  });

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];

    for (var index = 1; index <= 8; index++) {
      final enabled = sessionStatus['session$index'] ?? false;
      final completed = completedSessionIndexes.contains(index);
      items.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _SessionTile(
            index: index,
            title: homeSessionTitleFor(index),
            enabled: enabled,
            completed: completed,
            onTap: enabled ? () => onTapSession(index) : null,
          ),
        ),
      );
    }

    return Column(
      children: items,
    );
  }
}

class _SessionTile extends StatelessWidget {
  final int index;
  final String title;
  final bool enabled;
  final bool completed;
  final VoidCallback? onTap;

  const _SessionTile({
    required this.index,
    required this.title,
    required this.enabled,
    required this.completed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = completed ? const Color(0xFFAAE0C7) : const Color(0xFFCCE4E8);
    const accent = Color(0xFF2F7888);

    Widget trailing;
    if (!enabled) {
      trailing = _assetIcon(
        'assets/cadeado.svg',
        width: 20,
        height: 20,
        color: const Color(0xFF2F7888),
      );
    } else if (completed) {
      trailing = Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: accent,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check,
          size: 12,
          color: Colors.white,
        ),
      );
    } else {
      trailing = _assetIcon('assets/voltarerrado.png', width: 20, height: 20);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE3E3E3),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Sessão $index: $title',
                  maxLines: 2,
                  overflow: TextOverflow.clip,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF202020),
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}