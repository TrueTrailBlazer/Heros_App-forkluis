import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../auth/login_screen.dart';
import 'equipe_screen.dart'; // Importante para puxar a tela de Acerto

// ==========================================
// FUNÇÕES GLOBAIS DE DIALOG (MOVIDAS PARA O FAB CENTRAL)
// ==========================================
void mostrarDialogServico(BuildContext context, {String? id, String? nomeAtual, double? precoAtual, double? comissaoAtual}) {
  final nomeC = TextEditingController(text: nomeAtual);
  final precoC = TextEditingController(text: precoAtual?.toString());
  final comissaoC = TextEditingController(text: comissaoAtual?.toString() ?? '0');
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: Text(id == null ? 'Novo Serviço/Produto' : 'Editar', style: const TextStyle(fontWeight: FontWeight.bold)),
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
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          onPressed: () {
            double p = double.tryParse(precoC.text.replaceAll(',', '.')) ?? 0;
            double c = double.tryParse(comissaoC.text.replaceAll(',', '.')) ?? 0;
            if (id == null) DatabaseService().addServico(nomeC.text, p, c);
            else DatabaseService().updateServico(id, nomeC.text, p, c);
            Navigator.pop(context);
          },
          child: const Text('Salvar'),
        )
      ],
    ),
  );
}

void mostrarDialogDespesa(BuildContext context) {
  final descC = TextEditingController();
  final valorC = TextEditingController();
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: const Text('Lançar Despesa', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: descC, decoration: const InputDecoration(labelText: 'Descrição (Ex: Água, Luz)')),
          const SizedBox(height: 10),
          TextField(controller: valorC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Valor (R\$)')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          onPressed: () {
            double v = double.tryParse(valorC.text.replaceAll(',', '.')) ?? 0;
            DatabaseService().registrarDespesaVale('Despesa da Loja', descC.text, v);
            Navigator.pop(context);
          },
          child: const Text('Lançar'),
        )
      ],
    ),
  );
}

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _abaAtual = 0;

  void _abrirMenuCentral(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          border: Border(top: BorderSide(color: Color(0xFF1B1B1B), width: 2)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 6, decoration: BoxDecoration(color: const Color(0xFFCFC4C5), borderRadius: BorderRadius.circular(3))),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0)))),
                child: const Text('O QUE VOCÊ DESEJA ADICIONAR?', style: TextStyle(color: Color(0xFF737784), fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              ),
              _buildMenuItem(context, 'Novo Serviço', Icons.content_cut, const Color(0xFF2559BD), () { Navigator.pop(context); mostrarDialogServico(context); }),
              _buildMenuItem(context, 'Nova Despesa', Icons.receipt_long, const Color(0xFFB22222), () { Navigator.pop(context); mostrarDialogDespesa(context); }),
              _buildMenuItem(context, 'Novo Barbeiro', Icons.person_add, const Color(0xFF2E4A35), () { Navigator.pop(context); mostrarDialogGerenciarEquipe(context); }, isLast: true),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, String title, IconData icon, Color iconColor, VoidCallback onTap, {bool isLast = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFE0E0E0)))),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 32),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B1B1B)))),
            const Icon(Icons.arrow_forward, color: Color(0xFFCFC4C5)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem({required IconData icon, required String label, required int index}) {
    bool isSelected = _abaAtual == index;
    return InkWell(
      onTap: () => setState(() => _abaAtual = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? const Color(0xFF1B1B1B) : const Color(0xFF737784)),
          Text(label, style: TextStyle(fontSize: 12, color: isSelected ? const Color(0xFF1B1B1B) : const Color(0xFF737784), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final List<Widget> abas = [const AbaRelatorios(), const AbaServicos(), const AbaFinanceiro(), const EquipeScreen()];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // surface-background do Stitch
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B1B1B),
        foregroundColor: Colors.white,
        title: const Text("Hero's Barbearia", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: () async { await authService.logout(); if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())); })
        ],
      ),
      body: abas[_abaAtual],
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(top: 20), // empurra o botão levemente para baixo
        child: FloatingActionButton(
          backgroundColor: const Color(0xFF1B1B1B),
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          onPressed: () => _abrirMenuCentral(context),
          child: const Icon(Icons.add, size: 32),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 8,
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: 64, // altura fixa do menu
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTabItem(icon: Icons.analytics, label: 'Relat.', index: 0),
              _buildTabItem(icon: Icons.content_cut, label: 'Serviços', index: 1),
              const SizedBox(width: 48), // Espaço para o FAB
              _buildTabItem(icon: Icons.payments, label: 'Despesas', index: 2),
              _buildTabItem(icon: Icons.groups, label: 'Equipe', index: 3),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// ABA 1: RELATÓRIOS E AVISOS
// ==========================================
class AbaRelatorios extends StatelessWidget {
  const AbaRelatorios({super.key});

  Widget _buildBotao(BuildContext context, String titulo, String tipo, IconData icone) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetalheRelatorioScreen(tipo: tipo, titulo: titulo))),
      child: Container(
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0)))),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Row(
          children: [
            Icon(icone, color: const Color(0xFF1B1B1B), size: 24),
            const SizedBox(width: 16),
            Text('Relatório $titulo', style: const TextStyle(color: Color(0xFF1B1B1B), fontSize: 16, fontWeight: FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  bool _precisaPagar(String diaPagamento, Timestamp? ultimoPag) {
    int hoje = DateTime.now().weekday;
    Map<String, int> dias = {'Segunda': 1, 'Terça': 2, 'Quarta': 3, 'Quinta': 4, 'Sexta': 5, 'Sábado': 6, 'Domingo': 7};
    int diaAlvo = dias[diaPagamento] ?? 6;
    int ontem = hoje - 1;
    if (ontem == 0) ontem = 7;
    if (hoje != diaAlvo && ontem != diaAlvo) return false;
    if (ultimoPag != null && DateTime.now().difference(ultimoPag.toDate()).inDays < 3) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Faturamento Bruto
        StreamBuilder<QuerySnapshot>(
          stream: DatabaseService().getTodosOsCortes(),
          builder: (context, snapshot) {
            double lucroHoje = 0;
            int qtdServicos = 0;
            if (snapshot.hasData) {
              DateTime inicioHoje = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
              var cortesHoje = snapshot.data!.docs.where((doc) {
                var dados = doc.data() as Map<String, dynamic>? ?? {};
                if (dados['data'] == null) return false;
                return (dados['data'] as Timestamp).toDate().isAfter(inicioHoje) || (dados['data'] as Timestamp).toDate().isAtSameMomentAs(inicioHoje);
              }).toList();
              qtdServicos = cortesHoje.length;
              lucroHoje = cortesHoje.fold(0, (s, doc) => s + (((doc.data() as Map)['valor'] ?? 0) as num).toDouble());
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE0E0E0))),
              child: Column(
                children: [
                  const Text('Faturamento Bruto', style: TextStyle(color: Color(0xFF737784), fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  Text('R\$ ${lucroHoje.toStringAsFixed(2)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF0047AB))),
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
            );
          },
        ),

        // Acerto Pendente
        StreamBuilder<QuerySnapshot>(
          stream: DatabaseService().getBarbeiros(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();
            var barbeiros = snapshot.data!.docs;
            
            List<Widget> alertas = [];
            for (var b in barbeiros) {
              var d = b.data() as Map<String, dynamic>;
              String nome = d['nome'] ?? 'Barbeiro';
              String diaPag = d['diaPagamento'] ?? 'Sábado';
              Timestamp? ultimoPag = d['ultimoPagamento'];

              if (_precisaPagar(diaPag, ultimoPag)) {
                alertas.add(
                  Container(
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
                            InkWell(
                              onTap: () => DatabaseService().marcarComoPago(b.id),
                              child: const Text('Pagar', style: TextStyle(color: Color(0xFFBA1A1A), fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                            const SizedBox(width: 24),
                            InkWell(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AcertoBarbeiroScreen(nomeBarbeiro: nome, diaPagamento: diaPag))),
                              child: const Text('Ver Detalhes', style: TextStyle(color: Color(0xFF1B1B1B), fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ],
                        )
                      ],
                    ),
                  )
                );
              }
            }
            return Column(children: alertas);
          },
        ),

        // Relatórios
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE0E0E0))),
          child: ExpansionTile(
            title: const Text('Gerar Relatórios', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B1B1B))),
            iconColor: const Color(0xFF1B1B1B),
            collapsedIconColor: const Color(0xFF1B1B1B),
            children: [
              _buildBotao(context, 'Diário', 'Hoje', Icons.today),
              _buildBotao(context, 'Semanal', 'Semana', Icons.calendar_view_week),
              _buildBotao(context, 'Mensal', 'Mes', Icons.calendar_month),
            ],
          ),
        ),
      ],
    );
  }
}

// ==========================================
// TELA DO PDF
// ==========================================
class DetalheRelatorioScreen extends StatefulWidget {
  final String tipo;
  final String titulo;
  const DetalheRelatorioScreen({super.key, required this.tipo, required this.titulo});
  @override
  State<DetalheRelatorioScreen> createState() => _DetalheRelatorioScreenState();
}

class _DetalheRelatorioScreenState extends State<DetalheRelatorioScreen> {
  final DatabaseService _db = DatabaseService();
  String _barbeiroSelecionado = 'Todos';

  Future<void> _exportarRelatorioPDF(List<QueryDocumentSnapshot> cortes, double total) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Text("Relatório ${widget.titulo} - Heros'app", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text("Barbeiro: $_barbeiroSelecionado", style: const pw.TextStyle(fontSize: 16)),
            pw.Text("Faturamento Bruto: R\$ ${total.toStringAsFixed(2)}", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Text("--- HISTÓRICO DE SERVIÇOS ---", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            ...cortes.map((doc) {
              var d = doc.data() as Map<String, dynamic>;
              DateTime data = (d['data'] as Timestamp).toDate();
              String horaStr = "${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')} às ${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}";
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Text("[$horaStr] ${d['barbeiroNome']} | R\$ ${d['valor'].toStringAsFixed(2)} | Pag: ${d['formaPagamento']}"),
              );
            }),
          ];
        },
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'relatorio_${widget.titulo.toLowerCase()}.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: Text('Relatório ${widget.titulo}')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.getTodosOsCortes(),
        builder: (context, snapshotCortes) {
          if (!snapshotCortes.hasData) return const Center(child: CircularProgressIndicator(color: Colors.black));
          var cortes = snapshotCortes.data!.docs;
          DateTime agora = DateTime.now();
          DateTime inicioHoje = DateTime(agora.year, agora.month, agora.day);
          DateTime inicioSemana = inicioHoje.subtract(Duration(days: agora.weekday - 1));
          DateTime inicioMes = DateTime(agora.year, agora.month, 1);

          var cortesFiltrados = cortes.where((doc) {
            var dados = doc.data() as Map<String, dynamic>;
            if (dados['data'] == null) return false;
            DateTime d = (dados['data'] as Timestamp).toDate();
            if (widget.tipo == 'Hoje') return d.isAfter(inicioHoje) || d.isAtSameMomentAs(inicioHoje);
            if (widget.tipo == 'Semana') return d.isAfter(inicioSemana) || d.isAtSameMomentAs(inicioSemana);
            return d.isAfter(inicioMes) || d.isAtSameMomentAs(inicioMes);
          }).toList();

          Set<String> nomesBarbeiros = {'Todos'};
          for (var c in cortesFiltrados) nomesBarbeiros.add((c.data() as Map<String, dynamic>)['barbeiroNome']);
          if (!nomesBarbeiros.contains(_barbeiroSelecionado)) _barbeiroSelecionado = 'Todos';

          var cortesFinais = cortesFiltrados.where((doc) => _barbeiroSelecionado == 'Todos' || (doc.data() as Map<String, dynamic>)['barbeiroNome'] == _barbeiroSelecionado).toList();
          double totalCaixa = cortesFinais.fold(0, (s, doc) => s + ((doc.data() as Map<String, dynamic>)['valor'] as num).toDouble());

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _barbeiroSelecionado,
                      decoration: InputDecoration(labelText: 'Filtrar por Barbeiro', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.grey[50]),
                      items: nomesBarbeiros.map((n) => DropdownMenuItem(value: n, child: Text(n, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                      onChanged: (v) => setState(() => _barbeiroSelecionado = v!),
                    ),
                    const SizedBox(height: 20),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Faturamento Bruto:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('R\$ ${totalCaixa.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Baixar PDF Oficial'),
                        onPressed: () => _exportarRelatorioPDF(cortesFinais, totalCaixa),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                    )
                  ],
                ),
              ),
              Expanded(
                child: cortesFinais.isEmpty 
                  ? const Center(child: Text('Nenhum corte registrado.', style: TextStyle(color: Colors.grey))) 
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: cortesFinais.length,
                      itemBuilder: (context, index) {
                        var dados = cortesFinais[index].data() as Map<String, dynamic>;
                        List servicos = dados['servicos'] ?? [];
                        DateTime hora = (dados['data'] as Timestamp).toDate();
                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
                          color: Colors.white,
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ListTile(
                              leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.content_cut, color: Colors.white, size: 20)),
                              title: Text('${dados['barbeiroNome']} - R\$ ${dados['valor'].toStringAsFixed(2)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text("${servicos.join(" + ")}\nPag. ${dados['formaPagamento']}", style: const TextStyle(fontSize: 13)),
                              isThreeLine: true,
                              trailing: Text("${hora.day}/${hora.month} às ${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
                            ),
                          ),
                        );
                      },
                    ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ==========================================
// ABAS DE SERVIÇOS E FINANCEIRO
// ==========================================
class AbaServicos extends StatelessWidget {
  const AbaServicos({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: StreamBuilder<QuerySnapshot>(
        stream: DatabaseService().getServicos(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.black));
          var servicos = snapshot.data!.docs;
          if (servicos.isEmpty) return const Center(child: Text('Nenhum serviço.', style: TextStyle(color: Colors.grey)));

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
                itemCount: servicos.length,
                separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE0E0E0)),
                itemBuilder: (context, index) {
                  var s = servicos[index];
                  var d = s.data() as Map<String, dynamic>;
                  double com = d.containsKey('comissao') ? (d['comissao'] as num).toDouble() : 0.0;
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(d['nome'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B1B1B))),
                              const SizedBox(height: 4),
                              Text('R\$ ${(d['preco'] as num).toStringAsFixed(2)}${com > 0 ? ' (Comissão: R\$ $com)' : ''}', style: const TextStyle(fontSize: 14, color: Color(0xFF737784))),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () => mostrarDialogServico(context, id: s.id, nomeAtual: d['nome'], precoAtual: (d['preco'] as num).toDouble(), comissaoAtual: com),
                              child: const Icon(Icons.edit, color: Color(0xFF737784)),
                            ),
                            const SizedBox(width: 16),
                            InkWell(
                              onTap: () => DatabaseService().deleteServico(s.id),
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
          );
        },
      ),
    );
  }
}

class AbaFinanceiro extends StatefulWidget {
  const AbaFinanceiro({super.key});
  @override
  State<AbaFinanceiro> createState() => _AbaFinanceiroState();
}

class _AbaFinanceiroState extends State<AbaFinanceiro> {
  String _filtroMes = 'Mês Atual';

  @override
  Widget build(BuildContext context) {
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
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _filtroMes,
                    isExpanded: true,
                    icon: const Icon(Icons.expand_more, color: Color(0xFF737784)),
                    focusColor: Colors.transparent, // Remove as linhas pretas de foco
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    items: ['Mês Atual', 'Mês Passado', 'Todos'].map((n) => DropdownMenuItem(value: n, child: Text(n, style: const TextStyle(fontWeight: FontWeight.normal, color: Color(0xFF1B1B1B))))).toList(),
                    onChanged: (v) => setState(() => _filtroMes = v!),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: DatabaseService().getDespesasEVales(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.black));
                DateTime agora = DateTime.now();
                DateTime inicioMesAtual = DateTime(agora.year, agora.month, 1);
                DateTime inicioMesPassado = DateTime(agora.year, agora.month - 1, 1);
                var itens = snapshot.data!.docs.where((doc) {
                  var dados = doc.data() as Map<String, dynamic>? ?? {};
                  if (dados['data'] == null) return false;
                  DateTime d = (dados['data'] as Timestamp).toDate();
                  if (_filtroMes == 'Mês Atual') return d.isAfter(inicioMesAtual) || d.isAtSameMomentAs(inicioMesAtual);
                  if (_filtroMes == 'Mês Passado') return d.isAfter(inicioMesPassado) && d.isBefore(inicioMesAtual);
                  return true;
                }).toList();

                if (itens.isEmpty) return const Center(child: Text('Nenhuma despesa.', style: TextStyle(color: Colors.grey)));

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
                      itemCount: itens.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE0E0E0)),
                      itemBuilder: (context, index) {
                        var d = itens[index].data() as Map<String, dynamic>;
                        DateTime data = (d['data'] as Timestamp?)?.toDate() ?? DateTime.now();
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
                                      Text('${d['descricao']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B1B1B))),
                                      const SizedBox(height: 4),
                                      Text('${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}', style: const TextStyle(fontSize: 12, color: Color(0xFF737784))),
                                    ],
                                  ),
                                ],
                              ),
                              Text('- R\$ ${(d['valor'] as num).toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFB22222), fontWeight: FontWeight.bold, fontSize: 18)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}