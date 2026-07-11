import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/p2p_models.dart';

class DatabaseService {
  static const String _priceRecordsKey = 'price_records';
  static const int _maxRecords = 5000;

  Future<List<PriceRecord>> _getAllRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_priceRecordsKey);
    if (jsonStr == null) return [];
    
    final List<dynamic> jsonList = jsonDecode(jsonStr);
    return jsonList.map((e) => PriceRecord.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> _saveAllRecords(List<PriceRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    // Keep only the most recent records
    if (records.length > _maxRecords) {
      records = records.sublist(records.length - _maxRecords);
    }
    final jsonList = records.map((r) => r.toMap()).toList();
    await prefs.setString(_priceRecordsKey, jsonEncode(jsonList));
  }

  Future<void> insertPriceRecord(PriceRecord record) async {
    final records = await _getAllRecords();
    records.add(record);
    await _saveAllRecords(records);
  }

  Future<List<PriceRecord>> getPriceHistory({
    required String exchange,
    required String fiat,
    required String asset,
    int days = 7,
  }) async {
    final records = await _getAllRecords();
    final since = DateTime.now().subtract(Duration(days: days));
    
    return records.where((r) =>
      r.exchange == exchange &&
      r.fiat == fiat &&
      r.asset == asset &&
      r.timestamp.isAfter(since)
    ).toList();
  }

  Future<List<PriceRecord>> getAllPriceHistory({
    required String fiat,
    required String asset,
    int days = 7,
  }) async {
    final records = await _getAllRecords();
    final since = DateTime.now().subtract(Duration(days: days));
    
    return records.where((r) =>
      r.fiat == fiat &&
      r.asset == asset &&
      r.timestamp.isAfter(since)
    ).toList();
  }

  Future<int> cleanupOldRecords({int keepDays = 30}) async {
    final records = await _getAllRecords();
    final since = DateTime.now().subtract(Duration(days: keepDays));
    final initialCount = records.length;
    
    records.removeWhere((r) => r.timestamp.isBefore(since));
    await _saveAllRecords(records);
    
    return initialCount - records.length;
  }

  Future<Map<String, dynamic>> getExportData({
    required String fiat,
    required String asset,
    int days = 7,
  }) async {
    final records = await getAllPriceHistory(fiat: fiat, asset: asset, days: days);
    return {
      'fiat': fiat,
      'asset': asset,
      'days': days,
      'records': records.map((r) => r.toMap()).toList(),
    };
  }

  Future<void> close() async {
    // No-op for SharedPreferences
  }
}
