import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../../services/calculation_service.dart';
import 'configuracoes_precificacao_screen.dart';

class DadosScreen extends StatelessWidget {
  const DadosScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custo de Produção'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ConfiguracoesPrecificacaoScreen(),
                ),
              );
            },
            tooltip: 'Configurações de Precificação',
          ),
        ],
      ),
      body: const TempoProducaoTab(),
    );
  }
}

class TempoProducaoTab extends StatefulWidget {
  const TempoProducaoTab({Key? key}) : super(key: key);

  @override
  _TempoProducaoTabState createState() => _TempoProducaoTabState();
}

class _TempoProducaoTabState extends State<TempoProducaoTab> {
  double _custoHora = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustoHora();
  }

  Future<void> _loadCustoHora() async {
    setState(() => _isLoading = true);
    final custo = await CalculationService.calculateHourlyCost();
    if (mounted) {
      setState(() {
        _custoHora = custo;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Center(
            child: Card(
              elevation: 4,
              margin: const EdgeInsets.all(20),
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Custo da Hora de Trabalho',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      NumberFormat.currency(
                        locale: 'pt_BR',
                        symbol: 'R\$',
                      ).format(_custoHora),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Este valor é calculado com base nas suas despesas e jornada de trabalho.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _loadCustoHora,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Recalcular'),
                    ),
                  ],
                ),
              ),
            ),
          );
  }
}
