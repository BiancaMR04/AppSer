import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/auth/auth_error_messages.dart';
import '../core/constants/firestore_paths.dart';

class AutheticationService {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AutheticationService(this._firebaseAuth);

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<String?> registerUser({
    required String email,
    required String password,
    required String name,
    required String cpf,
  }) async {
    UserCredential? userCredential;

    try {
      userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        return AuthErrorMessages.systemFailure(AuthOperation.register);
      }

      await user.updateDisplayName(name);

      try {
        await _firestore
            .collection(FirestorePaths.usersCollection)
            .doc(user.uid)
            .set({
          'createdAt': FieldValue.serverTimestamp(),
          'session0': true,
          'session1': true,
          'session2': false,
          'session3': false,
          'session4': false,
          'session5': false,
          'session6': false,
          'session7': false,
          'session8': false,
          'nome': name,
          'cpf': cpf,
          'email': email,
        });
      } on FirebaseException catch (e) {
        try {
          await user.delete();
        } catch (_) {
          // A mensagem abaixo orienta o usuario a procurar suporte.
        }
        return AuthErrorMessages.fromFirebaseCode(
          e.code,
          operation: AuthOperation.firestoreProfile,
        );
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return AuthErrorMessages.fromFirebaseAuthCode(
        e.code,
        operation: AuthOperation.register,
      );
    } on FirebaseException catch (e) {
      return AuthErrorMessages.fromFirebaseCode(
        e.code,
        operation: AuthOperation.register,
      );
    } catch (_) {
      return AuthErrorMessages.systemFailure(AuthOperation.register);
    }
  }

  Future<String?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return AuthErrorMessages.fromFirebaseAuthCode(
        e.code,
        operation: AuthOperation.login,
      );
    } on FirebaseException catch (e) {
      return AuthErrorMessages.fromFirebaseCode(
        e.code,
        operation: AuthOperation.login,
      );
    } catch (_) {
      return AuthErrorMessages.systemFailure(AuthOperation.login);
    }
  }

  Future<void> logout() {
    return _firebaseAuth.signOut();
  }

  Future<String?> resetPassword({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return AuthErrorMessages.fromFirebaseAuthCode(
        e.code,
        operation: AuthOperation.passwordRecovery,
      );
    } on FirebaseException catch (e) {
      return AuthErrorMessages.fromFirebaseCode(
        e.code,
        operation: AuthOperation.passwordRecovery,
      );
    } catch (_) {
      return AuthErrorMessages.systemFailure(AuthOperation.passwordRecovery);
    }
  }
}
