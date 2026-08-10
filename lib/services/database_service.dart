import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/usuario_model.dart';
import '../models/servico_model.dart';
import '../models/corte_model.dart';
import '../models/despesa_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- CORTES E VENDAS ---
  Future<void> registrarCorte({
    required String barbeiroNome,
    required String barbeiroId,
    required List<String> servicosFeitos,
    required double valorTotal,
    required double comissaoProdutos,
    required String formaPagamento,
  }) async {
    await _firestore.collection('cortes').add({
      'barbeiroNome': barbeiroNome,
      'barbeiroId': barbeiroId,
      'servicos': servicosFeitos, 
      'valor': valorTotal,
      'comissaoProdutos': comissaoProdutos,
      'formaPagamento': formaPagamento,
      'data': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<CorteModel>> getTodosOsCortes() {
    return _firestore
        .collection('cortes')
        .orderBy('data', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => CorteModel.fromDoc(doc)).toList());
  }

  // --- SERVIÇOS E PRODUTOS ---
  Stream<List<ServicoModel>> getServicos() {
    return _firestore
        .collection('servicos')
        .orderBy('nome')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => ServicoModel.fromDoc(doc)).toList());
  }

  Future<void> addServico(String nome, double preco, double comissao) async {
    await _firestore.collection('servicos').add({'nome': nome, 'preco': preco, 'comissao': comissao});
  }

  Future<void> updateServico(String id, String nome, double preco, double comissao) async {
    await _firestore.collection('servicos').doc(id).update({'nome': nome, 'preco': preco, 'comissao': comissao});
  }

  Future<void> deleteServico(String id) async {
    await _firestore.collection('servicos').doc(id).delete();
  }

  // --- DESPESAS E VALES ---
  Future<void> registrarDespesaVale(String tipo, String descricao, double valor) async {
    await _firestore.collection('despesas').add({
      'tipo': tipo, 
      'descricao': descricao,
      'valor': valor,
      'data': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<DespesaModel>> getDespesasEVales() {
    return _firestore
        .collection('despesas')
        .orderBy('data', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => DespesaModel.fromDoc(doc)).toList());
  }

  // --- EQUIPE & PAGAMENTOS ---
  Stream<List<UsuarioModel>> getBarbeiros() {
    return _firestore
        .collection('usuarios')
        .where('role', isEqualTo: 'barbeiro')
        .where('ativo', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => UsuarioModel.fromDoc(doc)).toList());
  }

  // CRIA O USUÁRIO NO BANCO DE DADOS E NO AUTH SEM DESLOGAR O ADMIN
  Future<String?> criarBarbeiroComLogin(String nome, String diaPagamento, String email, String senha) async {
    try {
      // Cria um app temporário só para registrar o barbeiro e não deslogar o Chefe
      FirebaseApp tempApp = await Firebase.initializeApp(
        name: 'tempAuth_${DateTime.now().millisecondsSinceEpoch}', 
        options: Firebase.app().options
      );
      
      UserCredential cred = await FirebaseAuth.instanceFor(app: tempApp).createUserWithEmailAndPassword(email: email, password: senha);

      await _firestore.collection('usuarios').doc(cred.user!.uid).set({
        'nome': nome,
        'role': 'barbeiro',
        'diaPagamento': diaPagamento,
        'ultimoPagamento': null,
        'ativo': true,
      });

      await tempApp.delete();
      return null; // Sucesso
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Erro desconhecido: $e";
    }
  }

  Future<void> updateBarbeiro(String id, String novoNome, String diaPagamento) async {
    await _firestore.collection('usuarios').doc(id).update({'nome': novoNome, 'diaPagamento': diaPagamento});
  }

  Future<void> deleteBarbeiro(String id) async {
    await _firestore.collection('usuarios').doc(id).update({'ativo': false});
  }

  Future<void> marcarComoPago(String id) async {
    await _firestore.collection('usuarios').doc(id).update({'ultimoPagamento': FieldValue.serverTimestamp()});
  }
}