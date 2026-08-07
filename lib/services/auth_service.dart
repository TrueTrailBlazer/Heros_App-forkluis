import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UsuarioAtual {
  final String id;
  final String nome;
  final String role;

  UsuarioAtual({required this.id, required this.nome, required this.role});
}

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UsuarioAtual? usuarioAtual;
  bool isLoading = false;

  Future<String?> login(String email, String password) async {
    try {
      isLoading = true;
      notifyListeners();

      UserCredential cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      
      // Busca se é admin ou barbeiro
      DocumentSnapshot doc = await _firestore.collection('usuarios').doc(cred.user!.uid).get();
      
      if (doc.exists) {
        usuarioAtual = UsuarioAtual(
          id: cred.user!.uid,
          nome: doc['nome'] ?? 'Usuário',
          role: doc['role'] ?? 'barbeiro',
        );
      } else {
        // Se não tiver documento, assume que o criador é admin
        usuarioAtual = UsuarioAtual(id: cred.user!.uid, nome: 'Admin', role: 'admin');
      }

      isLoading = false;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      isLoading = false;
      notifyListeners();
      return e.message; // Retorna o erro pro app mostrar
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    usuarioAtual = null;
    notifyListeners();
  }
}