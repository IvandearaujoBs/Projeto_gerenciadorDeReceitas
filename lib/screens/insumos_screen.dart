import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lojinha_flutter/models/ingredient.dart';
import '../services/database_service.dart';

class InsumosScreen extends StatefulWidget {
  const InsumosScreen({super.key});

  @override
  State<InsumosScreen> createState() => _InsumosScreenState();
}

class _InsumosScreenState extends State<InsumosScreen> {
  List<Ingredient> _ingredients = [];
  bool _isLoading = true;
  String? _errorMsg;

  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$ ',
    decimalDigits: 2,
  );

  final NumberFormat _numberFormatter = NumberFormat.decimalPattern('pt_BR');

  final List<String> _unitsOfMeasure = const ['g', 'kg', 'ml', 'l', 'un'];

  @override
  void initState() {
    super.initState();
    _loadIngredients();
  }

  Future<void> _loadIngredients() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      final result = await DatabaseService.allQuery(
        'SELECT * FROM Ingredients',
      );
      setState(() {
        _ingredients = result.map((map) => Ingredient.fromMap(map)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = 'Erro ao carregar insumos:\n$e';
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddEditDialog({Ingredient? ingredient}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: ingredient?.name ?? '');
    final stockController = TextEditingController(
      text: ingredient?.stockQuantity.toString() ?? '',
    );
    final minimumStockController = TextEditingController(
      text: ingredient?.minimumStock.toString() ?? '',
    );
    final priceController = TextEditingController(
      text: ingredient?.price.toString() ?? '',
    );
    String unit = ingredient?.unit ?? _unitsOfMeasure.first;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ingredient == null ? 'Adicionar Insumo' : 'Editar Insumo'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do Insumo',
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Informe o nome' : null,
                ),
                TextFormField(
                  controller: stockController,
                  decoration: const InputDecoration(
                    labelText: 'Quantidade em Estoque',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Informe a quantidade'
                      : null,
                ),
                TextFormField(
                  controller: minimumStockController,
                  decoration: const InputDecoration(
                    labelText: 'Estoque Mínimo',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Informe o estoque mínimo'
                      : null,
                ),
                DropdownButtonFormField<String>(
                  value: unit,
                  decoration: const InputDecoration(
                    labelText: 'Unidade de Medida',
                  ),
                  items: _unitsOfMeasure
                      .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (value) => unit = value ?? unit,
                  validator: (value) =>
                      value == null ? 'Selecione uma unidade' : null,
                ),
                TextFormField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Preço por Unidade',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Informe o preço' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final name = nameController.text;
                final stockQuantity = double.parse(
                  stockController.text.replaceAll(',', '.'),
                );
                final minimumStock = double.parse(
                  minimumStockController.text.replaceAll(',', '.'),
                );
                final price = double.parse(
                  priceController.text.replaceAll(',', '.'),
                );

                if (ingredient == null) {
                  await DatabaseService.runQuery(
                    'INSERT INTO Ingredients (name, unit, price, stockQuantity, minimumStock) VALUES (?, ?, ?, ?, ?)',
                    [name, unit, price, stockQuantity, minimumStock],
                  );
                } else {
                  await DatabaseService.runQuery(
                    'UPDATE Ingredients SET name = ?, unit = ?, price = ?, stockQuantity = ?, minimumStock = ? WHERE id = ?',
                    [
                      name,
                      unit,
                      price,
                      stockQuantity,
                      minimumStock,
                      ingredient.id,
                    ],
                  );
                }
                _loadIngredients();
                Navigator.of(context).pop();
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteIngredient(Ingredient ingredient) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir "${ingredient.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseService.runQuery('DELETE FROM Ingredients WHERE id = ?', [
        ingredient.id,
      ]);
      _loadIngredients();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Insumos')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMsg != null
          ? Center(
              child: Text(
                _errorMsg!,
                style: const TextStyle(color: Colors.red),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _ingredients.length,
              itemBuilder: (context, index) {
                final ingredient = _ingredients[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(
                      ingredient.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estoque: ${_numberFormatter.format(ingredient.stockQuantity)} ${ingredient.unit}',
                          style: TextStyle(
                            color: ingredient.isLowStock
                                ? Colors.red
                                : Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Preço: ${_currencyFormatter.format(ingredient.price)} por ${ingredient.unit}',
                        ),
                        if (ingredient.minimumStock > 0)
                          Text(
                            'Mínimo: ${_numberFormatter.format(ingredient.minimumStock)} ${ingredient.unit}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () =>
                              _showAddEditDialog(ingredient: ingredient),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteIngredient(ingredient),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEditDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
