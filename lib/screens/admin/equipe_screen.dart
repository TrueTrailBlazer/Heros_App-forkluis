import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/admin_controller.dart';
import '../../services/database_service.dart';
import '../../models/usuario_model.dart';
import '../../widgets/dialogs.dart';
import 'acerto_barbeiro_screen.dart';

/// Aba de gerenciamento da equipe de barbeiros.
class EquipeScreen extends StatelessWidget {
  const EquipeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AdminController>();
    final db = Provider.of<DatabaseService>(context, listen: false);

    if (controller.isLoadingBarbeiros) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.erroBarbeiros != null) {
      return Center(child: Text('Erro DB: ${controller.erroBarbeiros}', style: const TextStyle(color: Colors.red)));
    }

    List<UsuarioModel> barbeiros = controller.barbeiros;
    if (barbeiros.isEmpty) return const Center(child: Text('Nenhum membro na equipe.', style: TextStyle(color: Colors.grey)));

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
                                        db.deleteBarbeiro(barbeiro.id);
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
      ),
    );
  }
}
