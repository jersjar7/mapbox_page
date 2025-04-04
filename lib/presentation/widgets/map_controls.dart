// lib/presentation/widgets/map_controls.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/map_provider.dart';
import '../providers/station_provider.dart';

class MapControls extends StatelessWidget {
  const MapControls({super.key});

  @override
  Widget build(BuildContext context) {
    final mapProvider = Provider.of<MapProvider>(context);
    final stationProvider = Provider.of<StationProvider>(context);

    return Positioned(
      right: 16,
      bottom: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Refresh button
          FloatingActionButton(
            heroTag: 'refresh',
            onPressed: () {
              mapProvider.updateVisibleRegion().then((_) {
                if (mapProvider.currentZoom >= 10.0) {
                  stationProvider.loadStationsInRegion(
                    mapProvider.visibleRegion!,
                  );
                } else {
                  stationProvider.loadSampleStations();
                }
              });
            },
            tooltip: 'Refresh stations',
            child: const Icon(Icons.refresh),
          ),
          const SizedBox(height: 8),

          // Style selector button
          FloatingActionButton(
            heroTag: 'style',
            onPressed: () => _showStyleSelector(context),
            tooltip: 'Change map style',
            child: const Icon(Icons.layers),
          ),
          const SizedBox(height: 8),

          // 3D toggle button
          FloatingActionButton(
            heroTag: '3d',
            onPressed: () {
              mapProvider.toggle3DTerrain();
              mapProvider.triggerDebounceTimer(() {
                mapProvider.updateVisibleRegion().then((_) {
                  if (mapProvider.currentZoom >= 10.0) {
                    stationProvider.loadStationsInRegion(
                      mapProvider.visibleRegion!,
                    );
                  }
                });
              });
            },
            tooltip: 'Toggle 3D view',
            child: Icon(
              mapProvider.is3DMode
                  ? Icons.view_in_ar
                  : Icons.view_in_ar_outlined,
            ),
          ),
          const SizedBox(height: 8),

          // Zoom in button
          FloatingActionButton(
            heroTag: 'zoomIn',
            onPressed: () {
              mapProvider.zoomIn().then((_) {
                mapProvider.triggerDebounceTimer(() {
                  if (mapProvider.currentZoom >= 10.0) {
                    stationProvider.loadStationsInRegion(
                      mapProvider.visibleRegion!,
                    );
                  } else if (stationProvider.stations.isNotEmpty) {
                    stationProvider.loadSampleStations();
                  }
                });
              });
            },
            tooltip: 'Zoom in',
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),

          // Zoom out button
          FloatingActionButton(
            heroTag: 'zoomOut',
            onPressed: () {
              mapProvider.zoomOut().then((_) {
                mapProvider.triggerDebounceTimer(() {
                  if (mapProvider.currentZoom >= 10.0) {
                    stationProvider.loadStationsInRegion(
                      mapProvider.visibleRegion!,
                    );
                  } else if (stationProvider.stations.isNotEmpty) {
                    stationProvider.clearStations();
                    stationProvider.loadSampleStations();
                  }
                });
              });
            },
            tooltip: 'Zoom out',
            child: const Icon(Icons.remove),
          ),
        ],
      ),
    );
  }

  void _showStyleSelector(BuildContext context) {
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    final stationProvider = Provider.of<StationProvider>(
      context,
      listen: false,
    );

    showModalBottomSheet(
      context: context,
      builder:
          (context) => MapStyleSelector(
            currentStyle: mapProvider.currentStyle,
            onStyleSelected: (style) {
              mapProvider.changeMapStyle(style, () {
                // This callback will be called after the style has been loaded
                if (stationProvider.stations.isNotEmpty) {
                  // Reload stations to ensure annotations are properly displayed
                  if (mapProvider.currentZoom >= 10.0 &&
                      mapProvider.visibleRegion != null) {
                    stationProvider.loadStationsInRegion(
                      mapProvider.visibleRegion!,
                    );
                  } else {
                    stationProvider.loadSampleStations();
                  }
                }
              });
              Navigator.pop(context);
            },
          ),
    );
  }
}
