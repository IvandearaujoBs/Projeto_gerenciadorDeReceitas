import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

import '../models/user_provider.dart';
import '../models/ingredient.dart';
import '../services/database_service.dart';
import 'minhas_receitas_screen.dart';
import 'historico_vendas_screen.dart';
import 'insumos_screen.dart';
import 'stock_control_screen.dart';
import 'login_screen.dart';
import 'registrar_venda_screen.dart';
import 'relatorios_screen.dart';
import 'settings_screen.dart';
import 'shopping_list_screen.dart';

class PaginaPrincipalScreen extends StatefulWidget {
  const PaginaPrincipalScreen({Key? key}) : super(key: key);

  @override
  State<PaginaPrincipalScreen> createState() => _PaginaPrincipalScreenState();
}

class _PaginaPrincipalScreenState extends State<PaginaPrincipalScreen> {
  List<Ingredient> _lowStockItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLowStockItems();
  }

  Future<void> _loadLowStockItems() async {
    try {
      final items = await DatabaseService.getLowStockIngredients();
      if (mounted) {
        setState(() {
          _lowStockItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Principal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              userProvider.logout();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner de alerta para estoque baixo
          if (_lowStockItems.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                border: Border.all(color: Colors.orange.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Estoque Baixo',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_lowStockItems.length} produto(s) com estoque baixo',
                    style: TextStyle(color: Colors.orange.shade700),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const InsumosScreen(),
                        ),
                      ).then((_) => _loadLowStockItems());
                    },
                    icon: const Icon(Icons.inventory_2),
                    label: const Text('Ver Insumos'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          // Grid principal
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(16.0),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: <Widget>[
                _buildMenuButton(
                  context,
                  'Registrar Venda',
                  Icons.point_of_sale,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegistrarVendaScreen(),
                    ),
                  ),
                ),
                _buildMenuButton(
                  context,
                  'Minhas Receitas',
                  Icons.receipt_long,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MinhasReceitasScreen(),
                    ),
                  ),
                ),
                _buildMenuButton(
                  context,
                  'Insumos',
                  Icons.inventory_2,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InsumosScreen(),
                    ),
                  ),
                ),
                _buildMenuButton(
                  context,
                  'Histórico',
                  Icons.history,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HistoricoVendasScreen(),
                    ),
                  ),
                ),
                _buildMenuButton(
                  context,
                  'Relatórios',
                  Icons.analytics,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RelatoriosScreen(),
                    ),
                  ),
                ),
                _buildMenuButton(
                  context,
                  'Configurações',
                  Icons.settings,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.menu,
        activeIcon: Icons.close,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        overlayOpacity: 0.2,
        spacing: 10,
        spaceBetweenChildren: 8,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.shopping_cart),
            label: 'Lista de Compras',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ShoppingListScreen(),
              ),
            ),
          ),
          SpeedDialChild(
            child: const Icon(Icons.inventory_2),
            label: 'Controle de Estoque',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StockControlScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 50, color: Theme.of(context).primaryColor),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
