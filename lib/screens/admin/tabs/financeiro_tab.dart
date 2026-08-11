import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/admin_controller.dart';
import '../../../models/despesa_model.dart';
import '../../../utils/formatters.dart';

/// Aba de Despesas e Vales (Financeiro).
class AbaFinanceiro extends StatefulWidget {
  const AbaFinanceiro({super.key});
  @override
  State<AbaFinanceiro> createState() => _AbaFinanceiroState();
}

class _AbaFinanceiroState extends State<AbaFinanceiro> {
  String _filtroMes = 'Mês Atual';

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AdminController>();

    if (controller.isLoadingDespesas) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.erroDespesas != null) {
      return Center(child: Text('Erro DB: ${controller.erroDespesas}', style: const TextStyle(color: Colors.red)));
    }

    DateTime agora = DateTime.now();
    DateTime inicioMesAtual = DateTime(agora.year, agora.month, 1);
    DateTime inicioMesPassado = DateTime(agora.year, agora.month - 1, 1);
    var itens = controller.despesas.where((despesa) {
      DateTime d = despesa.data;
      if (_filtroMes == 'Mês Atual') return d.isAfter(inicioMesAtual) || d.isAtSameMomentAs(inicioMesAtual);
      if (_filtroMes == 'Mês Passado') return d.isAfter(inicioMesPassado) && d.isBefore(inicioMesAtual);
      return true;
    }).toList();

    return Container(
      color: const Color(0xFFF5F5F5),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 200,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Theme.of(context).colorScheme.surfaceVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _filtroMes,
                    isExpanded: true,
                    icon: const Icon(Icons.expand_more, color: Color(0xFF737784)),
                    focusColor: Colors.transparent,
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    items: ['Mês Atual', 'Mês Passado', 'Todos'].map((n) => DropdownMenuItem(value: n, child: Text(n, style: TextStyle(fontWeight: FontWeight.normal, color: Theme.of(context).primaryColor)))).toList(),
                    onChanged: (v) => setState(() => _filtroMes = v!),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: itens.isEmpty
              ? const Center(child: Text('Nenhuma despesa.', style: TextStyle(color: Colors.grey)))
              : SingleChildScrollView(
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
                      itemCount: itens.length,
                      separatorBuilder: (context, index) => Divider(height: 1, color: Theme.of(context).colorScheme.surfaceVariant),
                      itemBuilder: (context, index) {
                        var despesa = itens[index];
                        DateTime data = despesa.data;
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.receipt_long, color: Color(0xFF737784)),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(despesa.descricao, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).primaryColor)),
                                      const SizedBox(height: 4),
                                      Text(Formatters.dataLonga(data), style: const TextStyle(fontSize: 12, color: Color(0xFF737784))),
                                    ],
                                  ),
                                ],
                              ),
                              Text('- R\$ ${Formatters.moeda(despesa.valor)}', style: const TextStyle(color: Color(0xFFB22222), fontWeight: FontWeight.bold, fontSize: 18)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }
}
