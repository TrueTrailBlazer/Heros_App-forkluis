import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../services/database_service.dart';
import '../../models/corte_model.dart';
import '../../utils/formatters.dart';

/// Tela de detalhe de relatório com filtro por barbeiro e exportação para PDF.
class DetalheRelatorioScreen extends StatefulWidget {
  final String tipo;
  final String titulo;
  const DetalheRelatorioScreen({super.key, required this.tipo, required this.titulo});
  @override
  State<DetalheRelatorioScreen> createState() => _DetalheRelatorioScreenState();
}

class _DetalheRelatorioScreenState extends State<DetalheRelatorioScreen> {
  late DatabaseService _db;
  String _barbeiroSelecionado = 'Todos';
  late Stream<List<CorteModel>> _streamCortes;

  @override
  void initState() {
    super.initState();
    _db = Provider.of<DatabaseService>(context, listen: false);
    DateTime agora = DateTime.now();
    DateTime inicioHoje = DateTime(agora.year, agora.month, agora.day);
    DateTime inicioSemana = inicioHoje.subtract(Duration(days: agora.weekday - 1));
    DateTime inicioMes = DateTime(agora.year, agora.month, 1);
    
    DateTime dataFiltro;
    if (widget.tipo == 'Hoje') dataFiltro = inicioHoje;
    else if (widget.tipo == 'Semana') dataFiltro = inicioSemana;
    else dataFiltro = inicioMes;

    _streamCortes = _db.getTodosOsCortes(dataInicio: dataFiltro);
  }

  /// Exporta o relatório para PDF com tratamento de exceções.
  Future<void> _exportarRelatorioPDF(List<CorteModel> cortes, double total) async {
    try {
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar PDF: $e'),
            backgroundColor: const Color(0xFFBA1A1A),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        title: Text('Relatório ${widget.titulo}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: StreamBuilder<List<CorteModel>>(
        stream: _streamCortes,
        builder: (context, snapshotCortes) {
          if (!snapshotCortes.hasData) return const Center(child: CircularProgressIndicator(color: Colors.black));
          var cortes = snapshotCortes.data!;
          
          var cortesFiltrados = cortes;

          Set<String> nomesBarbeiros = {'Todos'};
          for (var c in cortesFiltrados) nomesBarbeiros.add(c.barbeiroNome);
          if (!nomesBarbeiros.contains(_barbeiroSelecionado)) _barbeiroSelecionado = 'Todos';

          var cortesFinais = cortesFiltrados.where((c) => _barbeiroSelecionado == 'Todos' || c.barbeiroNome == _barbeiroSelecionado).toList();
          double totalCaixa = cortesFinais.fold(0, (s, c) => s + c.valor);

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.surfaceVariant)),
                ),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _barbeiroSelecionado,
                      decoration: InputDecoration(
                        labelText: 'Filtrar por Barbeiro', 
                        labelStyle: const TextStyle(color: Color(0xFF737784)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Theme.of(context).colorScheme.surfaceVariant)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Theme.of(context).colorScheme.surfaceVariant)),
                        filled: true, 
                        fillColor: Colors.white
                      ),
                      items: nomesBarbeiros.map((n) => DropdownMenuItem(value: n, child: Text(n, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)))).toList(),
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
                          backgroundColor: Theme.of(context).primaryColor, 
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
                          border: Border.all(color: Theme.of(context).colorScheme.surfaceVariant),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: cortesFinais.length,
                          separatorBuilder: (context, index) => Divider(height: 1, color: Theme.of(context).colorScheme.surfaceVariant),
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
                                    child: Icon(Icons.content_cut, color: Theme.of(context).primaryColor, size: 20),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(corte.barbeiroNome, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).primaryColor)),
                                        const SizedBox(height: 4),
                                        Text("${servicos.join(" + ")}\nPag. ${corte.formaPagamento}", style: const TextStyle(fontSize: 13, color: Color(0xFF737784))),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('R\$ ${Formatters.moeda(corte.valor)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).primaryColor)),
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
