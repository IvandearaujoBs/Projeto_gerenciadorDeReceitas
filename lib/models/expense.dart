class Expense {
  int? id;
  String name;
  double totalValue;
  int durationMonths;
  String type; // 'administrative' ou 'personnel'

  Expense({
    this.id,
    required this.name,
    required this.totalValue,
    required this.durationMonths,
    required this.type,
  });

  // Valor mensal calculado automaticamente
  double get monthlyValue =>
      durationMonths > 0 ? totalValue / durationMonths : 0.0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'totalValue': totalValue,
      'durationMonths': durationMonths,
      'type': type,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      name: map['name'],
      totalValue: (map['totalValue'] as num).toDouble(),
      durationMonths: map['durationMonths'] ?? 1,
      type: map['type'] ?? 'administrative',
    );
  }
}
