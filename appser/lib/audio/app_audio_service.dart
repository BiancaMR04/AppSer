import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

late final AppAudioHandler appAudioHandler;

Future<void> initAudioService() async {
  appAudioHandler = await AudioService.init(
    builder: () => AppAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.astracode.appser.audio',
      androidNotificationChannelName: 'Reprodução de áudio',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
}

class AppAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  StreamSubscription<PlaybackEvent>? _eventSub;

  AppAudioHandler() {
    _eventSub = _player.playbackEventStream.listen(_broadcastState);
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        // Keep state consistent and allow replay.
        _broadcastState(_player.playbackEvent);
      }
    });
  }

  Future<void> setUrlAndPlay({
    required String url,
    required String title,
    String? artUri,
    String? id,
  }) async {
    final mediaId = id ?? url;
    final baseItem = MediaItem(
      id: mediaId,
      title: title,
      artUri: artUri != null ? Uri.tryParse(artUri) : null,
    );
    mediaItem.add(baseItem);

    await _player.setUrl(url);

    final duration = _player.duration;
    if (duration != null) {
      mediaItem.add(baseItem.copyWith(duration: duration));
    }

    await _player.play();
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;

    final controls = <MediaControl>[
      if (playing) MediaControl.pause else MediaControl.play,
      MediaControl.stop,
    ];

    playbackState.add(
      playbackState.value.copyWith(
        controls: controls,
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1],
        processingState: _mapProcessingState(_player.processingState),
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
      ),
    );
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    // No-op for now (single item playback). Keep for notification controls.
  }

  @override
  Future<void> skipToPrevious() async {
    // No-op for now (single item playback). Keep for notification controls.
  }

  Future<void> close() async {
    await _eventSub?.cancel();
    await _player.dispose();
  }
}
