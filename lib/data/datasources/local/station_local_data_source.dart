// lib/data/datasources/local/station_local_data_source.dart

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/station_model.dart';

abstract class StationLocalDataSource {
  Future<List<StationModel>> getStationsInRegion(
    double minLat,
    double maxLat,
    double minLon,
    double maxLon, {
    int limit = 1000,
  });

  Future<List<StationModel>> getSampleStations({int limit = 10});

  Future<int> getStationCount();

  Future<List<StationModel>> getNearestStations(
    double lat,
    double lon, {
    int limit = 5,
    double radius = 50.0,
  });
}

class StationLocalDataSourceImpl implements StationLocalDataSource {
  static final StationLocalDataSourceImpl _instance =
      StationLocalDataSourceImpl._internal();
  static Database? _database;

  factory StationLocalDataSourceImpl() => _instance;

  StationLocalDataSourceImpl._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "stationsDatabase.db");

    bool fileExists = await File(path).exists();

    if (!fileExists) {
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

    return await openDatabase(path, readOnly: true);
  }

  @override
  Future<List<StationModel>> getStationsInRegion(
    double minLat,
    double maxLat,
    double minLon,
    double maxLon, {
    int limit = 1000,
  }) async {
    Database db = await database;

    try {
      final List<Map<String, dynamic>> result = await db.query(
        'Geolocations',
        columns: ['stationId', 'lat', 'lon'],
        where: 'lat >= ? AND lat <= ? AND lon >= ? AND lon <= ?',
        whereArgs: [minLat, maxLat, minLon, maxLon],
        limit: limit,
      );

      return result.map((map) => StationModel.fromMap(map)).toList();
    } catch (e) {
      print("Error querying stations: $e");
      return [];
    }
  }

  @override
  Future<List<StationModel>> getSampleStations({int limit = 10}) async {
    Database db = await database;

    try {
      final List<Map<String, dynamic>> result = await db.query(
        'Geolocations',
        columns: ['stationId', 'lat', 'lon'],
        limit: limit,
        orderBy: 'RANDOM()',
      );

      return result.map((map) => StationModel.fromMap(map)).toList();
    } catch (e) {
      print("Error querying sample stations: $e");
      return [];
    }
  }

  @override
  Future<int> getStationCount() async {
    Database db = await database;

    try {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM Geolocations',
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      print("Error counting stations: $e");
      return 0;
    }
  }

  @override
  Future<List<StationModel>> getNearestStations(
    double lat,
    double lon, {
    int limit = 5,
    double radius = 50.0,
  }) async {
    Database db = await database;

    try {
      final String haversineFormula = '''
        (6371 * acos(
          cos(radians($lat)) * cos(radians(lat)) * 
          cos(radians(lon) - radians($lon)) + 
          sin(radians($lat)) * sin(radians(lat))
        ))
      ''';

      final List<Map<String, dynamic>> result = await db.rawQuery('''
        SELECT stationId, lat, lon,
               $haversineFormula AS distance
        FROM Geolocations
        WHERE $haversineFormula < $radius
        ORDER BY distance
        LIMIT $limit
      ''');

      return result.map((map) => StationModel.fromMap(map)).toList();
    } catch (e) {
      print("Error querying nearest stations: $e");
      return [];
    }
  }
}
