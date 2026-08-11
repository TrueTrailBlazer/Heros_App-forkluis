import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';

import '../../services/auth_service.dart';
import '../../models/usuario_model.dart';
import 'auth/login_screen.dart';
import 'admin/admin_dashboard_screen.dart';
import 'barbeiro/barbeiro_home_screen.dart';

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarAuth();
    });
  }

  Future<void> _verificarAuth() async {
    User? user = FirebaseAuth.instance.currentUser;

    // Se não tem ninguém salvo no Firebase, manda pro Login para digitar e-mail e senha
    if (user == null) {
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    // Se tem login salvo, pede a Digital ou Facial!
    try {
      bool canCheckBiometrics = await _localAuth.canCheckBiometrics;

      if (canCheckBiometrics) {
        // Chamada simplificada e 100% compatível com a sua versão
        bool didAuthenticate = await _localAuth.authenticate(
          localizedReason: 'Toque no sensor para acessar o Heros\'app',
        );

        if (didAuthenticate) {
          _entrarNoApp(user);
        } else {
          // Se o usuário cancelar a digital, redireciona para o login sem deslogar
          if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
        }
      } else {
        // Se o celular for antigo e não tiver digital, entra direto
        _entrarNoApp(user);
      }
    } catch (e) {
      // Em caso de erro do sensor, entra com a sessão salva
      _entrarNoApp(user);
    }
  }

  Future<void> _entrarNoApp(User user) async {
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
    
    if (mounted) {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      if (!doc.exists) {
        // Se não tem documento, desloga
        await FirebaseAuth.instance.signOut();
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
        return;
      }

      authService.usuarioAtual = UsuarioModel.fromDoc(doc);

      if (!authService.usuarioAtual!.ativo) {
        await FirebaseAuth.instance.signOut();
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
        return;
      }
      
      if (authService.usuarioAtual?.role == 'admin') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BarbeiroHomeScreen()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black, // Fundo escuro premium
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fingerprint, size: 90, color: Colors.white),
            SizedBox(height: 25),
            Text('Verificando Segurança...', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
