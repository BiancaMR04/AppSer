import '../../domain/repositories/password_recovery_repository.dart';

class PasswordRecoveryController {
  PasswordRecoveryController({required PasswordRecoveryRepository repository})
      : _repository = repository;

  final PasswordRecoveryRepository _repository;

  Future<void> sendPasswordResetEmail({required String email}) {
    return _repository.sendPasswordResetEmail(email: email);
  }
}
