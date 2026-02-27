import 'package:flutter/material.dart';

import 'video_player.dart';

class WelcomeVideoPlayerScreen extends StatelessWidget {
  final String videoPath;
  final String videoTitle;

  final String? sessaoId;
  final String? itemId;
  final bool isSupplementary;

  const WelcomeVideoPlayerScreen({
    super.key,
    required this.videoPath,
    required this.videoTitle,
    this.sessaoId,
    this.itemId,
    this.isSupplementary = false,
  });

  @override
  Widget build(BuildContext context) {
    return VideoPlayerScreen(
      videoPath: videoPath,
      videoTitle: videoTitle,
      sessaoId: sessaoId,
      itemId: itemId,
      isSupplementary: isSupplementary,
      appBarTitleOverride: videoTitle,
      showVideoTitleAboveVideoOverride: false,
    );
  }
}
