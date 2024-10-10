import 'package:appser/screens/help.dart';
import 'package:flutter/material.dart';
import '../sessions/sessions.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      body: Stack(
        children: [
          Container(
            color: const Color(0xFFEAF2F2),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
              child: Column(
                children: <Widget>[
                  // Centralizando o "Bem-vindo ao App" com logo
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.1), // Ajuste lateral
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Texto "Bem-vindo ao App"
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
                        SizedBox(
                            width: screenWidth *
                                0.03), // Espaço entre o texto e a logo
                        // Logo ajustada para baixo
                        Padding(
                          padding: EdgeInsets.only(top: screenHeight * 0.01),
                          child: Image.asset(
                            'assets/logo.png',
                            height:
                                screenHeight * 0.13, // Tamanho ajustado da logo
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.04),
                  // Gerar os botões de sessão, centralizados
                  // Gerar os botões de sessão, centralizados
                  ...List.generate(
                      8,
                      (index) => AlternatingSessionButton(
                            number: (index + 1).toString().padLeft(2, '0'),
                            title: _getSessionTitle(index + 1),
                            screenHeight: screenHeight,
                            screenWidth: screenWidth,
                            isLeft: index % 2 == 0,
                            enabled: index ==
                                0, // Somente o primeiro botão estará habilitado
                            onPressed: () {
                              if (index == 0) {
                                // Garante que apenas o botão habilitado navegue
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        SessionScreen(sessionNumber: index + 1),
                                  ),
                                );
                              }
                            },
                          )),

                  SizedBox(height: screenHeight * 0.1),
                ],
              ),
            ),
          ),
        ],
      ),
      // Adicionando o BottomNavigationBar
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
            // Navegação para a HomeScreen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Home()),
            );
          } else if (index == 1) {
            // Navegação para a AjudaScreen
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
