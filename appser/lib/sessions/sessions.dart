import 'package:appser/screens/help.dart';
import 'package:appser/screens/home.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import para SharedPreferences
import 'contentscreenone.dart';
import 'materialscreenone.dart';
import 'contentscreentwo.dart';
import 'materialscreentwo.dart';
import 'contentscreenthree.dart';
import 'materialscreenthree.dart';
import 'contentscreenfour.dart';
import 'materialscreenfour.dart';
import 'contentscreenfive.dart';
import 'materialscreenfive.dart';
import 'contentscreensix.dart';
import 'materialscreensix.dart';
import 'contentscreenseven.dart';
import 'materialscreenseven.dart';
import 'contentscreeneight.dart';
import 'materialscreeneight.dart';

class SessionScreen extends StatelessWidget {
  final int sessionNumber;

  const SessionScreen({super.key, required this.sessionNumber});

  @override
  Widget build(BuildContext context) {
    String sessionTitle = 'Sessão $sessionNumber';
    String materialTitle = 'Material de apoio Sessão $sessionNumber';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFEAF2F2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // Ícone de voltar à esquerda
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        color: const Color(0xFFEAF2F2), // Define a cor de fundo aqui
        child: FutureBuilder<String?>(
          future: _getFirstAccessDate(sessionNumber),
          builder: (context, snapshot) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logo.png',
                  height: 100, // Ajuste a altura conforme necessário
                ),
                Text(
                  sessionTitle,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 70, 148, 166),
                  ),
                ),
                const SizedBox(height: 20),
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
                        builder: (context) => _getContentScreen(sessionNumber),
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
                        builder: (context) => _getMaterialScreen(sessionNumber),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white.withOpacity(0.9),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Color(0xFF00A896)),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline, color: Color(0xFF00A896)),
            label: '',
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Home()),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HelpScreen()),
            );
          }
        },
      ),
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
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 10.0),
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 250, 250, 250),
        padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color.fromARGB(255, 136, 187, 185)),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _getContentScreen(int sessionNumber) {
  switch (sessionNumber) {
    case 1:
      return ContentScreenOne();
    case 2:
      return ContentScreenTwo();
    case 3:
      return ContentScreenThree();
    case 4:
      return ContentScreenFour();
    case 5:
      return ContentScreenFive();
    case 6:
      return ContentScreenSix();
    case 7:
      return ContentScreenSeven();
    case 8:
      return ContentScreenEight();
    default:
      return ContentScreenOne();
  }
}

Widget _getMaterialScreen(int sessionNumber) {
  switch (sessionNumber) {
    case 1:
      return MaterialScreenOne();
    case 2:
      return MaterialScreenTwo();
    case 3:
      return MaterialScreenThree();
    case 4:
      return MaterialScreenFour();
    case 5:
      return MaterialScreenFive();
    case 6:
      return MaterialScreenSix();
    case 7:
      return MaterialScreenSeven();
    case 8:
      return MaterialScreenEight();
    default:
      return MaterialScreenOne();
  }
}
