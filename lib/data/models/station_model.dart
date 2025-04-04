// lib/data/models/station_model.dart

import '../../domain/entities/station.dart';

class StationModel extends Station {
  const StationModel({
    required super.stationId,
    required super.lat,
    required super.lon,
    super.elevation,
    super.name,
    super.type,
    super.description,
    super.color,
  });

  factory StationModel.fromMap(Map<String, dynamic> map) {
    return StationModel(
      stationId: map['stationId'] as int,
      lat: map['lat'] as double,
      lon: map['lon'] as double,
      elevation: map['elevation'] as double?,
      name: map['name'] as String?,
      type: map['type'] as String?,
      description: map['description'] as String?,
      color: map['color'] as String? ?? '#2389DA',
    );
  }

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
}
