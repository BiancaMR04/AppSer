import 'package:appser/core/constants/session_defaults.dart';
import 'package:appser/core/theme/app_colors.dart';
import 'package:appser/screens/home/widgets/session_titles.dart';
import 'package:flutter/material.dart';

class HomeSessionList extends StatelessWidget {
  final Map<String, bool> sessionStatus;
  final double screenHeight;
  final double screenWidth;
  final void Function(int index) onSessionPressed;

  const HomeSessionList({
    super.key,
    required this.sessionStatus,
    required this.screenHeight,
    required this.screenWidth,
    required this.onSessionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...List.generate(
          SessionDefaults.totalSessions,
          (index) => AlternatingSessionButton(
            number: index.toString().padLeft(2, '0'),
            title: homeSessionTitleFor(index),
            screenHeight: screenHeight,
            screenWidth: screenWidth,
            isLeft: index % 2 == 0,
            enabled: sessionStatus['session$index'] ?? false,
            onPressed: () => onSessionPressed(index),
          ),
        ),
      ],
    );
  }
}

class AlternatingSessionButton extends StatelessWidget {
  final String number;
  final String title;
  final double screenHeight;
  final double screenWidth;
  final bool isLeft;
  final bool enabled;
  final VoidCallback onPressed;

  const AlternatingSessionButton({
    super.key,
    required this.number,
    required this.title,
    required this.screenHeight,
    required this.screenWidth,
    required this.isLeft,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
          children: [
            Container(
              margin: isLeft
                  ? EdgeInsets.only(left: screenWidth * 0.12)
                  : EdgeInsets.only(right: screenWidth * 0.12),
              padding: EdgeInsets.symmetric(
                vertical: screenHeight * 0.025,
                horizontal: screenWidth * 0.08,
              ),
              decoration: BoxDecoration(
                color: enabled
                    ? AppColors.appBackground
                    : AppColors.sessionTileDisabledBg,
                border: Border.all(
                  color: enabled
                      ? AppColors.sessionTileEnabledBorder
                      : AppColors.sessionTileDisabledBorder,
                  width: 4,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              width: screenWidth * 0.75,
              child: GestureDetector(
                onTap: enabled ? onPressed : null,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: screenHeight * 0.015,
                    fontWeight: FontWeight.bold,
                    color: AppColors.sessionTileTitle,
                  ),
                ),
              ),
            ),
            Positioned(
              top: screenHeight * 0.020,
              left: isLeft ? 0 : null,
              right: isLeft ? null : 0,
              child: Container(
                width: screenHeight * 0.07,
                height: screenHeight * 0.07,
                decoration: BoxDecoration(
                  color: enabled
                      ? AppColors.appBackground
                      : AppColors.sessionBadgeDisabledBg,
                  border: Border.all(
                    color: enabled
                        ? AppColors.sessionBadgeEnabledBorder
                        : AppColors.sessionBadgeDisabledBorder,
                    width: 2,
                  ),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  number,
                  style: TextStyle(
                    fontSize: screenHeight * 0.03,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (number != '08')
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
            child: CustomPaint(
              painter: DottedLinePainter(screenHeight: screenHeight),
              child: SizedBox(
                height: screenHeight * 0.05,
                width: 2,
              ),
            ),
          ),
      ],
    );
  }
}

class DottedLinePainter extends CustomPainter {
  final double screenHeight;

  DottedLinePainter({required this.screenHeight});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.sessionDottedLine
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final max = size.height;
    final dashWidth = screenHeight * 0.005;
    final dashSpace = screenHeight * 0.005;
    double startY = 0;

    while (startY < max) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashWidth), paint);
      startY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
