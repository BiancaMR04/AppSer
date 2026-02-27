import '../../domain/repositories/password_recovery_repository.dart';
import '../datasources/password_recovery_firebase_auth_datasource.dart';

class PasswordRecoveryRepositoryImpl implements PasswordRecoveryRepository {
  PasswordRecoveryRepositoryImpl({required this.dataSource});

  final PasswordRecoveryFirebaseAuthDataSource dataSource;

  @override
  Future<void> sendPasswordResetEmail({required String email}) {
    return dataSource.sendPasswordResetEmail(email: email);
  }
}
