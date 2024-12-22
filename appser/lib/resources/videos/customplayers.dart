import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'dart:async';
import 'package:video_player/video_player.dart';

class CustomControls extends StatefulWidget {
  const CustomControls({Key? key}) : super(key: key);

  @override
  State<CustomControls> createState() => _CustomControlsState();
}

class _CustomControlsState extends State<CustomControls> {
  bool _controlsVisible = true;
  Timer? _hideControlsTimer;

  @override
  Widget build(BuildContext context) {
    final chewieController = ChewieController.of(context);

    if (chewieController == null) {
      return const SizedBox();
    }

    // Iniciar o timer para esconder controles automaticamente quando o vídeo começa a tocar
    if (chewieController.isPlaying) {
      _startHideControlsTimer();
    }

    return GestureDetector(
      onTap: _toggleControlsVisibility,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Video centralizado
          Center(
            child: AspectRatio(
              aspectRatio: chewieController.videoPlayerController.value.aspectRatio,
              child: VideoPlayer(chewieController.videoPlayerController),
            ),
          ),
          
          // Botões de controle (aparecem/desaparecem)
          if (_controlsVisible)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  VideoProgressIndicator(
                    chewieController.videoPlayerController,
                    allowScrubbing: true,
                    colors: VideoProgressColors(
                      playedColor: Theme.of(context).primaryColor,
                      bufferedColor: Colors.grey,
                      backgroundColor: Colors.black,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Play/Pause
                      IconButton(
                        icon: Icon(
                          chewieController.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            chewieController.isPlaying
                                ? chewieController.pause()
                                : chewieController.play();
                          });
                        },
                      ),
                      // Retroceder
                      IconButton(
                        icon: const Icon(Icons.replay_10, color: Colors.white),
                        onPressed: () {
                          chewieController.seekTo(
                            chewieController.videoPlayerController.value.position -
                                const Duration(seconds: 10),
                          );
                        },
                      ),
                      // Avançar
                      IconButton(
                        icon: const Icon(Icons.forward_10, color: Colors.white),
                        onPressed: () {
                          chewieController.seekTo(
                            chewieController.videoPlayerController.value.position +
                                const Duration(seconds: 10),
                          );
                        },
                      ),
                      // Mudo
                      IconButton(
                        icon: Icon(
                          chewieController.videoPlayerController.value.volume == 0
                              ? Icons.volume_off
                              : Icons.volume_up,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            if (chewieController.videoPlayerController.value.volume == 0) {
                              chewieController.setVolume(1.0);
                            } else {
                              chewieController.setVolume(0.0);
                            }
                          });
                        },
                      ),
                      // Tela cheia
                      IconButton(
                        icon: const Icon(Icons.fullscreen, color: Colors.white),
                        onPressed: () {
                          chewieController.toggleFullScreen();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _toggleControlsVisibility() {
    setState(() {
      _controlsVisible = !_controlsVisible;
    });

    if (_controlsVisible) {
      _startHideControlsTimer();
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _controlsVisible = false;
      });
    });
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    super.dispose();
  }
}
