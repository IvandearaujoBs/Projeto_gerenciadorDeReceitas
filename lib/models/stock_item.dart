class StockItem {
  final int? id;
  final String name;
  final String description;
  final int categoryId;
  final double currentStock;
  final double minimumStock;
  final double maximumStock;
  final String unit;
  final double unitCost;
  final String location; // Localização física no estoque
  final DateTime? lastUpdated;
  final DateTime? expiryDate; // Data de validade (opcional)

  StockItem({
    this.id,
    required this.name,
    this.description = '',
    required this.categoryId,
    this.currentStock = 0.0,
    this.minimumStock = 0.0,
    this.maximumStock = 0.0,
    required this.unit,
    this.unitCost = 0.0,
    this.location = '',
    this.lastUpdated,
    this.expiryDate,
  });

  bool get isLowStock => currentStock <= minimumStock;
  bool get isOverStock => maximumStock > 0 && currentStock > maximumStock;
  bool get isExpired =>
      expiryDate != null && expiryDate!.isBefore(DateTime.now());
  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final daysUntilExpiry = expiryDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 7 && daysUntilExpiry >= 0;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'categoryId': categoryId,
      'currentStock': currentStock,
      'minimumStock': minimumStock,
      'maximumStock': maximumStock,
      'unit': unit,
      'unitCost': unitCost,
      'location': location,
      'lastUpdated': lastUpdated?.millisecondsSinceEpoch,
      'expiryDate': expiryDate?.millisecondsSinceEpoch,
    };
  }

  factory StockItem.fromMap(Map<String, dynamic> map) {
    return StockItem(
      id: map['id'],
      name: map['name'],
      description: map['description'] ?? '',
      categoryId: map['categoryId'],
      currentStock: map['currentStock'] ?? 0.0,
      minimumStock: map['minimumStock'] ?? 0.0,
      maximumStock: map['maximumStock'] ?? 0.0,
      unit: map['unit'],
      unitCost: map['unitCost'] ?? 0.0,
      location: map['location'] ?? '',
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastUpdated'])
          : null,
      expiryDate: map['expiryDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['expiryDate'])
          : null,
    );
  }

  StockItem copyWith({
    int? id,
    String? name,
    String? description,
    int? categoryId,
    double? currentStock,
    double? minimumStock,
    double? maximumStock,
    String? unit,
    double? unitCost,
    String? location,
    DateTime? lastUpdated,
    DateTime? expiryDate,
  }) {
    return StockItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      currentStock: currentStock ?? this.currentStock,
      minimumStock: minimumStock ?? this.minimumStock,
      maximumStock: maximumStock ?? this.maximumStock,
      unit: unit ?? this.unit,
      unitCost: unitCost ?? this.unitCost,
      location: location ?? this.location,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      expiryDate: expiryDate ?? this.expiryDate,
    );
  }
}
