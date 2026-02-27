import 'dart:async';
import 'dart:math' as math;

import 'package:appser/presentation/widgets/app_background.dart';
import 'package:appser/presentation/widgets/app_bottom_nav_bar.dart';
import 'package:appser/presentation/widgets/app_back_app_bar.dart';
import 'package:appser/presentation/widgets/app_scaffold.dart';
import 'package:audio_session/audio_session.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../audio/app_audio_service.dart';
import '../../presentation/controllers/storage_url_controller.dart';
import '../../screens/user_tracking_service.dart';

class AudioPlayerScreen extends StatefulWidget {
  final String audioPath;
  final String audioTitle;
  final VoidCallback? onComplete;

  final String? sessaoId;
  final String? itemId;
  final bool isSupplementary;

  const AudioPlayerScreen({
    Key? key,
    required this.audioPath,
    required this.audioTitle,
    this.onComplete,
    this.sessaoId,
    this.itemId,
    this.isSupplementary = false,
  }) : super(key: key);

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  AppAudioHandler get _handler => appAudioHandler;
  Stream<Duration?> get _durationStream => _handler.mediaItem
      .map((item) => item?.duration)
      .distinct((a, b) => a == b);

  int _lastPositionSeconds = 0;
  int? _lastDurationSeconds;
  PlaybackState? _lastPlaybackState;
  AudioProcessingState? _lastProcessingState;
  late final StreamSubscription<Duration> _positionSub;
  late final StreamSubscription<Duration?> _durationSub;
  late final StreamSubscription<PlaybackState> _playbackSub;

  @override
  void initState() {
    super.initState();
    _positionSub = AudioService.position.listen((pos) {
      _lastPositionSeconds = pos.inSeconds;
    });
    _durationSub = _durationStream.listen((dur) {
      _lastDurationSeconds = dur?.inSeconds;
    });
    _playbackSub = _handler.playbackState.listen((state) {
      _lastPlaybackState = state;
      final processingState = state.processingState;
      final isTransitionToCompleted =
          processingState == AudioProcessingState.completed &&
              _lastProcessingState != AudioProcessingState.completed;
      _lastProcessingState = processingState;

      if (isTransitionToCompleted) {
        _logComplete();
      }
    });
    _loadAudio();
  }

  Future<void> _logComplete() async {
    final sessaoId = widget.sessaoId;
    final itemId = widget.itemId;
    if (sessaoId == null || itemId == null) return;

    await UserTrackingService.registrarTarefaCompleta(
      sessaoId: sessaoId,
      tipo: 'audio',
      itemId: itemId,
      isSupplementary: widget.isSupplementary,
      title: widget.audioTitle,
      path: widget.audioPath,
      durationSeconds: _lastDurationSeconds,
      mode: 'end',
    );
  }

  Future<void> _loadAudio() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      final url = await context
          .read<StorageUrlController>()
          .getDownloadUrl(widget.audioPath);

      await _handler.setUrlAndPlay(
        url: url,
        title: widget.audioTitle,
      );
    } catch (e) {
      print('Erro ao carregar áudio: $e');
    }
  }

  @override
  void dispose() {
    final sessaoId = widget.sessaoId;
    final itemId = widget.itemId;
    final playback = _lastPlaybackState;
    final isPlaying = playback?.playing ?? false;
    final isCompleted =
        playback?.processingState == AudioProcessingState.completed;

    if (!isCompleted && !isPlaying) {
      if (sessaoId != null && itemId != null && _lastPositionSeconds > 0) {
        UserTrackingService.registrarTarefaParcial(
          sessaoId: sessaoId,
          tipo: 'audio',
          itemId: itemId,
          isSupplementary: widget.isSupplementary,
          positionSeconds: _lastPositionSeconds,
          durationSeconds: _lastDurationSeconds,
          title: widget.audioTitle,
          path: widget.audioPath,
        );
      }
    }

    _positionSub.cancel();
    _durationSub.cancel();
    _playbackSub.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds.remainder(60))}';
  }

  int? _sessionNumberFromSessaoId(String? sessaoId) {
    if (sessaoId == null) return null;
    final match = RegExp(r'^sessao_(\d+)$').firstMatch(sessaoId.trim());
    final raw = match?.group(1);
    if (raw == null) return null;
    return int.tryParse(raw);
  }

  void _seekRelativeSeconds(int deltaSeconds) {
    final current = _lastPositionSeconds;
    final max = _lastDurationSeconds;

    final nextUnclamped = current + deltaSeconds;
    final next = nextUnclamped < 0 ? 0 : nextUnclamped;
    final clamped = (max == null) ? next : (next > max ? max : next);

    _handler.seek(Duration(seconds: clamped));
  }

  String _appBarTitleText() {
    final n = _sessionNumberFromSessaoId(widget.sessaoId);
    if (n == null) {
      return widget.audioTitle;
    }
    if (n == 0) {
      return 'Boas-Vindas';
    }
    return 'Sessão $n';
  }

  @override
  Widget build(BuildContext context) {
    final appBarTitleText = _appBarTitleText();

    return AppScaffold(
      appBar: AppBackAppBar(
        titleText: appBarTitleText,
      ),
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 145, 24, 24),
            child: Column(
              children: [
                if (widget.sessaoId != null) ...[
                  Text(
                    widget.audioTitle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF232323),
                    ),
                  ),
                  const SizedBox(height: 26),
                ] else ...[
                  const SizedBox(height: 10),
                ],

                // WAVEFORM DECORATIVO
                StreamBuilder<PlaybackState>(
                  stream: _handler.playbackState,
                  builder: (context, snapshot) {
                    final state = snapshot.data;
                    final isPlaying = state?.playing ?? false;
                    final processing = state?.processingState;
                    final isCompleted =
                        processing == AudioProcessingState.completed;
                    final isBufferingOrLoading =
                        processing == AudioProcessingState.buffering ||
                            processing == AudioProcessingState.loading;

                    return _DecorativeWaveform(
                      isActive:
                          (isPlaying || isBufferingOrLoading) && !isCompleted,
                      color: const Color(0xFF2F7888),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // CONTROLES
                StreamBuilder<PlaybackState>(
                  stream: _handler.playbackState,
                  builder: (context, snapshot) {
                    final state = snapshot.data;
                    final isPlaying = state?.playing ?? false;
                    final completed = state?.processingState ==
                        AudioProcessingState.completed;

                    Widget roundButton({
                      required VoidCallback? onTap,
                      required IconData icon,
                      required double size,
                      required double iconSize,
                      Color? backgroundColor,
                      Color? iconColor,
                    }) {
                      return SizedBox(
                        width: size,
                        height: size,
                        child: Material(
                          color: backgroundColor ?? Colors.transparent,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: onTap,
                            child: Center(
                              child: Icon(
                                icon,
                                size: iconSize,
                                color: iconColor ?? const Color(0xFF2F7888),
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    const sideButtonSize = 72.0;
                    const sideIconSize = 42.0;
                    const pauseButtonSize = 92.0;
                    const pauseIconSize = 50.0;
                    const playIconSize = 62.0;

                    final centerIcon = completed
                      ? Icons.replay
                      : isPlaying
                        ? Icons.pause
                        : Icons.play_arrow;
                    final centerIconSize =
                      centerIcon == Icons.play_arrow ? playIconSize : pauseIconSize;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        roundButton(
                          onTap: () {
                            _seekRelativeSeconds(-10);
                          },
                          icon: Icons.replay_10,
                          size: sideButtonSize,
                          iconSize: sideIconSize,
                        ),
                        const SizedBox(width: 10),
                        roundButton(
                          onTap: () async {
                            if (completed) {
                              await _handler.seek(Duration.zero);
                              await _handler.play();
                            } else if (isPlaying) {
                              await _handler.pause();
                            } else {
                              await _handler.play();
                            }
                          },
                          icon: centerIcon,
                          size: pauseButtonSize,
                          iconSize: centerIconSize,
                          backgroundColor: const Color(0xFF2F7888),
                          iconColor: Colors.white,
                        ),
                        const SizedBox(width: 10),
                        roundButton(
                          onTap: () {
                            _seekRelativeSeconds(10);
                          },
                          icon: Icons.forward_10,
                          size: sideButtonSize,
                          iconSize: sideIconSize,
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 40),

                // BARRA DE PROGRESSO
                StreamBuilder<Duration?>(
                  stream: _durationStream,
                  builder: (context, snapshotDuration) {
                    final duration = snapshotDuration.data ?? Duration.zero;

                    return StreamBuilder<Duration>(
                      stream: AudioService.position,
                      builder: (context, snapshotPosition) {
                        final position = snapshotPosition.data ?? Duration.zero;

                        return Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6,
                                ),
                              ),
                              child: Slider(
                                min: 0,
                                max: duration.inMilliseconds.toDouble(),
                                value: position.inMilliseconds
                                    .clamp(0, duration.inMilliseconds)
                                    .toDouble(),
                                activeColor: const Color(0xFF2F7888),
                                inactiveColor:
                                    const Color(0xFF2F7888).withOpacity(0.3),
                                onChanged: (value) {
                                  _handler.seek(
                                    Duration(milliseconds: value.toInt()),
                                  );
                                },
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(position),
                                  style: const TextStyle(
                                    color: Color(0xFF2F7888),
                                  ),
                                ),
                                Text(
                                  _formatDuration(duration),
                                  style: const TextStyle(
                                    color: Color(0xFF2F7888),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(),
    );
  }
}

class _DecorativeWaveform extends StatefulWidget {
  final bool isActive;
  final Color color;

  const _DecorativeWaveform({
    required this.isActive,
    required this.color,
  });

  @override
  State<_DecorativeWaveform> createState() => _DecorativeWaveformState();
}

class _DecorativeWaveformState extends State<_DecorativeWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final Stopwatch _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      // Usado só como "ticker" para repintar continuamente.
      duration: const Duration(milliseconds: 1000),
    );

    // Mantém o ticker e o tempo contínuos enquanto o widget existir.
    // O "isActive" controla apenas a intensidade do movimento.
    _stopwatch.start();
    _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _DecorativeWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Nada: o ticker roda sempre; isActive só afeta o painter.
  }

  @override
  void dispose() {
    _stopwatch.stop();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const height = 80.0;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Tempo contínuo (segundos), independente do loop do controller.
          final seconds = _stopwatch.elapsedMicroseconds / 1000000.0;
          // Converte pra radianos contínuos (como antes era value * 2π),
          // mas sem reinício abrupto.
          final t = seconds * 2 * math.pi;
          return CustomPaint(
            painter: _MountainWaveformPainter(
              color: widget.color,
              isActive: widget.isActive,
              t: t,
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

class _MountainWaveformPainter extends CustomPainter {
  final Color color;
  final bool isActive;
  final double t;

  const _MountainWaveformPainter({
    required this.color,
    required this.isActive,
    required this.t,
  });

  // ARRAY EXTRAÍDO DA SUA IMAGEM (pixel-perfect base)
  static const List<double> waveformHeights = [
    0.00,
    0.40,
    0.10,
    0.35,
    0.20,
    0.60,
    0.80,
    1.00,
    0.40,
    0.60,
    0.60,
    0.40,
    0.70,
    1.00,
    0.70,
    0.50,
    0.30,
    0.50,
    0.30,
    0.70,
    1.00,
    0.60,
    0.40,
    0.20,
    0.60,
    0.20,
    0.75,
    0.90,
    0.40,
    0.61,
    0.40,
    0.00,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 5.5;
    const animSeed = 4242;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final barCount = waveformHeights.length;

    final paddingX = size.width * 0.08;
    final availableWidth = size.width - (paddingX * 2);
    final dx = availableWidth / (barCount - 1);

    final centerY = size.height / 2;

    final minHalfHeight = size.height * 0.10;
    final maxHalfHeight = size.height * 0.42;

    double hash01(int x) {
      // determinístico (0..1)
      var v = x & 0x7fffffff;
      v ^= (v >> 16);
      v = (v * 1103515245 + 12345) & 0x7fffffff;
      v ^= (v >> 16);
      return (v & 0x7fffffff) / 0x7fffffff;
    }

    for (int i = 0; i < barCount; i++) {
      final base = waveformHeights[i].clamp(0.0, 1.0);
      var heightFactor = base;

      // Animação estilo "Spotify": cada barra mexe um pouquinho em ritmos
      // diferentes (não sincroniza tudo), mantendo o formato do array.
      if (isActive) {
        final r1 = hash01(animSeed + i * 97);
        final r2 = hash01(animSeed + i * 193 + 7);
        final r3 = hash01(animSeed + i * 389 + 13);

        // velocidades mais baixas = mais "calmo"
        final speed1 = 0.45 + (r1 * 0.95); // ~0.45..1.40
        final speed2 = 0.25 + (r2 * 0.70); // ~0.25..0.95
        final phase1 = r2 * 2 * math.pi;
        final phase2 = r3 * 2 * math.pi;

        // mexe mais, mas ainda suave; barras altas mexem mais
        final amp = (0.07 + (r3 * 0.08)) * (0.25 + (0.75 * base));

        final w1 = math.sin((t * speed1) + (i * 0.12) + phase1);
        final w2 = math.sin((t * speed2) + (i * 0.04) + phase2);

        final delta = (w1 * 0.70 + w2 * 0.30) * amp;
        heightFactor = (base + delta).clamp(0.0, 1.0);
      }

      final halfHeight =
          minHalfHeight + (maxHalfHeight - minHalfHeight) * heightFactor;

      final x = paddingX + dx * i;

      canvas.drawLine(
        Offset(x, centerY - halfHeight),
        Offset(x, centerY + halfHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MountainWaveformPainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.isActive != isActive ||
        oldDelegate.color != color;
  }
}