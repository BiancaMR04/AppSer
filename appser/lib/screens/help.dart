import 'package:appser/screens/home.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  // Função para abrir o link no navegador
  void _openWhatsApp() async {
    const url = 'https://wa.me/5555999890193'; // Substitua pelo link correto do WhatsApp
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(
        Uri.parse(url), 
        mode: LaunchMode.externalApplication,
      ); // Abre no navegador ou app externo
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajuda'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFFEAF3F3),
          image: DecorationImage(
            image: AssetImage('assets/logo.png'), // Imagem de fundo
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Ajuda',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A6363),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Está com alguma dúvida ou tem algum feedback? Nos chame aqui!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF4A6363),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _openWhatsApp,
                    child: const Text(
                      'wa.me/5555999890193', // Substitua pelo link correto
                      style: TextStyle(
                        color: Color(0xFF4A6363),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
}
