import 'package:appser/resources/audios/audiocheckinsix.dart';
import 'package:appser/resources/audios/audiocheckoutsix.dart';
import 'package:appser/resources/audios/audiopararsix.dart';
import 'package:appser/resources/audios/audiopraticapensamento.dart';
import 'package:appser/resources/docs/pdf_view.dart';
import 'package:appser/resources/videos/video_player.dart';
import 'package:flutter/material.dart';

class ContentScreenSix extends StatelessWidget {
  const ContentScreenSix({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AudioPlayerCheckinSix(),
                        ),
                      );
                    },
                  ),
                  _buildContentButton(
                    context,
                    title: '2. Prática dos Pensamentos',
                    duration: '14:30',
                    icon: Icons.headset,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AudioPlayerPraticaPensamento(),
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
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AudioPlayerPararAudioSix(),
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
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AudioPlayerCheckoutSix(),
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
