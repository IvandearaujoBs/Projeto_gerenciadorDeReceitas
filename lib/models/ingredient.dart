class Ingredient {
  final int? id;
  final String name;
  final double price;
  final String unit;
  final double stockQuantity; // Quantidade em estoque
  final double minimumStock; // Estoque mínimo para alerta
  final DateTime? lastUpdated;

  Ingredient({
    this.id,
    required this.name,
    required this.price,
    required this.unit,
    this.stockQuantity = 0.0,
    this.minimumStock = 0.0,
    this.lastUpdated,
  });

  double get unitPrice => price;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'unit': unit,
      'stockQuantity': stockQuantity,
      'minimumStock': minimumStock,
      'lastUpdated': lastUpdated?.millisecondsSinceEpoch,
    };
  }

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      id: map['id'],
      name: map['name'],
      price: map['price'],
      unit: map['unit'],
      stockQuantity: map['stockQuantity'] ?? 0.0,
      minimumStock: map['minimumStock'] ?? 0.0,
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastUpdated'])
          : null,
    );
  }

  Ingredient copyWith({
    int? id,
    String? name,
    double? price,
    String? unit,
    double? stockQuantity,
    double? minimumStock,
    DateTime? lastUpdated,
  }) {
    return Ingredient(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      minimumStock: minimumStock ?? this.minimumStock,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  bool get isLowStock => stockQuantity <= minimumStock;

  // Used when an ingredient is not found, to avoid null errors
  factory Ingredient.dummy() {
    return Ingredient(
      id: -1,
      name: 'Ingrediente não encontrado',
      price: 0,
      unit: 'un',
      stockQuantity: 0,
      minimumStock: 0,
    );
  }
}
