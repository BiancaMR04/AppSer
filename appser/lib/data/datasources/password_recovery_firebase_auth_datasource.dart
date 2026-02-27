import 'package:firebase_auth/firebase_auth.dart';

class PasswordRecoveryFirebaseAuthDataSource {
  PasswordRecoveryFirebaseAuthDataSource(this._auth);

  final FirebaseAuth _auth;

  Future<void> sendPasswordResetEmail({required String email}) {
    return _auth.sendPasswordResetEmail(email: email);
  }
}
