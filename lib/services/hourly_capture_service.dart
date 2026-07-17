import 'dart:async';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'database_service.dart';
import '../models/price_record.dart';
import '../utils/constants.dart';

/// Service that automatically captures P2P prices every hour
/// and stores them in the local SQLite database.
class HourlyCaptureService {
  static HourlyCaptureService? _instance;
  Timer? _timer;
  bool _isRunning = false;
  DateTime? _lastCaptureTime;

  HourlyCaptureService._();
  static HourlyCaptureService get instance => _instance ??= HourlyCaptureService._();

  /// Whether the capture service is running
  bool get isRunning => _isRunning;
  
  /// When the last capture occurred
  DateTime? get lastCaptureTime => _lastCaptureTime;

  /// Start the hourly capture service
  void start(ApiService apiService) {
    if (_isRunning) return;
    _isRunning = true;
    
    // Check every minute if an hour has passed since last capture
    _timer = Timer.periodic(const Duration(minutes: 1), (_) async {
      final now = DateTime.now();
      
      // Capture if: never captured before, or at least 59 minutes have passed
      if (_lastCaptureTime == null || 
          now.difference(_lastCaptureTime!).inMinutes >= 59) {
        await _capturePrices(apiService);
      }
    });

    // Do an immediate capture on start
    _capturePrices(apiService);
    
    debugPrint('HourlyCaptureService started');
  }

  /// Stop the hourly capture service
  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    debugPrint('HourlyCaptureService stopped');
  }

  /// Manually trigger a capture
  Future<void> captureNow(ApiService apiService) async {
    await _capturePrices(apiService);
  }

  /// Capture current prices from all exchanges and store in database
  Future<void> _capturePrices(ApiService apiService) async {
    try {
      // Ensure we have fresh data
      await apiService.fetchAllPrices();
      
      final timestamp = DateTime.now();
      int savedCount = 0;

      for (final fiat in apiService.selectedFiats) {
        for (final exchange in AppConstants.exchanges) {
          final buyKey = '${exchange}_$fiat';
          final sellKey = '${exchange}_$fiat';
          
          final buyAds = apiService.buyAds[buyKey] ?? [];
          final sellAds = apiService.sellAds[sellKey] ?? [];

          // Save best buy price (lowest)
          if (buyAds.isNotEmpty) {
            final sortedBuy = List.of(buyAds)..sort((a, b) => a.price.compareTo(b.price));
            final bestBuy = sortedBuy.first;
            
            await DatabaseService.instance.insertPriceRecord(PriceRecord(
              exchange: exchange,
              fiat: fiat,
              tradeType: 'BUY',
              price: bestBuy.price,
              availableAmount: bestBuy.availableAmount,
              timestamp: timestamp,
            ));
            savedCount++;
          }

          // Save best sell price (highest)
          if (sellAds.isNotEmpty) {
            final sortedSell = List.of(sellAds)..sort((a, b) => b.price.compareTo(a.price));
            final bestSell = sortedSell.first;
            
            await DatabaseService.instance.insertPriceRecord(PriceRecord(
              exchange: exchange,
              fiat: fiat,
              tradeType: 'SELL',
              price: bestSell.price,
              availableAmount: bestSell.availableAmount,
              timestamp: timestamp,
            ));
            savedCount++;
          }
        }
      }

      _lastCaptureTime = timestamp;
      debugPrint('HourlyCapture: saved $savedCount price records at ${timestamp.toIso8601String()}');
    } catch (e) {
      debugPrint('HourlyCapture error: $e');
    }
  }

  /// Clean up old records beyond retention period
  Future<int> cleanup() async {
    return await DatabaseService.instance.cleanupOldRecords();
  }
}
