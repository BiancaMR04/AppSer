import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

enum AuthOperation {
  login,
  register,
  passwordRecovery,
  firestoreProfile,
}

class AuthFieldErrors {
  final bool name;
  final bool cpf;
  final bool email;
  final bool password;
  final bool confirmPassword;

  const AuthFieldErrors({
    this.name = false,
    this.cpf = false,
    this.email = false,
    this.password = false,
    this.confirmPassword = false,
  });
}

class AuthErrorMessages {
  static final RegExp emailRegex = RegExp(
    r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$',
    caseSensitive: false,
  );

  static bool isValidEmail(String email) {
    return emailRegex.hasMatch(email.trim());
  }

  static String fromException(
    Object error, {
    required AuthOperation operation,
  }) {
    if (error is FirebaseAuthException) {
      return fromFirebaseAuthCode(error.code, operation: operation);
    }

    if (error is FirebaseException) {
      return fromFirebaseCode(error.code, operation: operation);
    }

    return systemFailure(operation);
  }

  static String fromFirebaseAuthCode(
    String code, {
    required AuthOperation operation,
  }) {
    switch (code) {
      case 'invalid-email':
        return 'E-mail invalido. Confira o formato e tente novamente.';
      case 'missing-email':
        return 'Informe seu e-mail.';
      case 'missing-password':
        return 'Informe sua senha.';
      case 'weak-password':
        return 'A senha e muito fraca. Use pelo menos 6 caracteres.';
      case 'email-already-in-use':
        return 'Este e-mail ja esta cadastrado. Tente entrar ou recuperar a senha.';
      case 'user-not-found':
        return operation == AuthOperation.passwordRecovery
            ? 'Nao encontramos uma conta com este e-mail.'
            : 'Nao encontramos uma conta com este e-mail.';
      case 'wrong-password':
        return 'Senha incorreta. Confira e tente novamente.';
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'E-mail ou senha incorretos. Confira os dados e tente novamente.';
      case 'user-disabled':
        return 'Esta conta foi desativada. Entre em contato com o suporte.';
      case 'too-many-requests':
        return 'Muitas tentativas em pouco tempo. Aguarde alguns minutos e tente novamente.';
      case 'operation-not-allowed':
        return 'Login por e-mail e senha nao esta habilitado no sistema. Entre em contato com o suporte.';
      case 'network-request-failed':
        return 'Falha de conexao. Verifique sua internet e tente novamente.';
      case 'requires-recent-login':
        return 'Por seguranca, entre novamente e tente de novo.';
      case 'account-exists-with-different-credential':
        return 'Ja existe uma conta com este e-mail usando outro metodo de acesso.';
      case 'credential-already-in-use':
        return 'Estes dados de acesso ja estao vinculados a outra conta.';
      case 'invalid-action-code':
      case 'expired-action-code':
        return 'O link de recuperacao expirou ou e invalido. Solicite um novo link.';
      case 'quota-exceeded':
        return 'O limite de envios foi atingido no momento. Tente novamente mais tarde.';
      case 'app-not-authorized':
      case 'invalid-api-key':
      case 'app-not-installed':
        return 'Erro de configuracao do app. Entre em contato com o suporte.';
      case 'internal-error':
      case 'web-storage-unsupported':
        return systemFailure(operation);
      default:
        return systemFailure(operation);
    }
  }

  static String fromFirebaseCode(
    String code, {
    required AuthOperation operation,
  }) {
    switch (code) {
      case 'permission-denied':
        return 'Nao foi possivel salvar os dados por permissao do sistema. Entre em contato com o suporte.';
      case 'unavailable':
      case 'deadline-exceeded':
        return 'O sistema esta temporariamente indisponivel. Tente novamente em instantes.';
      case 'resource-exhausted':
        return 'O sistema esta com muitas requisicoes no momento. Tente novamente mais tarde.';
      case 'not-found':
        return operation == AuthOperation.passwordRecovery
            ? 'Nao encontramos uma conta com este e-mail.'
            : systemFailure(operation);
      case 'cancelled':
        return 'Operacao cancelada. Tente novamente.';
      default:
        return systemFailure(operation);
    }
  }

  static String systemFailure(AuthOperation operation) {
    switch (operation) {
      case AuthOperation.login:
        return 'Nao foi possivel entrar agora. Verifique sua conexao e tente novamente.';
      case AuthOperation.register:
        return 'Nao foi possivel concluir o cadastro agora. Tente novamente em instantes.';
      case AuthOperation.passwordRecovery:
        return 'Nao foi possivel enviar o e-mail de recuperacao agora. Tente novamente em instantes.';
      case AuthOperation.firestoreProfile:
        return 'Sua conta foi criada, mas houve erro ao salvar seu perfil. Entre em contato com o suporte.';
    }
  }

  static AuthFieldErrors fieldsFor(String message) {
    final lower = message.toLowerCase();
    return AuthFieldErrors(
      email: lower.contains('e-mail') || lower.contains('email'),
      password: lower.contains('senha'),
      confirmPassword: lower.contains('senhas nao conferem') ||
          lower.contains('senhas n\u00E3o conferem'),
    );
  }
}
