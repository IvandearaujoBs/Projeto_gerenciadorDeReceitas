import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/stock_category.dart';
import '../models/stock_item.dart';
import '../services/database_service.dart';

class StockControlScreen extends StatefulWidget {
  const StockControlScreen({Key? key}) : super(key: key);

  @override
  _StockControlScreenState createState() => _StockControlScreenState();
}

class _StockControlScreenState extends State<StockControlScreen> {
  List<StockCategory> _categories = [];
  List<StockItem> _allItems = [];
  List<StockItem> _lowStockItems = [];
  List<StockItem> _expiringItems = [];
  bool _isLoading = true;
  int _selectedCategoryId = -1; // -1 = todas as categorias

  final _numberFormatter = NumberFormat.decimalPattern('pt_BR');
  final _currencyFormatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$ ',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final categories = await DatabaseService.getAllStockCategories();
      final allItems = await DatabaseService.getAllStockItems();
      final lowStockItems = await DatabaseService.getLowStockItems();
      final expiringItems = await DatabaseService.getExpiringItems();

      if (mounted) {
        setState(() {
          _categories = categories;
          _allItems = allItems;
          _lowStockItems = lowStockItems;
          _expiringItems = expiringItems;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e')));
      }
    }
  }

  List<StockItem> get _filteredItems {
    if (_selectedCategoryId == -1) return _allItems;
    return _allItems
        .where((item) => item.categoryId == _selectedCategoryId)
        .toList();
  }

  StockCategory? _getCategoryById(int id) {
    try {
      return _categories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }

  Color _getCategoryColor(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceAll('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Controle de Estoque'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Estoque', icon: Icon(Icons.inventory)),
              Tab(text: 'Alertas', icon: Icon(Icons.warning)),
              Tab(text: 'Categorias', icon: Icon(Icons.category)),
            ],
            indicatorColor: Colors.white,
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildStockTab(),
                  _buildAlertsTab(),
                  _buildCategoriesTab(),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddItemDialog(),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildStockTab() {
    return Column(
      children: [
        // Filtro de categorias
        Container(
          padding: const EdgeInsets.all(16),
          child: DropdownButtonFormField<int>(
            value: _selectedCategoryId,
            decoration: const InputDecoration(
              labelText: 'Filtrar por Categoria',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(
                value: -1,
                child: Text('Todas as Categorias'),
              ),
              ..._categories.map(
                (cat) => DropdownMenuItem(
                  value: cat.id,
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: _getCategoryColor(cat.color),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(cat.name),
                    ],
                  ),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCategoryId = value ?? -1;
              });
            },
          ),
        ),
        // Lista de itens
        Expanded(
          child: _filteredItems.isEmpty
              ? const Center(
                  child: Text('Nenhum item encontrado nesta categoria'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = _filteredItems[index];
                    final category = _getCategoryById(item.categoryId);
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getCategoryColor(
                            category?.color ?? '#2196F3',
                          ),
                          child: Text(
                            item.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_numberFormatter.format(item.currentStock)} ${item.unit}',
                            ),
                            if (category != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(
                                    category.color,
                                  ).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  category.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _getCategoryColor(category.color),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            if (item.location.isNotEmpty)
                              Text(
                                'Local: ${item.location}',
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
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _currencyFormatter.format(item.unitCost),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (item.isLowStock)
                                  const Icon(
                                    Icons.warning,
                                    color: Colors.red,
                                    size: 16,
                                  ),
                                if (item.isExpiringSoon)
                                  const Icon(
                                    Icons.schedule,
                                    color: Colors.orange,
                                    size: 16,
                                  ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () => _showItemDetailsDialog(item),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _deleteItem(item.id!),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAlertsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_lowStockItems.isNotEmpty) ...[
          _buildAlertSection(
            'Estoque Baixo',
            Icons.warning,
            Colors.red,
            _lowStockItems,
            (item) =>
                '${item.name}: ${_numberFormatter.format(item.currentStock)} ${item.unit}',
          ),
          const SizedBox(height: 16),
        ],
        if (_expiringItems.isNotEmpty) ...[
          _buildAlertSection(
            'Vencendo em 7 dias',
            Icons.schedule,
            Colors.orange,
            _expiringItems,
            (item) =>
                '${item.name}: ${DateFormat('dd/MM/yyyy').format(item.expiryDate!)}',
          ),
        ],
        if (_lowStockItems.isEmpty && _expiringItems.isEmpty)
          const Center(
            child: Column(
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text('Nenhum alerta no momento!'),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAlertSection(
    String title,
    IconData icon,
    Color color,
    List<StockItem> items,
    String Function(StockItem) itemText,
  ) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('• ${itemText(item)}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesTab() {
    return Column(
      children: [
        // Botão para adicionar categoria
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _showAddCategoryDialog,
            icon: const Icon(Icons.add),
            label: const Text('Adicionar Categoria'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        // Lista de categorias
        Expanded(
          child: _categories.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.category, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Nenhuma categoria criada'),
                      SizedBox(height: 8),
                      Text(
                        'Clique no botão acima para criar sua primeira categoria',
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final itemCount = _allItems
                        .where((item) => item.categoryId == category.id)
                        .length;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getCategoryColor(category.color),
                          child: Text(
                            category.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          category.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (category.description.isNotEmpty)
                              Text(category.description),
                            Text(
                              '$itemCount item(s)',
                              style: TextStyle(
                                color: itemCount > 0
                                    ? Colors.green
                                    : Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () =>
                                  _showEditCategoryDialog(category),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: itemCount > 0
                                  ? null
                                  : () => _deleteCategory(category.id!),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // Diálogos e métodos auxiliares
  void _showAddItemDialog() {
    _showItemDialog();
  }

  void _showItemDetailsDialog(StockItem item) {
    _showItemDialog(item: item);
  }

  void _showItemDialog({StockItem? item}) {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController(text: item?.name ?? '');
    final _descriptionController = TextEditingController(
      text: item?.description ?? '',
    );
    final _currentStockController = TextEditingController(
      text: item?.currentStock.toString() ?? '',
    );
    final _minimumStockController = TextEditingController(
      text: item?.minimumStock.toString() ?? '',
    );
    final _maximumStockController = TextEditingController(
      text: item?.maximumStock.toString() ?? '',
    );
    final _unitController = TextEditingController(text: item?.unit ?? '');
    final _unitCostController = TextEditingController(
      text: item?.unitCost.toString() ?? '',
    );
    final _locationController = TextEditingController(
      text: item?.location ?? '',
    );

    int _selectedCategoryId =
        item?.categoryId ??
        (_categories.isNotEmpty ? _categories.first.id! : -1);
    DateTime? _selectedExpiryDate = item?.expiryDate;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item == null ? 'Adicionar Item' : 'Editar Item'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do Item',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty == true ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories
                      .map(
                        (cat) => DropdownMenuItem(
                          value: cat.id,
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(cat.color),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(cat.name),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => _selectedCategoryId = value!,
                  validator: (value) =>
                      value == null ? 'Selecione uma categoria' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _currentStockController,
                        decoration: const InputDecoration(
                          labelText: 'Estoque Atual',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) =>
                            value?.isEmpty == true ? 'Campo obrigatório' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _unitController,
                        decoration: const InputDecoration(
                          labelText: 'Unidade',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value?.isEmpty == true ? 'Campo obrigatório' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _minimumStockController,
                        decoration: const InputDecoration(
                          labelText: 'Estoque Mínimo',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) =>
                            value?.isEmpty == true ? 'Campo obrigatório' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _maximumStockController,
                        decoration: const InputDecoration(
                          labelText: 'Estoque Máximo',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
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
                        controller: _unitCostController,
                        decoration: const InputDecoration(
                          labelText: 'Custo Unitário',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) =>
                            value?.isEmpty == true ? 'Campo obrigatório' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Localização',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Data de Validade'),
                  subtitle: Text(
                    _selectedExpiryDate != null
                        ? DateFormat('dd/MM/yyyy').format(_selectedExpiryDate!)
                        : 'Não definida',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_selectedExpiryDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () =>
                              setState(() => _selectedExpiryDate = null),
                        ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedExpiryDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365 * 2),
                            ),
                          );
                          if (date != null) {
                            setState(() => _selectedExpiryDate = date);
                          }
                        },
                      ),
                    ],
                  ),
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
              if (_formKey.currentState!.validate()) {
                final newItem = StockItem(
                  id: item?.id,
                  name: _nameController.text.trim(),
                  description: _descriptionController.text.trim(),
                  categoryId: _selectedCategoryId,
                  currentStock: double.parse(
                    _currentStockController.text.replaceAll(',', '.'),
                  ),
                  minimumStock: double.parse(
                    _minimumStockController.text.replaceAll(',', '.'),
                  ),
                  maximumStock:
                      double.tryParse(
                        _maximumStockController.text.replaceAll(',', '.'),
                      ) ??
                      0.0,
                  unit: _unitController.text.trim(),
                  unitCost: double.parse(
                    _unitCostController.text.replaceAll(',', '.'),
                  ),
                  location: _locationController.text.trim(),
                  expiryDate: _selectedExpiryDate,
                );

                if (item == null) {
                  await DatabaseService.insertStockItem(newItem);
                } else {
                  await DatabaseService.updateStockItem(newItem);
                }

                Navigator.of(context).pop();
                _loadData();
              }
            },
            child: Text(item == null ? 'Adicionar' : 'Salvar'),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog() {
    _showCategoryDialog();
  }

  void _showEditCategoryDialog(StockCategory category) {
    _showCategoryDialog(category: category);
  }

  void _showCategoryDialog({StockCategory? category}) {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController(text: category?.name ?? '');
    final _descriptionController = TextEditingController(
      text: category?.description ?? '',
    );
    String _selectedColor = category?.color ?? '#2196F3';

    final List<String> _colors = [
      '#2196F3',
      '#4CAF50',
      '#FF9800',
      '#F44336',
      '#9C27B0',
      '#607D8B',
      '#795548',
      '#E91E63',
      '#00BCD4',
      '#8BC34A',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          category == null ? 'Adicionar Categoria' : 'Editar Categoria',
        ),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Categoria',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty == true ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedColor,
                decoration: const InputDecoration(
                  labelText: 'Cor',
                  border: OutlineInputBorder(),
                ),
                items: _colors
                    .map(
                      (color) => DropdownMenuItem(
                        value: color,
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: _getCategoryColor(color),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(color),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => _selectedColor = value!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final newCategory = StockCategory(
                  id: category?.id,
                  name: _nameController.text.trim(),
                  description: _descriptionController.text.trim(),
                  color: _selectedColor,
                );

                if (category == null) {
                  await DatabaseService.insertStockCategory(newCategory);
                } else {
                  await DatabaseService.updateStockCategory(newCategory);
                }

                Navigator.of(context).pop();
                _loadData();
              }
            },
            child: Text(category == null ? 'Adicionar' : 'Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text(
          'Tem certeza de que deseja excluir esta categoria? Todos os itens associados serão perdidos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseService.deleteStockCategory(id);
      _loadData();
    }
  }

  Future<void> _deleteItem(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza de que deseja excluir este item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseService.deleteStockItem(id);
      _loadData();
    }
  }
}
