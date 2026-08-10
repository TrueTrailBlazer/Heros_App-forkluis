import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/usuario_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UsuarioModel? usuarioAtual;
  bool isLoading = false;

  Future<String?> login(String email, String password) async {
    try {
      isLoading = true;
      notifyListeners();

      UserCredential cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      
      DocumentSnapshot doc = await _firestore.collection('usuarios').doc(cred.user!.uid).get();
      
      if (doc.exists) {
        usuarioAtual = UsuarioModel.fromDoc(doc);

        if (!usuarioAtual!.ativo) {
          await _auth.signOut();
          isLoading = false;
          notifyListeners();
          return "Sua conta foi desativada. Fale com a gerência.";
        }
      } else {
        var checkAdmin = await _firestore.collection('usuarios').limit(1).get();
        
        if (checkAdmin.docs.isEmpty) {
          usuarioAtual = UsuarioModel(id: cred.user!.uid, nome: 'Admin', role: 'admin', ativo: true);
          await _firestore.collection('usuarios').doc(cred.user!.uid).set(usuarioAtual!.toMap());
        } else {
          await _auth.signOut();
          isLoading = false;
          notifyListeners();
          return "Conta inválida ou desativada no sistema.";
        }
      }

      isLoading = false;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      isLoading = false;
      notifyListeners();
      return e.message; 
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    usuarioAtual = null;
    notifyListeners();
  }
}
