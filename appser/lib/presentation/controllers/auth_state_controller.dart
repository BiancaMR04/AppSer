import 'package:appser/services/authetication_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthStateController {
  AuthStateController({required AutheticationService authService})
      : _authService = authService;

  final AutheticationService _authService;

  Stream<User?> get authStateChanges => _authService.authStateChanges;

  static const String superUserEmail = 'adminappser@gmail.com';

  bool isSuperUser(User user) => user.email == superUserEmail;
}
