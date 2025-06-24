import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/recipe.dart';
import '../models/ingredient.dart';
import '../models/recipe_ingredient.dart';
import '../services/database_service.dart';
import '../services/calculation_service.dart';

class FichaTecnicaScreen extends StatefulWidget {
  final Recipe? recipe;

  const FichaTecnicaScreen({Key? key, this.recipe}) : super(key: key);

  @override
  State<FichaTecnicaScreen> createState() => _FichaTecnicaScreenState();
}

class _FichaTecnicaScreenState extends State<FichaTecnicaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _preparationTimeController = TextEditingController();
  final _recipeYieldController = TextEditingController();
  final _weightPerUnitController = TextEditingController();
  final _profitMarginController = TextEditingController();
  final _notesController = TextEditingController();

  Recipe? _recipe;
  List<Ingredient> _allIngredients = [];
  List<RecipeIngredient> _recipeIngredients = [];
  Map<String, dynamic>? _pricingData;
  bool _isLoading = false;

  String _selectedTimeUnit = 'Minutos';

  @override
  void initState() {
    super.initState();
    _recipe = widget.recipe;
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _preparationTimeController.dispose();
    _recipeYieldController.dispose();
    _weightPerUnitController.dispose();
    _profitMarginController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Carregar todos os ingredientes disponíveis
      _allIngredients = await DatabaseService.getAllIngredients();

      if (_recipe != null) {
        // Carregar dados da receita existente
        _nameController.text = _recipe!.name;

        final currentMinutes = _recipe!.preparationTimeMinutes;
        if (currentMinutes > 0 && currentMinutes % 60 == 0) {
          _preparationTimeController.text = (currentMinutes / 60)
              .toStringAsFixed(0);
          _selectedTimeUnit = 'Horas';
        } else {
          _preparationTimeController.text = currentMinutes.toString();
          _selectedTimeUnit = 'Minutos';
        }

        _recipeYieldController.text = _recipe!.recipeYield.toString();
        _weightPerUnitController.text = _recipe!.weightPerUnit.toString();
        _profitMarginController.text = (_recipe!.profitMargin * 100).toString();
        _notesController.text = _recipe!.notes ?? '';

        // Carregar ingredientes da receita
        _recipeIngredients = await DatabaseService.getRecipeIngredients(
          _recipe!.id!,
        );

        // Calcular precificação
        await _calculatePricing();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _calculatePricing() async {
    if (_recipe?.id == null) return;

    try {
      final pricingData = await CalculationService.calculateFullPricing(
        _recipe!.id!,
      );
      setState(() {
        _pricingData = pricingData;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao calcular precificação: $e')),
      );
    }
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Cria uma receita temporária com os dados do formulário
      final tempRecipe = Recipe(
        id: _recipe?.id,
        name: _nameController.text.trim(),
        preparationTimeMinutes: _getPreparationTimeInMinutes(),
        recipeYield: int.tryParse(_recipeYieldController.text) ?? 1,
        weightPerUnit: double.tryParse(_weightPerUnitController.text) ?? 0.0,
        profitMargin:
            (double.tryParse(_profitMarginController.text) ?? 40.0) / 100.0,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      // Salva a receita temporária para obter um ID (se for nova) e ingredientes
      int recipeId;
      if (tempRecipe.id == null) {
        recipeId = await DatabaseService.insertRecipe(tempRecipe);
        _recipe = tempRecipe.copyWith(id: recipeId);
      } else {
        await DatabaseService.updateRecipe(tempRecipe);
        recipeId = tempRecipe.id!;
        _recipe = tempRecipe;
      }

      // Garante que os ingredientes estão salvos antes de calcular
      await _saveRecipeIngredients(recipeId);

      // Agora, calcula a precificação completa
      final pricingData = await CalculationService.calculateFullPricing(
        recipeId,
      );
      final summary = pricingData['summary'] as Map<String, dynamic>?;

      if (summary != null) {
        // Cria a receita final com os preços calculados
        final finalRecipe = _recipe!.copyWith(
          cost: summary['totalCost'],
          price: summary['finalPrice'],
        );

        // Atualiza a receita no banco com os valores finais
        await DatabaseService.updateRecipe(finalRecipe);
        _recipe = finalRecipe;
      }

      await _calculatePricing(); // Recarrega os dados na tela

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receita salva com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao salvar receita: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveRecipeIngredients(int recipeId) async {
    for (final ingredient in _recipeIngredients) {
      if (ingredient.id == null) {
        await DatabaseService.insertRecipeIngredient(
          ingredient.copyWith(recipeId: recipeId),
        );
      } else {
        await DatabaseService.updateRecipeIngredient(ingredient);
      }
    }
  }

  int _getPreparationTimeInMinutes() {
    final preparationTime = int.tryParse(_preparationTimeController.text) ?? 0;
    return _selectedTimeUnit == 'Horas'
        ? preparationTime * 60
        : preparationTime;
  }

  void _addIngredient() {
    showDialog(
      context: context,
      builder: (context) => _AddIngredientDialog(
        allIngredients: _allIngredients,
        onAdd: (ingredient, quantity) {
          setState(() {
            _recipeIngredients.add(
              RecipeIngredient(
                recipeId: _recipe?.id ?? 0,
                ingredientId: ingredient.id!,
                quantity: quantity,
                ingredientName: ingredient.name,
                ingredientUnit: ingredient.unit,
                ingredientUnitPrice: ingredient.unitPrice,
              ),
            );
          });
        },
      ),
    );
  }

  void _removeIngredient(int index) async {
    if (_recipeIngredients[index].id != null) {
      await DatabaseService.deleteRecipeIngredient(
        _recipeIngredients[index].id!,
      );
    }
    setState(() {
      _recipeIngredients.removeAt(index);
    });
    await _calculatePricing();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _recipe == null ? 'Nova Ficha Técnica' : 'Editar Ficha Técnica',
        ),
        actions: [
          if (_recipe?.id != null)
            IconButton(
              icon: const Icon(Icons.calculate),
              onPressed: _calculatePricing,
              tooltip: 'Recalcular Preços',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Informações básicas da receita
                    _buildBasicInfoSection(),
                    const SizedBox(height: 24),

                    // Lista de ingredientes
                    _buildIngredientsSection(),
                    const SizedBox(height: 24),

                    // Resultados da precificação
                    if (_pricingData != null) _buildPricingSection(),

                    const SizedBox(height: 24),

                    // Botão salvar
                    ElevatedButton.icon(
                      onPressed: _saveRecipe,
                      icon: const Icon(Icons.save),
                      label: const Text('Salvar Ficha Técnica'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informações Básicas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome da Receita',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nome é obrigatório';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _preparationTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Tempo de Preparo',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Tempo é obrigatório';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 120,
                  child: DropdownButtonFormField<String>(
                    value: _selectedTimeUnit,
                    items: <String>['Minutos', 'Horas'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedTimeUnit = newValue!;
                      });
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _recipeYieldController,
                    decoration: const InputDecoration(
                      labelText: 'Rendimento (unidades)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Rendimento é obrigatório';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _weightPerUnitController,
                    decoration: const InputDecoration(
                      labelText: 'Peso por Unidade (g)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _profitMarginController,
                    decoration: const InputDecoration(
                      labelText: 'Margem de Lucro (%)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Margem é obrigatória';
                      }
                      final margin = double.tryParse(value);
                      if (margin == null || margin < 0 || margin > 100) {
                        return 'Margem deve ser entre 0 e 100%';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Observações',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ingredientes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _addIngredient,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_recipeIngredients.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'Nenhum ingrediente adicionado',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recipeIngredients.length,
                itemBuilder: (context, index) {
                  final ingredient = _recipeIngredients[index];
                  return ListTile(
                    title: Text(ingredient.ingredientName ?? 'Ingrediente'),
                    subtitle: Text(
                      '${ingredient.quantity} ${ingredient.ingredientUnit} - R\$ ${ingredient.cost.toStringAsFixed(2)}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeIngredient(index),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingSection() {
    final summary = _pricingData!['summary'] as Map<String, dynamic>;
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );
    final percentFormat = NumberFormat.decimalPercentPattern(
      locale: 'pt_BR',
      decimalDigits: 1,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resultado da Precificação',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildPricingRow(
              'Custo Total:',
              currencyFormat.format(summary['totalCost']),
            ),
            _buildPricingRow(
              'Custo por Unidade:',
              currencyFormat.format(summary['costPerUnit']),
            ),
            const Divider(),
            _buildPricingRow(
              'Preço Ideal:',
              currencyFormat.format(summary['idealPrice']),
              color: Colors.green,
            ),
            _buildPricingRow(
              'Preço por Unidade:',
              currencyFormat.format(summary['idealPricePerUnit']),
              color: Colors.green,
            ),
            _buildPricingRow(
              'Lucro Total:',
              currencyFormat.format(summary['profitValue']),
              color: Colors.blue,
            ),
            _buildPricingRow(
              'Lucro por Unidade:',
              currencyFormat.format(summary['profitValuePerUnit']),
              color: Colors.blue,
            ),
            _buildPricingRow(
              'Margem de Lucro:',
              percentFormat.format(summary['profitPercentage'] / 100),
              color: Colors.blue,
            ),
            const Divider(),
            _buildPricingRow(
              'Taxas:',
              currencyFormat.format(summary['taxValue']),
              color: Colors.orange,
            ),
            _buildPricingRow(
              'Percentual de Taxas:',
              percentFormat.format(summary['taxPercentage'] / 100),
              color: Colors.orange,
            ),
            const Divider(),
            _buildPricingRow(
              'Preço Final:',
              currencyFormat.format(summary['finalPrice']),
              color: Colors.purple,
              isBold: true,
            ),
            _buildPricingRow(
              'Preço Final por Unidade:',
              currencyFormat.format(summary['finalPricePerUnit']),
              color: Colors.purple,
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingRow(
    String label,
    String value, {
    Color? color,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddIngredientDialog extends StatefulWidget {
  final List<Ingredient> allIngredients;
  final Function(Ingredient ingredient, double quantity) onAdd;

  const _AddIngredientDialog({
    required this.allIngredients,
    required this.onAdd,
  });

  @override
  State<_AddIngredientDialog> createState() => _AddIngredientDialogState();
}

class _AddIngredientDialogState extends State<_AddIngredientDialog> {
  Ingredient? selectedIngredient;
  final _quantityController = TextEditingController();

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar Ingrediente'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<Ingredient>(
            value: selectedIngredient,
            decoration: const InputDecoration(
              labelText: 'Ingrediente',
              border: OutlineInputBorder(),
            ),
            items: widget.allIngredients.map((ingredient) {
              return DropdownMenuItem(
                value: ingredient,
                child: Text('${ingredient.name} (${ingredient.unit})'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedIngredient = value;
              });
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _quantityController,
            decoration: InputDecoration(
              labelText: 'Quantidade ${selectedIngredient?.unit ?? ''}',
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (selectedIngredient != null &&
                _quantityController.text.isNotEmpty) {
              final quantity = double.tryParse(_quantityController.text);
              if (quantity != null && quantity > 0) {
                widget.onAdd(selectedIngredient!, quantity);
                Navigator.of(context).pop();
              }
            }
          },
          child: const Text('Adicionar'),
        ),
      ],
    );
  }
}
