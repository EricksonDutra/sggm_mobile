import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:sggm/controllers/auth_controller.dart';
import 'package:sggm/controllers/escalas_controller.dart';
import 'package:sggm/controllers/eventos_controller.dart';
import 'package:sggm/controllers/instrumentos_controller.dart';
import 'package:sggm/controllers/musicas_controller.dart';
import 'package:sggm/controllers/musicos_controller.dart';
import 'package:sggm/services/notification_service.dart';
import 'package:sggm/services/secure_token_service.dart';
import 'package:sggm/services/token_migration_service.dart';
import 'package:sggm/util/app_logger.dart';
import 'package:sggm/views/login_page.dart';
import 'package:sggm/home_page.dart';
import 'package:sggm/theme/app_theme.dart';
import 'package:sggm/views/debug/biometric_test_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final secureTokenService = SecureTokenService();
  await TokenMigrationService(secureTokenService).migrateIfNeeded();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AppLogger.info('Firebase inicializado com sucesso');

    await NotificationService().initialize();
    AppLogger.info('Serviço de notificações inicializado');
  } catch (e, stackTrace) {
    AppLogger.error('Erro ao inicializar Firebase/Notificações', e, stackTrace);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SecureTokenService>(
          create: (_) => SecureTokenService(),
        ),
        ChangeNotifierProvider(
          create: (context) {
            final authProvider = AuthProvider(
              secureTokenService: context.read<SecureTokenService>(),
            );

            authProvider.loadSavedAuth();

            NotificationService().onTokenRefresh((newToken) {
              AppLogger.debug('Token FCM atualizado pelo Firebase');
              if (authProvider.isAuthenticated) {
                authProvider.reenviarFCMToken();
              }
            });

            return authProvider;
          },
        ),
        ChangeNotifierProvider(create: (_) => EventoProvider()),
        ChangeNotifierProvider(create: (_) => EscalasProvider()),
        ChangeNotifierProvider(create: (_) => MusicosProvider()),
        ChangeNotifierProvider(create: (_) => InstrumentosProvider()),
        ChangeNotifierProvider(create: (_) => MusicasProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp(
            title: 'SGGM',
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('pt', 'BR'),
              Locale('en', 'US'),
            ],
            locale: const Locale('pt', 'BR'),
            theme: AppTheme.darkTheme,
            initialRoute: authProvider.isAuthenticated ? '/home' : '/',
            routes: {
              '/': (context) => const LoginPage(),
              '/home': (context) => const HomePage(),
              '/biometric_test': (context) => const BiometricTestPage(),
            },
          );
        },
      ),
    );
  }
}
