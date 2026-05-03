import 'package:sqflite/sqflite.dart';
import '../models/app_settings.dart';
import '../database/database_helper.dart';

abstract class SettingsService {
  Future<AppSettings> getSettings();
  Future<void> saveSettings(AppSettings settings);
}

class SettingsServiceImpl implements SettingsService {
  final DatabaseHelper _dbHelper;

  SettingsServiceImpl(this._dbHelper);

  @override
  Future<AppSettings> getSettings() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'app_settings',
      where: 'id = ?',
      whereArgs: [1],
    );

    if (maps.isNotEmpty) {
      return AppSettings.fromJson(maps.first);
    } else {
      // Should not happen as we insert default on create, but just in case
      return const AppSettings(
        brandName: '',
        phone: '',
        address: '',
        vatPercent: 15,
        language: 'EN',
        printingLanguage: 'EN',
        currency: 'USD',
      );
    }
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    final db = await _dbHelper.database;
    await db.insert(
      'app_settings',
      settings.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
