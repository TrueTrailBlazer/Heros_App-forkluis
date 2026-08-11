import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../controllers/barbeiro_controller.dart';
import '../auth/login_screen.dart';
import '../../utils/formatters.dart';

class BarbeiroHomeScreen extends StatelessWidget {
  const BarbeiroHomeScreen({super.key});

  void _abrirCarrinhoBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer<BarbeiroController>(
        builder: (context, controller, child) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(width: 40, height: 6, decoration: BoxDecoration(color: const Color(0xFFCFC4C5), borderRadius: BorderRadius.circular(3))),
                  const SizedBox(height: 16),
                  const Text('CARRINHO DO CLIENTE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF737784), letterSpacing: 1.2)),
                  const SizedBox(height: 16),
                  if (controller.servicosSelecionados.isEmpty)
                    const Padding(padding: EdgeInsets.all(24.0), child: Text('O carrinho está vazio.', style: TextStyle(color: Color(0xFF737784))))
                  else
                    Builder(
                      builder: (context) {
                        Map<String, List<Map<String, dynamic>>> grouped = {};
                        for (var s in controller.servicosSelecionados) {
                          grouped.putIfAbsent(s['nome'], () => []).add(s);
                        }
                        var groupKeys = grouped.keys.toList();

                        return Container(
                          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: groupKeys.length,
                            separatorBuilder: (context, index) => Divider(height: 16, color: Theme.of(context).colorScheme.surfaceVariant),
                            itemBuilder: (context, index) {
                              var nome = groupKeys[index];
                              var items = grouped[nome]!;
                              var quantidade = items.length;
                              var item = items.first;
                              double totalItem = (item['preco'] as num).toDouble() * quantidade;

                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text('${quantidade}x $nome', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).primaryColor), overflow: TextOverflow.ellipsis)),
                                  Row(
                                    children: [
                                      Text('R\$ ${Formatters.moeda(totalItem)}', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                                      const SizedBox(width: 12),
                                      GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () {
                                          int idx = controller.servicosSelecionados.lastIndexWhere((s) => s['nome'] == nome);
                                          if (idx != -1) controller.removerServico(idx);
                                          if (controller.servicosSelecionados.isEmpty) Navigator.pop(context);
                                        },
                                        child: const Padding(padding: EdgeInsets.all(4.0), child: Icon(Icons.remove_circle_outline, color: Color(0xFFB22222), size: 26)),
                                      )
                                    ],
                                  )
                                ],
                              );
                            },
                          ),
                        );
                      }
                    ),
                  if (controller.servicosSelecionados.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F9F9),
                        border: Border(top: BorderSide(color: Theme.of(context).colorScheme.surfaceVariant)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('TOTAL', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF737784), letterSpacing: 1.2)),
                              Text('R\$ ${Formatters.moeda(controller.valorTotal)}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF006400))),
                            ],
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: controller.formaPagamento,
                            dropdownColor: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Theme.of(context).colorScheme.surfaceVariant)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Theme.of(context).colorScheme.surfaceVariant)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items: ['PIX', 'Dinheiro', 'Cartão', 'Fiado'].map((f) => DropdownMenuItem(value: f, child: Text(f, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)))).toList(),
                            onChanged: (v) => controller.setFormaPagamento(v!),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: controller.salvando ? null : () async {
                                String? err = await controller.finalizarAtendimento();
                                if (context.mounted) {
                                  Navigator.pop(context); // fecha modal
                                  if (err == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Atendimento finalizado!'), backgroundColor: Colors.black));
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $err'), backgroundColor: const Color(0xFFBA1A1A)));
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: controller.salvando 
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text('FINALIZAR ATENDIMENTO', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1)),
                            ),
                          ),
                        ],
                      ),
                    )
                  ]
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final controller = context.watch<BarbeiroController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Image.asset('assets/appbar-icon.png', height: 28, errorBuilder: (context, error, stackTrace) => const Icon(Icons.content_cut, size: 24, color: Colors.white)),
            const SizedBox(width: 12),
            Expanded(child: Text("Hero's - ${authService.usuarioAtual?.nome ?? ''}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.white,
                  title: Text('Sair da conta', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                  content: const Text('Tem certeza que deseja sair da sua conta?', style: TextStyle(color: Color(0xFF737784))),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Color(0xFF737784)))),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB22222), foregroundColor: Colors.white),
                      onPressed: () async {
                        Navigator.pop(context);
                        await authService.logout();
                        if (context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                      },
                      child: const Text('Sair'),
                    ),
                  ],
                ),
              );
            },
          )
        ],
      ),
      body: Builder(
        builder: (context) {
          if (controller.isLoadingServicos) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.erroServicos != null) {
            return Center(child: Text('Erro DB: ${controller.erroServicos}', style: const TextStyle(color: Colors.red)));
          }
          
          final servicos = controller.servicos;
          
          if (servicos.isEmpty) return const Center(child: Text('Nenhum serviço cadastrado.', style: TextStyle(color: Colors.grey)));

          return ListView.separated(
            padding: EdgeInsets.only(bottom: controller.servicosSelecionados.isNotEmpty ? 100 : 20),
            itemCount: servicos.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: Theme.of(context).colorScheme.surfaceVariant),
            itemBuilder: (context, index) {
              var servico = servicos[index];
              double comissao = servico.comissao;
              
              int quantidade = controller.servicosSelecionados.where((s) => s['nome'] == servico.nome).length;

              return Container(
                color: Colors.white,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(servico.nome, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).primaryColor)),
                  subtitle: Text('R\$ ${Formatters.moeda(servico.preco)}${comissao > 0 ? ' (Ganha R\$ $comissao)' : ''}', style: const TextStyle(color: Color(0xFF737784))),
                  trailing: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (quantidade > 0) ...[
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              int idx = controller.servicosSelecionados.lastIndexWhere((s) => s['nome'] == servico.nome);
                              if (idx != -1) controller.removerServico(idx);
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Icon(Icons.remove, color: Color(0xFFBA1A1A), size: 20),
                            ),
                          ),
                          SizedBox(
                            width: 20,
                            child: Center(
                              child: Text('$quantidade', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ),
                        ],
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => controller.adicionarServico(servico.nome, servico.preco, comissao),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Icon(Icons.add, color: Colors.black, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: controller.servicosSelecionados.isEmpty ? null : GestureDetector(
        onTap: () => _abrirCarrinhoBottomSheet(context),
        child: Container(
          color: Theme.of(context).primaryColor,
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${controller.servicosSelecionados.length} Iten${controller.servicosSelecionados.length > 1 ? 's' : ''}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    Text('R\$ ${Formatters.moeda(controller.valorTotal)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
                Row(
                  children: const [
                    Text('Ver Carrinho', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    SizedBox(width: 8),
                    Icon(Icons.shopping_bag_outlined, color: Colors.white),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
