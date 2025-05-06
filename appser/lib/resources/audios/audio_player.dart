import 'package:appser/screens/help.dart';
import 'package:appser/screens/home.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AudioPlayerScreen extends StatefulWidget {
  final String audioPath;
  final String audioTitle;
  final VoidCallback? onComplete;

  const AudioPlayerScreen({
    Key? key,
    required this.audioPath,
    required this.audioTitle,
    this.onComplete,
  }) : super(key: key);

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadAudio();
  }

  Future<void> _loadAudio() async {
    try {
      final ref = FirebaseStorage.instance.ref().child(widget.audioPath);
      final url = await ref.getDownloadURL();
      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();
    } catch (e) {
      print('Erro ao carregar áudio: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        title: Text(widget.audioTitle),
        backgroundColor: const Color.fromARGB(0, 0, 150, 135),
      ),
      body: Stack(
  children: [
    Positioned.fill(
      child: Image.asset(
        'assets/Registrar.png',
        fit: BoxFit.cover,
      ),
    ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: width * 0.1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StreamBuilder<PlayerState>(
              stream: _audioPlayer.playerStateStream,
              builder: (context, snapshot) {
                final state = snapshot.data;
                final playing = state?.playing ?? false;
                final completed = state?.processingState == ProcessingState.completed;

                if (completed && widget.onComplete != null) {
                  widget.onComplete!();
                }

bool isPlaying = state?.playing ?? false;

return Center(
  child: AnimatedScale(
    scale: isPlaying ? 1 : 0.9,
    duration: const Duration(milliseconds: 500),
    curve: Curves.easeInOut,
    child: GestureDetector(
      onTap: () async {
        if (completed) {
          await _audioPlayer.seek(Duration.zero);
          await _audioPlayer.play();
        } else if (isPlaying) {
          await _audioPlayer.pause();
        } else {
          await _audioPlayer.play();
        }
      },
      child: Container(
        width: width * 0.3,
        height: width * 0.3,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [const Color.fromARGB(255, 136, 187, 185), const Color.fromARGB(255, 112, 172, 181), const Color.fromARGB(255, 116, 202, 158)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
            child: Icon(
              completed
                  ? Icons.replay
                  : isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
              key: ValueKey(isPlaying),
              size: width * 0.15,
              color: Colors.white,
            ),
          ),
        ),
      ),
    ),
  ),
);


              },
            ),
            SizedBox(height: 16),
            Text(widget.audioTitle,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
            StreamBuilder<Duration?>(
              stream: _audioPlayer.durationStream,
              builder: (context, snapshotDuration) {
                final duration = snapshotDuration.data ?? Duration.zero;
                return StreamBuilder<Duration>(
                  stream: _audioPlayer.positionStream,
                  builder: (context, snapshotPosition) {
                    final position = snapshotPosition.data ?? Duration.zero;
                    return Column(
                      children: [
                        Slider(
                          min: 0,
                          max: duration.inMilliseconds.toDouble(),
                          value: position.inMilliseconds.clamp(0, duration.inMilliseconds).toDouble(),
                          onChanged: (value) {
                            _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                          },
                          activeColor: Colors.teal,
                          inactiveColor: Colors.teal.withOpacity(0.3),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatDuration(position)),
                            Text(_formatDuration(duration)),
                          ],
                        )
                      ],
                    );
                  },
                );
              },
            ),
          ],
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
  
}
