import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapConstants {
  // Map styles - using the correct style constants
  static const String mapboxStreets = MapboxStyles.MAPBOX_STREETS;
  static const String mapboxLight = MapboxStyles.LIGHT;
  static const String mapboxDark = MapboxStyles.DARK;
  static const String mapboxSatellite = MapboxStyles.SATELLITE;
  static const String mapboxSatelliteStreets = MapboxStyles.SATELLITE_STREETS;
  static const String mapboxStandard = MapboxStyles.STANDARD;

  // Default map style
  static const String defaultMapStyle = MapboxStyles.MAPBOX_STREETS;

  // Default map center (Utah, USA)
  static final Point defaultCenter = Point(
    coordinates: Position(-111.658531, 40.233845),
  );

  // Default zoom level
  static const double defaultZoom = 9.0;

  // Minimum zoom level to show station markers
  // Approximately 400 feet from ground elevation
  static const double minZoomForMarkers = 15.0;

  // 3D settings
  static const double defaultTilt = 45.0;
  static const double terrainExaggeration = 1.5;

  // Marker clustering
  static const int clusterRadius = 50; // pixels
  static const int clusterMaxZoom = 14; // max zoom to cluster points
  static const int maxMarkersForPerformance =
      1000; // maximum markers to display for performance

  // Marker style
  static const double defaultMarkerSize = 15.0;
  static const double selectedMarkerSize = 20.0;
  static const String defaultMarkerColor = "#2389DA"; // Blue
  static const String selectedMarkerColor = "#FF5733"; // Orange-red

  // Search
  static const String mapboxSearchApiUrl =
      'https://api.mapbox.com/geocoding/v5/mapbox.places/';
  static const int searchResultLimit = 5;
}
