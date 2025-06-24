class StockCategory {
  final int? id;
  final String name;
  final String description;
  final String color; // Cor em formato hex para identificação visual

  StockCategory({
    this.id,
    required this.name,
    this.description = '',
    this.color = '#2196F3', // Azul padrão
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'description': description, 'color': color};
  }

  factory StockCategory.fromMap(Map<String, dynamic> map) {
    return StockCategory(
      id: map['id'],
      name: map['name'],
      description: map['description'] ?? '',
      color: map['color'] ?? '#2196F3',
    );
  }

  StockCategory copyWith({
    int? id,
    String? name,
    String? description,
    String? color,
  }) {
    return StockCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
    );
  }
}
