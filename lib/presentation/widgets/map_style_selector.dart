// // lib/presentation/widgets/map_style_selector.dart

// import 'package:flutter/material.dart';
// import '../../core/constants/map_constants.dart';

// class MapStyleSelector extends StatelessWidget {
//   final String currentStyle;
//   final Function(String) onStyleSelected;

//   const MapStyleSelector({
//     super.key,
//     required this.currentStyle,
//     required this.onStyleSelected,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         const Padding(
//           padding: EdgeInsets.all(16.0),
//           child: Text(
//             'Select Map Style',
//             style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
//           ),
//         ),
//         Divider(),
//         _buildStyleOption(
//           context,
//           'Streets',
//           MapConstants.mapboxStreets,
//           Icons.map,
//         ),
//         _buildStyleOption(
//           context,
//           'Satellite',
//           MapConstants.mapboxSatellite,
//           Icons.satellite,
//         ),
//         _buildStyleOption(
//           context,
//           'Satellite Streets',
//           MapConstants.mapboxStandard,
//           Icons.satellite_alt,
//         ),
//         _buildStyleOption(
//           context,
//           'Light',
//           MapConstants.mapboxLight,
//           Icons.light_mode,
//         ),
//         _buildStyleOption(
//           context,
//           'Dark',
//           MapConstants.mapboxDark,
//           Icons.dark_mode,
//         ),
//         _buildStyleOption(
//           context,
//           'Standard',
//           MapConstants.mapboxStandard,
//           Icons.public,
//         ),
//       ],
//     );
//   }

//   Widget _buildStyleOption(
//     BuildContext context,
//     String title,
//     String styleUri,
//     IconData icon,
//   ) {
//     final bool isSelected = currentStyle == styleUri;

//     return ListTile(
//       leading: Icon(
//         icon,
//         color: isSelected ? Theme.of(context).primaryColor : null,
//       ),
//       title: Text(
//         title,
//         style: TextStyle(
//           color: isSelected ? Theme.of(context).primaryColor : null,
//           fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//         ),
//       ),
//       trailing:
//           isSelected
//               ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor)
//               : null,
//       selected: isSelected,
//       onTap: () => onStyleSelected(styleUri),
//     );
//   }
// }
