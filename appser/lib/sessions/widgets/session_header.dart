import 'package:flutter/material.dart';

class SessionHeader extends StatelessWidget {
  final String title;
  final TextStyle titleStyle;
  final double logoHeight;
  final bool showBottomSpacing;
  final double bottomSpacing;

  const SessionHeader({
    super.key,
    required this.title,
    required this.titleStyle,
    this.logoHeight = 100,
    this.showBottomSpacing = true,
    this.bottomSpacing = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/logo.png',
          height: logoHeight,
        ),
        Text(
          title,
          style: titleStyle,
        ),
        if (showBottomSpacing) SizedBox(height: bottomSpacing),
      ],
    );
  }
}
