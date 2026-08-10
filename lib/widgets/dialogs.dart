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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE0E0E0))),
      title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFBA1A1A))),
      content: Text(mensagem, style: const TextStyle(color: Color(0xFF1B1B1B))),
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
void mostrarDialogServico(BuildContext context, {String? id, String? nomeAtual, double? precoAtual, double? comissaoAtual}) {
  final nomeC = TextEditingController(text: nomeAtual);
  final precoC = TextEditingController(text: precoAtual?.toString());
  final comissaoC = TextEditingController(text: comissaoAtual?.toString() ?? '0');
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE0E0E0))),
      title: Text(id == null ? 'Novo Serviço/Produto' : 'Editar Serviço', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B1B1B))),
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
            if (id == null) DatabaseService().addServico(nomeC.text.trim(), p, c);
            else DatabaseService().updateServico(id, nomeC.text.trim(), p, c);
            Navigator.pop(context);
          },
          child: const Text('Salvar'),
        )
      ],
    ),
  );
}

/// Modal para lançar uma Despesa da loja.
void mostrarDialogDespesa(BuildContext context) {
  final descC = TextEditingController();
  final valorC = TextEditingController();
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE0E0E0))),
      title: const Text('Nova Despesa', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B1B1B))),
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
            DatabaseService().registrarDespesaVale('Despesa da Loja', descC.text.trim(), v);
            Navigator.pop(context);
          },
          child: const Text('Lançar Despesa'),
        )
      ],
    ),
  );
}

/// Modal para criar ou editar um Barbeiro (com criação de login).
bool _isCreatingUserGlobal = false;

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
            onPressed: _isCreatingUserGlobal ? null : () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF737784))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
            onPressed: _isCreatingUserGlobal ? null : () async {
              if (nomeC.text.trim().isEmpty) return;
              
              setStateLocal(() => _isCreatingUserGlobal = true);

              if (id == null) {
                if (emailC.text.isEmpty || senhaC.text.length < 6) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email inválido ou senha muito curta (mín. 6).')));
                   setStateLocal(() => _isCreatingUserGlobal = false);
                   return;
                }
                String? erro = await DatabaseService().criarBarbeiroComLogin(nomeC.text.trim(), diaPagamento, emailC.text.trim(), senhaC.text.trim());
                if (erro != null) {
                   if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $erro')));
                   setStateLocal(() => _isCreatingUserGlobal = false);
                   return;
                }
              } else {
                await DatabaseService().updateBarbeiro(id, nomeC.text.trim(), diaPagamento);
              }
              
              setStateLocal(() => _isCreatingUserGlobal = false);
              if(context.mounted) Navigator.pop(context);
            },
            child: _isCreatingUserGlobal ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Salvar'),
          )
        ],
      ),
    ),
  );
}

