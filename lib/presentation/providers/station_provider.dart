// lib/presentation/providers/station_provider.dart

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../domain/entities/station.dart';
import '../../domain/usecases/get_nearest_stations.dart';
import '../../domain/usecases/get_sample_stations.dart';
import '../../domain/usecases/get_stations_in_region.dart';

enum StationLoadingStatus { initial, loading, loaded, error }

class StationProvider with ChangeNotifier {
  // Use cases
  final GetStationsInRegion getStationsInRegion;
  final GetSampleStations getSampleStations;
  final GetNearestStations getNearestStations;

  // State
  List<Station> _stations = [];
  List<Station> get stations => _stations;

  StationLoadingStatus _status = StationLoadingStatus.initial;
  StationLoadingStatus get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Station? _selectedStation;
  Station? get selectedStation => _selectedStation;

  StationProvider({
    required this.getStationsInRegion,
    required this.getSampleStations,
    required this.getNearestStations,
  });

  // Load stations in a specific region
  Future<void> loadStationsInRegion(
    CoordinateBounds bounds, {
    int limit = 1000,
  }) async {
    _setLoading();

    try {
      final stations = await getStationsInRegion(
        bounds.southwest.coordinates.lat.toDouble(),
        bounds.northeast.coordinates.lat.toDouble(),
        bounds.southwest.coordinates.lng.toDouble(),
        bounds.northeast.coordinates.lng.toDouble(),
        limit: limit,
      );

      _stations = stations;
      _status = StationLoadingStatus.loaded;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load stations: ${e.toString()}');
    }
  }

  // Load sample stations (for low zoom levels)
  Future<void> loadSampleStations({int limit = 10}) async {
    _setLoading();

    try {
      final stations = await getSampleStations(limit: limit);
      _stations = stations;
      _status = StationLoadingStatus.loaded;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load sample stations: ${e.toString()}');
    }
  }

  // Get nearest stations to a point
  Future<void> loadNearestStations(
    double lat,
    double lon, {
    int limit = 5,
    double radius = 50.0,
  }) async {
    _setLoading();

    try {
      final stations = await getNearestStations(
        lat,
        lon,
        limit: limit,
        radius: radius,
      );

      _stations = stations;
      _status = StationLoadingStatus.loaded;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load nearest stations: ${e.toString()}');
    }
  }

  // Clear all stations
  void clearStations() {
    _stations = [];
    _selectedStation = null;
    _status = StationLoadingStatus.initial;
    _errorMessage = null;
    notifyListeners();
  }

  // Select a station
  void selectStation(Station station) {
    _selectedStation = station;
    notifyListeners();
  }

  // Deselect the current station
  void deselectStation() {
    _selectedStation = null;
    notifyListeners();
  }

  // Helper methods to update state
  void _setLoading() {
    _status = StationLoadingStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = StationLoadingStatus.error;
    _errorMessage = message;
    notifyListeners();
  }
}
