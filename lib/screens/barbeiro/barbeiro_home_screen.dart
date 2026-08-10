import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/servico_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../auth/login_screen.dart';
import '../../utils/formatters.dart';

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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B1B1B),
        foregroundColor: Colors.white,
        title: Text('Hé/Os - ${authService.usuarioAtual?.nome}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
            child: StreamBuilder<List<ServicoModel>>(
              stream: _db.getServicos(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.black));
                final servicos = snapshot.data!;
                
                if (servicos.isEmpty) return const Center(child: Text('Nenhum serviço cadastrado.', style: TextStyle(color: Colors.grey)));

                return Container(
                  color: Colors.white,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(0),
                    itemCount: servicos.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE0E0E0)),
                    itemBuilder: (context, index) {
                      var servico = servicos[index];
                      double comissao = servico.comissao;
                      
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(servico.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B1B1B))),
                        subtitle: Text('R\$ ${Formatters.moeda(servico.preco)}${comissao > 0 ? ' (Ganha R\$ $comissao)' : ''}', style: const TextStyle(color: Color(0xFF737784))),
                        trailing: InkWell(
                          onTap: () => _adicionarServico(servico.nome, servico.preco, comissao),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.add, color: Color(0xFF1B1B1B), size: 20),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          
          // CARRINHO DE COMPRAS
          Expanded(
            flex: 2,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
              ),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('CARRINHO DO CLIENTE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF737784), letterSpacing: 1.2)),
                  ),
                  Expanded(
                    child: _servicosSelecionados.isEmpty 
                      ? const Center(child: Text('Nenhum serviço adicionado.', style: TextStyle(color: Color(0xFF737784))))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _servicosSelecionados.length,
                          separatorBuilder: (context, index) => const Divider(height: 16, color: Colors.transparent),
                          itemBuilder: (context, index) {
                            var item = _servicosSelecionados[index];
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(item['nome'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF1B1B1B))),
                                Row(
                                  children: [
                                    Text('R\$ ${Formatters.moeda((item['preco'] as num).toDouble())}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B1B1B))),
                                    const SizedBox(width: 10),
                                    GestureDetector(
                                      onTap: () => _removerServico(index),
                                      child: const Icon(Icons.remove_circle_outline, color: Color(0xFF737784)),
                                    )
                                  ],
                                )
                              ],
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
                            const Text('TOTAL', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF737784), letterSpacing: 1.2)),
                            Text('R\$ ${Formatters.moeda(_valorTotal)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF006400))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _formaPagamento,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            filled: true,
                            fillColor: const Color(0xFFF5F5F5),
                          ),
                          items: ['PIX', 'Dinheiro', 'Cartão', 'Fiado'].map((f) => DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B1B1B))))).toList(),
                          onChanged: (v) => setState(() => _formaPagamento = v!),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (_servicosSelecionados.isEmpty || _salvando) ? null : _finalizarAtendimento,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B1B1B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: _salvando 
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('FINALIZAR ATENDIMENTO', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1)),
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