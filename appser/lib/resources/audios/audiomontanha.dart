import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AudioPlayerMontanha extends StatefulWidget {
  const AudioPlayerMontanha({super.key});

  @override
  _AudioPlayerScreenState createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerMontanha> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? audioUrl;

  @override
  void initState() {
    super.initState();
    _loadAudio();
  }

Future<void> _loadAudio() async {
  try {
    Reference audioRef = FirebaseStorage.instance.ref().child('audios/sessaodois/montanha.mp3');
    String url = await audioRef.getDownloadURL();
    print("URL do áudio: $url");  // Adicione essa linha
    await _audioPlayer.setUrl(url);
    await _audioPlayer.play();
    setState(() {
      audioUrl = url;
    });
  } catch (error) {
    print('Erro ao carregar o áudio: $error');
  }
}


  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.teal),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: screenHeight * 0.1),
                Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.teal, Colors.greenAccent],
                    ),
                  ),
                  child: StreamBuilder<PlayerState>(
                    stream: _audioPlayer.playerStateStream,
                    builder: (context, snapshot) {
                      final playerState = snapshot.data;
                      final playing = playerState?.playing;
                      final processingState = playerState?.processingState;

                      if (processingState == ProcessingState.loading ||
                          processingState == ProcessingState.buffering) {
                        // Exibe um indicador de carregamento enquanto o áudio é carregado
                        return const CircularProgressIndicator();
                      } else if (playing != true) {
                        // Botão play
                        return IconButton(
                          iconSize: screenWidth * 0.2,
                          icon: const Icon(
                            Icons.play_circle_filled,
                            color: Colors.white,
                          ),
                          onPressed: () async {
                            await _audioPlayer.play();
                          },
                        );
                      } else if (processingState != ProcessingState.completed) {
                        // Botão pause
                        return IconButton(
                          iconSize: screenWidth * 0.2,
                          icon: const Icon(
                            Icons.pause_circle_filled,
                            color: Colors.white,
                          ),
                          onPressed: () async {
                            await _audioPlayer.pause();
                          },
                        );
                      } else {
                        return IconButton(
                          iconSize: screenWidth * 0.2,
                          icon: const Icon(
                            Icons.replay_circle_filled,
                            color: Colors.white,
                          ),
                          onPressed: () async {
                            await _audioPlayer.seek(Duration.zero);
                            await _audioPlayer.play();
                          },
                        );
                      }
                    },
                  ),
                ),
                SizedBox(height: screenHeight * 0.05),
                Text(
                  'Montanha',
                  style: TextStyle(
                    fontSize: screenWidth * 0.05,
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                StreamBuilder<Duration?>(
                  stream: _audioPlayer.durationStream,
                  builder: (context, snapshot) {
                    final duration = snapshot.data ?? Duration.zero;
                    return StreamBuilder<Duration>(
                      stream: _audioPlayer.positionStream,
                      builder: (context, snapshot) {
                        final position = snapshot.data ?? Duration.zero;
                        return Column(
                          children: [
                            Slider(
                              activeColor: Colors.teal,
                              inactiveColor: Colors.teal.withOpacity(0.3),
                              min: 0.0,
                              max: duration.inMilliseconds.toDouble(),
                              value: position.inMilliseconds.toDouble(),
                              onChanged: (value) {
                                _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                              },
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_formatDuration(position)),
                                Text(_formatDuration(duration)),
                              ],
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                SizedBox(height: screenHeight * 0.15),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: BottomNavigationBar(
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
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
