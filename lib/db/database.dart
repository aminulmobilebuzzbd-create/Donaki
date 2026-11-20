import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models.dart';

/// সব ডেটা ফোনের ভেতরে একটা SQLite ফাইলে থাকে। কোনো সার্ভার নেই, কোনো খরচ নেই।
class AppDb {
  AppDb._();
  static final AppDb instance = AppDb._();

  static const _fileName = 'dokani.db';
  Database? _db;

  Future<Database> get db async => _db ??= await _open();

  Future<String> filePath() async => p.join(await getDatabasesPath(), _fileName);

  Future<Database> _open() async {
    return openDatabase(
      await filePath(),
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE customers(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            phone TEXT,
            created_at INTEGER NOT NULL
          )''');
        await db.execute('''
          CREATE TABLE ledger(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            customer_id INTEGER NOT NULL,
            type TEXT NOT NULL CHECK(type IN ('gave','got')),
            amount REAL NOT NULL,
            note TEXT,
            date INTEGER NOT NULL
          )''');
        await db.execute('CREATE INDEX idx_ledger_customer ON ledger(customer_id)');
        await db.execute('''
          CREATE TABLE cash(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL CHECK(type IN ('sale','expense')),
            amount REAL NOT NULL,
            note TEXT,
            date INTEGER NOT NULL
          )''');
        await db.execute('CREATE INDEX idx_cash_date ON cash(date)');
        await db.execute('''
          CREATE TABLE products(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            price REAL NOT NULL DEFAULT 0,
            stock REAL NOT NULL DEFAULT 0
          )''');
        await _addProductColumnsV2(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _addProductColumnsV2(db);
      },
    );
  }

  /// ভার্সন ২: পণ্যের ক্রয়মূল্য, একক, ক্যাটাগরি, ছবি, বারকোড ইত্যাদি। পুরনো পণ্য ঠিক থাকে।
  static Future<void> _addProductColumnsV2(Database db) async {
    const columns = {
      'cost_price': 'REAL NOT NULL DEFAULT 0',
      'unit': "TEXT NOT NULL DEFAULT 'পিস'",
      'category': "TEXT NOT NULL DEFAULT ''",
      'sub_category': "TEXT NOT NULL DEFAULT ''",
      'description': "TEXT NOT NULL DEFAULT ''",
      'wholesale': 'INTEGER NOT NULL DEFAULT 0',
      'wholesale_price': 'REAL NOT NULL DEFAULT 0',
      'wholesale_min_qty': 'REAL NOT NULL DEFAULT 0',
      'low_alert': 'INTEGER NOT NULL DEFAULT 1',
      'low_alert_qty': 'REAL NOT NULL DEFAULT 5',
      'vat': 'INTEGER NOT NULL DEFAULT 0',
      'vat_percent': 'REAL NOT NULL DEFAULT 0',
      'warranty': 'INTEGER NOT NULL DEFAULT 0',
      'warranty_months': 'INTEGER NOT NULL DEFAULT 0',
      'discount': 'INTEGER NOT NULL DEFAULT 0',
      'discount_amount': 'REAL NOT NULL DEFAULT 0',
      'discount_is_percent': 'INTEGER NOT NULL DEFAULT 0',
      'barcode': "TEXT NOT NULL DEFAULT ''",
      'images': "TEXT NOT NULL DEFAULT ''",
    };
    for (final e in columns.entries) {
      await db.execute('ALTER TABLE products ADD COLUMN ${e.key} ${e.value}');
    }
  }

  // ---------------- কাস্টমার ----------------

  static const _balanceSql = '''
    SELECT c.id, c.name, c.phone,
      COALESCE(SUM(CASE WHEN l.type = 'gave' THEN l.amount ELSE -l.amount END), 0) AS balance
    FROM customers c
    LEFT JOIN ledger l ON l.customer_id = c.id
  ''';

  Future<List<Customer>> customers() async {
    final rows = await (await db).rawQuery('$_balanceSql GROUP BY c.id ORDER BY c.name COLLATE NOCASE');
    return rows.map(Customer.fromMap).toList();
  }

  Future<Customer?> customer(int id) async {
    final rows = await (await db).rawQuery('$_balanceSql WHERE c.id = ? GROUP BY c.id', [id]);
    return rows.isEmpty ? null : Customer.fromMap(rows.first);
  }

  Future<int> addCustomer(String name, String? phone) async {
    return (await db).insert('customers', {
      'name': name,
      'phone': phone,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> updateCustomer(int id, String name, String? phone) async {
    await (await db).update('customers', {'name': name, 'phone': phone},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteCustomer(int id) async {
    await (await db).transaction((txn) async {
      await txn.delete('ledger', where: 'customer_id = ?', whereArgs: [id]);
      await txn.delete('customers', where: 'id = ?', whereArgs: [id]);
    });
  }

  // ---------------- বাকি খাতা ----------------

  Future<List<LedgerEntry>> ledgerFor(int customerId) async {
    final rows = await (await db).query('ledger',
        where: 'customer_id = ?', whereArgs: [customerId], orderBy: 'date DESC, id DESC');
    return rows.map(LedgerEntry.fromMap).toList();
  }

  Future<void> addLedger(int customerId, String type, double amount, String note, DateTime date) async {
    await (await db).insert('ledger', {
      'customer_id': customerId,
      'type': type,
      'amount': amount,
      'note': note,
      'date': date.millisecondsSinceEpoch,
    });
  }

  Future<void> deleteLedger(int id) async {
    await (await db).delete('ledger', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- ক্যাশবক্স ----------------

  Future<List<CashEntry>> cashBetween(DateTime from, DateTime to) async {
    final rows = await (await db).query('cash',
        where: 'date >= ? AND date < ?',
        whereArgs: [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
        orderBy: 'date DESC, id DESC');
    return rows.map(CashEntry.fromMap).toList();
  }

  Future<void> addCash(String type, double amount, String note, DateTime date) async {
    await (await db).insert('cash', {
      'type': type,
      'amount': amount,
      'note': note,
      'date': date.millisecondsSinceEpoch,
    });
  }

  Future<void> deleteCash(int id) async {
    await (await db).delete('cash', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- স্টক ----------------

  Future<List<Product>> products() async {
    final rows = await (await db).query('products', orderBy: 'name COLLATE NOCASE');
    return rows.map(Product.fromMap).toList();
  }

  Future<void> saveProduct(Product product) async {
    final d = await db;
    if (product.id == null) {
      await d.insert('products', product.toMap());
    } else {
      await d.update('products', product.toMap(), where: 'id = ?', whereArgs: [product.id]);
    }
  }

  Future<void> adjustStock(int id, double delta) async {
    await (await db).rawUpdate('UPDATE products SET stock = MAX(stock + ?, 0) WHERE id = ?', [delta, id]);
  }

  Future<List<String>> productCategories() async {
    final rows = await (await db).rawQuery(
        "SELECT DISTINCT category FROM products WHERE category != '' ORDER BY category COLLATE NOCASE");
    return rows.map((r) => r['category'] as String).toList();
  }

  Future<bool> barcodeExists(String code, {int? exceptId}) async {
    final rows = await (await db).query('products',
        columns: ['id'], where: 'barcode = ? AND id != ?', whereArgs: [code, exceptId ?? -1], limit: 1);
    return rows.isNotEmpty;
  }

  Future<void> deleteProduct(int id) async {
    await (await db).delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- রিপোর্ট ----------------

  Future<Report> report(DateTime from, DateTime to) async {
    final d = await db;
    final range = [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch];

    final cash = (await d.rawQuery('''
      SELECT
        COALESCE(SUM(CASE WHEN type = 'sale' THEN amount END), 0) AS sales,
        COALESCE(SUM(CASE WHEN type = 'expense' THEN amount END), 0) AS expense
      FROM cash WHERE date >= ? AND date < ?''', range)).first;

    final ledger = (await d.rawQuery('''
      SELECT
        COALESCE(SUM(CASE WHEN type = 'gave' THEN amount END), 0) AS gave,
        COALESCE(SUM(CASE WHEN type = 'got' THEN amount END), 0) AS got
      FROM ledger WHERE date >= ? AND date < ?''', range)).first;

    final all = await customers();
    double receivable = 0, payable = 0;
    for (final c in all) {
      if (c.balance > 0) receivable += c.balance;
      if (c.balance < 0) payable += -c.balance;
    }

    double n(Object? v) => (v as num? ?? 0).toDouble();
    return Report(
      sales: n(cash['sales']),
      expense: n(cash['expense']),
      bakiGiven: n(ledger['gave']),
      bakiCollected: n(ledger['got']),
      totalReceivable: receivable,
      totalPayable: payable,
    );
  }
}
