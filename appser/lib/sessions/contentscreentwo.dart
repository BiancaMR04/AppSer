import 'package:appser/resources/audios/audiocheckintwo.dart';
import 'package:appser/resources/audios/audiocheckouttwo.dart';
import 'package:appser/resources/audios/audiomontanha.dart';
import 'package:appser/resources/docs/pdf_view.dart';
import 'package:appser/resources/videos/video_player.dart';
import 'package:flutter/material.dart';

class ContentScreenTwo extends StatelessWidget {
  const ContentScreenTwo({super.key});

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
              'Sessão 2',
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
                    duration: '1:40',
                    icon: Icons.headset,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AudioPlayerCheckinTwo(),
                        ),
                      );
                    },
                  ),
                  _buildContentButton(
                    context,
                    title: '2. Escaneamento com automassagem',
                    duration: '13:38',
                    icon: Icons.play_circle_filled,
                    onTap: () async {
                      String videoPath =
                          'videos/sessaodois/escaneamentodois.mp4'; // Caminho no Firebase Storage
                      try {
                        String videoUrl = getVideoUrl(
                            videoPath); // Obtenha a URL de download do Firebase Storage

                        if (videoUrl.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VideoPlayerScreen(
                                  videoPath:
                                      videoPath, videoTitle: 'Escaneamento com automassagem'), // Passe o caminho do vídeo
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
                    title: '3. Cinco desafios',
                    duration: '6:06',
                    icon: Icons.play_circle_filled,
                    onTap: () async {
                      String videoPath =
                          'videos/sessaodois/desafiosdois.mp4'; // Caminho no Firebase Storage
                      try {
                        String videoUrl = getVideoUrl(
                            videoPath); // Obtenha a URL de download do Firebase Storage

                        if (videoUrl.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VideoPlayerScreen(
                                  videoPath:
                                      videoPath, videoTitle: 'Cinco desafios'), // Passe o caminho do vídeo
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
                    title: '4. Andando na rua',
                    duration: '9:42',
                    icon: Icons.play_circle_filled,
                    onTap: () async {
                      String videoPath =
                          'videos/sessaodois/andandodois.mp4'; // Caminho no Firebase Storage
                      try {
                        String videoUrl = getVideoUrl(
                            videoPath); // Obtenha a URL de download do Firebase Storage

                        if (videoUrl.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VideoPlayerScreen(
                                  videoPath:
                                      videoPath, videoTitle: 'Andando na rua'), // Passe o caminho do vídeo
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
                    title: '5. Primeiro e segundo sofrimento',
                    duration: '9:39',
                    icon: Icons.play_circle_filled,
                    onTap: () async {
                      String videoPath =
                          'videos/sessaodois/pssofrimentodois.mp4'; // Caminho no Firebase Storage
                      try {
                        String videoUrl = getVideoUrl(
                            videoPath); // Obtenha a URL de download do Firebase Storage

                        if (videoUrl.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VideoPlayerScreen(
                                  videoPath:
                                      videoPath, videoTitle: 'Primeiro e segundo sofrimento'), // Passe o caminho do vídeo
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
                    title: '6. Montanha',
                    duration: '8:35',
                    icon: Icons.headset,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AudioPlayerMontanha(),
                        ),
                      );
                    },
                  ),
                  _buildContentButton(
                    context,
                    title: '7. Praticando em Casa',
                    duration: '',
                    icon: Icons.article,
                    onTap: () async {
                      String pdfPath =
                          'docs/sessaodois/praticandoemcasadois.pdf'; // Caminho no Firebase Storage

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PdfViewerScreen(pdfPath: pdfPath, downloadPath: 'docs/sessaodois/praticandoemcasadois.pdf', pdfTitle: 'Praticando em Casa'),
                        ),
                      );
                    },
                  ),
                  _buildContentButton(
                    context,
                    title: '8. Check-out',
                    duration: '2:56',
                    icon: Icons.headset,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AudioPlayerCheckoutTwo(),
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
