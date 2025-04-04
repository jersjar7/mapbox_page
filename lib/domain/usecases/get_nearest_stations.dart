// lib/domain/usecases/get_nearest_stations.dart

import '../entities/station.dart';
import '../repositories/station_repository.dart';

class GetNearestStations {
  final StationRepository repository;

  GetNearestStations(this.repository);

  Future<List<Station>> call(
    double lat,
    double lon, {
    int limit = 5,
    double radius = 50.0,
  }) async {
    return await repository.getNearestStations(
      lat,
      lon,
      limit: limit,
      radius: radius,
    );
  }
}
