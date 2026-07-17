import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/p2p_ad.dart';
import '../models/arbitrage_opportunity.dart';
import '../models/notification_config.dart';
import '../utils/constants.dart';
import 'binance_service.dart';
import 'bybit_service.dart';
import 'bingx_service.dart';
import 'arbitrage_service.dart';
import 'notification_service.dart';

/// Main API service that orchestrates all exchange APIs
class ApiService extends ChangeNotifier {
  final BinanceService _binanceService = BinanceService();
  final BybitService _bybitService = BybitService();
  final BingXService _bingxService = BingXService();
  final ArbitrageService _arbitrageService = ArbitrageService();

  // State
  Map<String, List<P2PAd>> _buyAds = {};
  Map<String, List<P2PAd>> _sellAds = {};
  List<ArbitrageOpportunity> _opportunities = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _error;
  List<String> _selectedFiats = AppConstants.defaultFiats;
  int _refreshInterval = AppConstants.defaultRefreshIntervalSeconds;
  NotificationConfig _notificationConfig = NotificationConfig();
  DateTime? _lastRefresh;

  // Getters
  Map<String, List<P2PAd>> get buyAds => _buyAds;
  Map<String, List<P2PAd>> get sellAds => _sellAds;
  List<ArbitrageOpportunity> get opportunities => _opportunities;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get error => _error;
  List<String> get selectedFiats => _selectedFiats;
  int get refreshInterval => _refreshInterval;
  NotificationConfig get notificationConfig => _notificationConfig;
  DateTime? get lastRefresh => _lastRefresh;
  
  /// Get best buy price for a fiat on an exchange
  double? getBestBuyPrice(String fiat, String exchange) {
    final key = '${exchange}_$fiat';
    final ads = _buyAds[key];
    if (ads == null || ads.isEmpty) return null;
    // For buying USDT, the best price is the lowest
    ads.sort((a, b) => a.price.compareTo(b.price));
    return ads.first.price;
  }

  /// Get best sell price for a fiat on an exchange
  double? getBestSellPrice(String fiat, String exchange) {
    final key = '${exchange}_$fiat';
    final ads = _sellAds[key];
    if (ads == null || ads.isEmpty) return null;
    // For selling USDT, the best price is the highest
    ads.sort((a, b) => b.price.compareTo(a.price));
    return ads.first.price;
  }

  /// Get all buy ads for a fiat
  List<P2PAd> getBuyAdsForFiat(String fiat) {
    final result = <P2PAd>[];
    for (final exchange in AppConstants.exchanges) {
      final key = '${exchange}_$fiat';
      final ads = _buyAds[key] ?? [];
      result.addAll(ads);
    }
    result.sort((a, b) => a.price.compareTo(b.price));
    return result;
  }

  /// Get all sell ads for a fiat
  List<P2PAd> getSellAdsForFiat(String fiat) {
    final result = <P2PAd>[];
    for (final exchange in AppConstants.exchanges) {
      final key = '${exchange}_$fiat';
      final ads = _sellAds[key] ?? [];
      result.addAll(ads);
    }
    result.sort((a, b) => b.price.compareTo(a.price));
    return result;
  }

  /// Fetch all prices from all exchanges
  Future<void> fetchAllPrices() async {
    if (_isLoading) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final futures = <Future<void>>[];
      
      for (final fiat in _selectedFiats) {
        futures.add(_fetchExchangePrices(fiat));
      }

      await Future.wait(futures);
      
      // Calculate arbitrage opportunities
      _opportunities = _arbitrageService.calculateOpportunities(
        buyAds: _buyAds,
        sellAds: _sellAds,
        fiats: _selectedFiats,
      );

      // Check for notifications
      if (_notificationConfig.enabled) {
        await _checkNotifications();
      }

      _lastRefresh = DateTime.now();
    } catch (e) {
      _error = 'Error fetching prices: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch prices for a specific fiat from all exchanges
  Future<void> _fetchExchangePrices(String fiat) async {
    final futures = <Future<void>>[
      _fetchBinancePrices(fiat),
      _fetchBybitPrices(fiat),
      _fetchBingXPrices(fiat),
    ];
    
    // Use Future.wait with graceful error handling
    final results = await Future.wait(
      futures.map((f) => f.then((_) => true).catchError((e) => false)),
    );
    
    // Log any failures but continue
    for (int i = 0; i < results.length; i++) {
      if (!results[i]) {
        final exchange = AppConstants.exchanges[i];
        debugPrint('Warning: Failed to fetch prices from $exchange for $fiat');
      }
    }
  }

  Future<void> _fetchBinancePrices(String fiat) async {
    try {
      final buyAds = await _binanceService.fetchAds(
        fiat: fiat, tradeType: 'BUY',
      );
      final sellAds = await _binanceService.fetchAds(
        fiat: fiat, tradeType: 'SELL',
      );
      _buyAds['Binance_$fiat'] = buyAds;
      _sellAds['Binance_$fiat'] = sellAds;
    } catch (e) {
      debugPrint('Binance fetch error for $fiat: $e');
      rethrow;
    }
  }

  Future<void> _fetchBybitPrices(String fiat) async {
    try {
      final buyAds = await _bybitService.fetchAds(
        fiat: fiat, tradeType: 'BUY',
      );
      final sellAds = await _bybitService.fetchAds(
        fiat: fiat, tradeType: 'SELL',
      );
      _buyAds['Bybit_$fiat'] = buyAds;
      _sellAds['Bybit_$fiat'] = sellAds;
    } catch (e) {
      debugPrint('Bybit fetch error for $fiat: $e');
      rethrow;
    }
  }

  Future<void> _fetchBingXPrices(String fiat) async {
    try {
      final buyAds = await _bingxService.fetchAds(
        fiat: fiat, tradeType: 'BUY',
      );
      final sellAds = await _bingxService.fetchAds(
        fiat: fiat, tradeType: 'SELL',
      );
      _buyAds['BingX_$fiat'] = buyAds;
      _sellAds['BingX_$fiat'] = sellAds;
    } catch (e) {
      debugPrint('BingX fetch error for $fiat: $e');
      rethrow;
    }
  }

  /// Check if any notifications should be triggered
  Future<void> _checkNotifications() async {
    for (final opp in _opportunities) {
      if (opp.netProfitPercent >= _notificationConfig.arbitrageThreshold &&
          _notificationConfig.selectedFiats.contains(opp.fiat) &&
          _notificationConfig.selectedExchanges.contains(opp.buyExchange) &&
          _notificationConfig.selectedExchanges.contains(opp.sellExchange)) {
        await NotificationService.instance.showArbitrageNotification(opp);
      }
    }
  }

  /// Set selected fiat currencies
  void setSelectedFiats(List<String> fiats) {
    _selectedFiats = fiats;
    notifyListeners();
    _savePreferences();
  }

  /// Set refresh interval
  void setRefreshInterval(int seconds) {
    _refreshInterval = seconds.clamp(
      AppConstants.minRefreshIntervalSeconds,
      AppConstants.maxRefreshIntervalSeconds,
    );
    notifyListeners();
    _savePreferences();
  }

  /// Update notification config
  void updateNotificationConfig(NotificationConfig config) {
    _notificationConfig = config;
    notifyListeners();
    _savePreferences();
  }

  /// Load preferences from storage
  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedFiats = prefs.getStringList('selected_fiats') ?? AppConstants.defaultFiats;
    _refreshInterval = prefs.getInt('refresh_interval') ?? AppConstants.defaultRefreshIntervalSeconds;
    
    _notificationConfig = NotificationConfig(
      enabled: prefs.getBool('notif_enabled') ?? true,
      arbitrageThreshold: prefs.getDouble('notif_threshold') ?? 1.0,
      selectedFiats: prefs.getStringList('notif_fiats') ?? AppConstants.defaultFiats,
      selectedExchanges: prefs.getStringList('notif_exchanges') ?? AppConstants.exchanges,
      soundEnabled: prefs.getBool('notif_sound') ?? true,
      vibrateEnabled: prefs.getBool('notif_vibrate') ?? true,
      cooldownMinutes: prefs.getInt('notif_cooldown') ?? 15,
    );
    
    notifyListeners();
  }

  /// Save preferences to storage
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('selected_fiats', _selectedFiats);
    await prefs.setInt('refresh_interval', _refreshInterval);
    await prefs.setBool('notif_enabled', _notificationConfig.enabled);
    await prefs.setDouble('notif_threshold', _notificationConfig.arbitrageThreshold);
    await prefs.setStringList('notif_fiats', _notificationConfig.selectedFiats);
    await prefs.setStringList('notif_exchanges', _notificationConfig.selectedExchanges);
    await prefs.setBool('notif_sound', _notificationConfig.soundEnabled);
    await prefs.setBool('notif_vibrate', _notificationConfig.vibrateEnabled);
    await prefs.setInt('notif_cooldown', _notificationConfig.cooldownMinutes);
  }
}
