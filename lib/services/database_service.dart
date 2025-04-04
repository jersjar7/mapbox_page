import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/station.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  // Factory constructor
  factory DatabaseService() => _instance;

  // Internal constructor
  DatabaseService._internal();

  // Get database singleton
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize the database
  Future<Database> _initDatabase() async {
    // Get the directory for the app's document directory
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "stationsDatabase.db");

    // Check if the database exists
    bool fileExists = await File(path).exists();

    if (!fileExists) {
      // Copy from assets if it doesn't exist
      ByteData data = await rootBundle.load(
        "assets/databases/stationsDatabase.db",
      );
      List<int> bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await File(path).writeAsBytes(bytes, flush: true);
      print("Database copied from assets");
    } else {
      print("Database already exists");
    }

    // Open the database
    return await openDatabase(path, readOnly: true);
  }

  // Get stations within a specific bounding box (visible map region)
  Future<List<Station>> getStationsInRegion(
    double minLat,
    double maxLat,
    double minLon,
    double maxLon, {
    int limit = 1000,
  }) async {
    Database db = await database;

    try {
      // Simplified query for the new schema (only stationId, lat, lon)
      final List<Map<String, dynamic>> result = await db.query(
        'Geolocations', // Table name
        columns: ['stationId', 'lat', 'lon'],
        where: 'lat >= ? AND lat <= ? AND lon >= ? AND lon <= ?',
        whereArgs: [minLat, maxLat, minLon, maxLon],
        limit: limit, // Limit the number of results for performance
      );

      print("Retrieved ${result.length} stations from visible region");

      // Convert the list of maps to a list of Station objects
      return result.map((map) => Station.fromMap(map)).toList();
    } catch (e) {
      print("Error querying stations: $e");

      // For debugging - get table structure
      try {
        var tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table'",
        );
        print("Available tables: $tables");

        if (tables.isNotEmpty) {
          var tableInfo = await db.rawQuery(
            "PRAGMA table_info(${tables.first['name']})",
          );
          print("Table structure: $tableInfo");
        }
      } catch (e) {
        print("Error querying database structure: $e");
      }

      return [];
    }
  }

  // Get a sample of stations for low zoom levels (just for context)
  Future<List<Station>> getSampleStations({int limit = 10}) async {
    Database db = await database;

    try {
      // Simplified query for the new schema (only stationId, lat, lon)
      final List<Map<String, dynamic>> result = await db.query(
        'Geolocations',
        columns: ['stationId', 'lat', 'lon'],
        limit: limit,
        orderBy: 'RANDOM()', // Get a random sample
      );

      print("Retrieved ${result.length} sample stations");
      return result.map((map) => Station.fromMap(map)).toList();
    } catch (e) {
      print("Error querying sample stations: $e");
      return [];
    }
  }

  // Count total stations for informational purposes
  Future<int> getStationCount() async {
    Database db = await database;

    try {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM Geolocations',
      );
      final count = Sqflite.firstIntValue(result) ?? 0;
      print("Total stations in database: $count");
      return count;
    } catch (e) {
      print("Error counting stations: $e");
      return 0;
    }
  }

  // Get stations nearest to a given location (for search results)
  Future<List<Station>> getNearestStations(
    double lat,
    double lon, {
    int limit = 5,
    double radius = 50.0, // km
  }) async {
    Database db = await database;

    try {
      // Using Haversine formula to calculate distance
      final String haversineFormula = '''
        (6371 * acos(
          cos(radians($lat)) * cos(radians(lat)) * 
          cos(radians(lon) - radians($lon)) + 
          sin(radians($lat)) * sin(radians(lat))
        ))
      ''';

      // Simplified query for the new schema (only stationId, lat, lon)
      final List<Map<String, dynamic>> result = await db.rawQuery('''
        SELECT stationId, lat, lon,
               $haversineFormula AS distance
        FROM Geolocations
        WHERE $haversineFormula < $radius
        ORDER BY distance
        LIMIT $limit
      ''');

      print("Retrieved ${result.length} nearest stations");
      return result.map((map) => Station.fromMap(map)).toList();
    } catch (e) {
      print("Error querying nearest stations: $e");
      return [];
    }
  }
}
