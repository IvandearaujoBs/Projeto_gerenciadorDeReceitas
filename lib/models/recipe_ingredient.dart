class RecipeIngredient {
  int? id;
  int recipeId;
  int ingredientId;
  double quantity;

  // Campos relacionados para facilitar o uso
  String? ingredientName;
  String? ingredientUnit;
  double? ingredientUnitPrice;

  RecipeIngredient({
    this.id,
    required this.recipeId,
    required this.ingredientId,
    required this.quantity,
    this.ingredientName,
    this.ingredientUnit,
    this.ingredientUnitPrice,
  });

  // Custo deste ingrediente na receita
  double get cost => (ingredientUnitPrice ?? 0.0) * quantity;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipe_id': recipeId,
      'ingredient_id': ingredientId,
      'quantity': quantity,
    };
  }

  factory RecipeIngredient.fromMap(Map<String, dynamic> map) {
    return RecipeIngredient(
      id: map['id'],
      recipeId: map['recipe_id'],
      ingredientId: map['ingredient_id'],
      quantity: (map['quantity'] as num).toDouble(),
      ingredientName: map['ingredient_name'],
      ingredientUnit: map['ingredient_unit'],
      ingredientUnitPrice: (map['ingredient_unit_price'] as num?)?.toDouble(),
    );
  }

  RecipeIngredient copyWith({
    int? id,
    int? recipeId,
    int? ingredientId,
    double? quantity,
    String? ingredientName,
    String? ingredientUnit,
    double? ingredientUnitPrice,
  }) {
    return RecipeIngredient(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      ingredientId: ingredientId ?? this.ingredientId,
      quantity: quantity ?? this.quantity,
      ingredientName: ingredientName ?? this.ingredientName,
      ingredientUnit: ingredientUnit ?? this.ingredientUnit,
      ingredientUnitPrice: ingredientUnitPrice ?? this.ingredientUnitPrice,
    );
  }
}
