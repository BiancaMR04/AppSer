import 'dart:async';

import 'package:appser/screens/authentication.dart';
import 'package:appser/screens/home.dart';
import 'package:appser/superuser/dashboardsuperuser.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'presentation/controllers/auth_state_controller.dart';
import 'services/practice_notification_service.dart';
import 'services/session_unlock_service.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  String? _lastProcessedUid;
  User? _currentUser;
  bool _currentUserIsSuperUser = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;

    final user = _currentUser;
    if (user == null) return;

    unawaited(_syncSessionUnlocksAndNotifications(
      user: user,
      isSuperUser: _currentUserIsSuperUser,
    ));
  }

  Future<void> _syncSessionUnlocksAndNotifications({
    required User user,
    required bool isSuperUser,
  }) async {
    if (!mounted) return;

    final sessionUnlockService = context.read<SessionUnlockService>();
    final notificationService = context.read<PracticeNotificationService>();

    await sessionUnlockService.ensureSessionUnlocks(uid: user.uid);

    if (isSuperUser) {
      await notificationService.cancelDailyReminder();
      return;
    }

    await notificationService.requestPermissionAndScheduleDailyReminder();
  }

  @override
  Widget build(BuildContext context) {
    final authStateController = context.read<AuthStateController>();
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: authStateController.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            final user = snapshot.data!;
            final isSuperUser = authStateController.isSuperUser(user);
            _currentUser = user;
            _currentUserIsSuperUser = isSuperUser;

            if (_lastProcessedUid != user.uid) {
              _lastProcessedUid = user.uid;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                unawaited(
                  _syncSessionUnlocksAndNotifications(
                    user: user,
                    isSuperUser: isSuperUser,
                  ),
                );
              });
            }

            if (isSuperUser) {
              return const SuperuserDashboard();
            }

            return const Home();
          }

          if (_lastProcessedUid != null) {
            _lastProcessedUid = null;
            _currentUser = null;
            _currentUserIsSuperUser = false;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              unawaited(
                context
                    .read<PracticeNotificationService>()
                    .cancelDailyReminder(),
              );
            });
          }

          return const Authentication();
        },
      ),
    );
  }
}
