import 'dart:async';
import 'package:flutter/material.dart';
import '../models/p2p_models.dart';
import '../services/p2p_api_service.dart';
import '../db/database_service.dart';

class P2PProvider extends ChangeNotifier {
  final P2PServiceManager _serviceManager;
  final DatabaseService _dbService;

  String _selectedFiat = 'VES';
  String _selectedAsset = 'USDT';
  Map<String, ExchangePrices> _prices = {};
  List<ArbitrageOpportunity> _opportunities = [];
  bool _isLoading = false;
  String? _error;
  Timer? _refreshTimer;
  int _refreshIntervalSeconds = 15;
  DateTime? _lastUpdate;
  double _minProfitFilter = 0.5;
  bool _isAutoRefresh = true;
  List<PriceRecord> _priceHistory = [];

  // Getters
  String get selectedFiat => _selectedFiat;
  String get selectedAsset => _selectedAsset;
  Map<String, ExchangePrices> get prices => _prices;
  List<ArbitrageOpportunity> get opportunities => _opportunities;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get refreshIntervalSeconds => _refreshIntervalSeconds;
  DateTime? get lastUpdate => _lastUpdate;
  double get minProfitFilter => _minProfitFilter;
  bool get isAutoRefresh => _isAutoRefresh;
  List<PriceRecord> get priceHistory => _priceHistory;
  DatabaseService get dbService => _dbService;

  static const List<String> supportedFiats = [
    'VES', 'ARS', 'COP', 'MXN', 'BRL', 'CLP', 'PEN', 'UYU',
    'CNY', 'INR', 'NGN', 'PKR', 'RUB', 'TRY', 'VND', 'IDR',
    'THB', 'PHP', 'KRW', 'JPY', 'EUR', 'GBP', 'USD',
  ];

  P2PProvider({
    required P2PServiceManager serviceManager,
    required DatabaseService dbService,
  })  : _serviceManager = serviceManager,
        _dbService = dbService;

  void setFiat(String fiat) {
    if (_selectedFiat == fiat) return;
    _selectedFiat = fiat;
    _prices.clear();
    _opportunities.clear();
    notifyListeners();
    refreshPrices();
  }

  void setAsset(String asset) {
    if (_selectedAsset == asset) return;
    _selectedAsset = asset;
    _prices.clear();
    _opportunities.clear();
    notifyListeners();
    refreshPrices();
  }

  void setMinProfitFilter(double value) {
    _minProfitFilter = value;
    _updateOpportunities();
    notifyListeners();
  }

  void setRefreshInterval(int seconds) {
    _refreshIntervalSeconds = seconds.clamp(5, 120);
    if (_isAutoRefresh) {
      stopAutoRefresh();
      startAutoRefresh();
    }
    notifyListeners();
  }

  void toggleAutoRefresh() {
    if (_isAutoRefresh) {
      stopAutoRefresh();
    } else {
      startAutoRefresh();
    }
    _isAutoRefresh = !_isAutoRefresh;
    notifyListeners();
  }

  void startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      Duration(seconds: _refreshIntervalSeconds),
      (_) => refreshPrices(),
    );
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> refreshPrices() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newPrices = await _serviceManager.fetchAllPrices(_selectedFiat, _selectedAsset);
      _prices = newPrices;
      _lastUpdate = DateTime.now();
      
      _updateOpportunities();
      await _savePriceRecords();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _updateOpportunities() {
    _opportunities = _serviceManager.detectArbitrage(
      _prices,
      minProfitPercent: _minProfitFilter,
    );
  }

  Future<void> _savePriceRecords() async {
    for (final entry in _prices.entries) {
      final exchangeData = entry.value;
      if (exchangeData.bestBuyPrice > 0 || exchangeData.bestSellPrice > 0) {
        await _dbService.insertPriceRecord(PriceRecord(
          exchange: entry.key,
          fiat: _selectedFiat,
          asset: _selectedAsset,
          bestBuyPrice: exchangeData.bestBuyPrice,
          bestSellPrice: exchangeData.bestSellPrice,
          spread: exchangeData.spread,
          timestamp: DateTime.now(),
        ));
      }
    }
  }

  Future<void> loadPriceHistory({int days = 7}) async {
    _priceHistory = await _dbService.getAllPriceHistory(
      fiat: _selectedFiat,
      asset: _selectedAsset,
      days: days,
    );
    notifyListeners();
  }

  Future<void> loadExchangePriceHistory(String exchange, {int days = 7}) async {
    final records = await _dbService.getPriceHistory(
      exchange: exchange,
      fiat: _selectedFiat,
      asset: _selectedAsset,
      days: days,
    );
    _priceHistory = records;
    notifyListeners();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _serviceManager.dispose();
    super.dispose();
  }
}
