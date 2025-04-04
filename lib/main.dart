import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'map_screen.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Configure Mapbox
  // Note: In production, use a more secure method to store the token
  // like --dart-define=ACCESS_TOKEN=your_token when running flutter
  const String mapboxAccessToken = String.fromEnvironment('ACCESS_TOKEN');

  // Set the Mapbox access token globally
  MapboxOptions.setAccessToken(mapboxAccessToken);

  runApp(const MapboxApp());
}

class MapboxApp extends StatelessWidget {
  const MapboxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mapbox Page',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const MapScreen(),
    );
  }
}
