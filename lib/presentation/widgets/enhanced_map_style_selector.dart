// lib/presentation/widgets/enhanced_map_style_selector.dart

import 'package:flutter/material.dart';
import '../../core/constants/map_constants.dart';

class EnhancedMapStyleSelector extends StatelessWidget {
  final String currentStyle;
  final Function(String) onStyleSelected;

  const EnhancedMapStyleSelector({
    super.key,
    required this.currentStyle,
    required this.onStyleSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Row(
              children: [
                const Text(
                  'Choose Map Style',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),

          // Style options grid
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio:
                  1.3, // Make cells more vertical for text beneath image
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStyleCard(
                  context,
                  'Explore',
                  MapConstants.mapboxStreets,
                  'assets/map_previews/streets.png',
                ),
                _buildStyleCard(
                  context,
                  'Outdoors',
                  MapConstants.mapboxOutdoors,
                  'assets/map_previews/outdoors.png',
                ),
                _buildStyleCard(
                  context,
                  'Standard',
                  MapConstants.mapboxStandard,
                  'assets/map_previews/standard.png',
                ),
                _buildStyleCard(
                  context,
                  'Hybrid',
                  MapConstants.mapboxSatelliteStreets,
                  'assets/map_previews/satellite_streets.png',
                ),
                _buildStyleCard(
                  context,
                  'Light',
                  MapConstants.mapboxLight,
                  'assets/map_previews/light.png',
                ),
                _buildStyleCard(
                  context,
                  'Dark',
                  MapConstants.mapboxDark,
                  'assets/map_previews/dark.png',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleCard(
    BuildContext context,
    String title,
    String styleUri,
    String imagePath,
  ) {
    final bool isSelected = currentStyle == styleUri;
    final Color primaryColor = Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: () => onStyleSelected(styleUri),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Preview Image with rounded corners
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                  image: DecorationImage(
                    image: AssetImage(imagePath),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            // Title at the bottom
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
                  color: isSelected ? primaryColor : Colors.black87,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
