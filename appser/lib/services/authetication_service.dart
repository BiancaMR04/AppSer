import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    try {
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Atualiza o nome do usuário
      await userCredential.user!.updateDisplayName(name);

      // Cria o documento no Firestore para o usuário
      await _firestore
          .collection(FirestorePaths.usersCollection)
          .doc(userCredential.user!.uid)
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
        // Outros dados iniciais podem ser incluídos aqui
      });

      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'Este e-mail já está cadastrado.';
        case 'invalid-email':
          return 'E-mail inválido.';
        case 'weak-password':
          return 'A senha é muito fraca. Use pelo menos 6 caracteres.';
        default:
          return 'Erro inesperado: ${e.message}\nEntre em contato com o suporte.';
      }
    } catch (e) {
      return 'Erro desconhecido: $e\nEntre em contato com o suporte.';
    }
  }

  Future<String?> loginUser(
    {
    required String email,
    required String password,
  }) async {
   try {
      await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          return 'Formato de e-mail inválido.';
        case 'user-disabled':
          return 'Conta desativada. Entre em contato com o suporte.';
        case 'user-not-found':
          return 'Usuário não encontrado.';
        case 'wrong-password':
          return 'Senha incorreta.';
        default:
          return 'Erro inesperado: ${e.message}\nEntre em contato com o suporte.';
      }
    } catch (e) {
      return 'Erro desconhecido: $e\nEntre em contato com o suporte.';
    }
  }

  Future<void> logout() async {
    return _firebaseAuth.signOut();
  }
  Future<String?> resetPassword({required String email}) async {
  try {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
    return null;
  } on FirebaseAuthException catch (e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Nenhuma conta encontrada com este e-mail.';
      case 'invalid-email':
        return 'E-mail inválido.';
      default:
        return 'Erro ao enviar e-mail de recuperação: ${e.message}';
    }
  } catch (e) {
    return 'Erro inesperado: $e';
  }
}

}
