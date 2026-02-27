import 'package:flutter/material.dart';

import 'package:appser/core/theme/app_colors.dart';

class HomeTopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onLogout;
  final VoidCallback onRefresh;

  const HomeTopAppBar({
    super.key,
    required this.onLogout,
    required this.onRefresh,
  });

  @override
  Size get preferredSize => const Size.fromHeight(50);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: AppColors.actionGreen),
          onPressed: onLogout,
          tooltip: 'Sair',
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: AppColors.actionGreen),
          onPressed: onRefresh,
          tooltip: 'Atualizar Sessões',
        ),
      ],
    );
  }
}
