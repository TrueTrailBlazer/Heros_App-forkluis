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
import '../../models/corte_model.dart';
import '../../models/servico_model.dart';
import '../../models/despesa_model.dart';
import '../../models/usuario_model.dart';
import '../../widgets/dialogs.dart';
import '../../utils/formatters.dart';

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
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, String title, IconData icon, Color iconColor, VoidCallback onTap, {bool isLast = false}) {
    return GestureDetector(behavior: HitTestBehavior.opaque,
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

  Widget _buildTabItem({required IconData iconOutline, required IconData iconFilled, required String label, required int index}) {
    bool isSelected = _abaAtual == index;
    return GestureDetector(behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _abaAtual = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isSelected ? iconFilled : iconOutline, color: isSelected ? const Color(0xFF1B1B1B) : const Color(0xFF737784)),
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
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 28, errorBuilder: (context, error, stackTrace) => const Icon(Icons.content_cut, size: 24, color: Colors.white)),
            const SizedBox(width: 12),
            const Text("Hero's Barbearia", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white), 
            onPressed: () async {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.white,
                  title: const Text('Sair da conta', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B1B1B))),
                  content: const Text('Tem certeza que deseja sair do aplicativo?', style: TextStyle(color: Color(0xFF737784))),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Color(0xFF737784)))),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB22222), foregroundColor: Colors.white),
                      onPressed: () async {
                        Navigator.pop(context);
                        await authService.logout();
                        if (context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                      },
                      child: const Text('Sair'),
                    ),
                  ],
                ),
              );
            },
          )
        ],
      ),
      body: Stack(
        children: [
          // Conteúdo Principal preenchendo toda a tela, com espaço embaixo para não ser coberto pela navbar
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 64),
              child: abas[_abaAtual],
            ),
          ),
          // HUD de botões Customizado na base
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 64,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildTabItem(iconOutline: Icons.analytics_outlined, iconFilled: Icons.analytics, label: 'Relat.', index: 0)),
                  Expanded(child: _buildTabItem(iconOutline: Icons.design_services_outlined, iconFilled: Icons.design_services, label: 'Serviços', index: 1)),
                  const Expanded(child: SizedBox()), // Espaço para o FAB no meio exato
                  Expanded(child: _buildTabItem(iconOutline: Icons.payments_outlined, iconFilled: Icons.payments, label: 'Despesas', index: 2)),
                  Expanded(child: _buildTabItem(iconOutline: Icons.groups_outlined, iconFilled: Icons.groups, label: 'Equipe', index: 3)),
                ],
              ),
            ),
          ),
          // Botão FAB Flutuante Posicionado
          Positioned(
            bottom: 20, // Fica mais para dentro do nav bar, saltando levemente para fora
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 64,
                height: 64,
                child: FloatingActionButton(
                  backgroundColor: const Color(0xFF1B1B1B),
                  foregroundColor: Colors.white,
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                  onPressed: () => _abrirMenuCentral(context),
                  child: const Icon(Icons.add, size: 32),
                ),
              ),
            ),
          ),
        ],
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
    return GestureDetector(behavior: HitTestBehavior.opaque,
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
        StreamBuilder<List<CorteModel>>(
          stream: DatabaseService().getTodosOsCortes(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text('Erro DB: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            double lucroHoje = 0;
            int qtdServicos = 0;
            if (snapshot.hasData) {
              DateTime inicioHoje = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
              var cortesHoje = snapshot.data!.where((corte) {
                return corte.data.isAfter(inicioHoje) || corte.data.isAtSameMomentAs(inicioHoje);
              }).toList();
              qtdServicos = cortesHoje.length;
              lucroHoje = cortesHoje.fold(0, (s, corte) => s + corte.valor);
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE0E0E0))),
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
            );
          },
        ),

        // Acerto Pendente
        StreamBuilder<List<UsuarioModel>>(
          stream: DatabaseService().getBarbeiros(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text('Erro DB: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (!snapshot.hasData) return const SizedBox();
            var barbeiros = snapshot.data!;
            
            List<Widget> alertas = [];
            for (var b in barbeiros) {
              String nome = b.nome;
              String diaPag = b.diaPagamento ?? 'Sábado';
              Timestamp? ultimoPag = b.ultimoPagamento;

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
                            GestureDetector(behavior: HitTestBehavior.opaque,
                              onTap: () => DatabaseService().marcarComoPago(b.id),
                              child: const Text('Pagar', style: TextStyle(color: Color(0xFFBA1A1A), fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                            const SizedBox(width: 24),
                            GestureDetector(behavior: HitTestBehavior.opaque,
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
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              shape: const Border(),
              collapsedShape: const Border(),
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

  Future<void> _exportarRelatorioPDF(List<CorteModel> cortes, double total) async {
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
            pw.Text("Faturamento Bruto: R\$ ${Formatters.moeda(total)}", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Text("--- HISTÓRICO DE SERVIÇOS ---", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            ...cortes.map((corte) {
              DateTime data = corte.data;
              String horaStr = Formatters.dataHora(data);
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Text("[$horaStr] ${corte.barbeiroNome} | R\$ ${Formatters.moeda(corte.valor)} | Pag: ${corte.formaPagamento}"),
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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B1B1B),
        foregroundColor: Colors.white,
        title: Text('Relatório ${widget.titulo}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: StreamBuilder<List<CorteModel>>(
        stream: _db.getTodosOsCortes(),
        builder: (context, snapshotCortes) {
          if (!snapshotCortes.hasData) return const Center(child: CircularProgressIndicator(color: Colors.black));
          var cortes = snapshotCortes.data!;
          DateTime agora = DateTime.now();
          DateTime inicioHoje = DateTime(agora.year, agora.month, agora.day);
          DateTime inicioSemana = inicioHoje.subtract(Duration(days: agora.weekday - 1));
          DateTime inicioMes = DateTime(agora.year, agora.month, 1);

          var cortesFiltrados = cortes.where((corte) {
            DateTime d = corte.data;
            if (widget.tipo == 'Hoje') return d.isAfter(inicioHoje) || d.isAtSameMomentAs(inicioHoje);
            if (widget.tipo == 'Semana') return d.isAfter(inicioSemana) || d.isAtSameMomentAs(inicioSemana);
            return d.isAfter(inicioMes) || d.isAtSameMomentAs(inicioMes);
          }).toList();

          Set<String> nomesBarbeiros = {'Todos'};
          for (var c in cortesFiltrados) nomesBarbeiros.add(c.barbeiroNome);
          if (!nomesBarbeiros.contains(_barbeiroSelecionado)) _barbeiroSelecionado = 'Todos';

          var cortesFinais = cortesFiltrados.where((c) => _barbeiroSelecionado == 'Todos' || c.barbeiroNome == _barbeiroSelecionado).toList();
          double totalCaixa = cortesFinais.fold(0, (s, c) => s + c.valor);

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
                ),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _barbeiroSelecionado,
                      decoration: InputDecoration(
                        labelText: 'Filtrar por Barbeiro', 
                        labelStyle: const TextStyle(color: Color(0xFF737784)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                        filled: true, 
                        fillColor: Colors.white
                      ),
                      items: nomesBarbeiros.map((n) => DropdownMenuItem(value: n, child: Text(n, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B1B1B))))).toList(),
                      onChanged: (v) => setState(() => _barbeiroSelecionado = v!),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                      children: [
                        const Text('Faturamento Bruto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF737784), letterSpacing: 1.2)),
                        Text('R\$ ${Formatters.moeda(totalCaixa)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF006400))),
                      ]
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Baixar PDF Oficial'),
                        onPressed: () => _exportarRelatorioPDF(cortesFinais, totalCaixa),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B1B1B), 
                          foregroundColor: Colors.white, 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              Expanded(
                child: cortesFinais.isEmpty 
                  ? const Center(child: Text('Nenhum corte registrado.', style: TextStyle(color: Color(0xFF737784)))) 
                  : SingleChildScrollView(
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
                          itemCount: cortesFinais.length,
                          separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE0E0E0)),
                          itemBuilder: (context, index) {
                            var corte = cortesFinais[index];
                            List<String> servicos = corte.servicos;
                            DateTime hora = corte.data;
                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(8)),
                                    child: const Icon(Icons.content_cut, color: Color(0xFF1B1B1B), size: 20),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${corte.barbeiroNome}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B1B1B))),
                                        const SizedBox(height: 4),
                                        Text("${servicos.join(" + ")}\nPag. ${corte.formaPagamento}", style: const TextStyle(fontSize: 13, color: Color(0xFF737784))),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('R\$ ${Formatters.moeda(corte.valor)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B1B1B))),
                                      const SizedBox(height: 4),
                                      Text(Formatters.dataHora(hora), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF737784), fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
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
      child: StreamBuilder<List<ServicoModel>>(
        stream: DatabaseService().getServicos(),
        builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text('Erro DB: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.black));
          var servicos = snapshot.data!;
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
                              Text(servico.nome, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B1B1B))),
                              const SizedBox(height: 4),
                              Text('R\$ ${Formatters.moeda(servico.preco)}${com > 0 ? ' (Comissão: R\$ $com)' : ''}', style: const TextStyle(fontSize: 14, color: Color(0xFF737784))),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(behavior: HitTestBehavior.opaque,
                              onTap: () => mostrarDialogServico(context, id: servico.id, nomeAtual: servico.nome, precoAtual: servico.preco, comissaoAtual: com),
                              child: const Icon(Icons.edit, color: Color(0xFF737784)),
                            ),
                            const SizedBox(width: 16),
                            GestureDetector(behavior: HitTestBehavior.opaque,
                              onTap: () {
                                mostrarDialogConfirmacao(
                                  context, 
                                  titulo: 'Excluir Serviço', 
                                  mensagem: 'Tem certeza que deseja excluir o serviço "${servico.nome}"? Essa ação não pode ser desfeita.', 
                                  onConfirmar: () => DatabaseService().deleteServico(servico.id),
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
            child: StreamBuilder<List<DespesaModel>>(
              stream: DatabaseService().getDespesasEVales(),
              builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text('Erro DB: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.black));
                DateTime agora = DateTime.now();
                DateTime inicioMesAtual = DateTime(agora.year, agora.month, 1);
                DateTime inicioMesPassado = DateTime(agora.year, agora.month - 1, 1);
                var itens = snapshot.data!.where((despesa) {
                  DateTime d = despesa.data;
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
                                      Text(despesa.descricao, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B1B1B))),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
