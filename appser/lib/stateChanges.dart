import 'package:appser/screens/authentication.dart';
import 'package:appser/screens/home.dart';
import 'package:appser/superuser/dashboardsuperuser.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'presentation/controllers/auth_state_controller.dart';
import 'services/session_unlock_service.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String? _lastProcessedUid;

  @override
  Widget build(BuildContext context) {
    final authStateController = context.read<AuthStateController>();
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: authStateController.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData) {
            final user = snapshot.data!;

            if (_lastProcessedUid != user.uid) {
              _lastProcessedUid = user.uid;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                // Best-effort: não bloqueia UI.
                context
                    .read<SessionUnlockService>()
                    .ensureSessionUnlocks(uid: user.uid);
              });
            }

            if (authStateController.isSuperUser(user)) {
              return const SuperuserDashboard();
            } else {
              return const Home();
            }
          } else {
            return const Authentication();
          }
        },
      ),
    );
  }
}