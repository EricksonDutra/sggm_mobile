import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sggm/controllers/escalas_controller.dart';
import 'package:sggm/controllers/eventos_controller.dart';
import 'package:sggm/controllers/musicos_controller.dart';
import 'package:sggm/controllers/instrumentos_controller.dart';
import 'package:sggm/controllers/musicas_controller.dart';
import 'package:sggm/controllers/auth_controller.dart';
import 'package:sggm/home_page.dart';
import 'package:sggm/views/login_page.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EventoProvider()),
        ChangeNotifierProvider(create: (_) => EscalasProvider()),
        ChangeNotifierProvider(create: (_) => MusicosProvider()),
        ChangeNotifierProvider(create: (_) => InstrumentosProvider()),
        ChangeNotifierProvider(create: (_) => MusicasProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return MaterialApp(
          title: 'Eventos App',
          // home: const HomePage(),
          home: auth.isAuthenticated
              ? const HomePage()
              : FutureBuilder(
                  future: auth.tryAutoLogin(),
                  builder: (ctx, snapshot) => auth.isAuthenticated ? const HomePage() : const LoginPage(),
                ),
          debugShowCheckedModeBanner: false,
          themeMode: ThemeMode.dark,
          theme: ThemeData.dark(useMaterial3: true),
        );
      },
    );
  }
}
