import 'dart:math' as math;

import 'package:appser/screens/help.dart';
import 'package:appser/screens/home/widgets/session_titles.dart';
import 'package:appser/services/session_unlock_service.dart';
import 'package:appser/sessions/session_hub_screen.dart';
import 'package:appser/stateChanges.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:appser/presentation/controllers/home_controller.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({super.key});

  static const double _barHeight = 72;
  static const double _iconHeight = 30;
  static const double _iconScale = 1.22;
  static const double _labelFontSize = 12;
  static const double _itemWidth = 88;
  static const double _itemGap = 18;

  static const String _homeRouteName = 'home';
  static const String _helpRouteName = 'help';

  String? _currentRouteName(BuildContext context) {
    return ModalRoute.of(context)?.settings.name;
  }

  Route<void> _buildInstantRoute(Widget page, {required String name}) {
    return PageRouteBuilder<void>(
      settings: RouteSettings(name: name),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (_, __, ___) => page,
    );
  }

  void _goToRoot(BuildContext context, Widget page, {required String name}) {
    Navigator.of(context).pushAndRemoveUntil(
      _buildInstantRoute(page, name: name),
      (route) => false,
    );
  }

  void _push(BuildContext context, Widget page, {required String name}) {
    Navigator.of(context).push(_buildInstantRoute(page, name: name));
  }

  Future<Map<String, bool>> _fetchSessionStatus(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await context.read<SessionUnlockService>().ensureSessionUnlocks(uid: uid);
    }
    return context.read<HomeController>().fetchSessionStatus();
  }

  Future<void> _openSessionsModal(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final screen = MediaQuery.sizeOf(dialogContext);
        final maxWidth = math.min(380.0, screen.width - 48);

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: FutureBuilder<Map<String, bool>>(
                  future: _fetchSessionStatus(dialogContext),
                  builder: (context, snapshot) {
                    Widget header() {
                      return const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: Text(
                          'Sessões liberadas',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF202020),
                          ),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          header(),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ],
                      );
                    }

                    if (snapshot.hasError) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          header(),
                          Text(
                            'Erro ao carregar sessões.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black.withOpacity(0.65),
                            ),
                          ),
                        ],
                      );
                    }

                    final status = snapshot.data ?? const <String, bool>{};
                    final unlocked = <int>[];
                    for (var i = 1; i <= 8; i++) {
                      if (status['session$i'] ?? false) unlocked.add(i);
                    }

                    if (unlocked.isEmpty) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          header(),
                          Text(
                            'Nenhuma sessão liberada no momento.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black.withOpacity(0.65),
                            ),
                          ),
                        ],
                      );
                    }

                    // Altura: cresce conforme a quantidade, mas limita e vira scroll.
                    const rowHeight = 64.0;
                    final desiredListHeight = unlocked.length * rowHeight;
                    final maxListHeight = screen.height * 0.5;
                    final listHeight =
                        desiredListHeight.clamp(0.0, maxListHeight);

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        header(),
                        SizedBox(
                          height: listHeight,
                          child: ListView.separated(
                            physics: unlocked.length <= 3
                                ? const NeverScrollableScrollPhysics()
                                : const BouncingScrollPhysics(),
                            itemCount: unlocked.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              thickness: 1,
                              color: const Color(0xFF10707E).withOpacity(0.18),
                            ),
                            itemBuilder: (context, index) {
                              final sessionNumber = unlocked[index];
                              return ListTile(
                                dense: true,
                                visualDensity: VisualDensity.compact,
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                title: Text(
                                  'Sessão $sessionNumber',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF202020),
                                  ),
                                ),
                                subtitle: Text(
                                  homeSessionTitleFor(sessionNumber),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black.withOpacity(0.62),
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right,
                                  color: Color(0xFF10707E),
                                ),
                                onTap: () {
                                  Navigator.of(dialogContext).pop();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => SessionHubScreen(
                                        sessionNumber: sessionNumber,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final labelStyle = TextStyle(
      fontSize: _labelFontSize,
      fontWeight: FontWeight.w400,
      color: const Color(0xFF232323),
    );

    Widget navItem({
      required String assetPath,
      required String label,
      required VoidCallback onTap,
      double? iconScale,
      double? iconHeight,
      Color? iconColor,
    }) {
      final effectiveIconScale = iconScale ?? _iconScale;
      final effectiveIconHeight = iconHeight ?? _iconHeight;

      Widget iconWidget() {
        final normalized = assetPath.toLowerCase();
        if (normalized.endsWith('.svg')) {
          return SvgPicture.asset(
            assetPath,
            height: effectiveIconHeight,
            width: effectiveIconHeight,
            fit: BoxFit.contain,
            colorFilter: iconColor == null
                ? null
                : ColorFilter.mode(iconColor, BlendMode.srcIn),
          );
        }

        return Image.asset(
          assetPath,
          height: effectiveIconHeight,
          width: effectiveIconHeight,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          color: iconColor,
        );
      }

      return SizedBox(
        width: _itemWidth,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.scale(
                  scale: effectiveIconScale,
                  child: iconWidget(),
                ),
                const SizedBox(height: 2),
                Text(label, style: labelStyle),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.white,
      child: Container(
        height: _barHeight + bottomInset,
        padding: EdgeInsets.only(bottom: bottomInset),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: Colors.black12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            navItem(
              assetPath: 'assets/casa.svg',
              label: 'Home',
              iconScale: 1.0,
              iconHeight: 25,
              iconColor: const Color(0xFF60BFCD),
              onTap: () {
                if (_currentRouteName(context) == _homeRouteName) {
                  return;
                }

                if (_currentRouteName(context) == _helpRouteName &&
                    Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                  return;
                }

                _goToRoot(context, const MainPage(), name: _homeRouteName);
              },
            ),
            const SizedBox(width: _itemGap),
            navItem(
              assetPath: 'assets/folha.svg',
              label: 'Sessões',
              iconScale: 1.0,
              iconHeight: 25,
              iconColor: const Color(0xFF60BFCD),
              onTap: () {
                _openSessionsModal(context);
              },
            ),
            const SizedBox(width: _itemGap),
            navItem(
              assetPath: 'assets/ajuda.svg',
              label: 'Ajuda',
              iconScale: 1.02,
              iconColor: const Color(0xFF60BFCD),
              onTap: () {
                if (_currentRouteName(context) == _helpRouteName) {
                  return;
                }
                _push(context, const HelpScreen(), name: _helpRouteName);
              },
            ),
          ],
        ),
      ),
    );
  }
}
