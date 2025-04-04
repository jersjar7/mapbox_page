// lib/main.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';

// Data Layer
import 'data/datasources/local/station_local_data_source.dart';
import 'data/datasources/remote/mapbox_remote_data_source.dart';
import 'data/repositories/station_repository_impl.dart';
import 'data/repositories/location_repository_impl.dart';

// Domain Layer
import 'domain/usecases/get_nearest_stations.dart';
import 'domain/usecases/get_sample_stations.dart';
import 'domain/usecases/get_stations_in_region.dart';
import 'domain/usecases/search_location.dart';

// Presentation Layer
import 'presentation/providers/map_provider.dart';
import 'presentation/providers/station_provider.dart';
import 'presentation/screens/map_screen.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Configure Mapbox
  // Note: In production, use a more secure method to store the token
  // like --dart-define=ACCESS_TOKEN=your_token when running flutter
  const String mapboxAccessToken = String.fromEnvironment('ACCESS_TOKEN');

  // Set the Mapbox access token globally
  MapboxOptions.setAccessToken(mapboxAccessToken);

  // Initialize dependencies
  final httpClient = http.Client();

  // Data sources
  final stationLocalDataSource = StationLocalDataSourceImpl();
  final mapboxRemoteDataSource = MapboxRemoteDataSourceImpl(client: httpClient);

  // Repositories
  final stationRepository = StationRepositoryImpl(
    localDataSource: stationLocalDataSource,
  );
  final locationRepository = LocationRepositoryImpl(
    remoteDataSource: mapboxRemoteDataSource,
  );

  // Use cases
  final getStationsInRegion = GetStationsInRegion(stationRepository);
  final getSampleStations = GetSampleStations(stationRepository);
  final getNearestStations = GetNearestStations(stationRepository);
  final searchLocation = SearchLocation(locationRepository);

  runApp(
    MultiProvider(
      providers: [
        // Map provider
        ChangeNotifierProvider<MapProvider>(
          create: (_) => MapProvider(searchLocationUseCase: searchLocation),
        ),

        // Station provider
        ChangeNotifierProvider<StationProvider>(
          create:
              (_) => StationProvider(
                getStationsInRegion: getStationsInRegion,
                getSampleStations: getSampleStations,
                getNearestStations: getNearestStations,
              ),
        ),
      ],
      child: const MapboxApp(),
    ),
  );
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
