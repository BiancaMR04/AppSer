import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:appser/presentation/widgets/app_background.dart';
import 'package:appser/presentation/widgets/app_elevated_row_button.dart';
import 'package:appser/presentation/widgets/app_scaffold.dart';
import 'package:appser/stateChanges.dart';

import '../presentation/controllers/superuser_controller.dart';
import 'superuser_groups_screen.dart';
import 'superuser_participants_screen.dart';

class SuperuserDashboard extends StatefulWidget {
  const SuperuserDashboard({super.key});

  @override
  State<SuperuserDashboard> createState() => _SuperuserDashboardState();
}

class _SuperuserDashboardState extends State<SuperuserDashboard> {
  Future<T> _runWithLoading<T>({
    required String message,
    required Future<T> Function() action,
  }) async {
    if (!mounted) return action();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _BlockingLoadingDialog(message: message),
    );

    try {
      return await action();
    } finally {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _logoutAndGoToLogin() async {
    try {
      await context.read<SuperuserController>().logout();
    } catch (_) {
      // best-effort
    }

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainPage()),
      (route) => false,
    );
  }

  Future<void> _exportExcel() async {
    try {
      final path = await _runWithLoading<String>(
        message: 'Gerando Excel...',
        action: () => context.read<SuperuserController>().exportarParaExcel(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Excel gerado. Arquivo: $path')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível exportar o Excel.')),
      );
    }
  }

  Future<void> _exportCsv() async {
    try {
      final path = await _runWithLoading<String>(
        message: 'Gerando CSV...',
        action: () => context.read<SuperuserController>().exportarParaCsv(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV gerado. Arquivo: $path')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível exportar o CSV.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth < 380 ? 16.0 : 24.0;

    const primaryButtonColor = Color(0xFF60BFCD);
    const accent = Color(0xFF10707E);

    return AppScaffold(
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Painel do Administrador',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF202020),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _logoutAndGoToLogin,
                      icon: const Icon(
                        Icons.logout,
                        color: Color(0xFF2F7888),
                      ),
                      tooltip: 'Sair',
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Container(
                  constraints: const BoxConstraints(minHeight: 210),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    image: const DecorationImage(
                      image: AssetImage('assets/back.png'),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 380;
                      final logoHeight = isNarrow ? 96.0 : 112.0;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/logo.png',
                                height: logoHeight,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Área administrativa\nMBRP',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF202020),
                                    height: 1.15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Gerencie grupos e participantes e exporte relatórios.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.black.withOpacity(0.62),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _exportExcel,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: accent,
                                    side: BorderSide(
                                      color: accent.withOpacity(0.55),
                                    ),
                                    backgroundColor: Colors.white,
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 11),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  child: const Text('Exportar Excel'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _exportCsv,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: accent,
                                    side: BorderSide(
                                      color: accent.withOpacity(0.55),
                                    ),
                                    backgroundColor: Colors.white,
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 11),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  child: const Text('Exportar CSV'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                AppElevatedRowButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SuperuserGroupsScreen(),
                      ),
                    );
                  },
                  icon: Icons.groups,
                  iconColor: Colors.white,
                  title: 'Grupos',
                  titleStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  backgroundColor: primaryButtonColor,
                  borderRadius: 16,
                  elevation: 2,
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                  ),
                ),
                AppElevatedRowButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SuperuserParticipantsScreen(),
                      ),
                    );
                  },
                  icon: Icons.people_alt,
                  iconColor: Colors.white,
                  title: 'Participantes',
                  titleStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  backgroundColor: primaryButtonColor,
                  borderRadius: 16,
                  elevation: 2,
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BlockingLoadingDialog extends StatelessWidget {
  const _BlockingLoadingDialog({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.6),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
