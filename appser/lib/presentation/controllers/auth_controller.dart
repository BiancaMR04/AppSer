import '../../services/authetication_service.dart';

class AuthController {
  final AutheticationService _authService;

  AuthController({required AutheticationService authService})
      : _authService = authService;

  Future<String?> login({required String email, required String password}) {
    return _authService.loginUser(email: email, password: password);
  }

  Future<String?> register({
    required String email,
    required String password,
    required String name,
    required String cpf,
  }) {
    return _authService.registerUser(
      email: email,
      password: password,
      name: name,
      cpf: cpf,
    );
  }

  Future<String?> resetPassword({required String email}) {
    return _authService.resetPassword(email: email);
  }

  Future<void> logout() {
    return _authService.logout();
  }
}
