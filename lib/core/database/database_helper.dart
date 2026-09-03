import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../../models/models.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('frankie_vendor.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Catalog Items
    await db.execute('''
      CREATE TABLE catalog_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        price REAL NOT NULL,
        category TEXT NOT NULL DEFAULT 'GENERAL',
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    // 2. Invoices
    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT NOT NULL UNIQUE,
        customer_name TEXT DEFAULT '',
        customer_phone TEXT DEFAULT '',
        subtotal REAL NOT NULL,
        discount REAL NOT NULL DEFAULT 0.0,
        tax REAL NOT NULL DEFAULT 0.0,
        grand_total REAL NOT NULL,
        payment_mode TEXT NOT NULL DEFAULT 'Cash',
        created_at TEXT NOT NULL
      )
    ''');

    // 3. Invoice Items
    await db.execute('''
      CREATE TABLE invoice_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER NOT NULL,
        item_name TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit_price REAL NOT NULL,
        line_total REAL NOT NULL,
        FOREIGN KEY (invoice_id) REFERENCES invoices (id) ON DELETE CASCADE
      )
    ''');

    // 4. Shop Settings
    await db.execute('''
      CREATE TABLE shop_settings (
        id INTEGER PRIMARY KEY,
        shop_name TEXT NOT NULL DEFAULT 'FRANKIE CORNER',
        phone TEXT NOT NULL DEFAULT '9876543210',
        address TEXT NOT NULL DEFAULT 'Food Street, Market Road',
        upi_id TEXT DEFAULT '',
        currency TEXT NOT NULL DEFAULT '₹',
        tax_percent REAL NOT NULL DEFAULT 0.0,
        footer_note TEXT NOT NULL DEFAULT 'Fresh & Delicious! Visit Again!',
        updated_at TEXT NOT NULL
      )
    ''');

    // Pre-seed default settings
    final nowStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    await db.insert('shop_settings', {
      'id': 1,
      'shop_name': 'FRANKIE CORNER',
      'phone': '9876543210',
      'address': 'Food Street, Market Road',
      'upi_id': 'vendor@upi',
      'currency': '₹',
      'tax_percent': 0.0,
      'footer_note': 'Fresh & Delicious! Visit Again!',
      'updated_at': nowStr,
    });

    // Pre-seed Frankie items
    final defaultItems = [
      {'name': 'VEG FRANKIE', 'price': 60.0, 'category': 'FRANKIE'},
      {'name': 'PANEER FRANKIE', 'price': 80.0, 'category': 'FRANKIE'},
      {'name': 'CHEESE FRANKIE', 'price': 90.0, 'category': 'FRANKIE'},
      {'name': 'SCHEZWAN FRANKIE', 'price': 70.0, 'category': 'FRANKIE'},
      {'name': 'EGG FRANKIE', 'price': 70.0, 'category': 'FRANKIE'},
      {'name': 'CHICKEN FRANKIE', 'price': 100.0, 'category': 'FRANKIE'},
      {'name': 'FRENCH FRIES', 'price': 70.0, 'category': 'SNACKS'},
      {'name': 'COLD DRINK', 'price': 40.0, 'category': 'BEVERAGE'},
      {'name': 'MINERAL WATER', 'price': 20.0, 'category': 'BEVERAGE'},
      {'name': 'EXTRA CHEESE', 'price': 30.0, 'category': 'EXTRA'},
      {'name': 'EXTRA MAYO', 'price': 15.0, 'category': 'EXTRA'},
    ];

    for (final item in defaultItems) {
      await db.insert('catalog_items', {
        'name': item['name'],
        'price': item['price'],
        'category': item['category'],
        'is_active': 1,
        'created_at': nowStr,
      });
    }
  }

  // ---------------- CATALOG QUERIES ----------------

  Future<List<CatalogItem>> getCatalogItems({
    bool onlyActive = false,
    String? category,
  }) async {
    final db = await instance.database;
    String where = '';
    final List<dynamic> whereArgs = [];

    if (onlyActive) {
      where += 'is_active = 1';
    }

    if (category != null && category.isNotEmpty && category != 'ALL') {
      if (where.isNotEmpty) where += ' AND ';
      where += 'category = ?';
      whereArgs.add(category.toUpperCase().trim());
    }

    final maps = await db.query(
      'catalog_items',
      where: where.isEmpty ? null : where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'category ASC, name ASC',
    );

    return maps.map((m) => CatalogItem.fromMap(m)).toList();
  }

  Future<int> insertCatalogItem(CatalogItem item) async {
    final db = await instance.database;
    final now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    return await db.insert(
      'catalog_items',
      item.copyWith(createdAt: now).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateCatalogItem(CatalogItem item) async {
    final db = await instance.database;
    return await db.update(
      'catalog_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteCatalogItem(int id) async {
    final db = await instance.database;
    return await db.delete(
      'catalog_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ---------------- INVOICE & BILLING ----------------

  Future<String> generateNextInvoiceNumber() async {
    final db = await instance.database;
    final now = DateTime.now();
    final datePrefix = DateFormat('yyyyMMdd').format(now);
    
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM invoices WHERE created_at LIKE ?',
      ['${DateFormat('yyyy-MM-dd').format(now)}%'],
    );
    final count = Sqflite.firstIntValue(result) ?? 0;
    final seq = (count + 1).toString().padLeft(3, '0');
    return 'INV-$datePrefix-$seq';
  }

  Future<InvoiceWithItems> saveInvoice({
    required Invoice invoice,
    required List<DraftCartItem> cartItems,
  }) async {
    final db = await instance.database;

    return await db.transaction((txn) async {
      final invoiceId = await txn.insert(
        'invoices',
        invoice.toMap(),
      );

      final List<InvoiceItem> savedItems = [];
      for (final cartItem in cartItems) {
        final itemMap = {
          'invoice_id': invoiceId,
          'item_name': cartItem.name.toUpperCase().trim(),
          'quantity': cartItem.quantity,
          'unit_price': cartItem.unitPrice,
          'line_total': cartItem.lineTotal,
        };
        final itemId = await txn.insert('invoice_items', itemMap);
        savedItems.add(InvoiceItem(
          id: itemId,
          invoiceId: invoiceId,
          itemName: cartItem.name.toUpperCase().trim(),
          quantity: cartItem.quantity,
          unitPrice: cartItem.unitPrice,
          lineTotal: cartItem.lineTotal,
        ));
      }

      final savedInvoice = invoice.copyWith(id: invoiceId);
      return InvoiceWithItems(invoice: savedInvoice, items: savedItems);
    });
  }

  Future<List<InvoiceWithItems>> getInvoices({
    String? searchQuery,
    String? dateFilter,
  }) async {
    final db = await instance.database;

    String where = '';
    final List<dynamic> whereArgs = [];

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = '%${searchQuery.trim().toUpperCase()}%';
      where += '(invoice_number LIKE ? OR customer_name LIKE ? OR customer_phone LIKE ?)';
      whereArgs.addAll([query, query, query]);
    }

    if (dateFilter != null && dateFilter.isNotEmpty) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'created_at LIKE ?';
      whereArgs.add('$dateFilter%');
    }

    final invoiceMaps = await db.query(
      'invoices',
      where: where.isEmpty ? null : where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'id DESC',
    );

    final List<InvoiceWithItems> results = [];
    for (final map in invoiceMaps) {
      final inv = Invoice.fromMap(map);
      final itemMaps = await db.query(
        'invoice_items',
        where: 'invoice_id = ?',
        whereArgs: [inv.id],
      );
      final items = itemMaps.map((m) => InvoiceItem.fromMap(m)).toList();
      results.add(InvoiceWithItems(invoice: inv, items: items));
    }

    return results;
  }

  Future<SalesSummary> getSalesSummary() async {
    final db = await instance.database;
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Overall sales
    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as bills, COALESCE(SUM(grand_total), 0.0) as sales FROM invoices'
    );
    final totalBills = Sqflite.firstIntValue(totalResult) ?? 0;
    final totalSales = (totalResult.first['sales'] as num? ?? 0.0).toDouble();

    // Today sales
    final todayResult = await db.rawQuery(
      'SELECT COUNT(*) as bills, COALESCE(SUM(grand_total), 0.0) as sales FROM invoices WHERE created_at LIKE ?',
      ['$todayStr%']
    );
    final todayBills = Sqflite.firstIntValue(todayResult) ?? 0;
    final todaySales = (todayResult.first['sales'] as num? ?? 0.0).toDouble();

    return SalesSummary(
      totalBills: totalBills,
      totalSales: totalSales,
      todayBills: todayBills,
      todaySales: todaySales,
    );
  }

  // ---------------- SHOP SETTINGS ----------------

  Future<ShopSettings> getShopSettings() async {
    final db = await instance.database;
    final maps = await db.query('shop_settings', where: 'id = ?', whereArgs: [1]);
    if (maps.isNotEmpty) {
      return ShopSettings.fromMap(maps.first);
    }
    return const ShopSettings();
  }

  Future<int> updateShopSettings(ShopSettings settings) async {
    final db = await instance.database;
    final now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    return await db.update(
      'shop_settings',
      settings.copyWith(updatedAt: now).toMap(),
      where: 'id = ?',
      whereArgs: [1],
    );
  }
}
