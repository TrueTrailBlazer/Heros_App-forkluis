import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/admin_controller.dart';
import '../../../services/database_service.dart';
import '../../../models/usuario_model.dart';
import '../../../widgets/dialogs.dart';
import '../../../utils/formatters.dart';
import '../detalhe_relatorio_screen.dart';
import '../acerto_barbeiro_screen.dart';

/// Aba de Relatórios e Avisos de Acerto Pendente.
class AbaRelatorios extends StatelessWidget {
  const AbaRelatorios({super.key});

  Widget _buildBotao(BuildContext context, String titulo, String tipo, IconData icone) {
    return GestureDetector(behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetalheRelatorioScreen(tipo: tipo, titulo: titulo))),
      child: Container(
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.surfaceVariant))),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Row(
          children: [
            Icon(icone, color: Theme.of(context).primaryColor, size: 24),
            const SizedBox(width: 16),
            Text('Relatório $titulo', style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 16, fontWeight: FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AdminController>();
    final db = Provider.of<DatabaseService>(context, listen: false);

    if (controller.isLoadingCortes || controller.isLoadingBarbeiros) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.erroCortes != null) {
      return Center(child: Text('Erro DB: ${controller.erroCortes}', style: const TextStyle(color: Colors.red)));
    }

    double lucroHoje = controller.faturamentoBrutoHoje;
    int qtdServicos = controller.qtdServicosHoje;
    List<UsuarioModel> barbeiros = controller.barbeiros;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Faturamento Bruto
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Theme.of(context).colorScheme.surfaceVariant)),
          child: Column(
            children: [
              const Text('Faturamento Bruto', style: TextStyle(color: Color(0xFF737784), fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              Text('R\$ ${Formatters.moeda(lucroHoje)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF0047AB))),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.trending_up, color: Color(0xFF006400), size: 16),
                  const SizedBox(width: 4),
                  Text('$qtdServicos serviços realizados hoje', style: const TextStyle(color: Color(0xFF006400), fontSize: 12)),
                ],
              ),
            ],
          ),
        ),

        // Acerto Pendente
        ...barbeiros.where((b) => controller.precisaPagar(b.diaPagamento ?? 'Sábado', b.ultimoPagamento)).map((b) {
          String nome = b.nome;
          String diaPag = b.diaPagamento ?? 'Sábado';
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: const Border(
                left: BorderSide(color: Color(0xFFBA1A1A), width: 4),
                top: BorderSide(color: Color(0xFFE0E0E0)),
                right: BorderSide(color: Color(0xFFE0E0E0)),
                bottom: BorderSide(color: Color(0xFFE0E0E0)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Acerto Pendente', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFBA1A1A), fontSize: 18)),
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFBA1A1A)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Barbeiro: $nome', style: const TextStyle(color: Color(0xFF737784))),
                const SizedBox(height: 16),
                Row(
                  children: [
                    GestureDetector(behavior: HitTestBehavior.opaque,
                      onTap: () => db.marcarComoPago(b.id),
                      child: const Text('Pagar', style: TextStyle(color: Color(0xFFBA1A1A), fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    const SizedBox(width: 24),
                    GestureDetector(behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AcertoBarbeiroScreen(nomeBarbeiro: nome, diaPagamento: diaPag))),
                      child: Text('Ver Detalhes', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                )
              ],
            ),
          );
        }),

        // Relatórios
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Theme.of(context).colorScheme.surfaceVariant)),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              shape: const Border(),
              collapsedShape: const Border(),
              title: Text('Gerar Relatórios', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
              iconColor: Theme.of(context).primaryColor,
              collapsedIconColor: Theme.of(context).primaryColor,
              children: [
                _buildBotao(context, 'Diário', 'Hoje', Icons.today),
                _buildBotao(context, 'Semanal', 'Semana', Icons.calendar_view_week),
                _buildBotao(context, 'Mensal', 'Mes', Icons.calendar_month),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
