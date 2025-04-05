// lib/presentation/widgets/map_controls.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/map_provider.dart';
import '../providers/station_provider.dart';
import 'enhanced_map_style_selector.dart';

class MapControls extends StatefulWidget {
  const MapControls({super.key});

  @override
  State<MapControls> createState() => _MapControlsState();
}

class _MapControlsState extends State<MapControls>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Burger menu at top right
        _buildBurgerMenu(),

        // Expanded menu options when open
        if (_isExpanded) _buildExpandedMenu(),

        // Zoom controls at the bottom
        _buildZoomControls(),
      ],
    );
  }

  Widget _buildBurgerMenu() {
    return Positioned(
      top: 16,
      right: 16,
      child: SafeArea(
        child: FloatingActionButton(
          onPressed: _toggle,
          tooltip: _isExpanded ? 'Hide options' : 'Show more options',
          elevation: 4,
          child: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: _controller,
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedMenu() {
    return Positioned(
      top: 80, // Position below the burger button
      right: 16,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _isExpanded ? 1.0 : 0.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(_isExpanded ? 0 : 50, 0, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildActionButton(
                icon: Icons.refresh,
                label: 'Refresh',
                tooltip: 'Reload stations in this area',
                onPressed: () {
                  _refreshStations();
                  _toggle();
                },
              ),
              const SizedBox(height: 12),

              _buildActionButton(
                icon: Icons.layers,
                label: 'Map Style',
                tooltip: 'Change map appearance',
                onPressed: () {
                  _toggle();
                  _showStyleSelector();
                },
              ),
              const SizedBox(height: 12),

              Consumer<MapProvider>(
                builder: (context, mapProvider, _) {
                  return _buildActionButton(
                    icon:
                        mapProvider.is3DMode
                            ? Icons.view_in_ar
                            : Icons.view_in_ar_outlined,
                    label: '3D View',
                    tooltip:
                        mapProvider.is3DMode
                            ? 'Switch to 2D view'
                            : 'Switch to 3D view',
                    onPressed: () {
                      _toggle3DMode();
                      _toggle();
                    },
                    isActive: mapProvider.is3DMode,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildZoomControls() {
    return Positioned(
      right: 16,
      bottom: 120, // Above the search bar
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Zoom in button
            _buildZoomButton(
              icon: Icons.add,
              tooltip: 'Zoom in',
              onPressed: _zoomIn,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),

            // Divider
            Container(
              height: 1,
              width: 36,
              color: Colors.grey.withValues(alpha: 0.3),
            ),

            // Zoom out button
            _buildZoomButton(
              icon: Icons.remove,
              tooltip: 'Zoom out',
              onPressed: _zoomOut,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoomButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required BorderRadius borderRadius,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: borderRadius,
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(icon),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String tooltip,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    final Color activeColor = Theme.of(context).primaryColor;
    final Color backgroundColor =
        isActive ? activeColor.withValues(alpha: 0.1) : Colors.white;

    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: isActive ? activeColor : Colors.grey[800]),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? activeColor : Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper methods for actions
  void _refreshStations() {
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    final stationProvider = Provider.of<StationProvider>(
      context,
      listen: false,
    );

    mapProvider.updateVisibleRegion().then((_) {
      if (mapProvider.currentZoom >= 10.0) {
        stationProvider.loadStationsInRegion(mapProvider.visibleRegion!);
      } else {
        stationProvider.loadSampleStations();
      }
    });
  }

  void _toggle3DMode() {
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    final stationProvider = Provider.of<StationProvider>(
      context,
      listen: false,
    );

    mapProvider.toggle3DTerrain();
    mapProvider.triggerDebounceTimer(() {
      mapProvider.updateVisibleRegion().then((_) {
        if (mapProvider.currentZoom >= 10.0) {
          stationProvider.loadStationsInRegion(mapProvider.visibleRegion!);
        }
      });
    });
  }

  void _zoomIn() {
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    final stationProvider = Provider.of<StationProvider>(
      context,
      listen: false,
    );

    mapProvider.zoomIn().then((_) {
      mapProvider.triggerDebounceTimer(() {
        if (mapProvider.currentZoom >= 10.0) {
          stationProvider.loadStationsInRegion(mapProvider.visibleRegion!);
        } else if (stationProvider.stations.isNotEmpty) {
          stationProvider.loadSampleStations();
        }
      });
    });
  }

  void _zoomOut() {
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    final stationProvider = Provider.of<StationProvider>(
      context,
      listen: false,
    );

    mapProvider.zoomOut().then((_) {
      mapProvider.triggerDebounceTimer(() {
        if (mapProvider.currentZoom >= 10.0) {
          stationProvider.loadStationsInRegion(mapProvider.visibleRegion!);
        } else if (stationProvider.stations.isNotEmpty) {
          stationProvider.clearStations();
          stationProvider.loadSampleStations();
        }
      });
    });
  }

  void _showStyleSelector() {
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    final stationProvider = Provider.of<StationProvider>(
      context,
      listen: false,
    );

    showModalBottomSheet(
      context: context,
      builder:
          (context) => EnhancedMapStyleSelector(
            currentStyle: mapProvider.currentStyle,
            onStyleSelected: (style) {
              mapProvider.changeMapStyle(style, () {
                if (stationProvider.stations.isNotEmpty) {
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
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    );
  }
}
