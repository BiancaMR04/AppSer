import 'package:appser/services/authetication_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthStateController {
  AuthStateController({required AutheticationService authService})
      : _authService = authService;

  final AutheticationService _authService;

  Stream<User?> get authStateChanges => _authService.authStateChanges;

  static const String superUserEmail = 'adminappser@gmail.com';

  // Fallback por UID (útil quando o e-mail do usuário no Auth muda,
  // ou quando há diferenças de maiúsculas/minúsculas).
  static const Set<String> superUserUids = {
    'vSOYniG70EP4eeQxuzebXc0uOIG2',
  };

  bool isSuperUser(User user) {
    if (superUserUids.contains(user.uid)) return true;
    final email = (user.email ?? '').trim().toLowerCase();
    return email == superUserEmail;
  }
}
