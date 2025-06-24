class ShoppingListItem {
  final int? id;
  final String description;
  final String priority; // 'baixa', 'média', 'alta'
  final bool isCompleted;
  final DateTime createdAt;

  ShoppingListItem({
    this.id,
    required this.description,
    this.priority = 'média',
    this.isCompleted = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'priority': priority,
      'isCompleted': isCompleted ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory ShoppingListItem.fromMap(Map<String, dynamic> map) {
    return ShoppingListItem(
      id: map['id'],
      description: map['description'],
      priority: map['priority'],
      isCompleted: map['isCompleted'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }

  ShoppingListItem copyWith({
    int? id,
    String? description,
    String? priority,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return ShoppingListItem(
      id: id ?? this.id,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
