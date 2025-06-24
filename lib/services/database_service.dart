import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/recipe.dart';
import '../models/ingredient.dart';
import '../models/expense.dart';
import '../models/work_schedule.dart';
import '../models/sale_tax.dart';
import '../models/recipe_ingredient.dart';
import '../models/shopping_list_item.dart';
import '../models/stock_category.dart';
import '../models/stock_item.dart';

class DatabaseService {
  static Database? _db;

  // Nome do arquivo do banco de dados
  static const String dbName = 'lojinha_od.db';

  // Inicializa e retorna a instância do banco de dados
  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);
    return await openDatabase(
      path,
      version: 2, // Incrementado para adicionar novas tabelas
      onCreate: (db, version) async {
        await createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _upgradeToVersion2(db);
        }
      },
    );
  }

  /// Cria todas as tabelas necessárias no banco de dados
  static Future<void> createTables([Database? dbInstance]) async {
    final db = dbInstance ?? await database;

    await db.execute('PRAGMA foreign_keys = ON');

    // Tabela de usuários
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        firstName TEXT,
        lastName TEXT
      )
    ''');

    // Tabela de ingredientes (atualizada com controle de estoque)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Ingredients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        unit TEXT NOT NULL,
        stockQuantity REAL DEFAULT 0,
        minimumStock REAL DEFAULT 0,
        lastUpdated INTEGER
      )
    ''');

    // Tabela de receitas
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Recipes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        preparationTimeMinutes INTEGER NOT NULL,
        recipeYield INTEGER NOT NULL,
        weightPerUnit REAL NOT NULL,
        profitMargin REAL NOT NULL,
        cost REAL DEFAULT 0,
        price REAL DEFAULT 0,
        notes TEXT
      )
    ''');

    // Tabela de ingredientes da receita
    await db.execute('''
      CREATE TABLE IF NOT EXISTS RecipeIngredients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipeId INTEGER NOT NULL,
        ingredientId INTEGER NOT NULL,
        quantity REAL NOT NULL,
        FOREIGN KEY (recipeId) REFERENCES Recipes (id) ON DELETE CASCADE,
        FOREIGN KEY (ingredientId) REFERENCES Ingredients (id) ON DELETE CASCADE
      )
    ''');

    // Tabela de despesas unificada
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        monthlyValue REAL NOT NULL,
        type TEXT NOT NULL
      )
    ''');

    // Tabela de jornada de trabalho
    await db.execute('''
      CREATE TABLE IF NOT EXISTS WorkSchedule (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hoursPerDay REAL NOT NULL,
        daysPerWeek INTEGER NOT NULL,
        weeksPerMonth REAL NOT NULL
      )
    ''');

    // Tabela de taxas de venda
    await db.execute('''
      CREATE TABLE IF NOT EXISTS SaleTaxes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        percentage REAL NOT NULL
      )
    ''');

    // Tabela de vendas
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipeId INTEGER,
        quantitySold INTEGER NOT NULL,
        totalPrice REAL NOT NULL,
        saleDate TEXT NOT NULL,
        FOREIGN KEY (recipeId) REFERENCES Recipes (id)
      )
    ''');

    // Tabela de lista de compras (simplificada)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ShoppingList (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        priority TEXT DEFAULT 'média',
        isCompleted INTEGER DEFAULT 0,
        createdAt INTEGER NOT NULL
      )
    ''');

    // Tabela de categorias de estoque
    await db.execute('''
      CREATE TABLE IF NOT EXISTS StockCategories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        color TEXT DEFAULT '#2196F3'
      )
    ''');

    // Tabela de itens de estoque
    await db.execute('''
      CREATE TABLE IF NOT EXISTS StockItems (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        categoryId INTEGER NOT NULL,
        currentStock REAL DEFAULT 0,
        minimumStock REAL DEFAULT 0,
        maximumStock REAL DEFAULT 0,
        unit TEXT NOT NULL,
        unitCost REAL DEFAULT 0,
        location TEXT,
        lastUpdated INTEGER,
        expiryDate INTEGER,
        FOREIGN KEY (categoryId) REFERENCES StockCategories (id) ON DELETE CASCADE
      )
    ''');

    // Inserir dados padrão se as tabelas estiverem vazias
    await _insertDefaultData(db);
  }

  /// Atualização para versão 2
  static Future<void> _upgradeToVersion2(Database db) async {
    // Adicionar novas colunas à tabela Recipes
    await db.execute(
      'ALTER TABLE Recipes ADD COLUMN yield INTEGER NOT NULL DEFAULT 1',
    );
    await db.execute(
      'ALTER TABLE Recipes ADD COLUMN weightPerUnit REAL NOT NULL DEFAULT 0',
    );
    await db.execute(
      'ALTER TABLE Recipes ADD COLUMN profitMargin REAL NOT NULL DEFAULT 0.4',
    );
    await db.execute('ALTER TABLE Recipes ADD COLUMN notes TEXT');

    // Criar novas tabelas
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        totalValue REAL NOT NULL,
        durationMonths INTEGER NOT NULL DEFAULT 1,
        type TEXT NOT NULL DEFAULT 'administrative'
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS WorkSchedule (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hoursMonday REAL NOT NULL DEFAULT 0,
        hoursTuesday REAL NOT NULL DEFAULT 0,
        hoursWednesday REAL NOT NULL DEFAULT 0,
        hoursThursday REAL NOT NULL DEFAULT 0,
        hoursFriday REAL NOT NULL DEFAULT 0,
        hoursSaturday REAL NOT NULL DEFAULT 0,
        hoursSunday REAL NOT NULL DEFAULT 0
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS SaleTaxes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        percentage REAL NOT NULL
      );
    ''');

    await _insertDefaultData(db);
  }

  /// Insere dados padrão nas novas tabelas
  static Future<void> _insertDefaultData([Database? dbInstance]) async {
    final db = dbInstance ?? await database;

    // Verificar se já existem dados
    final expenseCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM Expenses'),
    );

    if (expenseCount == 0) {
      // Inserir despesas padrão
      await db.insert('Expenses', {
        'name': 'Aluguel',
        'totalValue': 1200.0,
        'durationMonths': 12,
        'type': 'administrative',
      });

      await db.insert('Expenses', {
        'name': 'Pró-labore',
        'totalValue': 2000.0,
        'durationMonths': 1,
        'type': 'personnel',
      });
    }

    final workScheduleCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM WorkSchedule'),
    );

    if (workScheduleCount == 0) {
      // Inserir jornada padrão (8h/dia, 6 dias/semana)
      await db.insert('WorkSchedule', {
        'hoursMonday': 8.0,
        'hoursTuesday': 8.0,
        'hoursWednesday': 8.0,
        'hoursThursday': 8.0,
        'hoursFriday': 8.0,
        'hoursSaturday': 4.0,
        'hoursSunday': 0.0,
      });
    }

    final taxCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM SaleTaxes'),
    );

    if (taxCount == 0) {
      // Inserir taxas padrão
      await db.insert('SaleTaxes', {
        'name': 'Taxa do Cartão',
        'percentage': 0.0378, // 3.78%
      });

      await db.insert('SaleTaxes', {
        'name': 'Comissão',
        'percentage': 0.05, // 5%
      });
    }

    // Verificar se a tabela de ingredientes está vazia antes de inserir exemplos
    final ingredientCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM Ingredients'),
    );
    if (ingredientCount == 0) {
      await _insertSampleIngredients(db);
    }
  }

  /// Executa uma query SQL que não retorna resultados (INSERT, UPDATE, DELETE)
  static Future<int> runQuery(
    String sql, [
    List<Object?> params = const [],
  ]) async {
    final db = await database;
    final sqlTrim = sql.trim().toUpperCase();
    if (sqlTrim.startsWith('INSERT')) {
      return await db.rawInsert(sql, params);
    } else if (sqlTrim.startsWith('UPDATE')) {
      return await db.rawUpdate(sql, params);
    } else if (sqlTrim.startsWith('DELETE')) {
      return await db.rawDelete(sql, params);
    } else {
      throw Exception('Comando SQL não suportado por runQuery');
    }
  }

  /// Executa uma query SQL que retorna múltiplas linhas (SELECT)
  static Future<List<Map<String, Object?>>> allQuery(
    String sql, [
    List<Object?> params = const [],
  ]) async {
    final db = await database;
    return await db.rawQuery(sql, params);
  }

  /// Executa uma query SQL que retorna uma única linha (SELECT)
  static Future<Map<String, Object?>?> getQuery(
    String sql, [
    List<Object?> params = const [],
  ]) async {
    final db = await database;
    final result = await db.rawQuery(sql, params);
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  /// Insere um produto de teste no banco de dados (MODIFICADO PARA NOVA ESTRUTURA)
  static Future<void> insertSampleRecipe() async {
    final db = await database;
    await db.insert('Recipes', {
      'name': 'Bolo de Cenoura (Exemplo)',
      'price': 45.0,
      'cost': 15.0,
      'stockQuantity': 5,
      'preparationTimeMinutes': 60,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  /// Insere insumos de exemplo no banco de dados (MODIFICADO PARA NOVA ESTRUTURA)
  static Future<void> _insertSampleIngredients([Database? dbInstance]) async {
    final db = dbInstance ?? await database;
    final List<Map<String, Object?>> exemplos = [
      {
        'name': 'Farinha de Trigo',
        'packageSize': 1000,
        'unit': 'g',
        'price': 5.50,
      },
      {
        'name': 'Açúcar Refinado',
        'packageSize': 1000,
        'unit': 'g',
        'price': 4.80,
      },
      {'name': 'Ovo', 'packageSize': 12, 'unit': 'un', 'price': 10.00},
      {'name': 'Óleo de Soja', 'packageSize': 900, 'unit': 'ml', 'price': 8.00},
      {'name': 'Cenoura', 'packageSize': 1000, 'unit': 'g', 'price': 3.50},
      {
        'name': 'Chocolate em Pó',
        'packageSize': 400,
        'unit': 'g',
        'price': 9.00,
      },
    ];

    for (final exemplo in exemplos) {
      await db.insert(
        'Ingredients',
        exemplo,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  // Mantenha esta função se houver lógica legada que a utilize, caso contrário, pode ser removida.
  static Future<void> insertSampleProduct() async {
    // Esta função refere-se à tabela "Products" que não estamos mais usando primariamente.
    // Pode ser mantida para compatibilidade ou removida. Por segurança, vamos deixá-la vazia.
  }

  // Métodos de busca específicos

  static Future<List<Map<String, dynamic>>> getSalesByMonth(
    int month,
    int year,
  ) async {
    final db = await database;
    // Formata o mês e ano para o formato 'YYYY-MM'
    String monthStr = month.toString().padLeft(2, '0');
    String yearMonth = '$year-$monthStr';

    return await db.query(
      'Sales',
      where: "strftime('%Y-%m', saleDateTime) = ?",
      whereArgs: [yearMonth],
    );
  }

  static Future<Recipe?> getRecipeById(int id) async {
    final db = await database;
    final maps = await db.query('Recipes', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return Recipe.fromMap(maps.first);
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> getIngredientsForRecipe(
    int recipeId,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      '''
      SELECT i.name, i.price, ri.quantity 
      FROM RecipeIngredients ri
      JOIN Ingredients i ON i.id = ri.ingredient_id
      WHERE ri.recipe_id = ?
    ''',
      [recipeId],
    );
    return result;
  }

  // Métodos para gerenciar Despesas
  static Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final maps = await db.query('Expenses', orderBy: 'name');
    return maps.map((map) => Expense.fromMap(map)).toList();
  }

  static Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return await db.insert('Expenses', expense.toMap());
  }

  static Future<int> updateExpense(Expense expense) async {
    final db = await database;
    return await db.update(
      'Expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  static Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete('Expenses', where: 'id = ?', whereArgs: [id]);
  }

  // Métodos para gerenciar Jornada de Trabalho
  static Future<WorkSchedule?> getWorkSchedule() async {
    final db = await database;
    final maps = await db.query('WorkSchedule', limit: 1);
    if (maps.isNotEmpty) {
      return WorkSchedule.fromMap(maps.first);
    }
    return null;
  }

  static Future<int> saveWorkSchedule(WorkSchedule schedule) async {
    final db = await database;
    if (schedule.id != null) {
      return await db.update(
        'WorkSchedule',
        schedule.toMap(),
        where: 'id = ?',
        whereArgs: [schedule.id],
      );
    } else {
      return await db.insert('WorkSchedule', schedule.toMap());
    }
  }

  // Métodos para gerenciar Taxas de Venda
  static Future<List<SaleTax>> getAllSaleTaxes() async {
    final db = await database;
    final maps = await db.query('SaleTaxes', orderBy: 'name');
    return maps.map((map) => SaleTax.fromMap(map)).toList();
  }

  static Future<int> insertSaleTax(SaleTax tax) async {
    final db = await database;
    return await db.insert('SaleTaxes', tax.toMap());
  }

  static Future<int> updateSaleTax(SaleTax tax) async {
    final db = await database;
    return await db.update(
      'SaleTaxes',
      tax.toMap(),
      where: 'id = ?',
      whereArgs: [tax.id],
    );
  }

  static Future<int> deleteSaleTax(int id) async {
    final db = await database;
    return await db.delete('SaleTaxes', where: 'id = ?', whereArgs: [id]);
  }

  // Métodos para gerenciar Ingredientes de Receita
  static Future<List<RecipeIngredient>> getRecipeIngredients(
    int recipeId,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      '''
      SELECT ri.*, i.name as ingredient_name, i.unit as ingredient_unit, 
             (i.price / i.packageSize) as ingredient_unit_price
      FROM RecipeIngredients ri
      JOIN Ingredients i ON i.id = ri.ingredient_id
      WHERE ri.recipe_id = ?
      ORDER BY i.name
      ''',
      [recipeId],
    );
    return result.map((map) => RecipeIngredient.fromMap(map)).toList();
  }

  static Future<int> insertRecipeIngredient(RecipeIngredient ingredient) async {
    final db = await database;
    return await db.insert('RecipeIngredients', ingredient.toMap());
  }

  static Future<int> updateRecipeIngredient(RecipeIngredient ingredient) async {
    final db = await database;
    return await db.update(
      'RecipeIngredients',
      ingredient.toMap(),
      where: 'id = ?',
      whereArgs: [ingredient.id],
    );
  }

  static Future<int> deleteRecipeIngredient(int id) async {
    final db = await database;
    return await db.delete(
      'RecipeIngredients',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Métodos para gerenciar Receitas (atualizados)
  static Future<List<Recipe>> getAllRecipes() async {
    final db = await database;
    final maps = await db.query('Recipes', orderBy: 'name');
    return maps.map((map) => Recipe.fromMap(map)).toList();
  }

  static Future<int> insertRecipe(Recipe recipe) async {
    final db = await database;
    return await db.insert('Recipes', recipe.toMap());
  }

  static Future<int> updateRecipe(Recipe recipe) async {
    final db = await database;
    return await db.update(
      'Recipes',
      recipe.toMap(),
      where: 'id = ?',
      whereArgs: [recipe.id],
    );
  }

  static Future<int> deleteRecipe(int id) async {
    final db = await database;
    return await db.delete('Recipes', where: 'id = ?', whereArgs: [id]);
  }

  // Métodos para gerenciar Insumos (atualizados)
  static Future<List<Ingredient>> getAllIngredients() async {
    final db = await database;
    final maps = await db.query('Ingredients', orderBy: 'name');
    return maps.map((map) => Ingredient.fromMap(map)).toList();
  }

  static Future<int> insertIngredient(Ingredient ingredient) async {
    final db = await database;
    return await db.insert('Ingredients', ingredient.toMap());
  }

  static Future<int> updateIngredient(Ingredient ingredient) async {
    final db = await database;
    return await db.update(
      'Ingredients',
      ingredient.toMap(),
      where: 'id = ?',
      whereArgs: [ingredient.id],
    );
  }

  static Future<int> deleteIngredient(int id) async {
    final db = await database;
    return await db.delete('Ingredients', where: 'id = ?', whereArgs: [id]);
  }

  // Métodos para Lista de Compras
  static Future<int> insertShoppingListItem(ShoppingListItem item) async {
    final db = await database;
    return await db.insert('ShoppingList', item.toMap());
  }

  static Future<List<ShoppingListItem>> getAllShoppingListItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ShoppingList',
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => ShoppingListItem.fromMap(maps[i]));
  }

  static Future<void> updateShoppingListItem(ShoppingListItem item) async {
    final db = await database;
    await db.update(
      'ShoppingList',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  static Future<void> deleteShoppingListItem(int id) async {
    final db = await database;
    await db.delete('ShoppingList', where: 'id = ?', whereArgs: [id]);
  }

  // Métodos atualizados para controle de estoque
  static Future<void> updateIngredientStock(
    int ingredientId,
    double newQuantity,
  ) async {
    final db = await database;
    await db.update(
      'Ingredients',
      {
        'stockQuantity': newQuantity,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [ingredientId],
    );
  }

  static Future<void> decreaseIngredientStock(
    int ingredientId,
    double quantity,
  ) async {
    final db = await database;
    final ingredient = await getIngredientById(ingredientId);
    if (ingredient != null) {
      final newQuantity = (ingredient.stockQuantity - quantity).clamp(
        0.0,
        double.infinity,
      );
      await updateIngredientStock(ingredientId, newQuantity);
    }
  }

  static Future<List<Ingredient>> getLowStockIngredients() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Ingredients',
      where: 'stockQuantity <= minimumStock AND minimumStock > 0',
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Ingredient.fromMap(maps[i]));
  }

  // Método para diminuir estoque quando uma receita é vendida
  static Future<void> decreaseStockForRecipe(
    int recipeId,
    int quantitySold,
  ) async {
    final recipeIngredients = await getIngredientsForRecipe(recipeId);

    for (final ingredient in recipeIngredients) {
      final ingredientId = ingredient['ingredient_id'] as int;
      final quantityUsed = (ingredient['quantity'] as double) * quantitySold;
      await decreaseIngredientStock(ingredientId, quantityUsed);
    }
  }

  static Future<Ingredient?> getIngredientById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Ingredients',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Ingredient.fromMap(maps.first);
    }
    return null;
  }

  // Métodos para Categorias de Estoque
  static Future<int> insertStockCategory(StockCategory category) async {
    final db = await database;
    return await db.insert('StockCategories', category.toMap());
  }

  static Future<List<StockCategory>> getAllStockCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('StockCategories');
    return List.generate(maps.length, (i) => StockCategory.fromMap(maps[i]));
  }

  static Future<void> updateStockCategory(StockCategory category) async {
    final db = await database;
    await db.update(
      'StockCategories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  static Future<void> deleteStockCategory(int id) async {
    final db = await database;
    await db.delete('StockCategories', where: 'id = ?', whereArgs: [id]);
  }

  // Métodos para Itens de Estoque
  static Future<int> insertStockItem(StockItem item) async {
    final db = await database;
    return await db.insert('StockItems', item.toMap());
  }

  static Future<List<StockItem>> getAllStockItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'StockItems',
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => StockItem.fromMap(maps[i]));
  }

  static Future<List<StockItem>> getStockItemsByCategory(int categoryId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'StockItems',
      where: 'categoryId = ?',
      whereArgs: [categoryId],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => StockItem.fromMap(maps[i]));
  }

  static Future<List<StockItem>> getLowStockItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'StockItems',
      where: 'currentStock <= minimumStock AND minimumStock > 0',
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => StockItem.fromMap(maps[i]));
  }

  static Future<List<StockItem>> getExpiringItems() async {
    final db = await database;
    final now = DateTime.now();
    final sevenDaysFromNow = now.add(const Duration(days: 7));

    final List<Map<String, dynamic>> maps = await db.query(
      'StockItems',
      where: 'expiryDate IS NOT NULL AND expiryDate <= ? AND expiryDate >= ?',
      whereArgs: [
        sevenDaysFromNow.millisecondsSinceEpoch,
        now.millisecondsSinceEpoch,
      ],
      orderBy: 'expiryDate ASC',
    );
    return List.generate(maps.length, (i) => StockItem.fromMap(maps[i]));
  }

  static Future<void> updateStockItem(StockItem item) async {
    final db = await database;
    await db.update(
      'StockItems',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  static Future<void> deleteStockItem(int id) async {
    final db = await database;
    await db.delete('StockItems', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> updateStockQuantity(
    int itemId,
    double newQuantity,
  ) async {
    final db = await database;
    await db.update(
      'StockItems',
      {
        'currentStock': newQuantity,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }
}
