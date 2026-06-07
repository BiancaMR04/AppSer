import 'package:firebase_auth/firebase_auth.dart';

import '../../core/auth/auth_error_messages.dart';

class PasswordRecoveryFirebaseAuthDataSource {
  PasswordRecoveryFirebaseAuthDataSource(this._auth);

  final FirebaseAuth _auth;

  Future<void> sendPasswordResetEmail({required String email}) async {
    final trimmedEmail = email.trim();

    if (!AuthErrorMessages.isValidEmail(trimmedEmail)) {
      throw FirebaseAuthException(code: 'invalid-email');
    }

    final methods = await _auth.fetchSignInMethodsForEmail(trimmedEmail);
    if (methods.isEmpty) {
      throw FirebaseAuthException(code: 'user-not-found');
    }

    return _auth.sendPasswordResetEmail(email: trimmedEmail);
  }
}
