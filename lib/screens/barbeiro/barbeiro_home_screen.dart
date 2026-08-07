import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../auth/login_screen.dart';

class BarbeiroHomeScreen extends StatefulWidget {
  const BarbeiroHomeScreen({super.key});

  @override
  State<BarbeiroHomeScreen> createState() => _BarbeiroHomeScreenState();
}

class _BarbeiroHomeScreenState extends State<BarbeiroHomeScreen> {
  final DatabaseService _db = DatabaseService();
  final List<Map<String, dynamic>> _servicosSelecionados = [];
  String _formaPagamento = 'PIX';
  bool _salvando = false;

  double get _valorTotal => _servicosSelecionados.fold(0, (sum, item) => sum + (item['preco'] as num).toDouble());
  double get _comissaoExtra => _servicosSelecionados.fold(0, (sum, item) => sum + (item['comissao'] as num).toDouble());

  void _adicionarServico(String nome, double preco, double comissao) {
    setState(() => _servicosSelecionados.add({'nome': nome, 'preco': preco, 'comissao': comissao}));
  }

  void _removerServico(int index) {
    setState(() => _servicosSelecionados.removeAt(index));
  }

  void _finalizarAtendimento() async {
    if (_servicosSelecionados.isEmpty) return;
    setState(() => _salvando = true);

    final auth = Provider.of<AuthService>(context, listen: false);
    List<String> nomesServicos = _servicosSelecionados.map((s) => s['nome'].toString()).toList();

    await _db.registrarCorte(
      barbeiroNome: auth.usuarioAtual?.nome ?? 'Barbeiro',
      barbeiroId: auth.usuarioAtual?.id ?? '',
      servicosFeitos: nomesServicos,
      valorTotal: _valorTotal,
      comissaoProdutos: _comissaoExtra,
      formaPagamento: _formaPagamento,
    );

    setState(() {
      _servicosSelecionados.clear();
      _salvando = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Atendimento finalizado!'), backgroundColor: Colors.black));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Hé/Os - ${authService.usuarioAtual?.nome}', style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.logout();
              if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          )
        ],
      ),
      body: Column(
        children: [
          // LISTA DE SERVIÇOS
          Expanded(
            flex: 3,
            child: StreamBuilder<QuerySnapshot>(
              stream: _db.getServicos(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.black));
                final servicos = snapshot.data!.docs;
                
                if (servicos.isEmpty) return const Center(child: Text('Nenhum serviço cadastrado.', style: TextStyle(color: Colors.grey)));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: servicos.length,
                  itemBuilder: (context, index) {
                    var s = servicos[index];
                    var d = s.data() as Map<String, dynamic>;
                    double comissao = d.containsKey('comissao') ? (d['comissao'] as num).toDouble() : 0.0;
                    
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(d['nome'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text('R\$ ${(d['preco'] as num).toStringAsFixed(2)}${comissao > 0 ? ' (Ganha R\$ $comissao)' : ''}'),
                        trailing: InkWell(
                          onTap: () => _adicionarServico(d['nome'], (d['preco'] as num).toDouble(), comissao),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.add, color: Colors.white),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // CARRINHO DE COMPRAS
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
              ),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('CARRINHO DO CLIENTE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
                  ),
                  Expanded(
                    child: _servicosSelecionados.isEmpty 
                      ? const Center(child: Text('Nenhum serviço adicionado.', style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _servicosSelecionados.length,
                          itemBuilder: (context, index) {
                            var item = _servicosSelecionados[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(item['nome'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                  Row(
                                    children: [
                                      Text('R\$ ${item['preco'].toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 10),
                                      GestureDetector(
                                        onTap: () => _removerServico(index),
                                        child: const Icon(Icons.remove_circle_outline, color: Colors.grey),
                                      )
                                    ],
                                  )
                                ],
                              ),
                            );
                          },
                        ),
                  ),
                  // PAGAMENTO
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('TOTAL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                            Text('R\$ ${_valorTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _formaPagamento,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          items: ['PIX', 'Dinheiro', 'Cartão', 'Fiado'].map((f) => DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                          onChanged: (v) => setState(() => _formaPagamento = v!),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (_servicosSelecionados.isEmpty || _salvando) ? null : _finalizarAtendimento,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _salvando 
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('FINALIZAR ATENDIMENTO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}