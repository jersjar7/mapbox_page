// lib/domain/usecases/get_sample_stations.dart

import '../entities/station.dart';
import '../repositories/station_repository.dart';

class GetSampleStations {
  final StationRepository repository;

  GetSampleStations(this.repository);

  Future<List<Station>> call({int limit = 10}) async {
    return await repository.getSampleStations(limit: limit);
  }
}
