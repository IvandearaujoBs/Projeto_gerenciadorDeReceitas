class WorkSchedule {
  int? id;
  double hoursMonday;
  double hoursTuesday;
  double hoursWednesday;
  double hoursThursday;
  double hoursFriday;
  double hoursSaturday;
  double hoursSunday;

  WorkSchedule({
    this.id,
    this.hoursMonday = 0.0,
    this.hoursTuesday = 0.0,
    this.hoursWednesday = 0.0,
    this.hoursThursday = 0.0,
    this.hoursFriday = 0.0,
    this.hoursSaturday = 0.0,
    this.hoursSunday = 0.0,
  });

  // Total de horas semanais
  double get totalWeeklyHours =>
      hoursMonday +
      hoursTuesday +
      hoursWednesday +
      hoursThursday +
      hoursFriday +
      hoursSaturday +
      hoursSunday;

  // Total de horas mensais (4 semanas)
  double get totalMonthlyHours => totalWeeklyHours * 4;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hoursMonday': hoursMonday,
      'hoursTuesday': hoursTuesday,
      'hoursWednesday': hoursWednesday,
      'hoursThursday': hoursThursday,
      'hoursFriday': hoursFriday,
      'hoursSaturday': hoursSaturday,
      'hoursSunday': hoursSunday,
    };
  }

  factory WorkSchedule.fromMap(Map<String, dynamic> map) {
    return WorkSchedule(
      id: map['id'],
      hoursMonday: (map['hoursMonday'] as num?)?.toDouble() ?? 0.0,
      hoursTuesday: (map['hoursTuesday'] as num?)?.toDouble() ?? 0.0,
      hoursWednesday: (map['hoursWednesday'] as num?)?.toDouble() ?? 0.0,
      hoursThursday: (map['hoursThursday'] as num?)?.toDouble() ?? 0.0,
      hoursFriday: (map['hoursFriday'] as num?)?.toDouble() ?? 0.0,
      hoursSaturday: (map['hoursSaturday'] as num?)?.toDouble() ?? 0.0,
      hoursSunday: (map['hoursSunday'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
