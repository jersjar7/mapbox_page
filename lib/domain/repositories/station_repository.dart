// lib/domain/repositories/station_repository.dart

import '../entities/station.dart';

abstract class StationRepository {
  /// Gets stations within a bounding box defined by latitude and longitude
  Future<List<Station>> getStationsInRegion(
    double minLat,
    double maxLat,
    double minLon,
    double maxLon, {
    int limit = 1000,
  });

  /// Gets a sample of stations (useful for low zoom levels)
  Future<List<Station>> getSampleStations({int limit = 10});

  /// Gets the total count of stations in the database
  Future<int> getStationCount();

  /// Gets the stations nearest to a specific location
  Future<List<Station>> getNearestStations(
    double lat,
    double lon, {
    int limit = 5,
    double radius = 50.0,
  });
}
