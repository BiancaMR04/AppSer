import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
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
      if (e.code == "email-already-in-use") {
        return "O usuário já está cadastrado!";
      }
      return "Erro ao cadastrar usuário! Chame o suporte pelo Whatsapp!";
    }
  }

  Future<String?> loginUser(
    {
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
      if (e.code == "user-not-found") {
        return "Usuário não encontrado!";
      } else if (e.code == "wrong-password") {
        return "Senha incorreta!";
      }
      return "E-mail ou senha incorretos";
    }
  }

  Future<void> logout() async {
    return _firebaseAuth.signOut();
  }
}
