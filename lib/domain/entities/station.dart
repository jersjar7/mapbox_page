// lib/domain/entities/station.dart

class Station {
  final int stationId;
  final double lat;
  final double lon;
  final double? elevation;
  final String? name;
  final String? type;
  final String? description;
  final String? color;

  const Station({
    required this.stationId,
    required this.lat,
    required this.lon,
    this.elevation,
    this.name,
    this.type,
    this.description,
    this.color,
  });
}
