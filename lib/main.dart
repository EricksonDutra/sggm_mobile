import 'package:flutter/foundation.dart' show kIsWeb; // ✅ adicionado
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:sggm/controllers/auth_controller.dart';
import 'package:sggm/controllers/comentarios_controller.dart';
import 'package:sggm/controllers/escalas_controller.dart';
import 'package:sggm/controllers/eventos_controller.dart';
import 'package:sggm/controllers/instrumentos_controller.dart';
import 'package:sggm/controllers/musicas_controller.dart';
import 'package:sggm/controllers/musicos_controller.dart';
import 'package:sggm/services/musicas_service.dart';
import 'package:sggm/services/notification_service.dart';
import 'package:sggm/services/secure_token_service.dart';
import 'package:sggm/services/token_migration_service.dart';
import 'package:sggm/util/app_logger.dart';
import 'package:sggm/util/navigation_service.dart';
import 'package:sggm/views/evento_detalhes_loader_page.dart';
import 'package:sggm/views/login_page.dart';
import 'package:sggm/views/home_page.dart';
import 'package:sggm/theme/app_theme.dart';
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

  runApp(MyApp(secureTokenService: secureTokenService));
}

class MyApp extends StatelessWidget {
  final SecureTokenService secureTokenService;

  const MyApp({super.key, required this.secureTokenService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SecureTokenService>.value(
          value: secureTokenService,
        ),
        ChangeNotifierProvider(
          create: (context) {
            final authProvider = AuthProvider(
              secureTokenService: context.read<SecureTokenService>(),
            );

            authProvider.loadSavedAuth();

            // ✅ onTokenRefresh só registrado em mobile
            // Na web, FirebaseMessaging não está totalmente inicializado
            // neste ponto e causaria crash com FirebaseException
            if (!kIsWeb) {
              NotificationService().onTokenRefresh((newToken) {
                AppLogger.debug('Token FCM atualizado pelo Firebase');
                if (authProvider.isAuthenticated) {
                  authProvider.reenviarFCMToken();
                }
              });
            }

            return authProvider;
          },
        ),
        ChangeNotifierProvider(create: (_) => EventoProvider()),
        ChangeNotifierProvider(create: (_) => EscalasProvider()),
        ChangeNotifierProvider(create: (_) => MusicosProvider()),
        ChangeNotifierProvider(create: (_) => InstrumentosProvider()),
        ChangeNotifierProvider(create: (_) => MusicasProvider()),
        ChangeNotifierProvider(create: (_) => ComentariosProvider()),
        Provider(create: (_) => MusicasService()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp(
            navigatorKey: NavigationService.navigatorKey,
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
              '/evento_detalhes': (context) {
                final eventoId = ModalRoute.of(context)!.settings.arguments as String;
                return EventoDetalhesLoaderPage(eventoId: eventoId);
              },
            },
          );
        },
      ),
    );
  }
}
