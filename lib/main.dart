import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:sggm/controllers/auth_controller.dart';
import 'package:sggm/controllers/escalas_controller.dart';
import 'package:sggm/controllers/eventos_controller.dart';
import 'package:sggm/controllers/instrumentos_controller.dart';
import 'package:sggm/controllers/musicas_controller.dart';
import 'package:sggm/controllers/musicos_controller.dart';
import 'package:sggm/services/notification_service.dart';
import 'package:sggm/services/secure_token_service.dart';
import 'package:sggm/services/token_migration_service.dart';
import 'package:sggm/views/login_page.dart';
import 'package:sggm/home_page.dart';
import 'firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sggm/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔐 Executar migração se necessário
  final secureTokenService = SecureTokenService();
  final migrationService = TokenMigrationService(secureTokenService);
  await migrationService.migrateIfNeeded();

  try {
    // Inicializar Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase inicializado com sucesso');

    // Inicializar serviço de notificações
    await NotificationService().initialize();
    print('✅ Serviço de notificações inicializado');
  } catch (e, stackTrace) {
    print('❌ Erro ao inicializar Firebase/Notificações: $e');
    print('StackTrace: $stackTrace');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 🔐 Provider de serviço seguro de token
        Provider<SecureTokenService>(
          create: (_) => SecureTokenService(),
        ),

        // 🔐 Provider de autenticação
        ChangeNotifierProvider(
          create: (context) {
            final secureTokenService = context.read<SecureTokenService>();
            final authProvider = AuthProvider(
              secureTokenService: secureTokenService,
            );

            // ✅ Carregar autenticação salva de forma assíncrona
            authProvider.loadSavedAuth();

            // ✅ Configurar listener APENAS para refresh
            // (não tenta enviar na inicialização)
            NotificationService().onTokenRefresh((newToken) {
              print('🔄 Token FCM foi atualizado pelo Firebase');
              // Só reenvia se já estiver autenticado
              if (authProvider.isAuthenticated) {
                authProvider.reenviarFCMToken();
              }
            });

            return authProvider;
          },
        ),

        // Providers dos demais controllers
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
              Locale('pt', 'BR'), // Português do Brasil
              Locale('en', 'US'), // Inglês (fallback)
            ],
            locale: const Locale('pt', 'BR'),
            theme: AppTheme.darkTheme,
            // ✅ Navegação corrigida com base na autenticação
            routes: {
              '/': (context) => const LoginPage(),
              '/home': (context) => const HomePage(),
            },
            // ✅ Usar initialRoute baseado na autenticação
            initialRoute: authProvider.isAuthenticated ? '/home' : '/',
          );
        },
      ),
    );
  }
}
