// lib/data/datasources/remote/mapbox_remote_data_source.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../core/constants/map_constants.dart';
import '../../../domain/usecases/search_location.dart';

abstract class MapboxRemoteDataSource {
  Future<List<SearchResult>> searchLocation(String query, String accessToken);
  Future<String> getAccessToken();
}

class MapboxRemoteDataSourceImpl implements MapboxRemoteDataSource {
  final http.Client client;

  MapboxRemoteDataSourceImpl({required this.client});

  @override
  Future<List<SearchResult>> searchLocation(
    String query,
    String accessToken,
  ) async {
    if (query.isEmpty) {
      return [];
    }

    try {
      final url =
          '${MapConstants.mapboxSearchApiUrl}$query.json?'
          'access_token=$accessToken'
          '&limit=${MapConstants.searchResultLimit}';

      final response = await client.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List;

        return features.map<SearchResult>((feature) {
          final coordinates = feature['center'] as List;
          return SearchResult(
            name: feature['text'] as String,
            address: feature['place_name'] as String?,
            point: Point(
              coordinates: Position(
                coordinates[0].toDouble(),
                coordinates[1].toDouble(),
              ),
            ),
          );
        }).toList();
      } else {
        print('Error searching: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Exception during search: $e');
      return [];
    }
  }

  @override
  Future<String> getAccessToken() async {
    try {
      return await MapboxOptions.getAccessToken() ?? '';
    } catch (e) {
      print('Error getting access token: $e');
      return '';
    }
  }
}
