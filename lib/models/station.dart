class Station {
  final int stationId;
  final double lat;
  final double lon;
  // Fields below are kept for backward compatibility but will be null
  // when loaded from the simplified database
  final double? elevation;
  final String? name;
  final String? type;
  final String? description;

  // Color to use for the marker (optional)
  final String? color;

  Station({
    required this.stationId,
    required this.lat,
    required this.lon,
    this.elevation,
    this.name,
    this.type,
    this.description,
    this.color,
  });

  // Create a Station object from a database map
  factory Station.fromMap(Map<String, dynamic> map) {
    return Station(
      stationId: map['stationId'] as int,
      lat: map['lat'] as double,
      lon: map['lon'] as double,
      // These fields won't be in the database, so they'll be null:
      elevation: null,
      name: null,
      type: null,
      description: null,
      // Default color
      color: '#2389DA',
    );
  }
}
