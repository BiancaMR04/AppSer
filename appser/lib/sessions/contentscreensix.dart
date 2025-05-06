import 'package:appser/resources/audios/audio_player.dart';
import 'package:appser/resources/docs/pdf_view.dart';
import 'package:appser/resources/videos/video_player.dart';
import 'package:appser/screens/help.dart';
import 'package:appser/screens/home.dart';
import 'package:appser/screens/user_tracking_service.dart';
import 'package:flutter/material.dart';

class ContentScreenSix extends StatelessWidget {
  const ContentScreenSix({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: const Color.fromARGB(255, 234, 242, 242),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // Ícone de voltar à esquerda
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Image.asset(
              'assets/logo.png',
              height: 100, // Ajuste a altura conforme necessário
            ),
            const Text(
              'Sessão 6',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 70, 148, 166),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildContentButton(
                    context,
                    title: '1. Check-in',
                    duration: '1:30',
                    icon: Icons.headset,
                    onTap: () async {
                      await UserTrackingService.registrarClique(
                        sessaoId: 'sessao_6',
                        tipo: 'audio',
                        itemId: 'checkin',
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AudioPlayerScreen(
                            audioPath: 'audios/sessaoseis/checkinseis.mp3',
                            audioTitle: 'Check-in',
                          ),
                        ),
                      );
                    },
                  ),
                  _buildContentButton(
                    context,
                    title: '2. Prática dos Pensamentos',
                    duration: '14:30',
                    icon: Icons.headset,
                    onTap: () async {
                      await UserTrackingService.registrarClique(
                        sessaoId: 'sessao_6',
                        tipo: 'audio',
                        itemId: 'pratica_pensamentos',
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AudioPlayerScreen(
                            audioPath: 'audios/sessaoseis/praticadospenseis.mp3',
                            audioTitle: 'Prática dos Pensamentos',
                          ),
                        ),
                      );
                    },
                  ),
                  _buildContentButton(
                    context,
                    title: '3. Te Recebo Aceito Solto (RAS)',
                    duration: '9:46',
                    icon: Icons.play_circle_filled,
                    onTap: () async {
                      await UserTrackingService.registrarClique(
                        sessaoId: 'sessao_6',
                        tipo: 'video',
                        itemId: 'ras',
                      );
                      String videoPath =
                          'videos/sessaoseis/rasseis.mp4'; // Caminho no Firebase Storage
                      try {
                        String videoUrl = getVideoUrl(
                            videoPath); // Obtenha a URL de download do Firebase Storage

                        if (videoUrl.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VideoPlayerScreen(
                                  videoPath:
                                      videoPath, videoTitle: 'Te Recebo Aceito Solto (RAS)'), // Passe o caminho do vídeo
                            ),
                          );
                        } else {
                          print('Erro: URL do vídeo está vazia');
                        }
                      } catch (error) {
                        print('Erro ao obter a URL do vídeo: $error');
                      }
                    },
                  ),
                  _buildContentButton(
                    context,
                    title: '4. Cadeia da reatividade',
                    duration: '22:42',
                    icon: Icons.play_circle_filled,
                    onTap: () async {
                      await UserTrackingService.registrarClique(
                        sessaoId: 'sessao_6',
                        tipo: 'video',
                        itemId: 'cadeira_reatividade',
                      );
                      String videoPath =
                          'videos/sessaoseis/cadeiaseis.mp4'; // Caminho no Firebase Storage
                      try {
                        String videoUrl = getVideoUrl(
                            videoPath); // Obtenha a URL de download do Firebase Storage

                        if (videoUrl.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VideoPlayerScreen(
                                  videoPath:
                                      videoPath, videoTitle: 'Cadeia da reatividade'), // Passe o caminho do vídeo
                            ),
                          );
                        } else {
                          print('Erro: URL do vídeo está vazia');
                        }
                      } catch (error) {
                        print('Erro ao obter a URL do vídeo: $error');
                      }
                    },
                  ),
                  _buildContentButton(
                    context,
                    title: '5. Parar Áudio',
                    duration: '5:12',
                    icon: Icons.headset,
                    onTap: () async {
                      await UserTrackingService.registrarClique(
                        sessaoId: 'sessao_6',
                        tipo: 'audio',
                        itemId: 'parar_audio',
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AudioPlayerScreen(
                            audioPath: 'audios/sessaoseis/pararaudioseis.mp3',
                            audioTitle: 'Parar Áudio',
                          ),
                        ),
                      );
                    },
                  ),
                  _buildContentButton(
                    context,
                    title: '6. Praticando em Casa',
                    duration: '',
                    icon: Icons.article,
                    onTap: () async {
                      await UserTrackingService.registrarClique(
                        sessaoId: 'sessao_6',
                        tipo: 'pdf',
                        itemId: 'praticando_em_casa',
                      );
                      String pdfPath =
                          'docs/sessaoseis/praticandoemcasaseis.pdf'; // Caminho no Firebase Storage

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PdfViewerScreen(pdfPath: pdfPath, downloadPath: 'docs/sessaoseis/praticandoemcasaseis.pdf', pdfTitle: 'Praticando em Casa'),
                        ),
                      );
                    },
                  ),
                  _buildContentButton(
                    context,
                    title: '7. Check-out',
                    duration: '2:55',
                    icon: Icons.headset,
                    onTap: () async {
                      await UserTrackingService.registrarClique(
                        sessaoId: 'sessao_6',
                        tipo: 'audio',
                        itemId: 'checkout',
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AudioPlayerScreen(
                            audioPath: 'audios/sessaoseis/checkoutseis.mp3',
                            audioTitle: 'Check-out',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
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
            icon: const Icon(Icons.info_outline, color: Color(0xFF00A896)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpScreen()),
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

  Widget _buildContentButton(BuildContext context,
      {required String title, required String duration, required IconData icon, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          elevation: 3,
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF00A896)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
            Text(
              duration,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
  String getVideoUrl(String videoPath) {
    // Aqui você pode implementar a lógica para buscar a URL do vídeo
    return 'https://example.com/$videoPath'; // Exemplo de URL
  }
}
