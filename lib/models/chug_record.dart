class ChugRecord {
  final String? id;
  final String funnelId;
  final String name;
  final String liquid;
  final int quantityMl;
  final int durationMs;
  final DateTime loggedAt;

  const ChugRecord({
    this.id,
    required this.funnelId,
    required this.name,
    required this.liquid,
    required this.quantityMl,
    required this.durationMs,
    required this.loggedAt,
  });

  factory ChugRecord.fromJson(Map<String, dynamic> json) => ChugRecord(
        id: json['id'] as String?,
        funnelId: json['funnelId'] as String,
        name: json['name'] as String,
        liquid: json['liquid'] as String,
        quantityMl: json['quantityMl'] as int,
        durationMs: json['durationMs'] as int,
        loggedAt: DateTime.parse(json['loggedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'funnelId': funnelId,
        'name': name,
        'liquid': liquid,
        'quantityMl': quantityMl,
        'durationMs': durationMs,
        'loggedAt': loggedAt.toIso8601String(),
      };

  ChugRecord copyWith({String? id}) => ChugRecord(
        id: id ?? this.id,
        funnelId: funnelId,
        name: name,
        liquid: liquid,
        quantityMl: quantityMl,
        durationMs: durationMs,
        loggedAt: loggedAt,
      );
}
