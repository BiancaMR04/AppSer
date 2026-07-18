import 'dart:async';
import 'dart:io';

import 'package:appser/presentation/widgets/app_background.dart';
import 'package:appser/presentation/widgets/app_back_app_bar.dart';
import 'package:appser/presentation/widgets/app_bottom_nav_bar.dart';
import 'package:appser/presentation/widgets/app_scaffold.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';

import '../../presentation/controllers/storage_url_controller.dart';
import '../../screens/user_tracking_service.dart';
import '../../services/activity_auto_advance_settings_service.dart';
import '../../sessions/session_activity_navigation.dart';
import 'app_video_cache_manager.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoPath;
  final String videoTitle; // Adicionando o título

  final String? sessaoId;
  final String? itemId;
  final bool isSupplementary;

  // Overrides para casos especiais (ex.: Boas-Vindas)
  final String? appBarTitleOverride;
  final bool? showVideoTitleAboveVideoOverride;

  const VideoPlayerScreen({
    super.key,
    required this.videoPath,
    required this.videoTitle,
    this.sessaoId,
    this.itemId,
    this.isSupplementary = false,
    this.appBarTitleOverride,
    this.showVideoTitleAboveVideoOverride,
  });

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoPlayerController;
  String videoUrl = '';
  bool _hasController = false;

  bool _wasCompleted = false;
  bool _didHandleCompletion = false;
  Duration _lastPosition = Duration.zero;
  Duration? _lastDuration;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    VideoPlayerController? controller;

    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      videoUrl = await context
          .read<StorageUrlController>()
          .getDownloadUrl(widget.videoPath);

      if (videoUrl.isNotEmpty) {
        controller = await _createControllerForVideo(videoUrl: videoUrl);

        if (!mounted) {
          await controller.dispose();
          return;
        }

        _videoPlayerController = controller;
        _hasController = true;

        _lastDuration = _videoPlayerController.value.duration;
        _videoPlayerController.addListener(_onVideoTick);

        if (!mounted) return;

        // Auto-play ao entrar na tela.
        await _videoPlayerController.play();
        unawaited(
          AppVideoCacheManager.instance.prefetchVideo(
            videoUrl: videoUrl,
            videoPath: widget.videoPath,
          ),
        );
        setState(() {});
      } else {
        print('Erro: URL do vídeo está vazia');
      }
    } catch (e) {
      await controller?.dispose();
      if (!mounted) return;

      print('Erro ao inicializar o player de vídeo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao carregar o vídeo')),
      );
    }
  }

  Future<VideoPlayerController> _createControllerForVideo({
    required String videoUrl,
  }) async {
    try {
      final cachedVideoFile = await AppVideoCacheManager.instance
          .getCachedVideoFile(videoPath: widget.videoPath);

      if (cachedVideoFile != null) {
        final fileController = VideoPlayerController.file(
          File(cachedVideoFile.path),
          videoPlayerOptions: VideoPlayerOptions(
            allowBackgroundPlayback: true,
            mixWithOthers: true,
          ),
        );
        await fileController.initialize();
        return fileController;
      }
    } catch (e) {
      debugPrint('Falha ao ler cache local do vídeo, usando streaming direto: $e');
    }

    final networkController = VideoPlayerController.networkUrl(
      Uri.parse(videoUrl),
      videoPlayerOptions: VideoPlayerOptions(
        allowBackgroundPlayback: true,
        mixWithOthers: true,
      ),
    );
    await networkController.initialize();
    return networkController;
  }

  void _onVideoTick() {
    final v = _videoPlayerController.value;
    if (!v.isInitialized) return;

    _lastPosition = v.position;
    _lastDuration = v.duration;

    final duration = v.duration;
    final isCompletedNow = duration > Duration.zero && v.position >= duration;

    if (isCompletedNow && !_wasCompleted) {
      unawaited(_completeAndMaybeAdvance());
    }

    _wasCompleted = isCompletedNow;
  }

  Future<void> _logComplete() async {
    final sessaoId = widget.sessaoId;
    final itemId = widget.itemId;
    if (sessaoId == null || itemId == null) return;

    await UserTrackingService.registrarTarefaCompleta(
      sessaoId: sessaoId,
      tipo: 'video',
      itemId: itemId,
      isSupplementary: widget.isSupplementary,
      title: widget.videoTitle,
      path: widget.videoPath,
      durationSeconds: _lastDuration?.inSeconds,
      mode: 'end',
    );
  }

  Future<void> _completeAndMaybeAdvance() async {
    if (_didHandleCompletion) return;
    _didHandleCompletion = true;
    final navigator = Navigator.of(context);

    await _logComplete();

    if (widget.isSupplementary) return;
    final autoAdvance = await ActivityAutoAdvanceSettingsService.isEnabled();
    if (!autoAdvance || !mounted) return;

    await openNextSessionContentItemWithNavigator(
      navigator: navigator,
      sessaoId: widget.sessaoId,
      itemId: widget.itemId,
    );
  }

  @override
  void dispose() {
    if (_hasController) {
      final sessaoId = widget.sessaoId;
      final itemId = widget.itemId;
      final v = _videoPlayerController.value;

      if (v.isInitialized) {
        final isPlaying = v.isPlaying;
        final duration = _lastDuration ?? v.duration;
        final position = _lastPosition;
        final isCompleted = duration > Duration.zero && position >= duration;

        if (!isCompleted && !isPlaying) {
          if (sessaoId != null && itemId != null && position.inSeconds > 0) {
            UserTrackingService.registrarTarefaParcial(
              sessaoId: sessaoId,
              tipo: 'video',
              itemId: itemId,
              isSupplementary: widget.isSupplementary,
              positionSeconds: position.inSeconds,
              durationSeconds: duration.inSeconds,
              title: widget.videoTitle,
              path: widget.videoPath,
            );
          }
        }
      }

      _videoPlayerController.removeListener(_onVideoTick);
      _videoPlayerController.dispose();
    }
    super.dispose();
  }

  static const Color _controlsColor = Color(0xFF2F7888);

  int? _sessionNumberFromSessaoId(String? sessaoId) {
    if (sessaoId == null) return null;
    final match = RegExp(r'^sessao_(\d+)$').firstMatch(sessaoId);
    if (match == null) return null;
    return int.tryParse(match.group(1) ?? '');
  }

  String _appBarTitleText() {
    final override = widget.appBarTitleOverride;
    if (override != null && override.isNotEmpty) {
      return override;
    }

    final n = _sessionNumberFromSessaoId(widget.sessaoId);
    if (n != null && n > 0) {
      return 'Sessão $n';
    }

    return widget.videoTitle;
  }

  bool _shouldShowVideoTitleAboveVideo() {
    final override = widget.showVideoTitleAboveVideoOverride;
    if (override != null) return override;

    final n = _sessionNumberFromSessaoId(widget.sessaoId);
    return n != null && n > 0;
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    final hours = d.inHours;
    if (hours > 0) {
      return '${twoDigits(hours)}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  void _seekRelative(Duration offset) {
    if (!_hasController || !_videoPlayerController.value.isInitialized) {
      return;
    }

    final current = _videoPlayerController.value.position;
    final duration = _videoPlayerController.value.duration;
    final next = current + offset;

    final clamped = next < Duration.zero
        ? Duration.zero
        : (next > duration ? duration : next);

    _videoPlayerController.seekTo(clamped);
  }

  void _togglePlayPause() {
    if (!_hasController || !_videoPlayerController.value.isInitialized) {
      return;
    }

    if (_videoPlayerController.value.isPlaying) {
      _videoPlayerController.pause();
    } else {
      _videoPlayerController.play();
    }
  }

  Future<void> _openFullscreen() async {
    if (!_hasController || !_videoPlayerController.value.isInitialized) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _FullscreenVideoPlayerRoute(
          controller: _videoPlayerController,
        ),
      ),
    );
  }

  Widget _buildControls({required double width}) {
    if (!_hasController) {
      return const SizedBox.shrink();
    }

    Widget roundIconButton({
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
                color: iconColor ?? _controlsColor,
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: width,
      child: ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: _videoPlayerController,
        builder: (context, value, child) {
          final duration = value.duration;
          final position = value.position;
          final isInitialized = value.isInitialized;
          final isPlaying = value.isPlaying;

          final maxMs =
              duration.inMilliseconds.toDouble().clamp(1.0, double.infinity);
          final posMs = position.inMilliseconds.toDouble().clamp(0.0, maxMs);

          const pauseButtonSize = 82.0;
          const sideButtonSize = 64.0;
          const pauseIconSize = 52.0;
          const sideIconSize = 38.0;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  roundIconButton(
                    onTap: isInitialized
                        ? () => _seekRelative(const Duration(seconds: -10))
                        : null,
                    icon: Icons.replay_10,
                    size: sideButtonSize,
                    iconSize: sideIconSize,
                  ),
                  const SizedBox(width: 10),
                  roundIconButton(
                    onTap: isInitialized
                        ? () {
                            if (isPlaying) {
                              _videoPlayerController.pause();
                            } else {
                              _videoPlayerController.play();
                            }
                          }
                        : null,
                    icon: isPlaying ? Icons.pause : Icons.play_arrow,
                    size: pauseButtonSize,
                    iconSize: pauseIconSize,
                    backgroundColor: _controlsColor,
                    iconColor: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  roundIconButton(
                    onTap: isInitialized
                        ? () => _seekRelative(const Duration(seconds: 10))
                        : null,
                    icon: Icons.forward_10,
                    size: sideButtonSize,
                    iconSize: sideIconSize,
                  ),
                  const SizedBox(width: 10),
                  roundIconButton(
                    onTap: isInitialized ? _openFullscreen : null,
                    icon: Icons.fullscreen,
                    size: sideButtonSize,
                    iconSize: sideIconSize,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: _controlsColor,
                  inactiveTrackColor: _controlsColor.withOpacity(0.25),
                  thumbColor: _controlsColor,
                  overlayColor: _controlsColor.withOpacity(0.12),
                  trackHeight: 6,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 8),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 14),
                ),
                child: Slider(
                  value: posMs,
                  min: 0.0,
                  max: maxMs,
                  onChanged: isInitialized
                      ? (newValue) {
                          _videoPlayerController.seekTo(
                            Duration(milliseconds: newValue.round()),
                          );
                        }
                      : null,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(position),
                      style: const TextStyle(
                        color: _controlsColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _formatDuration(duration),
                      style: const TextStyle(
                        color: Color(0xFFC7CBCC),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appBarTitleText = _appBarTitleText();
    final showTitleAboveVideo = _shouldShowVideoTitleAboveVideo();

    return AppScaffold(
      appBar: AppBackAppBar(
        titleText: appBarTitleText,
        iconColor: Colors.grey,
      ),
      body: AppBackground(
        child: LayoutBuilder(
          builder: (context, constraints) {
            const borderRadius = 18.0;
            const horizontalPadding = 12.0;
            const controlsHeight = 156.0;
            const titleBlockHeight = 44.0;
            const titleTopGap = 26.0;
            const titleBottomGap = 10.0;
            const videoToControlsGap = 10.0;

            final isReady =
                _hasController && _videoPlayerController.value.isInitialized;

            final videoAspectRaw =
                isReady ? _videoPlayerController.value.aspectRatio : (16 / 9);
            final targetAspectRatio =
                (videoAspectRaw.isFinite && videoAspectRaw > 0)
                    ? videoAspectRaw
                    : (16 / 9);

            final verticalBias = showTitleAboveVideo
                ? -0.06 // desce mais pra dar respiro abaixo da navbar
                : -0.18; // um pouco acima do meio

            final reservedTitleHeight = showTitleAboveVideo
                ? (titleTopGap + titleBlockHeight + titleBottomGap)
                : 0.0;

            final double maxPlayerWidth =
                (constraints.maxWidth - (horizontalPadding * 2))
                    .clamp(0.0, double.infinity)
                    .toDouble();

            final maxGroupHeight =
                constraints.maxHeight * (showTitleAboveVideo ? 0.80 : 0.86);
            final double maxPlayerHeight = (maxGroupHeight -
                    controlsHeight -
                    reservedTitleHeight -
                    videoToControlsGap)
                .clamp(0.0, double.infinity);

            double playerWidth = maxPlayerWidth;
            double playerHeight = playerWidth / targetAspectRatio;

            if (playerHeight > maxPlayerHeight) {
              playerHeight = maxPlayerHeight;
              playerWidth = playerHeight * targetAspectRatio;
            }

            return Align(
              alignment: Alignment(0, verticalBias),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showTitleAboveVideo) ...[
                    const SizedBox(height: titleTopGap),
                    SizedBox(
                      width: playerWidth,
                      child: Text(
                        widget.videoTitle,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF232323),
                        ),
                      ),
                    ),
                    const SizedBox(height: titleBottomGap),
                  ],
                  SizedBox(
                    width: playerWidth,
                    height: playerHeight,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(borderRadius),
                      child: DecoratedBox(
                        decoration: const BoxDecoration(color: Colors.black),
                        child: isReady
                            ? GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: _togglePlayPause,
                                child: Center(
                                  child: AspectRatio(
                                    aspectRatio: targetAspectRatio,
                                    child: VideoPlayer(_videoPlayerController),
                                  ),
                                ),
                              )
                            : const Center(
                                child: CircularProgressIndicator(),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: videoToControlsGap),
                  _buildControls(width: playerWidth),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(),
    );
  }
}

class _FullscreenVideoPlayerRoute extends StatefulWidget {
  final VideoPlayerController controller;

  const _FullscreenVideoPlayerRoute({required this.controller});

  @override
  State<_FullscreenVideoPlayerRoute> createState() =>
      _FullscreenVideoPlayerRouteState();
}

class _FullscreenVideoPlayerRouteState
    extends State<_FullscreenVideoPlayerRoute> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _togglePlayPause() {
    final value = widget.controller.value;
    if (!value.isInitialized) return;
    if (value.isPlaying) {
      widget.controller.pause();
    } else {
      widget.controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _togglePlayPause,
          child: Stack(
            children: [
              Center(
                child: ValueListenableBuilder<VideoPlayerValue>(
                  valueListenable: widget.controller,
                  builder: (context, value, child) {
                    final raw =
                        value.isInitialized ? value.aspectRatio : 16 / 9;
                    final aspectRatio =
                        (raw.isFinite && raw > 0) ? raw : 16 / 9;

                    if (!value.isInitialized) {
                      return const CircularProgressIndicator();
                    }

                    return AspectRatio(
                      aspectRatio: aspectRatio,
                      child: VideoPlayer(widget.controller),
                    );
                  },
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.fullscreen_exit, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
