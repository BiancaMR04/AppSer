import 'package:firebase_auth/firebase_auth.dart';

class AutheticationService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<String?>registerUser({
    required String email,
    required String password,
    required String name,
  }) async {
    try{
    UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await userCredential.user!.updateDisplayName(name);
    return null;
  } on FirebaseAuthException catch (e) {
    if(e.code == "email-already-in-use") {
      return "O usuário já está cadastrado!";
    }

    return "Erro ao cadastrar usuário! Chame o suporte pelo Whatsapp!";
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
      if (e.code == "user-not-found") {
        return "Usuário não encontrado!";
      } else if (e.code == "wrong-password") {
        return "Senha incorreta!";
      }

      return "Erro ao logar usuário! Chame o suporte por esse link: !";
    }
  }

  Future<void> logout() async {
    return _firebaseAuth.signOut();
  }
}