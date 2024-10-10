import 'package:appser/screens/help.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:appser/resources/audios/audiocheckinone.dart';
import 'package:appser/resources/audios/audioescaneamentoone.dart';
import 'package:appser/resources/audios/audiocheckoutone.dart';
import 'package:appser/resources/videos/video_player.dart';
import 'package:appser/resources/docs/pdf_view.dart';
import 'package:appser/screens/home.dart';

class ContentScreenOne extends StatelessWidget {
  const ContentScreenOne({super.key});

  Future<String> getPdfUrl(String pdfPath) async {
    try {
      final ref = FirebaseStorage.instance.ref(pdfPath);
      String pdfUrl = await ref.getDownloadURL();
      print('PDF URL: $pdfUrl');
      return pdfUrl;
    } catch (e) {
      print('Erro ao obter a URL do PDF: $e');
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 234, 242, 242),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
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
              'Sessão 1',
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
                    duration: '2:59',
                    icon: Icons.headset,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AudioPlayerCheckinOne(),
                        ),
                      );
                    },
                  ),
                  _buildContentButton(
                    context,
                    title:
                        '2. Preparação para o exercício "Prática da Uva Passa"',
                    duration: '1:05',
                    icon: Icons.play_circle_filled,
                    onTap: () async {
                      String videoPath =
                          'videos/sessaoum/preparacaouva.mp4'; // Caminho no Firebase Storage
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
                                      'Preparação para o exercício "Prática da Uva Passa"'), // Passe o caminho do vídeo
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
                    title: '3. Prática da Uva Passa',
                    duration: '12:39',
                    icon: Icons.play_circle_filled,
                    onTap: () async {
                      String videoPath =
                          'videos/sessaoum/praticauvapassaum.mp4'; // Caminho no Firebase Storage
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
                                      'Prática da Uva Passa'), // Passe o caminho do vídeo
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
                    title: '4. O que é Mindfulness',
                    duration: '6:01',
                    icon: Icons.play_circle_filled,
                    onTap: () async {
                      String videoPath =
                          'videos/sessaoum/oquemindfulnessum.mp4'; // Caminho no Firebase Storage
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
                                      'O que é Mindfulness'), // Passe o caminho do vídeo
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
                    title: '5. Posturas copy',
                    duration: '7:59',
                    icon: Icons.play_circle_filled,
                    onTap: () async {
                      String videoPath =
                          'videos/sessaoum/videosposturaum.mp4'; // Caminho no Firebase Storage
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
                                      'Posturas copy'), // Passe o caminho do vídeo
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
                    title: '6. Escaneamento corporal',
                    duration: '13:33',
                    icon: Icons.headset,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AudioPlayerEscaneamOne(),
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
                          'docs/sessaoum/praticandoemcasaum.pdf'; // Caminho no Firebase Storage

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PdfViewerScreen(
                              pdfPath: pdfPath,
                              downloadPath:
                                  'docs/sessaoum/praticandoemcasaum.pdf',
                              pdfTitle: 'Praticando em Casa'),
                        ),
                      );
                    },
                  ),
                  _buildContentButton(
                    context,
                    title: '8. Check-out',
                    duration: '2:49',
                    icon: Icons.headset,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AudioPlayerCheckoutOne(),
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

  Widget _buildContentButton(BuildContext context,
      {required String title,
      required String duration,
      required IconData icon,
      required VoidCallback onTap}) {
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
            Icon(icon, color: const Color.fromARGB(255, 136, 187, 185)),
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
