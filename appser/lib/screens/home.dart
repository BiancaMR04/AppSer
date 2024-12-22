import 'package:appser/screens/help.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../sessions/sessions.dart';
import '../services/authetication_service.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late Future<Map<String, bool>> _sessionStatus;

  @override
  void initState() {
    super.initState();
    _sessionStatus = _fetchSessionStatus();
  }

Future<Map<String, bool>> _fetchSessionStatus() async {
  final userId = FirebaseAuth.instance.currentUser?.uid;

  if (userId == null) {
    return {
      'session1': true,
      'session2': false,
      'session3': false,
      'session4': false,
      'session5': false,
      'session6': false,
      'session7': false,
      'session8': false,
    };
  }

  try {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      // Retorna status padrão se o documento não existir
      return {
        'session1': true,
        'session2': false,
        'session3': false,
        'session4': false,
        'session5': false,
        'session6': false,
        'session7': false,
        'session8': false,
      };
    }

    return {
      'session1': userDoc['session1'] ?? true,
      'session2': userDoc['session2'] ?? false,
      'session3': userDoc['session3'] ?? false,
      'session4': userDoc['session4'] ?? false,
      'session5': userDoc['session5'] ?? false,
      'session6': userDoc['session6'] ?? false,
      'session7': userDoc['session7'] ?? false,
      'session8': userDoc['session8'] ?? false,
    };
  } catch (e) {
    // Se ocorrer um erro, retorne um status padrão
    return {
      'session1': true,
      'session2': false,
      'session3': false,
      'session4': false,
      'session5': false,
      'session6': false,
      'session7': false,
      'session8': false,
    };
  }
}


  void _refreshSessions() {
    setState(() {
      _sessionStatus = _fetchSessionStatus();
    });
  }

    Future<void> _logout() async {
    await AutheticationService().logout();
    Navigator.of(context).pushReplacementNamed('/login'); // Navegue para a tela de login
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: AppBar(
          backgroundColor: const Color(0xFFEAF2F2), // Cor combinando com o fundo
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Color.fromARGB(255, 0, 129, 71)),
              onPressed: _logout,
              tooltip: 'Sair',
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Color.fromARGB(255, 0, 129, 71)), // Ícone branco
              onPressed: _refreshSessions,
              tooltip: 'Atualizar Sessões',
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Container(
            color: const Color(0xFFEAF2F2),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
              child: FutureBuilder<Map<String, bool>>(
                future: _sessionStatus,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Erro ao carregar sessões: ${snapshot.error}'));
                  } else if (!snapshot.hasData) {
                    return const Center(child: Text('Dados de sessão não disponíveis.'));
                  }

                  final sessionStatus = snapshot.data!;
                  return Column(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Bem-vindo',
                                  style: TextStyle(
                                    fontSize: screenHeight * 0.035,
                                    fontWeight: FontWeight.bold,
                                    color: const Color.fromARGB(255, 70, 148, 166),
                                  ),
                                ),
                                Text(
                                  'ao App',
                                  style: TextStyle(
                                    fontSize: screenHeight * 0.035,
                                    fontWeight: FontWeight.bold,
                                    color: const Color.fromARGB(255, 70, 148, 166),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            Padding(
                              padding: EdgeInsets.only(top: screenHeight * 0.01),
                              child: Image.asset(
                                'assets/logo.png',
                                height: screenHeight * 0.13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.04),
                      ...List.generate(
                        8,
                        (index) => AlternatingSessionButton(
                          number: (index + 1).toString().padLeft(2, '0'),
                          title: _getSessionTitle(index + 1),
                          screenHeight: screenHeight,
                          screenWidth: screenWidth,
                          isLeft: index % 2 == 0,
                          enabled: sessionStatus['session${index + 1}'] ?? false,
                          onPressed: () {
                            if (sessionStatus['session${index + 1}'] ?? false) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      SessionScreen(sessionNumber: index + 1),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.1),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
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


  String _getSessionTitle(int index) {
    switch (index) {
      case 1:
        return 'Mindfulness, Piloto automático e reatividade';
      case 2:
        return 'Consciência dos gatilhos, Pensamentos e impulsos';
      case 3:
        return 'Atentar e acolher os desafios diários';
      case 4:
        return 'Manejo emocional e reatividade';
      case 5:
        return 'Aceitação e ação habilidosa';
      case 6:
        return 'Pensamentos são só pensamentos';
      case 7:
        return 'Autocuidado e estilo de vida balanceado';
      case 8:
        return 'Suporte e prática continuada';
      default:
        return '';
    }
  }
}

class AlternatingSessionButton extends StatelessWidget {
  final String number;
  final String title;
  final double screenHeight;
  final double screenWidth;
  final bool isLeft;
  final bool enabled;
  final VoidCallback onPressed;

  const AlternatingSessionButton({
    super.key,
    required this.number,
    required this.title,
    required this.screenHeight,
    required this.screenWidth,
    required this.isLeft,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Stack(
          children: [
            Align(
              alignment: Alignment.center, // Centralizando o botão
              child: Container(
                width: screenWidth * 0.75, // Largura ajustada do botão
                padding: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.02,
                  horizontal: screenWidth * 0.05,
                ),
                child: ElevatedButton(
                  onPressed: enabled ? onPressed : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 175, 210, 208),
                    padding: EdgeInsets.all(screenHeight * 0.02),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 3,
                  ),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: screenHeight * 0.02,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: isLeft ? screenWidth * 0.02 : null,
              right: isLeft ? null : screenWidth * 0.02,
              top: screenHeight * 0.01,
              child: CircleAvatar(
                backgroundColor: const Color.fromARGB(255, 175, 210, 208),
                radius: screenHeight * 0.045,
                child: Text(
                  number,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenHeight * 0.03,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (number != '08')
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
            child: CustomPaint(
              painter: DottedLinePainter(screenHeight: screenHeight),
              child: SizedBox(
                height: screenHeight * 0.05,
                width: 2,
              ),
            ),
          ),
      ],
    );
  }
}

class DottedLinePainter extends CustomPainter {
  final double screenHeight;

  DottedLinePainter({required this.screenHeight});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = const Color.fromARGB(255, 241, 209, 208)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    var max = size.height;
    var dashWidth = screenHeight * 0.005;
    var dashSpace = screenHeight * 0.005;
    double startY = 0;

    while (startY < max) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashWidth), paint);
      startY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
