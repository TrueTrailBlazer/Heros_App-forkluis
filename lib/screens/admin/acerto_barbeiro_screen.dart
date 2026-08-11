import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../models/corte_model.dart';
import '../../utils/formatters.dart';

/// Tela de acerto financeiro de um barbeiro específico.
class AcertoBarbeiroScreen extends StatefulWidget {
  final String nomeBarbeiro;
  final String diaPagamento;
  const AcertoBarbeiroScreen({super.key, required this.nomeBarbeiro, required this.diaPagamento});
  
  @override
  State<AcertoBarbeiroScreen> createState() => _AcertoBarbeiroScreenState();
}

class _AcertoBarbeiroScreenState extends State<AcertoBarbeiroScreen> {
  late DatabaseService _db;
  late Stream<List<CorteModel>> _streamCortes;

  @override
  void initState() {
    super.initState();
    _db = Provider.of<DatabaseService>(context, listen: false);
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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('HISTÓRICO DE CORTES', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF737784), fontSize: 13, letterSpacing: 1.2)),
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
