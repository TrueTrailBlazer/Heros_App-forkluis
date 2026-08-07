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

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _abaAtual = 0;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    final List<Widget> abas = [
      const AbaRelatorios(),
      const AbaServicos(),
      const AbaFinanceiro(),
      const EquipeScreen(), // Puxando do arquivo separado
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Heros'app", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.logout();
              if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          )
        ],
      ),
      body: abas[_abaAtual],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: BottomNavigationBar(
          currentIndex: _abaAtual,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
          elevation: 0,
          onTap: (index) => setState(() => _abaAtual = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Relatórios'),
            BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Serviços'),
            BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'Despesas'),
            BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Equipe'),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// ABA 1: RELATÓRIOS E AVISOS (COM DOIS BOTÕES)
// ==========================================
class AbaRelatorios extends StatelessWidget {
  const AbaRelatorios({super.key});

  Widget _buildBotao(BuildContext context, String titulo, String tipo, IconData icone) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetalheRelatorioScreen(tipo: tipo, titulo: titulo))),
      child: Card(
        color: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Row(
            children: [
              Icon(icone, color: Colors.white, size: 28),
              const SizedBox(width: 20),
              Text(titulo, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 18),
            ],
          ),
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
      padding: const EdgeInsets.all(20),
      children: [
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
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red)),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Acerto: $nome', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                              const Text('Fechamento pendente!', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, minimumSize: const Size(80, 30), padding: EdgeInsets.zero),
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AcertoBarbeiroScreen(nomeBarbeiro: nome, diaPagamento: diaPag))),
                              child: const Text('RESUMO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 5),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, minimumSize: const Size(80, 30), padding: EdgeInsets.zero),
                              onPressed: () => DatabaseService().marcarComoPago(b.id),
                              child: const Text('PAGO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            )
                          ],
                        )
                      ],
                    ),
                  )
                );
              }
            }
            if (alertas.isEmpty) return const SizedBox();
            return Column(children: alertas);
          },
        ),

        const Text('Exportar Relatórios PDF:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 15),
        _buildBotao(context, 'Diário', 'Hoje', Icons.today),
        _buildBotao(context, 'Semanal', 'Semana', Icons.date_range),
        _buildBotao(context, 'Mensal', 'Mes', Icons.calendar_month),
        
        const SizedBox(height: 30),
        const Text('Dashboard - Hoje', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 15),
        
        StreamBuilder<QuerySnapshot>(
          stream: DatabaseService().getTodosOsCortes(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.black));
            DateTime inicioHoje = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
            var cortesHoje = snapshot.data!.docs.where((doc) {
              var dados = doc.data() as Map<String, dynamic>? ?? {};
              if (dados['data'] == null) return false;
              return (dados['data'] as Timestamp).toDate().isAfter(inicioHoje) || (dados['data'] as Timestamp).toDate().isAtSameMomentAs(inicioHoje);
            }).toList();

            double lucroHoje = cortesHoje.fold(0, (s, doc) => s + (((doc.data() as Map)['valor'] ?? 0) as num).toDouble());

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Faturamento Bruto do Dia', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text('R\$ ${lucroHoje.toStringAsFixed(2)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 5),
                  Text('${cortesHoje.length} serviços realizados hoje', style: const TextStyle(color: Colors.grey)),
                ],
              ),
            );
          },
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
// ABAS DE SERVIÇOS E FINANCEIRO (Permanecem idênticas ao arquivo antigo)
// ==========================================
class AbaServicos extends StatelessWidget {
  const AbaServicos({super.key});

  void _mostrarDialog(BuildContext context, {String? id, String? nomeAtual, double? precoAtual, double? comissaoAtual}) {
    final nomeC = TextEditingController(text: nomeAtual);
    final precoC = TextEditingController(text: precoAtual?.toString());
    final comissaoC = TextEditingController(text: comissaoAtual?.toString() ?? '0');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
            onPressed: () {
              double p = double.parse(precoC.text.replaceAll(',', '.'));
              double c = double.parse(comissaoC.text.replaceAll(',', '.'));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () => _mostrarDialog(context), child: const Icon(Icons.add, color: Colors.white)
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: DatabaseService().getServicos(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.black));
          var servicos = snapshot.data!.docs;
          if (servicos.isEmpty) return const Center(child: Text('Nenhum serviço.', style: TextStyle(color: Colors.grey)));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: servicos.length,
            itemBuilder: (context, index) {
              var s = servicos[index];
              var d = s.data() as Map<String, dynamic>;
              double com = d.containsKey('comissao') ? (d['comissao'] as num).toDouble() : 0.0;
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(d['nome'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Preço: R\$ ${(d['preco'] as num).toStringAsFixed(2)}${com > 0 ? ' | Com: R\$ $com' : ''}', style: const TextStyle(fontSize: 13)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.black54), onPressed: () => _mostrarDialog(context, id: s.id, nomeAtual: d['nome'], precoAtual: (d['preco'] as num).toDouble(), comissaoAtual: com)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => DatabaseService().deleteServico(s.id)),
                    ],
                  ),
                ),
              );
            },
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

  void _mostrarDialog(BuildContext context) {
    final descC = TextEditingController();
    final valorC = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
            onPressed: () {
              double v = double.parse(valorC.text.replaceAll(',', '.'));
              DatabaseService().registrarDespesaVale('Despesa da Loja', descC.text, v);
              Navigator.pop(context);
            },
            child: const Text('Lançar'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () => _mostrarDialog(context), child: const Icon(Icons.add, color: Colors.white)
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: DropdownButtonFormField<String>(
              value: _filtroMes,
              decoration: InputDecoration(labelText: 'Filtrar Lançamentos', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.grey[50]),
              items: ['Mês Atual', 'Mês Passado', 'Todos'].map((n) => DropdownMenuItem(value: n, child: Text(n, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
              onChanged: (v) => setState(() => _filtroMes = v!),
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

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: itens.length,
                  itemBuilder: (context, index) {
                    var d = itens[index].data() as Map<String, dynamic>;
                    DateTime data = (d['data'] as Timestamp?)?.toDate() ?? DateTime.now();
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.money_off, color: Colors.white)),
                        title: Text('${d['descricao']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${data.day}/${data.month}/${data.year}", style: const TextStyle(fontSize: 12)),
                        trailing: Text('- R\$ ${(d['valor'] as num).toStringAsFixed(2)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}