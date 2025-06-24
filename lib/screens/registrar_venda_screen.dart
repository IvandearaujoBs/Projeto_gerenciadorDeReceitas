import 'package:flutter/material.dart';
import 'package:lojinha_flutter/models/recipe.dart';
import 'package:lojinha_flutter/services/database_service.dart';

class RegistrarVendaScreen extends StatefulWidget {
  const RegistrarVendaScreen({super.key});

  @override
  _RegistrarVendaScreenState createState() => _RegistrarVendaScreenState();
}

class _RegistrarVendaScreenState extends State<RegistrarVendaScreen> {
  final _formKey = GlobalKey<FormState>();
  Recipe? _selectedRecipe;
  final _quantityController = TextEditingController();

  List<Recipe> _recipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    setState(() => _isLoading = true);
    final data = await DatabaseService.allQuery(
      'SELECT * FROM Recipes WHERE stockQuantity > 0',
    );
    setState(() {
      _recipes = data.map((item) => Recipe.fromMap(item)).toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Venda')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    DropdownButtonFormField<Recipe>(
                      value: _selectedRecipe,
                      hint: const Text('Selecione uma Receita'),
                      isExpanded: true,
                      items: _recipes.map((recipe) {
                        return DropdownMenuItem<Recipe>(
                          value: recipe,
                          child: Text(recipe.name),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedRecipe = value),
                      validator: (value) => value == null
                          ? 'Por favor, selecione uma receita'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantidade Vendida',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira a quantidade';
                        }
                        final quantity = int.tryParse(value);
                        if (quantity == null || quantity <= 0) {
                          return 'A quantidade deve ser um número positivo';
                        }
                        if (_selectedRecipe != null &&
                            quantity > _selectedRecipe!.stockQuantity) {
                          return 'Estoque insuficiente. Disponível: ${_selectedRecipe!.stockQuantity}';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _registerSale,
                      child: const Text('Registrar'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _registerSale() async {
    if (!_formKey.currentState!.validate() || _selectedRecipe == null) {
      return;
    }

    final recipe = _selectedRecipe!;
    final quantitySold = int.parse(_quantityController.text);

    try {
      // Registrar na tabela de vendas
      await DatabaseService.runQuery(
        '''
        INSERT INTO Sales (
          saleDateTime,
          recipe_id,
          productNameAtSale,
          quantitySold,
          unitPriceAtSale,
          unitCostAtSale,
          profitValueAtSale
        ) VALUES (?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          DateTime.now().toIso8601String(),
          recipe.id,
          recipe.name,
          quantitySold,
          recipe.price,
          recipe.cost,
          (recipe.price - recipe.cost) * quantitySold, // Lucro total da venda
        ],
      );

      // Atualizar o estoque
      final newStock = recipe.stockQuantity - quantitySold;
      await DatabaseService.runQuery(
        'UPDATE Recipes SET stockQuantity = ? WHERE id = ?',
        [newStock, recipe.id!],
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venda registrada com sucesso!')),
      );

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ocorreu um erro ao registrar a venda: $e')),
      );
    }
  }
}
