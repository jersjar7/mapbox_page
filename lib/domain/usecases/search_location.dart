// lib/domain/usecases/search_location.dart

import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class SearchResult {
  final String name;
  final Point point;
  final String? address;

  SearchResult({required this.name, required this.point, this.address});
}

abstract class LocationRepository {
  Future<List<SearchResult>> searchLocation(String query);
}

class SearchLocation {
  final LocationRepository repository;

  SearchLocation(this.repository);

  Future<List<SearchResult>> call(String query) async {
    return await repository.searchLocation(query);
  }
}
