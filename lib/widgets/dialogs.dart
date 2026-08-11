import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../services/database_service.dart';

// ==========================================
// DIÁLOGOS REUTILIZÁVEIS DO SISTEMA
// ==========================================

/// Modal de confirmação genérico (usado para exclusão de serviços e barbeiros).
void mostrarDialogConfirmacao(BuildContext context, {required String titulo, required String mensagem, required VoidCallback onConfirmar}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Theme.of(context).colorScheme.surfaceVariant)),
      title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFBA1A1A))),
      content: Text(mensagem, style: TextStyle(color: Theme.of(context).primaryColor)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Color(0xFF737784)))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFBA1A1A), foregroundColor: Colors.white),
          onPressed: () {
            Navigator.pop(context);
            onConfirmar();
          },
          child: const Text('Excluir'),
        )
      ],
    ),
  );
}

/// Modal para criar ou editar um Serviço/Produto.
void mostrarDialogServico(BuildContext context, {String? id, String? nomeAtual, double? precoAtual, double? comissaoAtual, required Function(String, double, double) onSalvar}) {
  final nomeC = TextEditingController(text: nomeAtual);
  final precoC = TextEditingController(text: precoAtual?.toString());
  final comissaoC = TextEditingController(text: comissaoAtual?.toString() ?? '0');
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Theme.of(context).colorScheme.surfaceVariant)),
      title: Text(id == null ? 'Novo Serviço/Produto' : 'Editar Serviço', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: nomeC, decoration: const InputDecoration(labelText: 'Nome (Ex: Pomada)')),
          const SizedBox(height: 10),
          TextField(controller: precoC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Preço Cliente (R\$)')),
          const SizedBox(height: 10),
          TextField(controller: comissaoC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Comissão Barbeiro (R\$)')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Color(0xFF737784)))),
        ElevatedButton(
          onPressed: () {
            if (nomeC.text.trim().isEmpty || precoC.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha os campos obrigatórios (Nome e Preço).')));
              return;
            }
            double p = double.tryParse(precoC.text.replaceAll(',', '.')) ?? 0;
            double c = double.tryParse(comissaoC.text.replaceAll(',', '.')) ?? 0;
            onSalvar(nomeC.text.trim(), p, c);
            Navigator.pop(context);
          },
          child: const Text('Salvar'),
        )
      ],
    ),
  );
}

/// Modal para lançar uma Despesa da loja.
void mostrarDialogDespesa(BuildContext context, {required Function(String, double) onSalvar}) {
  final descC = TextEditingController();
  final valorC = TextEditingController();
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Theme.of(context).colorScheme.surfaceVariant)),
      title: Text('Nova Despesa', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: descC, decoration: const InputDecoration(labelText: 'Descrição (Ex: Água, Luz)')),
          const SizedBox(height: 10),
          TextField(controller: valorC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Valor (R\$)')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Color(0xFF737784)))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB22222), foregroundColor: Colors.white),
          onPressed: () {
            if (descC.text.trim().isEmpty || valorC.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha os campos obrigatórios (Descrição e Valor).')));
              return;
            }
            double v = double.tryParse(valorC.text.replaceAll(',', '.')) ?? 0;
            onSalvar(descC.text.trim(), v);
            Navigator.pop(context);
          },
          child: const Text('Lançar Despesa'),
        )
      ],
    ),
  );
}

/// Modal para gerenciar equipe (criar novo barbeiro ou editar existente).
void mostrarDialogGerenciarEquipe(BuildContext context, {String? id, String? nomeAtual, String? diaPagAtual}) {
  final nomeC = TextEditingController(text: nomeAtual);
  final emailC = TextEditingController();
  final senhaC = TextEditingController();
  String diaPagamento = diaPagAtual ?? 'Sábado';
  bool isCreatingUser = false;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setStateLocal) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Theme.of(context).colorScheme.surfaceVariant)),
        title: Text(id == null ? 'Novo Barbeiro' : 'Editar Barbeiro', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nomeC, decoration: const InputDecoration(labelText: 'Nome do Barbeiro')),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: diaPagamento,
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
            onPressed: isCreatingUser ? null : () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF737784))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
            onPressed: isCreatingUser ? null : () async {
              if (nomeC.text.trim().isEmpty) return;
              
              setStateLocal(() => isCreatingUser = true);

              if (id == null) {
                if (emailC.text.isEmpty || senhaC.text.length < 6) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email inválido ou senha muito curta (mín. 6).')));
                   setStateLocal(() => isCreatingUser = false);
                   return;
                }
                String? erro = await Provider.of<DatabaseService>(context, listen: false).criarBarbeiroComLogin(nomeC.text.trim(), diaPagamento, emailC.text.trim(), senhaC.text.trim());
                if (erro != null) {
                   if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $erro')));
                   setStateLocal(() => isCreatingUser = false);
                   return;
                }
              } else {
                await Provider.of<DatabaseService>(context, listen: false).updateBarbeiro(id, nomeC.text.trim(), diaPagamento);
              }
              
              setStateLocal(() => isCreatingUser = false);
              if(context.mounted) Navigator.pop(context);
            },
            child: isCreatingUser ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Salvar'),
          )
        ],
      ),
    ),
  );

