// lib/data/repositories/station_repository_impl.dart

import '../../domain/entities/station.dart';
import '../../domain/repositories/station_repository.dart';
import '../datasources/local/station_local_data_source.dart';

class StationRepositoryImpl implements StationRepository {
  final StationLocalDataSource localDataSource;

  StationRepositoryImpl({required this.localDataSource});

  @override
  Future<List<Station>> getStationsInRegion(
    double minLat,
    double maxLat,
    double minLon,
    double maxLon, {
    int limit = 1000,
  }) async {
    return await localDataSource.getStationsInRegion(
      minLat,
      maxLat,
      minLon,
      maxLon,
      limit: limit,
    );
  }

  @override
  Future<List<Station>> getSampleStations({int limit = 10}) async {
    return await localDataSource.getSampleStations(limit: limit);
  }

  @override
  Future<int> getStationCount() async {
    return await localDataSource.getStationCount();
  }

  @override
  Future<List<Station>> getNearestStations(
    double lat,
    double lon, {
    int limit = 5,
    double radius = 50.0,
  }) async {
    return await localDataSource.getNearestStations(
      lat,
      lon,
      limit: limit,
      radius: radius,
    );
  }
}
