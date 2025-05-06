import 'package:appser/screens/authentication.dart';
import 'package:appser/screens/home.dart';
import 'package:appser/superuser/dashboardsuperuser.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MainPage extends StatelessWidget {
  const MainPage({Key? key}): super(key: key);
  static const String superUserEmail = 'adminappser@gmail.com';

@override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData) {
            final user = snapshot.data!;
            if (user.email == superUserEmail) {
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