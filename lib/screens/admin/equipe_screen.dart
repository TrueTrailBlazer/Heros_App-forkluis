import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/usuario_model.dart';
import '../../models/corte_model.dart';
import '../../widgets/dialogs.dart';
import '../../utils/formatters.dart';

class EquipeScreen extends StatefulWidget {
  const EquipeScreen({super.key});
  @override
  State<EquipeScreen> createState() => _EquipeScreenState();
}

class _EquipeScreenState extends State<EquipeScreen> {
  late Stream<List<UsuarioModel>> _streamBarbeiros;

  @override
  void initState() {
    super.initState();
    _streamBarbeiros = DatabaseService().getBarbeiros();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: StreamBuilder<List<UsuarioModel>>(
        stream: _streamBarbeiros,
        builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text('Erro DB: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.black));
          var barbeiros = snapshot.data!;
          if (barbeiros.isEmpty) return const Center(child: Text('Nenhum membro na equipe.', style: TextStyle(color: Colors.grey)));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.surfaceVariant),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: barbeiros.length,
                separatorBuilder: (context, index) => Divider(height: 1, color: Theme.of(context).colorScheme.surfaceVariant),
                itemBuilder: (context, index) {
                  var barbeiro = barbeiros[index];
                  String nome = barbeiro.nome;
                  String diaPag = barbeiro.diaPagamento ?? 'Sábado';
                  
                  return GestureDetector(behavior: HitTestBehavior.opaque,
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
                                  color: Theme.of(context).primaryColor,
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
                                  Text(nome, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).primaryColor)),
                                  const SizedBox(height: 4),
                                  Text('Acerto: $diaPag', style: const TextStyle(fontSize: 14, color: Color(0xFF737784))),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(behavior: HitTestBehavior.opaque,
                                onTap: () => mostrarDialogGerenciarEquipe(context, id: barbeiro.id, nomeAtual: nome, diaPagAtual: diaPag),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Theme.of(context).colorScheme.surfaceVariant),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.edit, color: Color(0xFF737784), size: 20),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: Colors.white,
                                      surfaceTintColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Theme.of(context).colorScheme.surfaceVariant)),
                                      title: const Text('Desativar Barbeiro', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFBA1A1A))),
                                      content: Text('Tem certeza que deseja desativar o barbeiro "$nome"? Ele perderá o acesso ao app.'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Color(0xFF737784)))),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFBA1A1A), foregroundColor: Colors.white),
                                          onPressed: () {
                                            Navigator.pop(context);
                                            DatabaseService().deleteBarbeiro(barbeiro.id);
                                          },
                                          child: const Text('Desativar'),
                                        )
                                      ],
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Theme.of(context).colorScheme.surfaceVariant),
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

class AcertoBarbeiroScreen extends StatefulWidget {
  final String nomeBarbeiro;
  final String diaPagamento;
  const AcertoBarbeiroScreen({super.key, required this.nomeBarbeiro, required this.diaPagamento});
  
  @override
  State<AcertoBarbeiroScreen> createState() => _AcertoBarbeiroScreenState();
}

class _AcertoBarbeiroScreenState extends State<AcertoBarbeiroScreen> {
  final DatabaseService _db = DatabaseService();
  late Stream<List<CorteModel>> _streamCortes;

  @override
  void initState() {
    super.initState();
    _streamCortes = _db.getTodosOsCortes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        title: Text('Caixa: ${widget.nomeBarbeiro}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: StreamBuilder<List<CorteModel>>(
        stream: _streamCortes,
        builder: (context, snapshotCortes) {
          if (!snapshotCortes.hasData) return const Center(child: CircularProgressIndicator(color: Colors.black));

          // A LÓGICA DE DATAS: Pega os ganhos do "Último Dia de Pagamento" até Agora.
          int hoje = DateTime.now().weekday; // 1=Segunda, 7=Domingo
          Map<String, int> diasSemana = {'Segunda': 1, 'Terça': 2, 'Quarta': 3, 'Quinta': 4, 'Sexta': 5, 'Sábado': 6, 'Domingo': 7};
          int diaAlvo = diasSemana[widget.diaPagamento] ?? 6;

          int diffDias = hoje - diaAlvo;
          if (diffDias < 0) diffDias += 7;
          if (diffDias == 0) diffDias = 7; // Se estivermos no próprio dia de pagamento, puxa os 7 dias passados!

          DateTime agora = DateTime.now();
          DateTime inicioCiclo = DateTime(agora.year, agora.month, agora.day).subtract(Duration(days: diffDias));

          var cortes = snapshotCortes.data!.where((corte) {
            if (corte.barbeiroNome != widget.nomeBarbeiro) return false;
            return corte.data.isAfter(inicioCiclo) || corte.data.isAtSameMomentAs(inicioCiclo);
          }).toList();

          double totalGanhos = cortes.fold(0, (s, corte) => s + corte.valor);
          double totalPomadas = cortes.fold(0, (s, corte) => s + corte.comissaoProdutos);
          double saldoFinal = totalGanhos + totalPomadas;
          String dataFormatada = Formatters.dataCurta(inicioCiclo);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).colorScheme.surfaceVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.event_available, color: Theme.of(context).primaryColor, size: 24),
                          const SizedBox(width: 8),
                          Text('Toda(o) ${widget.diaPagamento}', style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text('Lucro do Ciclo', style: TextStyle(color: Color(0xFF737784), fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      const SizedBox(height: 8),
                      Text('R\$ ${Formatters.moeda(saldoFinal)}', style: const TextStyle(color: Color(0xFF006400), fontSize: 32, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Desde o dia $dataFormatada', style: const TextStyle(color: Color(0xFF737784), fontSize: 12)),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: const Text('HISTÓRICO DE CORTES', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF737784), fontSize: 13, letterSpacing: 1.2)),
                ),
              ),
              Expanded(
                child: cortes.isEmpty 
                  ? const Center(child: Text('Nenhum corte no ciclo.', style: TextStyle(color: Color(0xFF737784))))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Theme.of(context).colorScheme.surfaceVariant),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: cortes.length,
                          separatorBuilder: (context, index) => Divider(height: 1, color: Theme.of(context).colorScheme.surfaceVariant),
                          itemBuilder: (context, index) {
                            var corte = cortes[index];
                            DateTime data = corte.data;
                            List<String> servicos = corte.servicos;
                            double pomada = corte.comissaoProdutos;
                            
                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(servicos.join(" + "), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).primaryColor)),
                                        const SizedBox(height: 4),
                                        Text(Formatters.dataHora(data), style: const TextStyle(color: Color(0xFF737784), fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Text('R\$ ${Formatters.moeda(corte.valor + pomada)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).primaryColor)),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
              )
            ],
          );
        },
      ),
    );
  }
}

