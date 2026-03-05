import 'package:appser/presentation/controllers/home_controller.dart';
import 'package:appser/presentation/widgets/app_background.dart';
import 'package:appser/presentation/widgets/app_back_app_bar.dart';
import 'package:appser/presentation/widgets/app_bottom_nav_bar.dart';
import 'package:appser/presentation/widgets/app_scaffold.dart';
import 'package:appser/core/theme/app_colors.dart';
import 'package:appser/resources/docs/recomendacoes_gerais_view.dart';
import 'package:appser/resources/videos/welcome_video_player.dart';
import 'package:appser/screens/home/widgets/session_list.dart';
import 'package:appser/services/session_unlock_service.dart';
import 'package:appser/sessions/session_hub_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

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

class SessionsOverviewScreen extends StatefulWidget {
  const SessionsOverviewScreen({super.key});

  @override
  State<SessionsOverviewScreen> createState() => _SessionsOverviewScreenState();
}

class _SessionsOverviewScreenState extends State<SessionsOverviewScreen> {
  late Future<Map<String, bool>> _sessionStatus;

  @override
  void initState() {
    super.initState();
    _sessionStatus = _fetchSessionStatus();
  }

  Future<Map<String, bool>> _fetchSessionStatus() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await context.read<SessionUnlockService>().ensureSessionUnlocks(uid: uid);
    }
    return context.read<HomeController>().fetchSessionStatus();
  }

  void _openSession({
    required BuildContext context,
    required int index,
    required Map<String, bool> sessionStatus,
  }) {
    if (!(sessionStatus['session$index'] ?? false)) {
      return;
    }

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
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionHubScreen(sessionNumber: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return AppScaffold(
      appBar: const AppBackAppBar(
        titleText: 'Sessões',
        showBackButton: false,
      ),
      body: AppBackground(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
          child: FutureBuilder<Map<String, bool>>(
            future: _sessionStatus,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(
                  child: Text('Erro ao carregar sessões: ${snapshot.error}'),
                );
              } else if (!snapshot.hasData) {
                return const Center(
                  child: Text('Dados de sessão não disponíveis.'),
                );
              }

              final sessionStatus = snapshot.data!;
              return Column(
                children: <Widget>[
                  SizedBox(height: screenHeight * 0.05),
                  Row(
                    children: [
                      Expanded(
                        child: _ShortcutCard(
                          title: 'Recomendações\ngerais',
                          iconAsset: 'assets/pedra.svg',
                          color: AppColors.shortcutRecommendationsBg,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RecomendacoesGeraisView(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  HomeSessionList(
                    sessionStatus: sessionStatus,
                    screenHeight: screenHeight,
                    screenWidth: screenWidth,
                    onSessionPressed: (index) => _openSession(
                      context: context,
                      index: index,
                      sessionStatus: sessionStatus,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.1),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(),
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
