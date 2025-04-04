// lib/presentation/screens/map_screen.dart

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:mapbox_page/domain/entities/station.dart';
import 'package:provider/provider.dart';

import '../../core/constants/map_constants.dart';
import '../providers/map_provider.dart';
import '../providers/station_provider.dart';
import '../widgets/map_controls.dart';
import '../widgets/map_search_bar.dart';
import '../widgets/station_marker.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  StationMarkerManager? _markerManager;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Initialize marker manager if not already created
    if (_markerManager == null) {
      final mapProvider = Provider.of<MapProvider>(context, listen: false);
      final stationProvider = Provider.of<StationProvider>(
        context,
        listen: false,
      );
      _markerManager = StationMarkerManager(mapProvider, stationProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Mapbox Map
          _buildMap(),

          // UI Elements
          SafeArea(
            child: Column(
              children: [
                // Search Bar
                const MapSearchBar(),

                // Map Content - Takes remaining space
                Expanded(
                  child: Stack(
                    children: [
                      // Zoom message overlay
                      _buildZoomMessage(),

                      // Loading indicator
                      _buildLoadingIndicator(),

                      // Station info panel
                      const StationInfoPanel(),

                      // Map Controls
                      const MapControls(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return Consumer<MapProvider>(
      builder: (context, mapProvider, child) {
        return MapWidget(
          key: const ValueKey('mapWidget'),
          onMapCreated: _onMapCreated,
          cameraOptions: CameraOptions(
            center: MapConstants.defaultCenter,
            zoom: MapConstants.defaultZoom,
            pitch: mapProvider.is3DMode ? MapConstants.defaultTilt : 0.0,
            bearing: 0,
          ),
          styleUri: mapProvider.currentStyle,
          // Add this parameter for camera change events
          onCameraChangeListener: _handleCameraChanged,
        );
      },
    );
  }

  Widget _buildZoomMessage() {
    return Consumer<MapProvider>(
      builder: (context, mapProvider, child) {
        if (!mapProvider.showZoomMessage) {
          return const SizedBox.shrink();
        }

        return Positioned(
          bottom: 150,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Consumer<StationProvider>(
      builder: (context, stationProvider, child) {
        if (stationProvider.status != StationLoadingStatus.loading) {
          return const SizedBox.shrink();
        }

        return Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        );
      },
    );
  }

  // And then simplify your _onMapCreated method
  void _onMapCreated(MapboxMap mapboxMap) {
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    final stationProvider = Provider.of<StationProvider>(
      context,
      listen: false,
    );

    // Initialize map in the provider
    mapProvider.onMapCreated(mapboxMap);

    // Listen for station changes to update markers
    stationProvider.addListener(() {
      _updateMarkers(stationProvider.stations);
    });

    // Load initial sample stations
    stationProvider.loadSampleStations();
  }

  // Implement the camera change handler
  void _handleCameraChanged(CameraChangedEventData data) {
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    final stationProvider = Provider.of<StationProvider>(
      context,
      listen: false,
    );

    // Debounce map movements
    mapProvider.triggerDebounceTimer(() {
      _onMapMoved(mapProvider, stationProvider);
    });
  }

  void _onMapMoved(MapProvider mapProvider, StationProvider stationProvider) {
    mapProvider.updateVisibleRegion().then((_) {
      if (mapProvider.currentZoom >= MapConstants.minZoomForMarkers) {
        // Zoomed in enough to show detailed stations
        if (mapProvider.visibleRegion != null) {
          stationProvider.loadStationsInRegion(mapProvider.visibleRegion!);
        }
      } else if (stationProvider.stations.isNotEmpty &&
          stationProvider.stations.length > 10) {
        // Zoomed out, show only sample stations
        stationProvider.clearStations();
        stationProvider.loadSampleStations();
      }
    });
  }

  void _updateMarkers(List<Station> stations) {
    if (_markerManager != null) {
      _markerManager!.addStationMarkers(stations);
    }
  }
}
