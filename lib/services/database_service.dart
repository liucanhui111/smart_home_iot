import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../constants.dart';
import '../models/device.dart';
import '../models/device_property.dart';
import '../models/automation_rule.dart';

/// 数据库服务（单例）
/// 管理 SQLite 数据库的创建、升级和 CRUD 操作
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  /// 获取数据库实例（懒加载）
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
    );
  }

  /// 创建表结构
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE devices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        topicPrefix TEXT NOT NULL UNIQUE,
        deviceType TEXT NOT NULL,
        isOnline INTEGER DEFAULT 0,
        iconName TEXT DEFAULT '',
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE device_properties (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        deviceId INTEGER NOT NULL,
        propertyKey TEXT NOT NULL,
        value TEXT DEFAULT '',
        dataType TEXT NOT NULL,
        label TEXT DEFAULT '',
        readOnly INTEGER DEFAULT 0,
        unit TEXT,
        minValue REAL,
        maxValue REAL,
        FOREIGN KEY (deviceId) REFERENCES devices(id) ON DELETE CASCADE,
        UNIQUE(deviceId, propertyKey)
      )
    ''');

    await db.execute('''
      CREATE TABLE automation_rules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        enabled INTEGER DEFAULT 1,
        triggerDeviceId INTEGER NOT NULL,
        triggerPropertyKey TEXT NOT NULL,
        condition TEXT NOT NULL,
        threshold TEXT DEFAULT '',
        actionDeviceId INTEGER NOT NULL,
        actionPropertyKey TEXT NOT NULL,
        actionValue TEXT DEFAULT '',
        FOREIGN KEY (triggerDeviceId) REFERENCES devices(id) ON DELETE CASCADE,
        FOREIGN KEY (actionDeviceId) REFERENCES devices(id) ON DELETE CASCADE
      )
    ''');
  }

  // ══════════════════════════════════════════
  // 设备 CRUD
  // ══════════════════════════════════════════

  Future<int> insertDevice(Device device) async {
    final db = await database;
    return await db.insert('devices', device.toMap());
  }

  Future<List<Device>> getAllDevices() async {
    final db = await database;
    final maps = await db.query('devices', orderBy: 'createdAt DESC');
    return maps.map((m) => Device.fromMap(m)).toList();
  }

  Future<Device?> getDeviceById(int id) async {
    final db = await database;
    final maps = await db.query('devices', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Device.fromMap(maps.first);
  }

  Future<void> updateDevice(Device device) async {
    final db = await database;
    await db.update('devices', device.toMap(), where: 'id = ?', whereArgs: [device.id]);
  }

  Future<void> deleteDevice(int id) async {
    final db = await database;
    await db.delete('devices', where: 'id = ?', whereArgs: [id]);
    // 级联删除属性和规则（SQLite 外键约束需开启）
    await db.delete('device_properties', where: 'deviceId = ?', whereArgs: [id]);
    await db.delete('automation_rules',
        where: 'triggerDeviceId = ? OR actionDeviceId = ?', whereArgs: [id, id]);
  }

  // ══════════════════════════════════════════
  // 设备属性 CRUD
  // ══════════════════════════════════════════

  Future<int> insertProperty(DeviceProperty prop) async {
    final db = await database;
    return await db.insert('device_properties', prop.toMap());
  }

  Future<List<DeviceProperty>> getPropertiesByDevice(int deviceId) async {
    final db = await database;
    final maps = await db.query(
      'device_properties',
      where: 'deviceId = ?',
      whereArgs: [deviceId],
    );
    return maps.map((m) => DeviceProperty.fromMap(m)).toList();
  }

  Future<void> updatePropertyValue(int deviceId, String propertyKey, String value) async {
    final db = await database;
    await db.update(
      'device_properties',
      {'value': value},
      where: 'deviceId = ? AND propertyKey = ?',
      whereArgs: [deviceId, propertyKey],
    );
  }

  Future<void> deletePropertiesByDevice(int deviceId) async {
    final db = await database;
    await db.delete('device_properties', where: 'deviceId = ?', whereArgs: [deviceId]);
  }

  // ══════════════════════════════════════════
  // 联动规则 CRUD
  // ══════════════════════════════════════════

  Future<int> insertRule(AutomationRule rule) async {
    final db = await database;
    return await db.insert('automation_rules', rule.toMap());
  }

  Future<List<AutomationRule>> getAllRules() async {
    final db = await database;
    final maps = await db.query('automation_rules', orderBy: 'id DESC');
    return maps.map((m) => AutomationRule.fromMap(m)).toList();
  }

  Future<void> updateRule(AutomationRule rule) async {
    final db = await database;
    await db.update('automation_rules', rule.toMap(),
        where: 'id = ?', whereArgs: [rule.id]);
  }

  Future<void> deleteRule(int id) async {
    final db = await database;
    await db.delete('automation_rules', where: 'id = ?', whereArgs: [id]);
  }
}
