import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lojinha_flutter/services/database_service.dart';

class RelatoriosScreen extends StatefulWidget {
  const RelatoriosScreen({super.key});

  @override
  State<RelatoriosScreen> createState() => _RelatoriosScreenState();
}

class _RelatoriosScreenState extends State<RelatoriosScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _profitabilityData = [];

  @override
  void initState() {
    super.initState();
    _loadProfitabilityData();
  }

  Future<void> _loadProfitabilityData() async {
    setState(() => _isLoading = true);
    final data = await DatabaseService.allQuery('''
      SELECT 
        ProductNameAtSale, 
        SUM(ProfitValueAtSale) as TotalProfit
      FROM Sales
      WHERE ProfitValueAtSale IS NOT NULL
      GROUP BY ProductNameAtSale
      ORDER BY TotalProfit DESC
    ''');
    setState(() {
      _profitabilityData = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Relatório de Lucratividade')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profitabilityData.isEmpty
          ? const Center(
              child: Text(
                'Nenhuma venda registrada para gerar o relatório.',
                textAlign: TextAlign.center,
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Text(
                  'Lucro Total por Produto',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 24,
                      right: 16,
                      bottom: 8,
                    ),
                    child: SizedBox(
                      height: 400,
                      child: BarChart(_buildBarChartData()),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  BarChartData _buildBarChartData() {
    final currencyFormatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY:
          (_profitabilityData
              .map((d) => (d['TotalProfit'] as num?) ?? 0)
              .reduce((a, b) => a > b ? a : b)) *
          1.2,
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final item = _profitabilityData[groupIndex];
            final productName =
                item['ProductNameAtSale']?.toString() ?? 'Produto Desconhecido';
            return BarTooltipItem(
              '$productName\n',
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              children: <TextSpan>[
                TextSpan(
                  text: currencyFormatter.format(rod.toY),
                  style: const TextStyle(
                    color: Colors.yellow,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              textAlign: TextAlign.center,
            );
          },
          tooltipPadding: const EdgeInsets.all(8),
          tooltipMargin: 8,
          tooltipBorder: const BorderSide(color: Colors.blueGrey, width: 1),
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < _profitabilityData.length) {
                final productName =
                    _profitabilityData[index]['ProductNameAtSale']
                        ?.toString() ??
                    'Produto Desconhecido';
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Transform.rotate(
                    angle: -1.57,
                    child: Text(
                      productName.characters.take(10).toString(),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                );
              }
              return const Text('');
            },
            reservedSize: 42,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) => Text(
              currencyFormatter.format(value),
              style: const TextStyle(fontSize: 10),
            ),
            reservedSize: 60,
          ),
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) {
          return const FlLine(
            color: Colors.grey,
            strokeWidth: 0.5,
            dashArray: [5, 5],
          );
        },
      ),
      borderData: FlBorderData(show: false),
      barGroups: _profitabilityData
          .asMap()
          .entries
          .map(
            (entry) => BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: (entry.value['TotalProfit'] as num?)?.toDouble() ?? 0.0,
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 16,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }
}
