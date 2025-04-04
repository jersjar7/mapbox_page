// In lib/map_screen.dart

import 'dart:async'; // Add this import for Timer
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'services/database_service.dart';
import 'models/station.dart';
import 'utils/constants.dart';
import 'widgets/map_search_bar.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Mapbox map controller
  MapboxMap? _mapboxMap;

  // Current map style
  String _currentStyle = MapConstants.defaultMapStyle;

  // 3D mode
  bool _is3DMode = true;

  // Database service for fetching stations
  final DatabaseService _databaseHelper = DatabaseService();

  // Currently displayed stations
  List<Station> _stations = [];

  // Loading state
  bool _isLoading = false;

  // Current zoom level and visible region
  double _currentZoom = MapConstants.defaultZoom;
  CoordinateBounds? _visibleRegion;

  // Whether we're showing "zoom in" message
  bool _showZoomMessage = true;

  // Whether the map is initialized
  bool _isMapInitialized = false;

  // Points manager for adding and removing markers
  PointAnnotationManager? _pointAnnotationManager;

  // Store access token as a field
  String _accessToken = '';

  // Add debounce timer for map movement
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadAccessToken();
  }

  // Load access token asynchronously
  Future<void> _loadAccessToken() async {
    final token = await MapboxOptions.getAccessToken();
    setState(() {
      _accessToken = token ?? '';
    });
  }

  @override
  void dispose() {
    // Cancel any active timer when disposing
    _debounceTimer?.cancel();
    super.dispose();
  }

  // Called when the map is created
  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    _isMapInitialized = true;

    // Create point annotation manager
    _createAnnotationManager();

    // Enable 3D terrain if 3D mode is enabled
    if (_is3DMode) {
      _enableTerrain();
    }

    // Initial update of the visible region
    _updateVisibleRegion();

    // Load sample stations for context at lower zoom levels
    _loadSampleStations();
  }

  // Helper method to trigger debounce
  void _triggerDebounceTimer() {
    // Cancel previous timer if it's still running
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }

    // Set a new timer to trigger after movement stops
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _updateMapAfterMovement();
    });
  }

  // Function to call after map movement stops
  void _updateMapAfterMovement() {
    _updateVisibleRegion().then((_) {
      // Only load stations if we're zoomed in enough
      if (_currentZoom >= MapConstants.minZoomForMarkers) {
        _loadStationsInVisibleRegion();
      } else if (_stations.isNotEmpty) {
        // Clear markers when zoomed out for performance
        setState(() {
          _stations = [];
          _clearAnnotations();
        });

        // Show sample stations at lower zoom
        _loadSampleStations();
      }
    });
  }

  // Create annotation manager for adding points
  Future<void> _createAnnotationManager() async {
    try {
      final annotationsManager = _mapboxMap!.annotations;
      _pointAnnotationManager =
          await annotationsManager.createPointAnnotationManager();
    } catch (e) {
      print('Error creating annotation manager: $e');
    }
  }

  // Enable 3D terrain
  Future<void> _enableTerrain() async {
    if (_mapboxMap == null) return;

    try {
      // Get the style
      var styleObj = _mapboxMap!.style;

      // Try to remove existing terrain if any
      try {
        await styleObj.removeStyleSource('mapbox-dem');
      } catch (e) {
        // Source might not exist yet, which is fine
        print('No existing terrain source to remove: $e');
      }

      // Add terrain source as String
      final demSource = '''{
        "type": "raster-dem",
        "url": "mapbox://mapbox.mapbox-terrain-dem-v1",
        "tileSize": 512,
        "maxzoom": 14.0
      }''';

      await styleObj.addStyleSource('mapbox-dem', demSource);

      // Set terrain properties as String
      final terrain = '''{
        "source": "mapbox-dem",
        "exaggeration": ${MapConstants.terrainExaggeration}
      }''';

      await styleObj.setStyleTerrain(terrain);
    } catch (e) {
      print('Error setting up terrain: $e');
    }
  }

  // Disable 3D terrain
  Future<void> _disableTerrain() async {
    if (_mapboxMap == null) return;

    try {
      var styleObj = _mapboxMap!.style;
      await styleObj.setStyleTerrain("{}");
    } catch (e) {
      print('Error disabling terrain: $e');
    }
  }

  // Update visible region
  Future<void> _updateVisibleRegion() async {
    if (_mapboxMap == null) return;

    try {
      // Get the camera state
      CameraState cameraState = await _mapboxMap!.getCameraState();
      _currentZoom = cameraState.zoom;

      // Update whether to show zoom message
      setState(() {
        _showZoomMessage = _currentZoom < MapConstants.minZoomForMarkers;
      });

      // Convert CameraState to CameraOptions for the bounds calculation
      CameraOptions cameraOptions = CameraOptions(
        center: cameraState.center,
        zoom: cameraState.zoom,
        bearing: cameraState.bearing,
        pitch: cameraState.pitch,
      );

      // Get the visible bounds
      _visibleRegion = await _mapboxMap!.coordinateBoundsForCamera(
        cameraOptions,
      );
    } catch (e) {
      print("Error getting visible region: $e");
    }
  }

  // Load a small sample of stations when zoomed out
  Future<void> _loadSampleStations() async {
    if (!_isMapInitialized) return;

    final sampleStations = await _databaseHelper.getSampleStations(limit: 10);

    // Add sample markers for reference at low zoom
    if (sampleStations.isNotEmpty &&
        _currentZoom < MapConstants.minZoomForMarkers) {
      setState(() {
        _stations = sampleStations;
        _addAnnotations(_stations);
      });
    }
  }

  // Load stations in the currently visible region
  Future<void> _loadStationsInVisibleRegion() async {
    if (!_isMapInitialized || _visibleRegion == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final bounds = _visibleRegion!;
      final stations = await _databaseHelper.getStationsInRegion(
        bounds.southwest.coordinates.lat.toDouble(),
        bounds.northeast.coordinates.lat.toDouble(),
        bounds.southwest.coordinates.lng.toDouble(),
        bounds.northeast.coordinates.lng.toDouble(),
        limit: MapConstants.maxMarkersForPerformance,
      );

      if (stations.isEmpty) {
        print("No stations found in visible region");
        setState(() {
          _stations = [];
          _clearAnnotations();
          _isLoading = false;
        });
        return;
      }

      print("Loaded ${stations.length} stations in visible region");

      // Update stations and add annotations
      setState(() {
        _stations = stations;
        _clearAnnotations();
        _addAnnotations(_stations);
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading stations: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Manual refresh of stations
  void _refreshStations() {
    _updateVisibleRegion().then((_) {
      if (_currentZoom >= MapConstants.minZoomForMarkers) {
        _loadStationsInVisibleRegion();
      } else {
        _loadSampleStations();
      }
    });
  }

  // Clear all annotations from the map
  void _clearAnnotations() {
    if (_pointAnnotationManager == null) return;

    try {
      _pointAnnotationManager!.deleteAll();
    } catch (e) {
      print('Error clearing annotations: $e');
    }
  }

  // Add annotations for stations
  void _addAnnotations(List<Station> stations) {
    if (_pointAnnotationManager == null) return;

    try {
      // Create point annotations for each station
      final pointAnnotationOptions =
          stations.map((station) {
            return PointAnnotationOptions(
              geometry: Point(coordinates: Position(station.lon, station.lat)),
              iconSize: 0.5,
              iconOffset: [0, 0],
              symbolSortKey: 1.0,
              textField: station.name ?? station.stationId.toString(),
              textOffset: [0, 1.5],
              textSize: 12.0,
              textColor: 0xFF000000,
              iconImage:
                  "marker-blue", // This requires you to have added the icon
            );
          }).toList();

      // Add the annotations to the map
      _pointAnnotationManager!.createMulti(pointAnnotationOptions);
    } catch (e) {
      print('Error adding annotations: $e');
    }
  }

  // Set camera pitch
  Future<void> _setCameraPitch(double pitch) async {
    if (_mapboxMap == null) return;

    try {
      var cameraState = await _mapboxMap!.getCameraState();
      var cameraOptions = CameraOptions(
        center: cameraState.center,
        zoom: cameraState.zoom,
        bearing: cameraState.bearing,
        pitch: pitch,
      );
      await _mapboxMap!.setCamera(cameraOptions);
    } catch (e) {
      print('Error setting camera pitch: $e');
    }
  }

  // Toggle 3D terrain
  void _toggle3DTerrain() {
    setState(() {
      _is3DMode = !_is3DMode;
    });

    if (_mapboxMap == null) return;

    if (_is3DMode) {
      // Enable 3D terrain
      _enableTerrain();
      // Set camera pitch
      _setCameraPitch(MapConstants.defaultTilt);
    } else {
      // Disable 3D terrain
      _disableTerrain();
      // Reset camera pitch
      _setCameraPitch(0);
    }

    // Trigger refresh after terrain change
    _triggerDebounceTimer();
  }

  // Go to location
  void _goToLocation(Point point) {
    if (_mapboxMap == null) return;

    try {
      _mapboxMap!.flyTo(
        CameraOptions(
          center: point,
          zoom: MapConstants.minZoomForMarkers,
          pitch: _is3DMode ? MapConstants.defaultTilt : 0,
        ),
        MapAnimationOptions(duration: 2, startDelay: 0),
      );

      // Trigger debounce for station loading after camera movement completes
      _triggerDebounceTimer();
    } catch (e) {
      print('Error going to location: $e');
    }
  }

  // Show style selector
  void _showStyleSelector() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Streets'),
                selected: _currentStyle == MapConstants.mapboxStreets,
                onTap: () => _changeMapStyle(MapConstants.mapboxStreets),
              ),
              ListTile(
                title: const Text('Satellite'),
                selected: _currentStyle == MapConstants.mapboxSatellite,
                onTap: () => _changeMapStyle(MapConstants.mapboxSatellite),
              ),
              ListTile(
                title: const Text('Satellite Streets'),
                selected: _currentStyle == MapConstants.mapboxSatelliteStreets,
                onTap:
                    () => _changeMapStyle(MapConstants.mapboxSatelliteStreets),
              ),
              ListTile(
                title: const Text('Light'),
                selected: _currentStyle == MapConstants.mapboxLight,
                onTap: () => _changeMapStyle(MapConstants.mapboxLight),
              ),
              ListTile(
                title: const Text('Dark'),
                selected: _currentStyle == MapConstants.mapboxDark,
                onTap: () => _changeMapStyle(MapConstants.mapboxDark),
              ),
              ListTile(
                title: const Text('Standard'),
                selected: _currentStyle == MapConstants.mapboxStandard,
                onTap: () => _changeMapStyle(MapConstants.mapboxStandard),
              ),
            ],
          ),
    );
  }

  // Change map style
  void _changeMapStyle(String style) {
    setState(() {
      _currentStyle = style;
    });

    if (_mapboxMap == null) return;

    Navigator.pop(context);

    // Load the new style
    _mapboxMap!.loadStyleURI(style).then((_) {
      // Re-enable terrain if 3D mode is on
      if (_is3DMode) {
        _enableTerrain();
      }

      // Reload annotations
      _clearAnnotations();
      _createAnnotationManager().then((_) {
        if (_stations.isNotEmpty) {
          _addAnnotations(_stations);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // The map
          MapWidget(
            key: const ValueKey('mapWidget'),
            onMapCreated: _onMapCreated,
            cameraOptions: CameraOptions(
              center: MapConstants.defaultCenter,
              zoom: MapConstants.defaultZoom,
              pitch: _is3DMode ? MapConstants.defaultTilt : 0.0,
              bearing: 0,
            ),
            styleUri: _currentStyle,
          ),

          // Search bar
          SafeArea(
            child: MapSearchBar(
              onPlaceSelected: _goToLocation,
              accessToken: _accessToken,
            ),
          ),

          // Zoom message overlay
          if (_showZoomMessage)
            Positioned(
              bottom: 150,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Zoom in to see stations',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),

          // Loading indicator
          if (_isLoading)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Loading stations...'),
                    ],
                  ),
                ),
              ),
            ),

          // Map controls
          Positioned(
            right: 16,
            bottom: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Refresh button (new)
                FloatingActionButton(
                  heroTag: 'refresh',
                  onPressed: _refreshStations,
                  tooltip: 'Refresh stations',
                  child: const Icon(Icons.refresh),
                ),
                const SizedBox(height: 8),
                // Style selector button
                FloatingActionButton(
                  heroTag: 'style',
                  onPressed: _showStyleSelector,
                  tooltip: 'Change map style',
                  child: const Icon(Icons.layers),
                ),
                const SizedBox(height: 8),
                // 3D toggle button
                FloatingActionButton(
                  heroTag: '3d',
                  onPressed: _toggle3DTerrain,
                  tooltip: 'Toggle 3D view',
                  child: Icon(
                    _is3DMode ? Icons.view_in_ar : Icons.view_in_ar_outlined,
                  ),
                ),
                const SizedBox(height: 8),
                // Zoom in button
                FloatingActionButton(
                  heroTag: 'zoomIn',
                  onPressed: () {
                    if (_mapboxMap != null) {
                      _mapboxMap!.getCameraState().then((cameraState) {
                        _mapboxMap!.setCamera(
                          CameraOptions(zoom: cameraState.zoom + 1),
                        );
                        // Trigger debounce for station loading after zoom
                        _triggerDebounceTimer();
                      });
                    }
                  },
                  tooltip: 'Zoom in',
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                // Zoom out button
                FloatingActionButton(
                  heroTag: 'zoomOut',
                  onPressed: () {
                    if (_mapboxMap != null) {
                      _mapboxMap!.getCameraState().then((cameraState) {
                        _mapboxMap!.setCamera(
                          CameraOptions(zoom: cameraState.zoom - 1),
                        );
                        // Trigger debounce for station loading after zoom
                        _triggerDebounceTimer();
                      });
                    }
                  },
                  tooltip: 'Zoom out',
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
