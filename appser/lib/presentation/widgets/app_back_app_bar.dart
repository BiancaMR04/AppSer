import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AppBackAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? titleText;
  final Widget? title;
  final bool centerTitle;
  final Color? backgroundColor;
  final double elevation;
  final Color? iconColor;
  final VoidCallback? onBack;
  final bool showBackButton;
  final List<Widget>? actions;

  const AppBackAppBar({
    super.key,
    this.titleText,
    this.title,
    this.centerTitle = true,
    this.backgroundColor,
    this.elevation = 0,
    this.iconColor,
    this.onBack,
    this.showBackButton = true,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTitleStyle = const TextStyle(
      color: AppColors.navbarTitle,
      fontWeight: FontWeight.bold,
    );

    Widget? resolvedTitle = title;
    if (resolvedTitle == null && titleText != null) {
      resolvedTitle = Text(titleText!);
    }

    if (resolvedTitle is Text) {
      final data = resolvedTitle.data;
      if (data != null) {
        resolvedTitle = Text(
          data,
          key: resolvedTitle.key,
          style: (resolvedTitle.style ?? const TextStyle())
              .merge(effectiveTitleStyle),
          strutStyle: resolvedTitle.strutStyle,
          textAlign: resolvedTitle.textAlign,
          textDirection: resolvedTitle.textDirection,
          locale: resolvedTitle.locale,
          softWrap: resolvedTitle.softWrap,
          overflow: resolvedTitle.overflow,
          maxLines: resolvedTitle.maxLines,
          semanticsLabel: resolvedTitle.semanticsLabel,
          textWidthBasis: resolvedTitle.textWidthBasis,
          textHeightBehavior: resolvedTitle.textHeightBehavior,
          selectionColor: resolvedTitle.selectionColor,
        );
      }
    }

    return AppBar(
      title: resolvedTitle,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? Colors.transparent,
      elevation: elevation,
      automaticallyImplyLeading: false,
      leading: showBackButton
          ? IconButton(
              icon: Image.asset(
                'assets/voltar.png',
                height: 22,
                color: iconColor,
              ),
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            )
          : null,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
