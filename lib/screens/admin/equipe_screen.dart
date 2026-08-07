import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/database_service.dart';

class EquipeScreen extends StatefulWidget {
  const EquipeScreen({super.key});
  @override
  State<EquipeScreen> createState() => _EquipeScreenState();
}

bool _isCreatingUserEquipeGlobal = false;

void mostrarDialogGerenciarEquipe(BuildContext context, {String? id, String? nomeAtual, String? diaPagAtual}) {
  final nomeC = TextEditingController(text: nomeAtual);
  final emailC = TextEditingController();
  final senhaC = TextEditingController();
  String diaPagamento = diaPagAtual ?? 'Sábado';

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setStateLocal) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE0E0E0))),
        title: Text(id == null ? 'Novo Barbeiro' : 'Editar Barbeiro', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B1B1B))),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nomeC, decoration: const InputDecoration(labelText: 'Nome do Barbeiro')),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                initialValue: diaPagamento, 
                decoration: InputDecoration(labelText: 'Dia de Fechar Caixa', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                items: ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (v) => setStateLocal(() => diaPagamento = v!),
              ),
              if (id == null) ...[
                const Divider(height: 30),
                const Text('Criar Acesso (Login)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 10),
                TextField(controller: emailC, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-mail do barbeiro')),
                const SizedBox(height: 10),
                TextField(controller: senhaC, obscureText: true, decoration: const InputDecoration(labelText: 'Senha (mínimo 6 num.)')),
              ]
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isCreatingUserEquipeGlobal ? null : () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF737784))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
            onPressed: _isCreatingUserEquipeGlobal ? null : () async {
              if (nomeC.text.trim().isEmpty) return;
              
              setStateLocal(() => _isCreatingUserEquipeGlobal = true);

              if (id == null) {
                if (emailC.text.isEmpty || senhaC.text.length < 6) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email inválido ou senha muito curta (mín. 6).')));
                   setStateLocal(() => _isCreatingUserEquipeGlobal = false);
                   return;
                }
                String? erro = await DatabaseService().criarBarbeiroComLogin(nomeC.text.trim(), diaPagamento, emailC.text.trim(), senhaC.text.trim());
                if (erro != null) {
                   if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $erro')));
                   setStateLocal(() => _isCreatingUserEquipeGlobal = false);
                   return;
                }
              } else {
                await DatabaseService().updateBarbeiro(id, nomeC.text.trim(), diaPagamento);
              }
              
              setStateLocal(() => _isCreatingUserEquipeGlobal = false);
              if(context.mounted) Navigator.pop(context);
            },
            child: _isCreatingUserEquipeGlobal ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Salvar'),
          )
        ],
      ),
    ),
  );
}

class _EquipeScreenState extends State<EquipeScreen> {
  // state fields
  bool _isCreatingUser = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: StreamBuilder<QuerySnapshot>(
        stream: DatabaseService().getBarbeiros(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.black));
          var barbeiros = snapshot.data!.docs;
          if (barbeiros.isEmpty) return const Center(child: Text('Nenhum membro na equipe.', style: TextStyle(color: Colors.grey)));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: barbeiros.length,
                separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE0E0E0)),
                itemBuilder: (context, index) {
                  var b = barbeiros[index];
                  var d = b.data() as Map<String, dynamic>;
                  String nome = d['nome'] ?? 'Sem nome';
                  String diaPag = d['diaPagamento'] ?? 'Não definido';
                  
                  return InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AcertoBarbeiroScreen(nomeBarbeiro: nome, diaPagamento: diaPag))),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1B1B1B),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B1B1B))),
                                  const SizedBox(height: 4),
                                  Text('Acerto: $diaPag', style: const TextStyle(fontSize: 14, color: Color(0xFF737784))),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () => mostrarDialogGerenciarEquipe(context, id: b.id, nomeAtual: nome, diaPagAtual: diaPag),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFFE0E0E0)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.edit, color: Color(0xFF737784), size: 20),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => DatabaseService().deleteBarbeiro(b.id),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFFE0E0E0)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.delete, color: Color(0xFFB22222), size: 20),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class AcertoBarbeiroScreen extends StatelessWidget {
  final String nomeBarbeiro;
  final String diaPagamento;
  AcertoBarbeiroScreen({super.key, required this.nomeBarbeiro, required this.diaPagamento});
  
  final DatabaseService _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: Text('Caixa: $nomeBarbeiro', maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.getTodosOsCortes(),
        builder: (context, snapshotCortes) {
          if (!snapshotCortes.hasData) return const Center(child: CircularProgressIndicator(color: Colors.black));

          // A LÓGICA DE DATAS: Pega os ganhos do "Último Dia de Pagamento" até Agora.
          int hoje = DateTime.now().weekday; // 1=Segunda, 7=Domingo
          Map<String, int> diasSemana = {'Segunda': 1, 'Terça': 2, 'Quarta': 3, 'Quinta': 4, 'Sexta': 5, 'Sábado': 6, 'Domingo': 7};
          int diaAlvo = diasSemana[diaPagamento] ?? 6;

          int diffDias = hoje - diaAlvo;
          if (diffDias < 0) diffDias += 7;
          if (diffDias == 0) diffDias = 7; // Se estivermos no próprio dia de pagamento, puxa os 7 dias passados!

          DateTime agora = DateTime.now();
          DateTime inicioCiclo = DateTime(agora.year, agora.month, agora.day).subtract(Duration(days: diffDias));

          var cortes = snapshotCortes.data!.docs.where((doc) {
            var d = doc.data() as Map<String, dynamic>? ?? {};
            if (!d.containsKey('data') || d['data'] == null || d['barbeiroNome'] != nomeBarbeiro) return false;
            return (d['data'] as Timestamp).toDate().isAfter(inicioCiclo) || (d['data'] as Timestamp).toDate().isAtSameMomentAs(inicioCiclo);
          }).toList();

          double totalGanhos = cortes.fold(0, (s, doc) => s + (((doc.data() as Map)['valor'] ?? 0) as num).toDouble());
          double totalPomadas = cortes.fold(0, (s, doc) => s + (((doc.data() as Map)['comissaoProdutos'] ?? 0) as num).toDouble());
          double saldoFinal = totalGanhos + totalPomadas;
          String dataFormatada = "${inicioCiclo.day.toString().padLeft(2, '0')}/${inicioCiclo.month.toString().padLeft(2, '0')}";

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: Colors.black),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.event_available, color: Colors.white, size: 30),
                        const SizedBox(width: 15),
                        Text('Pagamento: Toda(o) $diaPagamento', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Lucro do Ciclo:', style: TextStyle(color: Colors.grey, fontSize: 16)),
                            Text('(Desde o dia $dataFormatada)', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                          ],
                        ),
                        Text('R\$ ${saldoFinal.toStringAsFixed(2)}', style: const TextStyle(color: Colors.greenAccent, fontSize: 28, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                alignment: Alignment.centerLeft,
                child: const Text('Histórico de Cortes:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              Expanded(
                child: cortes.isEmpty 
                  ? const Center(child: Text('Nenhum corte no ciclo.', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: cortes.length,
                      itemBuilder: (context, index) {
                        var d = cortes[index].data() as Map<String, dynamic>;
                        DateTime data = (d['data'] as Timestamp).toDate();
                        List servicos = d['servicos'] ?? [];
                        double pomada = d.containsKey('comissaoProdutos') ? (d['comissaoProdutos'] as num).toDouble() : 0;
                        
                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                          color: Colors.white,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(servicos.join(" + "), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("${data.day}/${data.month} às ${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}", style: const TextStyle(color: Colors.grey)),
                            trailing: Text('R\$ ${(d['valor'] + pomada).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        );
                      },
                    ),
              )
            ],
          );
        },
      ),
    );
  }
}