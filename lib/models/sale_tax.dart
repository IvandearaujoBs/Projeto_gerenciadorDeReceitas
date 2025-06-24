class SaleTax {
  int? id;
  String name;
  double percentage; // Ex: 0.0378 para 3.78%

  SaleTax({this.id, required this.name, required this.percentage});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'percentage': percentage};
  }

  factory SaleTax.fromMap(Map<String, dynamic> map) {
    return SaleTax(
      id: map['id'],
      name: map['name'],
      percentage: (map['percentage'] as num).toDouble(),
    );
  }
}
