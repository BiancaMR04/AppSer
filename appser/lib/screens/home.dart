import 'package:appser/screens/help.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
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
        'session0': true,
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
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (!userDoc.exists) {
        // Retorna status padrão se o documento não existir
        return {
          'session0': true,
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
        'session0': userDoc['session0'] ?? true,
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
        'session0': true,
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


  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: AppBar(
          backgroundColor:
              const Color.fromARGB(0, 242, 3, 3), // Fundo 100% transparente
          elevation: 0, // Sem sombra
          automaticallyImplyLeading:
              false, // Opcional: remove botão de voltar se não quiser
          actions: [
            IconButton(
              icon: const Icon(Icons.logout,
                  color: Color.fromARGB(255, 0, 129, 71)),
              onPressed : context.read<AutheticationService>().logout,
              tooltip: 'Sair',
            ),
            IconButton(
              icon: const Icon(Icons.refresh,
                  color: Color.fromARGB(255, 0, 129, 71)), // Ícone branco
              onPressed: _refreshSessions,
              tooltip: 'Atualizar Sessões',
            ),
          ],
        ),
      ),
      extendBody: true,
      body: Stack(
        children: [
          Container(
            //padding: const EdgeInsets.all(25),
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/Registrar.png'),
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
              child: FutureBuilder<Map<String, bool>>(
                future: _sessionStatus,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                        child: Text(
                            'Erro ao carregar sessões: ${snapshot.error}'));
                  } else if (!snapshot.hasData) {
                    return const Center(
                        child: Text('Dados de sessão não disponíveis.'));
                  }

                  final sessionStatus = snapshot.data!;
                  return Column(
                    children: <Widget>[
                      SizedBox(height: screenHeight * 0.05), // ajustável
                      Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
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
                                    color:
                                        const Color.fromARGB(255, 70, 148, 166),
                                  ),
                                ),
                                Text(
                                  'ao App',
                                  style: TextStyle(
                                    fontSize: screenHeight * 0.035,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        const Color.fromARGB(255, 70, 148, 166),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: screenWidth * 0.01),
                            Padding(
                              padding:
                                  EdgeInsets.only(top: screenHeight * 0.06),
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
                        9,
                        (index) => AlternatingSessionButton(
                          number: index.toString().padLeft(2, '0'),
                          title: _getSessionTitle(index),
                          screenHeight: screenHeight,
                          screenWidth: screenWidth,
                          isLeft: index % 2 == 0,
                          enabled: sessionStatus['session$index'] ?? false,
                          onPressed: () {
                            if (sessionStatus['session$index'] ?? false) {
                              /*if (index == 0) {
                                String videoPath =
                                    'videos/sessaozero/boasvindas.mp4'; // Caminho no Firebase Storage
                                try {
                                  String videoUrl = getVideoUrl(
                                      videoPath); // Obtenha a URL de download do Firebase Storage

                                  if (videoUrl.isNotEmpty) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => VideoPlayerScreen(
                                            videoPath: videoPath,
                                            videoTitle:
                                                'Boas-Vindas'), // Passe o caminho do vídeo
                                      ),
                                    );
                                  } else {
                                    print('Erro: URL do vídeo está vazia');
                                  }
                                } catch (error) {
                                  print('Erro ao obter a URL do vídeo: $error');
                                }
                              }*/
                              if (index == 0) {
    print("Sessão 0 desativada.");
    return; // Ignora o clique
  } else {
                            
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        SessionScreen(sessionNumber: index),
                                  ),
                                );
                              }
                            }
                          }
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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 20.0), // distância do fundo
        child: SafeArea(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.home, color: Color(0xFF00A896)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Home()),
                    );
                  },
                ),
                IconButton(
                  icon:
                      const Icon(Icons.info_outline, color: Color(0xFF00A896)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HelpScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getSessionTitle(int index) {
    switch (index) {
      case 0:
        return 'Boas-Vindas \n ao App';
      case 1:
        return 'Mindfulness, Piloto automático e reatividade';
      case 2:
        return 'Consciência dos gatilhos, Pensamentos e impulsos';
      case 3:
        return 'Atentar e acolher os desafios diários';
      case 4:
        return 'Manejo emocional e \n reatividade';
      case 5:
        return 'Aceitação e ação \n habilidosa';
      case 6:
        return 'Pensamentos são só pensamentos';
      case 7:
        return 'Autocuidado e estilo de vida balanceado';
      case 8:
        return 'Suporte e prática \n continuada';
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
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
          children: [
            // Retângulo
            Container(
              margin: isLeft
                  ? EdgeInsets.only(left: screenWidth * 0.12)
                  : EdgeInsets.only(right: screenWidth * 0.12),
              padding: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.025,
                  horizontal: screenWidth * 0.08),
              decoration: BoxDecoration(
                color: enabled
                    ? const Color.fromARGB(255, 175, 210, 208) // cor ativa
                    : const Color.fromARGB(
                        255, 224, 224, 224), // cor desativada
                border: Border.all(
                  color: enabled
                      ? const Color.fromARGB(255, 198, 231, 234) // cor ativa
                      : const Color.fromARGB(
                          255, 201, 201, 201), // cor desativada
                  width: 4,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              width: screenWidth * 0.75,
              child: GestureDetector(
                onTap: enabled ? onPressed : null,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: screenHeight * 0.015,
                    fontWeight: FontWeight.bold,
                    color: enabled
                        ? const Color.fromARGB(255, 62, 73, 73) // cor ativa
                        : const Color.fromARGB(
                            255, 62, 73, 73), // cor desativada
                  ),
                ),
              ),
            ),

            // Círculo
            Positioned(
              top: screenHeight * 0.020,
              left: isLeft ? 0 : null,
              right: isLeft ? null : 0,
              child: Container(
                width: screenHeight * 0.07,
                height: screenHeight * 0.07,
                decoration: BoxDecoration(
                  color: enabled
                      ? const Color.fromARGB(255, 175, 210, 208) // cor ativa
                      : const Color.fromARGB(
                          255, 209, 209, 209), // cor desativada
                  border: Border.all(
                    color: enabled
                        ? const Color.fromARGB(255, 115, 202, 214) // cor ativa
                        : const Color.fromARGB(
                            255, 231, 231, 231), // cor desativada
                    width: 2,
                  ),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  number,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: screenHeight * 0.03,
                    color: enabled
                        ? Colors.white
                        : const Color.fromARGB(
                            255, 255, 255, 255), // cor do número
                    fontWeight: FontWeight.bold,
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

String getVideoUrl(String videoPath) {
  // Aqui você pode implementar a lógica para buscar a URL do vídeo
  return 'https://example.com/$videoPath'; // Exemplo de URL
}
