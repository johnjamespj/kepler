import 'dart:async';

import 'package:kepler/api/api.dart';
import 'package:kepler/models/starData.dart';
import 'package:kepler/utils/keplerUtils.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/planetData.dart';

class KeplerDatabase {
  KeplerDatabase._();
  static final KeplerDatabase db = KeplerDatabase._();

  final String _table = "tb_kepler";
  final String _createTable = """CREATE TABLE tb_kepler(
                  id INTEGER PRIMARY KEY,
                  pl_name TEXT,
                  hostname TEXT,
                  disc_year INT,
                  pl_orbper REAL,
                  pl_radj REAL,
                  pl_bmassj REAL,
                  pl_dens REAL,
                  st_teff REAL,
                  st_rad REAL,
                  st_mass REAL,
                  st_age REAL,
                  sy_bmag REAL,
                  sy_vmag REAL
                  )""";

  static Database _database;

  Future<Database> get database async {
    if (_database != null) return _database;
    _database = await initDb();
    return _database;
  }

  Future<Database> initDb() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, "kepler.db");

    return await openDatabase(path, version: 1,
        onCreate: (Database db, int newerVersion) async {
    });
  }

  Future<void> dropTable() async{
    Database db = await database;
    db.execute("DROP TABLE IF EXISTS $_table");
  }

  Future<bool> updateData() async {
    try {
      Database db = await database;
      await API.getAllData().then((data) async {
        final Batch batch = db.batch();
        batch.execute("DROP TABLE IF EXISTS $_table");
        KeplerUtils.syncUpdate("Creating database table...", 0.50);
        batch.execute(_createTable);
        KeplerUtils.syncUpdate("Inserting data...", 0.60);
        data.forEach((item) {
          batch.insert(_table, item);
        });
        KeplerUtils.syncUpdate("Commiting database changes...", 0.7);
        await batch.commit(noResult: true);
        KeplerUtils.syncUpdate("Finishing...", 0.9);
      });
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<PlanetData> getPlanetByName(String name)async{
    Database db = await database;
    final List<Map<String, dynamic>> data = await db.query(
      "tb_kepler",
      where:
      "pl_name like '%$name%'",
    );
    final planets = data
        .map((Map<String, dynamic> planet) => PlanetData.fromMap(planet))
        .toList();
    return planets[0];
  }

  Future<List<StarData>> getAllStars() async {
    Database db = await database;
    final List<Map<String, dynamic>> data = await db.query("tb_kepler",
        columns: ["hostname", "st_teff", "st_rad", "st_mass", "st_age"],
        distinct: true);
    final stars = data
        .map((Map<String, dynamic> star) => StarData.fromMap(star))
        .toList();
    return stars.cast<StarData>();
  }

  Future<List<PlanetData>> getPlanetsOrbitsBetween(lower, upper) async {
    Database db = await database;
    final List<Map<String, dynamic>> data = await db.query(
      "tb_kepler",
      columns: ["pl_name", "pl_orbper"],
      orderBy: "pl_orbper desc",
      where:
          "pl_orbper IS NOT NULL and pl_orbper != '' and pl_orbper >= $lower and pl_orbper <= $upper",
    );
    final planets = data
        .map((Map<String, dynamic> planet) => PlanetData.fromMap(planet))
        .toList();
    // planets.forEach((PlanetData planet) {
    //   if(planet)
    // });
    return planets;
  }

  Future<List<PlanetData>> getAllPlanetsOrbits() async {
    Database db = await database;
    final List<Map<String, dynamic>> data = await db.query(
      "tb_kepler",
      columns: ["pl_name", "pl_orbper"],
      orderBy: "pl_orbper desc",
      where: "pl_orbper IS NOT NULL and pl_orbper != ''",
    );
    final planets = data
        .map((Map<String, dynamic> planet) => PlanetData.fromMap(planet))
        .toList();
    // planets.forEach((PlanetData planet) {
    //   if(planet)
    // });
    return planets;
  }

  Future<List<PlanetData>> getPlanetsOrbits(
    String orderBy, {
    int limit = 6,
  }) async {
    Database db = await database;
    final List<Map<String, dynamic>> data = await db.query("tb_kepler",
        columns: ["pl_name", "pl_orbper"],
        orderBy: "pl_orbper " + orderBy,
        where: "pl_orbper IS NOT NULL and pl_orbper != ''",
        limit: limit);
    final planets = data
        .map((Map<String, dynamic> planet) => PlanetData.fromMap(planet))
        .toList();
    // planets.forEach((PlanetData planet) {
    //   if(planet)
    // });
    return planets;
  }

  Future<List<PlanetData>> getSolarSystemPlanets(String star) async {
    Database db = await database;
    final List<Map<String, dynamic>> data = await db.query("tb_kepler",
        columns: [
          "hostname",
          "pl_name",
          "disc_year",
          "pl_orbper",
          "pl_radj",
          "pl_bmassj",
          "pl_dens",
          "sy_bmag",
          "sy_vmag"
        ],
        where: "hostname='$star'");
    final planets = data
        .map((Map<String, dynamic> star) => PlanetData.fromMap(star))
        .toList();
    return planets.cast<PlanetData>();
  }

  Future close() async {
    Database db = await database;
    db.close();
  }
}
