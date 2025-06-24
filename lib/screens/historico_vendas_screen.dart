import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';

class HistoricoVendasScreen extends StatefulWidget {
  const HistoricoVendasScreen({Key? key}) : super(key: key);

  @override
  _HistoricoVendasScreenState createState() => _HistoricoVendasScreenState();
}

class _HistoricoVendasScreenState extends State<HistoricoVendasScreen> {
  List<Map<String, Object?>> _vendas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVendas();
  }

  Future<void> _loadVendas() async {
    setState(() => _isLoading = true);
    final vendas = await DatabaseService.allQuery(
      'SELECT * FROM Sales ORDER BY SaleDateTime DESC',
    );
    setState(() {
      _vendas = vendas;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );
    final dateTimeFormatter = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de Vendas')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vendas.isEmpty
          ? const Center(child: Text('Nenhuma venda registrada.'))
          : ListView.builder(
              itemCount: _vendas.length,
              itemBuilder: (context, index) {
                final venda = _vendas[index];

                // --- Correções de Segurança (Null-Safety) ---
                final saleDateTimeStr = venda['saleDateTime']?.toString();
                final dataVenda = saleDateTimeStr != null
                    ? DateTime.parse(saleDateTimeStr)
                    : DateTime.now();

                final productName =
                    venda['productNameAtSale']?.toString() ??
                    'Produto Desconhecido';
                final quantity = (venda['quantitySold'] as num?) ?? 0;
                final unitPrice = (venda['unitPriceAtSale'] as num?) ?? 0.0;
                final profit = (venda['profitValueAtSale'] as num?) ?? 0.0;
                final total = unitPrice * quantity;
                // --- Fim das Correções ---

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: ListTile(
                    title: Text(
                      productName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '$quantity un. - ${dateTimeFormatter.format(dataVenda)}',
                    ),
                    trailing: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Total: ${currencyFormatter.format(total)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Lucro: ${currencyFormatter.format(profit)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: profit < 0 ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
