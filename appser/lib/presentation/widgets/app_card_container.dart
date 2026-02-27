import 'package:flutter/material.dart';

class AppCardContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color backgroundColor;
  final double borderRadius;
  final List<BoxShadow> boxShadow;
  final bool clipContent;

  const AppCardContainer({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor = Colors.white,
    this.borderRadius = 16,
    this.boxShadow = const <BoxShadow>[],
    this.clipContent = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    if (clipContent) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: content,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow.isEmpty ? null : boxShadow,
      ),
      child: content,
    );
  }
}
