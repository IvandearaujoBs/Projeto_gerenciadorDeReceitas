class Recipe {
  int? id;
  String name;
  double price;
  double cost;
  int stockQuantity;
  int preparationTimeMinutes;

  // Novos campos para ficha técnica
  int recipeYield; // Rendimento da receita (quantidade ou peso)
  double weightPerUnit; // Peso por unidade em gramas (se aplicável)
  double profitMargin; // Margem de lucro desejada (ex: 0.4 para 40%)
  String? notes; // Observações adicionais

  Recipe({
    this.id,
    required this.name,
    this.price = 0.0,
    this.cost = 0.0,
    this.stockQuantity = 0,
    this.preparationTimeMinutes = 0,
    this.recipeYield = 1,
    this.weightPerUnit = 0.0,
    this.profitMargin = 0.4, // 40% por padrão
    this.notes,
  });

  // Custo por unidade
  double get costPerUnit => recipeYield > 0 ? cost / recipeYield : 0.0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'cost': cost,
      'stockQuantity': stockQuantity,
      'preparationTimeMinutes': preparationTimeMinutes,
      'yield': recipeYield,
      'weightPerUnit': weightPerUnit,
      'profitMargin': profitMargin,
      'notes': notes,
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'],
      name: map['name'],
      price: (map['price'] as num).toDouble(),
      cost: (map['cost'] as num).toDouble(),
      stockQuantity: map['stockQuantity'] ?? 0,
      preparationTimeMinutes: map['preparationTimeMinutes'] ?? 0,
      recipeYield: map['yield'] ?? 1,
      weightPerUnit: (map['weightPerUnit'] as num?)?.toDouble() ?? 0.0,
      profitMargin: (map['profitMargin'] as num?)?.toDouble() ?? 0.4,
      notes: map['notes'],
    );
  }

  Recipe copyWith({
    int? id,
    String? name,
    double? price,
    double? cost,
    int? stockQuantity,
    int? preparationTimeMinutes,
    int? recipeYield,
    double? weightPerUnit,
    double? profitMargin,
    String? notes,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      preparationTimeMinutes:
          preparationTimeMinutes ?? this.preparationTimeMinutes,
      recipeYield: recipeYield ?? this.recipeYield,
      weightPerUnit: weightPerUnit ?? this.weightPerUnit,
      profitMargin: profitMargin ?? this.profitMargin,
      notes: notes ?? this.notes,
    );
  }
}
