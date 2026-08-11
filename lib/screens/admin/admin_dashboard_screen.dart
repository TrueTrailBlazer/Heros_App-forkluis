import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../auth/login_screen.dart';
import '../../widgets/dialogs.dart';

// Abas extraídas
import 'tabs/relatorios_tab.dart';
import 'tabs/servicos_tab.dart';
import 'tabs/financeiro_tab.dart';
import 'equipe_screen.dart';

/// Scaffold principal do painel Admin.
/// Contém APENAS a navegação e o menu central. As abas vivem em /tabs/.
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          border: Border(top: BorderSide(color: Theme.of(context).primaryColor, width: 2)),
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
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.surfaceVariant))),
                child: const Text('O QUE VOCÊ DESEJA ADICIONAR?', style: TextStyle(color: Color(0xFF737784), fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              ),
              _buildMenuItem(context, 'Novo Serviço', Icons.content_cut, const Color(0xFF2559BD), () { 
                Navigator.pop(context); 
                mostrarDialogServico(context, onSalvar: (nome, preco, comissao) {
                  Provider.of<DatabaseService>(context, listen: false).addServico(nome, preco, comissao);
                }); 
              }),
              _buildMenuItem(context, 'Nova Despesa', Icons.receipt_long, const Color(0xFFB22222), () { 
                Navigator.pop(context); 
                mostrarDialogDespesa(context, onSalvar: (descricao, valor) {
                  Provider.of<DatabaseService>(context, listen: false).registrarDespesaVale('Despesa da Loja', descricao, valor);
                }); 
              }),
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
        decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: Theme.of(context).colorScheme.surfaceVariant))),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 32),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).primaryColor))),
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
          Icon(isSelected ? iconFilled : iconOutline, color: isSelected ? Theme.of(context).primaryColor : const Color(0xFF737784)),
          Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Theme.of(context).primaryColor : const Color(0xFF737784), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final List<Widget> abas = [const AbaRelatorios(), const AbaServicos(), const AbaFinanceiro(), const EquipeScreen()];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Image.asset('assets/appbar-icon.png', height: 28, errorBuilder: (context, error, stackTrace) => const Icon(Icons.content_cut, size: 24, color: Colors.white)),
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
                  title: Text('Sair da conta', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                  content: const Text('Tem certeza que deseja sair da sua conta?', style: TextStyle(color: Color(0xFF737784))),
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
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 64),
              child: abas[_abaAtual],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Theme.of(context).colorScheme.surfaceVariant)),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildTabItem(iconOutline: Icons.analytics_outlined, iconFilled: Icons.analytics, label: 'Relat.', index: 0)),
                  Expanded(child: _buildTabItem(iconOutline: Icons.design_services_outlined, iconFilled: Icons.design_services, label: 'Serviços', index: 1)),
                  const Expanded(child: SizedBox()),
                  Expanded(child: _buildTabItem(iconOutline: Icons.payments_outlined, iconFilled: Icons.payments, label: 'Despesas', index: 2)),
                  Expanded(child: _buildTabItem(iconOutline: Icons.groups_outlined, iconFilled: Icons.groups, label: 'Equipe', index: 3)),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 64,
                height: 64,
                child: FloatingActionButton(
                  backgroundColor: Theme.of(context).primaryColor,
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
