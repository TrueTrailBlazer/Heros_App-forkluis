import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/admin_controller.dart';
import '../../../services/database_service.dart';
import '../../../models/servico_model.dart';
import '../../../widgets/dialogs.dart';
import '../../../utils/formatters.dart';

/// Aba de listagem e gerenciamento de Serviços.
class AbaServicos extends StatelessWidget {
  const AbaServicos({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AdminController>();
    final db = Provider.of<DatabaseService>(context, listen: false);

    if (controller.isLoadingServicos) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.erroServicos != null) {
      return Center(child: Text('Erro DB: ${controller.erroServicos}', style: const TextStyle(color: Colors.red)));
    }

    List<ServicoModel> servicos = controller.servicos;
    if (servicos.isEmpty) return const Center(child: Text('Nenhum serviço.', style: TextStyle(color: Colors.grey)));

    return Container(
      color: const Color(0xFFF5F5F5),
      child: SingleChildScrollView(
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
            itemCount: servicos.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: Theme.of(context).colorScheme.surfaceVariant),
            itemBuilder: (context, index) {
              var servico = servicos[index];
              double com = servico.comissao;
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(servico.nome, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                          const SizedBox(height: 4),
                          Text('R\$ ${Formatters.moeda(servico.preco)}${com > 0 ? ' (Comissão: R\$ $com)' : ''}', style: const TextStyle(fontSize: 14, color: Color(0xFF737784))),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(behavior: HitTestBehavior.opaque,
                          onTap: () => mostrarDialogServico(context, id: servico.id, nomeAtual: servico.nome, precoAtual: servico.preco, comissaoAtual: com, onSalvar: (nome, preco, comissao) {
                            db.updateServico(servico.id, nome, preco, comissao);
                          }),
                          child: const Icon(Icons.edit, color: Color(0xFF737784)),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(behavior: HitTestBehavior.opaque,
                          onTap: () {
                            mostrarDialogConfirmacao(
                              context, 
                              titulo: 'Excluir Serviço', 
                              mensagem: 'Tem certeza que deseja excluir o serviço "${servico.nome}"? Essa ação não pode ser desfeita.', 
                              onConfirmar: () => db.deleteServico(servico.id),
                            );
                          },
                          child: const Icon(Icons.delete, color: Color(0xFFB22222)),
                        ),
                      ],
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
