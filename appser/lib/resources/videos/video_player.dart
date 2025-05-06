import 'package:appser/screens/help.dart';
import 'package:appser/screens/home.dart';
import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'customplayers.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoPath;
  final String videoTitle; // Adicionando o título

  const VideoPlayerScreen(
      {super.key, required this.videoPath, required this.videoTitle});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  String videoUrl = '';

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      videoUrl = await getVideoUrl(widget.videoPath);

      if (videoUrl.isNotEmpty) {
        _videoPlayerController = VideoPlayerController.network(videoUrl);
        await _videoPlayerController.initialize();

        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController,
          autoPlay: false,
          looping: false,
          customControls: const CustomControls(), // Substitua aqui
          aspectRatio: _videoPlayerController.value.aspectRatio,
        );

        setState(() {});
      } else {
        print('Erro: URL do vídeo está vazia');
      }
    } catch (e) {
      print('Erro ao inicializar o player de vídeo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao carregar o vídeo')),
      );
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      //backgroundColor: const Color.fromARGB(255, 234, 242, 242),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Stack(
  children: [
    Positioned.fill(
      child: Image.asset(
        'assets/Registrar.png',
        fit: BoxFit.cover,
      ),
    ),
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.videoTitle, // Usando o título dinâmico
            style: TextStyle(fontSize: 24, color: Colors.teal[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _chewieController != null &&
                  _chewieController!.videoPlayerController.value.isInitialized
              ? AspectRatio(
                  aspectRatio: _videoPlayerController.value.aspectRatio,
                  child: Chewie(controller: _chewieController!),
                )
              : const Center(child: CircularProgressIndicator()),
        ],
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

  Future<String> getVideoUrl(String videoPath) async {
    try {
      final ref = FirebaseStorage.instance.ref(videoPath);
      String videoUrl = await ref.getDownloadURL();
      return videoUrl;
    } catch (e) {
      print('Erro ao obter a URL do vídeo: $e');
      return '';
    }
  }
}
