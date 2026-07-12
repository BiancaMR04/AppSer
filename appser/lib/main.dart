import 'package:appser/services/authetication_service.dart';
import 'package:appser/stateChanges.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/app_route_observer.dart';
import 'audio/app_audio_service.dart';
import 'data/datasources/user_sessions_firestore_datasource.dart';
import 'data/datasources/password_recovery_firebase_auth_datasource.dart';
import 'data/repositories/password_recovery_repository_impl.dart';
import 'data/repositories/session_repository_impl.dart';
import 'data/datasources/user_tracking_firestore_datasource.dart';
import 'data/repositories/user_tracking_repository_impl.dart';
import 'data/datasources/pdf_progress_firestore_datasource.dart';
import 'data/datasources/pdf_storage_download_datasource.dart';
import 'data/datasources/storage_url_firebase_storage_datasource.dart';
import 'data/datasources/superuser_report_excel_datasource.dart';
import 'data/datasources/superuser_report_file_datasource.dart';
import 'data/datasources/superuser_report_firestore_datasource.dart';
import 'data/repositories/pdf_viewer_repository_impl.dart';
import 'data/repositories/storage_url_repository_impl.dart';
import 'data/repositories/superuser_report_repository_impl.dart';
import 'domain/repositories/session_repository.dart';
import 'domain/repositories/password_recovery_repository.dart';
import 'domain/repositories/user_tracking_repository.dart';
import 'domain/repositories/pdf_viewer_repository.dart';
import 'domain/repositories/storage_url_repository.dart';
import 'domain/repositories/superuser_report_repository.dart';
import 'presentation/controllers/auth_controller.dart';
import 'presentation/controllers/auth_state_controller.dart';
import 'presentation/controllers/home_controller.dart';
import 'presentation/controllers/password_recovery_controller.dart';
import 'presentation/controllers/user_tracking_controller.dart';
import 'presentation/controllers/pdf_viewer_controller.dart';
import 'presentation/controllers/storage_url_controller.dart';
import 'presentation/controllers/superuser_controller.dart';
import 'firebase_options.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'screens/user_tracking_service.dart';
import 'services/practice_notification_service.dart';
import 'services/session_unlock_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  try {
    await initAudioService();
  } catch (e) {
    // ignore: avoid_print
    print('Falha ao inicializar AudioService: $e');
  }
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AutheticationService>(
          create: (_) => AutheticationService(FirebaseAuth.instance),
        ),
        StreamProvider<User?>(
          create: (context) =>
              context.read<AutheticationService>().authStateChanges,
          initialData: null,
        ),

        // Clean Architecture (incremental): Session status da Home
        Provider<UserSessionsFirestoreDataSource>(
          create: (_) =>
              UserSessionsFirestoreDataSource(FirebaseFirestore.instance),
        ),
        Provider<SessionRepository>(
          create: (context) => SessionRepositoryImpl(
            auth: FirebaseAuth.instance,
            firestoreDataSource:
                context.read<UserSessionsFirestoreDataSource>(),
          ),
        ),
        Provider<HomeController>(
          create: (context) => HomeController(
            sessionRepository: context.read<SessionRepository>(),
          ),
        ),
        Provider<PracticeNotificationService>(
          create: (context) => PracticeNotificationService(
            homeController: context.read<HomeController>(),
          ),
        ),

        Provider<AuthController>(
          create: (context) => AuthController(
            authService: context.read<AutheticationService>(),
          ),
        ),

        Provider<AuthStateController>(
          create: (context) => AuthStateController(
            authService: context.read<AutheticationService>(),
          ),
        ),

        Provider<SessionUnlockService>(
          create: (_) => SessionUnlockService(FirebaseFirestore.instance),
        ),

        // Clean Architecture (incremental): Recuperação de senha
        Provider<PasswordRecoveryFirebaseAuthDataSource>(
          create: (_) =>
              PasswordRecoveryFirebaseAuthDataSource(FirebaseAuth.instance),
        ),
        Provider<PasswordRecoveryRepository>(
          create: (context) => PasswordRecoveryRepositoryImpl(
            dataSource: context.read<PasswordRecoveryFirebaseAuthDataSource>(),
          ),
        ),
        Provider<PasswordRecoveryController>(
          create: (context) => PasswordRecoveryController(
            repository: context.read<PasswordRecoveryRepository>(),
          ),
        ),

        // Clean Architecture (incremental): Tracking de cliques/finalizações/sessoes
        Provider<UserTrackingFirestoreDataSource>(
          create: (_) =>
              UserTrackingFirestoreDataSource(FirebaseFirestore.instance),
        ),
        Provider<UserTrackingRepository>(
          create: (context) => UserTrackingRepositoryImpl(
            auth: FirebaseAuth.instance,
            dataSource: context.read<UserTrackingFirestoreDataSource>(),
          ),
        ),
        Provider<UserTrackingController>(
          create: (context) => UserTrackingController(
            repository: context.read<UserTrackingRepository>(),
          ),
        ),

        // Clean Architecture (incremental): PDF Viewer (download + progress)
        Provider<PdfStorageDownloadDataSource>(
          create: (_) => PdfStorageDownloadDataSource(FirebaseStorage.instance),
        ),
        Provider<PdfProgressFirestoreDataSource>(
          create: (_) =>
              PdfProgressFirestoreDataSource(FirebaseFirestore.instance),
        ),
        Provider<PdfViewerRepository>(
          create: (context) => PdfViewerRepositoryImpl(
            downloadDataSource: context.read<PdfStorageDownloadDataSource>(),
            progressDataSource: context.read<PdfProgressFirestoreDataSource>(),
          ),
        ),
        Provider<PdfViewerController>(
          create: (context) => PdfViewerController(
            repository: context.read<PdfViewerRepository>(),
          ),
        ),

        // Clean Architecture (incremental): Storage URL helper (áudio/vídeo/pdf url)
        Provider<StorageUrlFirebaseStorageDataSource>(
          create: (_) =>
              StorageUrlFirebaseStorageDataSource(FirebaseStorage.instance),
        ),
        Provider<StorageUrlRepository>(
          create: (context) => StorageUrlRepositoryImpl(
            dataSource: context.read<StorageUrlFirebaseStorageDataSource>(),
          ),
        ),
        Provider<StorageUrlController>(
          create: (context) => StorageUrlController(
            repository: context.read<StorageUrlRepository>(),
          ),
        ),

        // Clean Architecture (incremental): Superuser (relatório + export)
        Provider<SuperuserReportFirestoreDataSource>(
          create: (_) =>
              SuperuserReportFirestoreDataSource(FirebaseFirestore.instance),
        ),
        Provider<SuperuserReportExcelDataSource>(
          create: (_) => SuperuserReportExcelDataSource(),
        ),
        Provider<SuperuserReportFileDataSource>(
          create: (_) => SuperuserReportFileDataSource(),
        ),
        Provider<SuperuserReportRepository>(
          create: (context) => SuperuserReportRepositoryImpl(
            firestoreDataSource:
                context.read<SuperuserReportFirestoreDataSource>(),
            excelDataSource: context.read<SuperuserReportExcelDataSource>(),
            fileDataSource: context.read<SuperuserReportFileDataSource>(),
            sheetName: 'Relatório',
          ),
        ),
        Provider<SuperuserController>(
          create: (context) => SuperuserController(
            reportRepository: context.read<SuperuserReportRepository>(),
            authService: context.read<AutheticationService>(),
          ),
        ),
      ],
      child: Builder(
        builder: (context) {
          // Bind do adapter estático para evitar Firebase direto nele.
          UserTrackingService.bind(context.read<UserTrackingController>());

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.build(),
            navigatorObservers: [appRouteObserver],
            home: const MainPage(),
          );
        },
      ),
    );
  }
}
