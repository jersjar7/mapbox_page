class Station {
  final int stationId;
  final double lat;
  final double lon;
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
      elevation: map['elevation'] as double?,
      name: map['name'] as String?,
      type: map['type'] as String?,
      description: map['description'] as String?,
      // Default color if not provided
      color: map['color'] as String? ?? '#2389DA',
    );
  }

  // Convert Station to a Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'stationId': stationId,
      'lat': lat,
      'lon': lon,
      'elevation': elevation,
      'name': name,
      'type': type,
      'description': description,
      'color': color,
    };
  }

  // For debugging and logging
  @override
  String toString() {
    return 'Station{stationId: $stationId, lat: $lat, lon: $lon, name: $name}';
  }
}
