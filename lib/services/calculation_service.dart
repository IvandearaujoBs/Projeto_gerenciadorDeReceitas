import '../models/expense.dart';
import '../models/work_schedule.dart';
import '../models/recipe.dart';
import '../models/recipe_ingredient.dart';
import '../models/sale_tax.dart';
import '../services/database_service.dart';

class CalculationService {
  static CalculationService? _instance;
  static CalculationService get instance =>
      _instance ??= CalculationService._();

  CalculationService._();

  /// Calcula o custo por hora baseado nas despesas e jornada de trabalho
  static Future<double> calculateHourlyCost() async {
    try {
      // Buscar todas as despesas
      final expenses = await _getAllExpenses();

      // Buscar jornada de trabalho
      final workSchedule = await _getWorkSchedule();

      // Calcular total de despesas mensais
      double totalMonthlyExpenses = 0.0;
      for (final expense in expenses) {
        totalMonthlyExpenses += expense.monthlyValue;
      }

      // Calcular custo por hora
      if (workSchedule.totalMonthlyHours > 0) {
        return totalMonthlyExpenses / workSchedule.totalMonthlyHours;
      }

      return 0.0;
    } catch (e) {
      print('Erro ao calcular custo por hora: $e');
      return 0.0;
    }
  }

  /// Calcula o custo total de uma receita
  static Future<Map<String, double>> calculateRecipeCost(int recipeId) async {
    try {
      // Buscar a receita
      final recipe = await DatabaseService.getRecipeById(recipeId);
      if (recipe == null) throw Exception('Receita não encontrada');

      // Buscar ingredientes da receita
      final recipeIngredients = await _getRecipeIngredients(recipeId);

      // Calcular custo dos insumos
      double ingredientsCost = 0.0;
      for (final ri in recipeIngredients) {
        ingredientsCost += ri.cost;
      }

      // Calcular custo de produção (tempo)
      final hourlyCost = await calculateHourlyCost();
      final productionTimeHours = recipe.preparationTimeMinutes / 60.0;
      final productionCost = productionTimeHours * hourlyCost;

      // Custo total
      final totalCost = ingredientsCost + productionCost;

      return {
        'ingredientsCost': ingredientsCost,
        'productionCost': productionCost,
        'totalCost': totalCost,
        'costPerUnit': recipe.recipeYield > 0
            ? totalCost / recipe.recipeYield
            : 0.0,
      };
    } catch (e) {
      print('Erro ao calcular custo da receita: $e');
      return {
        'ingredientsCost': 0.0,
        'productionCost': 0.0,
        'totalCost': 0.0,
        'costPerUnit': 0.0,
      };
    }
  }

  /// Calcula o preço ideal de venda com margem de lucro
  static Future<Map<String, double>> calculateIdealPrice(int recipeId) async {
    try {
      final recipe = await DatabaseService.getRecipeById(recipeId);
      if (recipe == null) throw Exception('Receita não encontrada');

      final costData = await calculateRecipeCost(recipeId);
      final totalCost = costData['totalCost']!;

      // Preço ideal = custo total ÷ (1 - margem de lucro)
      final idealPrice = totalCost / (1 - recipe.profitMargin);

      return {
        'idealPrice': idealPrice,
        'idealPricePerUnit': recipe.recipeYield > 0
            ? idealPrice / recipe.recipeYield
            : 0.0,
        'profitValue': idealPrice - totalCost,
        'profitValuePerUnit': recipe.recipeYield > 0
            ? (idealPrice - totalCost) / recipe.recipeYield
            : 0.0,
        'profitPercentage': totalCost > 0
            ? ((idealPrice - totalCost) / totalCost) * 100
            : 0.0,
      };
    } catch (e) {
      print('Erro ao calcular preço ideal: $e');
      return {
        'idealPrice': 0.0,
        'idealPricePerUnit': 0.0,
        'profitValue': 0.0,
        'profitValuePerUnit': 0.0,
        'profitPercentage': 0.0,
      };
    }
  }

  /// Calcula o preço final com taxas embutidas
  static Future<Map<String, double>> calculateFinalPrice(int recipeId) async {
    try {
      final idealPriceData = await calculateIdealPrice(recipeId);
      final idealPrice = idealPriceData['idealPrice']!;

      // Buscar todas as taxas de venda
      final saleTaxes = await _getAllSaleTaxes();

      // Calcular soma das taxas
      double totalTaxPercentage = 0.0;
      for (final tax in saleTaxes) {
        totalTaxPercentage += tax.percentage;
      }

      // Preço final = preço ideal ÷ (1 - soma das taxas)
      final finalPrice = idealPrice / (1 - totalTaxPercentage);

      return {
        'finalPrice': finalPrice,
        'finalPricePerUnit': idealPriceData['idealPricePerUnit']! > 0
            ? finalPrice / idealPriceData['idealPricePerUnit']!
            : 0.0,
        'totalTaxValue': finalPrice - idealPrice,
        'totalTaxPercentage': totalTaxPercentage * 100,
      };
    } catch (e) {
      print('Erro ao calcular preço final: $e');
      return {
        'finalPrice': 0.0,
        'finalPricePerUnit': 0.0,
        'totalTaxValue': 0.0,
        'totalTaxPercentage': 0.0,
      };
    }
  }

  /// Calcula todos os valores de precificação de uma receita
  static Future<Map<String, dynamic>> calculateFullPricing(int recipeId) async {
    try {
      final recipe = await DatabaseService.getRecipeById(recipeId);
      if (recipe == null) throw Exception('Receita não encontrada');

      final costData = await calculateRecipeCost(recipeId);
      final idealPriceData = await calculateIdealPrice(recipeId);
      final finalPriceData = await calculateFinalPrice(recipeId);

      return {
        'recipe': recipe,
        'costs': costData,
        'idealPrice': idealPriceData,
        'finalPrice': finalPriceData,
        'summary': {
          'totalCost': costData['totalCost']!,
          'costPerUnit': costData['costPerUnit']!,
          'idealPrice': idealPriceData['idealPrice']!,
          'idealPricePerUnit': idealPriceData['idealPricePerUnit']!,
          'finalPrice': finalPriceData['finalPrice']!,
          'finalPricePerUnit': finalPriceData['finalPricePerUnit']!,
          'profitValue': idealPriceData['profitValue']!,
          'profitValuePerUnit': idealPriceData['profitValuePerUnit']!,
          'profitPercentage': idealPriceData['profitPercentage']!,
          'taxValue': finalPriceData['totalTaxValue']!,
          'taxPercentage': finalPriceData['totalTaxPercentage']!,
        },
      };
    } catch (e) {
      print('Erro ao calcular precificação completa: $e');
      return {};
    }
  }

  // Métodos auxiliares para buscar dados do banco
  static Future<List<Expense>> _getAllExpenses() async {
    try {
      final result = await DatabaseService.allQuery(
        'SELECT * FROM Expenses ORDER BY name',
      );
      return result.map((map) => Expense.fromMap(map)).toList();
    } catch (e) {
      print('Erro ao buscar despesas: $e');
      return [];
    }
  }

  static Future<WorkSchedule> _getWorkSchedule() async {
    try {
      final result = await DatabaseService.getQuery(
        'SELECT * FROM WorkSchedule LIMIT 1',
      );
      if (result != null) {
        return WorkSchedule.fromMap(result);
      }
      // Retorna jornada padrão se não existir
      return WorkSchedule(
        hoursMonday: 8.0,
        hoursTuesday: 8.0,
        hoursWednesday: 8.0,
        hoursThursday: 8.0,
        hoursFriday: 8.0,
        hoursSaturday: 4.0,
        hoursSunday: 0.0,
      );
    } catch (e) {
      print('Erro ao buscar jornada de trabalho: $e');
      return WorkSchedule();
    }
  }

  static Future<List<RecipeIngredient>> _getRecipeIngredients(
    int recipeId,
  ) async {
    try {
      final result = await DatabaseService.allQuery(
        '''
        SELECT ri.*, i.name as ingredient_name, i.unit as ingredient_unit, 
               (i.price / i.packageSize) as ingredient_unit_price
        FROM RecipeIngredients ri
        JOIN Ingredients i ON i.id = ri.ingredient_id
        WHERE ri.recipe_id = ?
        ''',
        [recipeId],
      );
      return result.map((map) => RecipeIngredient.fromMap(map)).toList();
    } catch (e) {
      print('Erro ao buscar ingredientes da receita: $e');
      return [];
    }
  }

  static Future<List<SaleTax>> _getAllSaleTaxes() async {
    try {
      final result = await DatabaseService.allQuery(
        'SELECT * FROM SaleTaxes ORDER BY name',
      );
      return result.map((map) => SaleTax.fromMap(map)).toList();
    } catch (e) {
      print('Erro ao buscar taxas de venda: $e');
      return [];
    }
  }
}
