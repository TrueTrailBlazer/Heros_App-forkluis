import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';

import '../../services/auth_service.dart';
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
    _verificarAuth();
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
          // Se o usuário cancelar a digital, desloga por segurança
          await FirebaseAuth.instance.signOut();
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
      
      if (doc.exists) {
        authService.usuarioAtual = UsuarioAtual(
          id: user.uid,
          nome: doc['nome'] ?? 'Usuário',
          role: doc['role'] ?? 'barbeiro',
        );
        
        if (authService.usuarioAtual?.role == 'admin') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BarbeiroHomeScreen()));
        }
      } else {
        // Se for o chefão que não está na coleção
        authService.usuarioAtual = UsuarioAtual(id: user.uid, nome: 'Admin', role: 'admin');
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
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