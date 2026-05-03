import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('products.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 6,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createSettingsTable(db);
      await _createInvoiceTables(db);
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE invoices ADD COLUMN type TEXT NOT NULL DEFAULT "cash"');
      await db.execute('ALTER TABLE invoices ADD COLUMN paymentMethod TEXT NOT NULL DEFAULT "cash"');
      await db.execute('ALTER TABLE invoices ADD COLUMN paidAmount REAL NOT NULL DEFAULT 0.0');
      await db.execute('ALTER TABLE invoices ADD COLUMN remainingAmount REAL NOT NULL DEFAULT 0.0');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE app_settings ADD COLUMN isOnboarded INTEGER DEFAULT 0');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE invoices ADD COLUMN clientName TEXT');
    }
    if (oldVersion < 6) {
      await _createMoneyCollectionsTable(db);
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const doubleType = 'REAL NOT NULL';

    await db.execute('''
CREATE TABLE products ( 
  id $idType, 
  name $textType,
  code $textType UNIQUE,
  price $doubleType
  )
''');

    await _createSettingsTable(db);
    await _createInvoiceTables(db);
    await _createMoneyCollectionsTable(db);
  }

  Future _createMoneyCollectionsTable(Database db) async {
    await db.execute('''
CREATE TABLE money_collections (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  invoiceId INTEGER NOT NULL,
  amount REAL NOT NULL,
  remainingBefore REAL NOT NULL,
  remainingAfter REAL NOT NULL,
  createdAt TEXT NOT NULL,
  clientName TEXT,
  FOREIGN KEY (invoiceId) REFERENCES invoices (id) ON DELETE CASCADE
)
''');
  }

  Future _createSettingsTable(Database db) async {
    await db.execute('''
CREATE TABLE app_settings (
  id INTEGER PRIMARY KEY,
  brandName TEXT,
  phone TEXT,
  address TEXT,
  vatPercent INTEGER DEFAULT 15,
  language TEXT DEFAULT 'EN',
  logoPath TEXT,
  currency TEXT DEFAULT 'USD',
  isOnboarded INTEGER DEFAULT 0
)
''');
    // Insert default settings
    await db.insert('app_settings', {
      'id': 1,
      'brandName': '',
      'vatPercent': 15,
      'language': 'EN',
      'currency': 'USD',
      'isOnboarded': 0
    });
  }

  Future _createInvoiceTables(Database db) async {
    await db.execute('''
CREATE TABLE invoices (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  createdAt TEXT NOT NULL,
  subtotal REAL NOT NULL,
  vatAmount REAL NOT NULL,
  total REAL NOT NULL,
  vatPercent INTEGER NOT NULL,
  currency TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT "cash",
  paymentMethod TEXT NOT NULL DEFAULT "cash",
  paidAmount REAL NOT NULL DEFAULT 0.0,
  remainingAmount REAL NOT NULL DEFAULT 0.0,
  clientName TEXT
)
''');

    await db.execute('''
CREATE TABLE invoice_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  invoiceId INTEGER NOT NULL,
  productId INTEGER,
  productName TEXT NOT NULL,
  productCode TEXT NOT NULL,
  qty INTEGER NOT NULL,
  unitPrice REAL NOT NULL,
  lineTotal REAL NOT NULL,
  FOREIGN KEY (invoiceId) REFERENCES invoices (id) ON DELETE CASCADE
)
''');
  }

  Future<int> deleteInvoice(int id) async {
    final db = await database;
    // Also delete invoice items
    await db.delete(
      'invoice_items',
      where: 'invoiceId = ?',
      whereArgs: [id],
    );
    return await db.delete(
      'invoices',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
