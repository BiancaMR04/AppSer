import 'package:flutter/material.dart';

import 'package:appser/core/theme/app_colors.dart';

class HomeHeader extends StatelessWidget {
  final String userName;
  final VoidCallback onLogout;
  final VoidCallback onRefresh;

  const HomeHeader({
    super.key,
    required this.userName,
    required this.onLogout,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Seja bem vindo(a),',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark.withOpacity(0.85),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF232323),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _HeaderIconButton(
          icon: Icons.refresh,
          tooltip: 'Atualizar',
          onPressed: onRefresh,
        ),
        const SizedBox(width: 6),
        _HeaderIconButton(
          icon: Icons.logout,
          tooltip: 'Deslogar',
          onPressed: onLogout,
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(
              icon,
              size: 20,
              color: AppColors.actionGreen,
            ),
          ),
        ),
      ),
    );
  }
}
