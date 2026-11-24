/// Одно сближение астероида с Землёй в конкретный день.
///
/// Числовые поля nullable: если NASA не прислала значение или оно битое,
/// мы показываем «нет данных», а не подставляем ноль.
class Asteroid {
  const Asteroid({
    required this.id,
    required this.name,
    this.diamMinM,
    this.diamMaxM,
    this.speedKms,
    this.distKm,
    this.hazardous,
  });

  final String id;
  final String name;

  /// Оценка диаметра, метры.
  final double? diamMinM;
  final double? diamMaxM;

  /// Относительная скорость, км/с.
  final double? speedKms;

  /// Расстояние промаха (miss distance), км.
  final double? distKm;

  /// Потенциально опасный объект (null — NASA не указала).
  final bool? hazardous;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'dMin': diamMinM,
        'dMax': diamMaxM,
        'v': speedKms,
        'dist': distKm,
        'haz': hazardous,
      };

  factory Asteroid.fromJson(Map<String, dynamic> j) => Asteroid(
        id: j['id'] as String,
        name: j['name'] as String,
        diamMinM: (j['dMin'] as num?)?.toDouble(),
        diamMaxM: (j['dMax'] as num?)?.toDouble(),
        speedKms: (j['v'] as num?)?.toDouble(),
        distKm: (j['dist'] as num?)?.toDouble(),
        hazardous: j['haz'] as bool?,
      );
}
