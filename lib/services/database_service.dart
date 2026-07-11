import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/price_record.dart';
import '../utils/constants.dart';

/// SQLite database service for storing price history
class DatabaseService {
  static DatabaseService? _instance;
  Database? _database;

  DatabaseService._();
  static DatabaseService get instance => _instance ??= DatabaseService._();

  /// Initialize the database
  Future<void> init() async {
    if (_database != null && _database!.isOpen) return;
    
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, AppConstants.dbName);
    
    _database = await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE price_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exchange TEXT NOT NULL,
        fiat TEXT NOT NULL,
        trade_type TEXT NOT NULL,
        price REAL NOT NULL,
        available_amount REAL DEFAULT 0,
        timestamp INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_price_records_exchange_fiat 
      ON price_records(exchange, fiat)
    ''');

    await db.execute('''
      CREATE INDEX idx_price_records_timestamp 
      ON price_records(timestamp)
    ''');

    await db.execute('''
      CREATE INDEX idx_price_records_lookup 
      ON price_records(exchange, fiat, trade_type, timestamp)
    ''');

    // Arbitrage history table
    await db.execute('''
      CREATE TABLE arbitrage_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        buy_exchange TEXT NOT NULL,
        sell_exchange TEXT NOT NULL,
        fiat TEXT NOT NULL,
        buy_price REAL NOT NULL,
        sell_price REAL NOT NULL,
        spread_percent REAL NOT NULL,
        net_profit_percent REAL NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_arbitrage_history_fiat 
      ON arbitrage_history(fiat, timestamp)
    ''');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migrations go here
  }

  /// Insert a price record
  Future<int> insertPriceRecord(PriceRecord record) async {
    final db = await _ensureDb();
    return db.insert('price_records', record.toMap());
  }

  /// Insert multiple price records in a batch
  Future<void> insertPriceRecords(List<PriceRecord> records) async {
    final db = await _ensureDb();
    final batch = db.batch();
    for (final record in records) {
      batch.insert('price_records', record.toMap());
    }
    await batch.commit(noResult: true);
  }

  /// Get price records for a specific exchange/fiat/tradeType
  Future<List<PriceRecord>> getPriceRecords({
    required String exchange,
    required String fiat,
    String? tradeType,
    DateTime? startTime,
    DateTime? endTime,
    int? limit,
  }) async {
    final db = await _ensureDb();
    
    var where = 'exchange = ? AND fiat = ?';
    final args = <dynamic>[exchange, fiat];
    
    if (tradeType != null) {
      where += ' AND trade_type = ?';
      args.add(tradeType);
    }
    if (startTime != null) {
      where += ' AND timestamp >= ?';
      args.add(startTime.millisecondsSinceEpoch);
    }
    if (endTime != null) {
      where += ' AND timestamp <= ?';
      args.add(endTime.millisecondsSinceEpoch);
    }
    
    final maps = await db.query(
      'price_records',
      where: where,
      whereArgs: args,
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    
    return maps.map((map) => PriceRecord.fromMap(map)).toList();
  }

  /// Get aggregated price data (OHLC) for charting
  Future<List<Map<String, dynamic>>> getOHLCData({
    required String exchange,
    required String fiat,
    required String tradeType,
    required int hoursBack,
  }) async {
    final db = await _ensureDb();
    final startTime = DateTime.now().subtract(Duration(hours: hoursBack));
    
    // Aggregate into hourly buckets
    final result = await db.rawQuery('''
      SELECT 
        (timestamp / 3600000) * 3600000 as bucket_start,
        MIN(price) as low,
        MAX(price) as high,
        (SELECT price FROM price_records pr2 
         WHERE pr2.exchange = ? AND pr2.fiat = ? AND pr2.trade_type = ?
         AND (pr2.timestamp / 3600000) = (pr.timestamp / 3600000)
         ORDER BY pr2.timestamp ASC LIMIT 1) as open,
        (SELECT price FROM price_records pr3 
         WHERE pr3.exchange = ? AND pr3.fiat = ? AND pr3.trade_type = ?
         AND (pr3.timestamp / 3600000) = (pr.timestamp / 3600000)
         ORDER BY pr3.timestamp DESC LIMIT 1) as close,
        AVG(price) as avg_price,
        COUNT(*) as count
      FROM price_records pr
      WHERE exchange = ? AND fiat = ? AND trade_type = ?
        AND timestamp >= ?
      GROUP BY bucket_start
      ORDER BY bucket_start ASC
    ''', [exchange, fiat, tradeType, exchange, fiat, tradeType, exchange, fiat, tradeType, 
         startTime.millisecondsSinceEpoch]);
    
    return result;
  }

  /// Insert arbitrage history record
  Future<int> insertArbitrageRecord(Map<String, dynamic> record) async {
    final db = await _ensureDb();
    return db.insert('arbitrage_history', {
      'buy_exchange': record['buyExchange'],
      'sell_exchange': record['sellExchange'],
      'fiat': record['fiat'],
      'buy_price': record['buyPrice'],
      'sell_price': record['sellPrice'],
      'spread_percent': record['spreadPercent'],
      'net_profit_percent': record['netProfitPercent'],
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Get arbitrage history
  Future<List<Map<String, dynamic>>> getArbitrageHistory({
    String? fiat,
    int? limit,
  }) async {
    final db = await _ensureDb();
    
    var where = '';
    final args = <dynamic>[];
    
    if (fiat != null) {
      where = 'fiat = ?';
      args.add(fiat);
    }
    
    final result = await db.query(
      'arbitrage_history',
      where: where.isNotEmpty ? where : null,
      whereArgs: args.isNotEmpty ? args : null,
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    
    return result;
  }

  /// Clean up old records beyond retention period
  Future<int> cleanupOldRecords() async {
    final db = await _ensureDb();
    final cutoff = DateTime.now()
        .subtract(Duration(days: AppConstants.historyRetentionDays))
        .millisecondsSinceEpoch;
    
    final count = await db.delete(
      'price_records',
      where: 'timestamp < ?',
      whereArgs: [cutoff],
    );
    
    await db.delete(
      'arbitrage_history',
      where: 'timestamp < ?',
      whereArgs: [cutoff],
    );
    
    return count;
  }

  /// Export records to CSV format
  Future<String> exportToCSV({
    required String exchange,
    required String fiat,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    final records = await getPriceRecords(
      exchange: exchange,
      fiat: fiat,
      startTime: startTime,
      endTime: endTime,
      limit: 10000,
    );
    
    if (records.isEmpty) return '';
    
    final buffer = StringBuffer();
    buffer.writeln('id,exchange,fiat,trade_type,price,available_amount,timestamp');
    
    for (final record in records) {
      buffer.writeln(
        '${record.id},${record.exchange},${record.fiat},${record.tradeType},'
        '${record.price},${record.availableAmount},${record.timestamp.toIso8601String()}'
      );
    }
    
    return buffer.toString();
  }

  /// Get record count
  Future<int> getRecordCount({String? exchange, String? fiat}) async {
    final db = await _ensureDb();
    
    var where = '';
    final args = <dynamic>[];
    
    if (exchange != null) {
      where += 'exchange = ?';
      args.add(exchange);
    }
    if (fiat != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'fiat = ?';
      args.add(fiat);
    }
    
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM price_records${where.isNotEmpty ? ' WHERE $where' : ''}',
      args,
    );
    
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Ensure database is initialized
  Future<Database> _ensureDb() async {
    if (_database == null || !_database!.isOpen) {
      await init();
    }
    return _database!;
  }

  /// Close the database
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
