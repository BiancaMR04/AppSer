import 'package:flutter/material.dart';

class AppElevatedRowButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final Color iconColor;
  final String title;
  final TextStyle? titleStyle;
  final Widget? trailing;
  final double iconGap;

  final EdgeInsets outerPadding;
  final EdgeInsets innerPadding;
  final Color backgroundColor;
  final double borderRadius;
  final double? elevation;

  const AppElevatedRowButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.titleStyle,
    this.trailing,
    this.iconGap = 16,
    this.outerPadding = const EdgeInsets.symmetric(vertical: 8.0),
    this.innerPadding =
        const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
    this.backgroundColor = Colors.white,
    this.borderRadius = 12.0,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: outerPadding,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          padding: innerPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: elevation,
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor),
            SizedBox(width: iconGap),
            Expanded(
              child: Text(
                title,
                style: titleStyle ??
                    const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
