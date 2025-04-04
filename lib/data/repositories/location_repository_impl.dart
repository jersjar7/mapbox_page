// lib/data/repositories/location_repository_impl.dart

import '../../domain/usecases/search_location.dart';
import '../datasources/remote/mapbox_remote_data_source.dart';

class LocationRepositoryImpl implements LocationRepository {
  final MapboxRemoteDataSource remoteDataSource;
  String? _cachedToken;

  LocationRepositoryImpl({required this.remoteDataSource});

  Future<String> _getAccessToken() async {
    if (_cachedToken == null || _cachedToken!.isEmpty) {
      _cachedToken = await remoteDataSource.getAccessToken();
    }
    return _cachedToken!;
  }

  @override
  Future<List<SearchResult>> searchLocation(String query) async {
    final token = await _getAccessToken();
    return await remoteDataSource.searchLocation(query, token);
  }
}
