import 'package:appser/presentation/widgets/app_bottom_nav_bar.dart';
import 'package:appser/presentation/widgets/app_background.dart';
import 'package:appser/presentation/widgets/app_back_app_bar.dart';
import 'package:appser/presentation/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import para SharedPreferences
import 'package:appser/sessions/session_content_screen.dart';
import 'package:appser/sessions/session_material_screen.dart';

import 'package:appser/core/theme/app_colors.dart';
import 'package:appser/presentation/widgets/app_elevated_row_button.dart';
import 'package:appser/sessions/widgets/session_header.dart';

class SessionScreen extends StatelessWidget {
  final int sessionNumber;

  const SessionScreen({super.key, required this.sessionNumber});

  @override
  Widget build(BuildContext context) {
    String sessionTitle = 'Sessão $sessionNumber';
    String materialTitle = 'Material de apoio Sessão $sessionNumber';

    return AppScaffold(
      appBar: AppBackAppBar(
        titleText: 'Sessão $sessionNumber',
        backgroundColor: Colors.transparent,
      ),
      body: AppBackground(
        child: FutureBuilder<String?>(
          future: _getFirstAccessDate(sessionNumber),
          builder: (context, snapshot) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SessionHeader(
                  title: sessionTitle,
                  titleStyle: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
                if (snapshot.hasData && snapshot.data != null)
                  Text(
                    'Primeiro acesso: ${snapshot.data}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                const SizedBox(height: 20),
                _buildSessionButton(
                  context,
                  title: sessionTitle,
                  icon: Icons.play_circle_fill,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SessionContentScreen(sessionNumber: sessionNumber),
                      ),
                    );
                  },
                ),
                _buildSessionButton(
                  context,
                  title: materialTitle,
                  icon: Icons.book,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SessionMaterialScreen(sessionNumber: sessionNumber),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(),
    );
  }

  Future<String?> _getFirstAccessDate(int sessionNumber) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String key = 'session_${sessionNumber}_first_access';
    if (prefs.containsKey(key)) {
      return prefs.getString(key); // Retorna a data salva
    }
    return null; // Caso não haja data registrada
  }

  // O resto do código permanece o mesmo...
}

Widget _buildSessionButton(BuildContext context,
    {required String title,
    required IconData icon,
    required VoidCallback onTap}) {
  return AppElevatedRowButton(
    onPressed: onTap,
    icon: icon,
    iconColor: AppColors.sessionIconMuted,
    title: title,
    backgroundColor: const Color.fromARGB(255, 250, 250, 250),
    outerPadding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 10.0),
    iconGap: 20,
    titleStyle: const TextStyle(
      fontSize: 18,
      color: Colors.black87,
    ),
  );
}
