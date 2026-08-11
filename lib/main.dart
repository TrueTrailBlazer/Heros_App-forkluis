import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:heros_b/screens/auth_check.dart';
import 'package:provider/provider.dart';

// Importe os caminhos corretos de acordo com as pastas do seu projeto
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'controllers/admin_controller.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider<DatabaseService>(create: (_) => DatabaseService()),
        ChangeNotifierProxyProvider<DatabaseService, AdminController>(
          create: (ctx) => AdminController(Provider.of<DatabaseService>(ctx, listen: false)),
          update: (ctx, db, prev) => prev ?? AdminController(db),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hé/Os Barbearia',

      // --- NOVO TEMA STITCH (MINIMALISTA) ---
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5), // bg-surface-background
        primaryColor: const Color(0xFF0047AB), // primary-container (Azul Cobalto)
        
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1B1B1B), // bg-on-surface
          foregroundColor: Colors.white,
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.01),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B1B1B),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF9F9F9),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0047AB), width: 1.5)),
          labelStyle: const TextStyle(color: Color(0xFF737784)),
        ),

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0047AB),
          primary: const Color(0xFF0047AB),
          secondary: const Color(0xFF1B1B1B),
          surface: const Color(0xFFF5F5F5),
          onSurface: const Color(0xFF1B1B1B),
          error: const Color(0xFFBA1A1A),
        ),
        
        dividerTheme: const DividerThemeData(
          color: Color(0xFFE0E0E0),
          thickness: 1,
          space: 1,
        ),
      ),

      // Tela inicial que verifica se está logado
      home: const AuthCheck(),
    );
  }
}

