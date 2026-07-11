import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/p2p_models.dart';

abstract class P2PApiService {
  String get exchangeName;
  Future<ExchangePrices> fetchPrices(String fiat, String asset);
}

class BinanceP2PService implements P2PApiService {
  static const String _baseUrl = 'https://p2p.binance.com/bapi/c2c/v2/friendly/c2c/adv/search';
  final http.Client _client;
  
  BinanceP2PService({http.Client? client}) : _client = client ?? http.Client();

  @override
  String get exchangeName => 'Binance';

  @override
  Future<ExchangePrices> fetchPrices(String fiat, String asset) async {
    try {
      final buyListings = await _fetchListings(fiat, asset, isBuy: true);
      final sellListings = await _fetchListings(fiat, asset, isBuy: false);

      final bestBuy = buyListings.isNotEmpty ? buyListings.first.price : 0.0;
      final bestSell = sellListings.isNotEmpty ? sellListings.first.price : 0.0;
      final spread = bestBuy > 0 && bestSell > 0 ? ((bestSell - bestBuy) / bestBuy) * 100 : 0.0;

      return ExchangePrices(
        exchange: exchangeName,
        bestBuyPrice: bestBuy,
        bestSellPrice: bestSell,
        spread: spread,
        lastUpdate: DateTime.now(),
        buyListings: buyListings,
        sellListings: sellListings,
      );
    } catch (e) {
      return ExchangePrices(
        exchange: exchangeName,
        error: e.toString(),
        lastUpdate: DateTime.now(),
      );
    }
  }

  Future<List<P2PListing>> _fetchListings(String fiat, String asset, {required bool isBuy}) async {
    final response = await _client.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'asset': asset,
        'fiat': fiat,
        'tradeType': isBuy ? 'BUY' : 'SELL',
        'page': 1,
        'rows': 10,
        'payTypes': [],
        'publisherType': null,
        'transAmount': '',
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List advs = data['data'] ?? [];
      return advs.map<P2PListing>((adv) {
        final advData = adv['adv'] ?? adv;
        return P2PListing(
          exchange: exchangeName,
          asset: advData['asset'] ?? asset,
          fiat: advData['fiatUnit'] ?? fiat,
          price: double.tryParse(advData['price']?.toString() ?? '0') ?? 0,
          minAmount: double.tryParse(advData['minSingleTransAmount']?.toString() ?? '0') ?? 0,
          maxAmount: double.tryParse(advData['maxSingleTransAmount']?.toString() ?? '0') ?? 0,
          availableAmount: double.tryParse(advData['surplusAmount']?.toString() ?? '0') ?? 0,
          paymentMethod: _extractPaymentMethods(advData),
          advertiserName: adv['advertiser']?['nickName'] ?? 'Unknown',
          completionRate: int.tryParse(adv['advertiser']?['monthOrderCount']?.toString() ?? '0') ?? 0,
          ordersCount: int.tryParse(adv['advertiser']?['monthFinishRate']?.toString() ?? '0') ?? 0,
          isBuy: isBuy,
        );
      }).toList();
    } else {
      throw Exception('Binance API error: ${response.statusCode}');
    }
  }

  String _extractPaymentMethods(Map advData) {
    final methods = advData['tradeMethods'] as List?;
    if (methods == null || methods.isEmpty) return 'Multiple';
    return methods.map((m) => m['identifier'] ?? m['tradeMethodName'] ?? '').join(', ');
  }
}

class BybitP2PService implements P2PApiService {
  static const String _baseUrl = 'https://api2.bybit.com/fiat/otc/item/online';
  final http.Client _client;

  BybitP2PService({http.Client? client}) : _client = client ?? http.Client();

  @override
  String get exchangeName => 'Bybit';

  @override
  Future<ExchangePrices> fetchPrices(String fiat, String asset) async {
    try {
      final buyListings = await _fetchListings(fiat, asset, isBuy: true);
      final sellListings = await _fetchListings(fiat, asset, isBuy: false);

      final bestBuy = buyListings.isNotEmpty ? buyListings.first.price : 0.0;
      final bestSell = sellListings.isNotEmpty ? sellListings.first.price : 0.0;
      final spread = bestBuy > 0 && bestSell > 0 ? ((bestSell - bestBuy) / bestBuy) * 100 : 0.0;

      return ExchangePrices(
        exchange: exchangeName,
        bestBuyPrice: bestBuy,
        bestSellPrice: bestSell,
        spread: spread,
        lastUpdate: DateTime.now(),
        buyListings: buyListings,
        sellListings: sellListings,
      );
    } catch (e) {
      return ExchangePrices(
        exchange: exchangeName,
        error: e.toString(),
        lastUpdate: DateTime.now(),
      );
    }
  }

  Future<List<P2PListing>> _fetchListings(String fiat, String asset, {required bool isBuy}) async {
    final response = await _client.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'tokenId': asset,
        'currencyId': fiat,
        'payment': [],
        'side': isBuy ? '1' : '0',
        'size': 10,
        'page': 1,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List items = data['result']?['items'] ?? [];
      return items.map<P2PListing>((item) {
        return P2PListing(
          exchange: exchangeName,
          asset: item['tokenId'] ?? asset,
          fiat: item['currencyId'] ?? fiat,
          price: double.tryParse(item['price']?.toString() ?? '0') ?? 0,
          minAmount: double.tryParse(item['minAmount']?.toString() ?? '0') ?? 0,
          maxAmount: double.tryParse(item['maxAmount']?.toString() ?? '0') ?? 0,
          availableAmount: double.tryParse(item['quantity']?.toString() ?? '0') ?? 0,
          paymentMethod: _extractPaymentMethods(item),
          advertiserName: item['nickName'] ?? item['userName'] ?? 'Unknown',
          completionRate: int.tryParse(item['recentExecuteRate']?.toString() ?? '0') ?? 0,
          ordersCount: int.tryParse(item['recentOrderNum']?.toString() ?? '0') ?? 0,
          isBuy: isBuy,
        );
      }).toList();
    } else {
      throw Exception('Bybit API error: ${response.statusCode}');
    }
  }

  String _extractPaymentMethods(Map item) {
    final payments = item['payments'] as List?;
    if (payments == null || payments.isEmpty) return 'Multiple';
    return payments.map((p) => p['name'] ?? p['paymentType'] ?? '').join(', ');
  }
}

class BingXP2PService implements P2PApiService {
  static const String _baseUrl = 'https://open-api.bingx.com/api/v1/p2p/adv/search';
  final http.Client _client;

  BingXP2PService({http.Client? client}) : _client = client ?? http.Client();

  @override
  String get exchangeName => 'BingX';

  @override
  Future<ExchangePrices> fetchPrices(String fiat, String asset) async {
    try {
      final buyListings = await _fetchListings(fiat, asset, isBuy: true);
      final sellListings = await _fetchListings(fiat, asset, isBuy: false);

      final bestBuy = buyListings.isNotEmpty ? buyListings.first.price : 0.0;
      final bestSell = sellListings.isNotEmpty ? sellListings.first.price : 0.0;
      final spread = bestBuy > 0 && bestSell > 0 ? ((bestSell - bestBuy) / bestBuy) * 100 : 0.0;

      return ExchangePrices(
        exchange: exchangeName,
        bestBuyPrice: bestBuy,
        bestSellPrice: bestSell,
        spread: spread,
        lastUpdate: DateTime.now(),
        buyListings: buyListings,
        sellListings: sellListings,
      );
    } catch (e) {
      return ExchangePrices(
        exchange: exchangeName,
        error: e.toString(),
        lastUpdate: DateTime.now(),
      );
    }
  }

  Future<List<P2PListing>> _fetchListings(String fiat, String asset, {required bool isBuy}) async {
    final response = await _client.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36',
        'Accept': 'application/json',
        'X-BingX-APIKEY': '',
      },
      body: jsonEncode({
        'coin': asset,
        'currency': fiat,
        'tradeType': isBuy ? 'BUY' : 'SELL',
        'page': 1,
        'pageSize': 10,
        'payMethod': '',
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List items = data['data']?['advList'] ?? data['data'] ?? [];
      return items.map<P2PListing>((item) {
        return P2PListing(
          exchange: exchangeName,
          asset: item['coin'] ?? asset,
          fiat: item['currency'] ?? fiat,
          price: double.tryParse(item['price']?.toString() ?? '0') ?? 0,
          minAmount: double.tryParse(item['minTradeAmount']?.toString() ?? '0') ?? 0,
          maxAmount: double.tryParse(item['maxTradeAmount']?.toString() ?? '0') ?? 0,
          availableAmount: double.tryParse(item['availableAmount']?.toString() ?? '0') ?? 0,
          paymentMethod: _extractPaymentMethods(item),
          advertiserName: item['nickName'] ?? item['userName'] ?? 'Unknown',
          completionRate: int.tryParse(item['completeRate']?.toString() ?? '0') ?? 0,
          ordersCount: int.tryParse(item['orderCount']?.toString() ?? '0') ?? 0,
          isBuy: isBuy,
        );
      }).toList();
    } else {
      throw Exception('BingX API error: ${response.statusCode}');
    }
  }

  String _extractPaymentMethods(Map item) {
    final methods = item['payMethodList'] as List?;
    if (methods == null || methods.isEmpty) return 'Multiple';
    return methods.map((m) => m['payMethodName'] ?? m['name'] ?? '').join(', ');
  }
}

class P2PServiceManager {
  final List<P2PApiService> _services;
  final Duration refreshInterval;
  Timer? _timer;
  int _callCount = 0;
  DateTime _lastCallTime = DateTime.now();

  P2PServiceManager({
    required List<P2PApiService> services,
    this.refreshInterval = const Duration(seconds: 15),
  }) : _services = services;

  factory P2PServiceManager.defaultServices() {
    return P2PServiceManager(
      services: [
        BinanceP2PService(),
        BybitP2PService(),
        BingXP2PService(),
      ],
    );
  }

  Future<Map<String, ExchangePrices>> fetchAllPrices(String fiat, String asset) async {
    final results = <String, ExchangePrices>{};
    
    await Future.wait(
      _services.map((service) async {
        await _rateLimit();
        final prices = await service.fetchPrices(fiat, asset);
        results[service.exchangeName] = prices;
      }),
    );
    
    return results;
  }

  Future<void> _rateLimit() async {
    final now = DateTime.now();
    final diff = now.difference(_lastCallTime);
    if (diff.inMilliseconds < 500) {
      await Future.delayed(Duration(milliseconds: 500 - diff.inMilliseconds));
    }
    _lastCallTime = DateTime.now();
    _callCount++;
  }

  List<ArbitrageOpportunity> detectArbitrage(
    Map<String, ExchangePrices> prices, {
    double minProfitPercent = 0.5,
  }) {
    final opportunities = <ArbitrageOpportunity>[];
    final exchanges = prices.keys.toList();

    for (int i = 0; i < exchanges.length; i++) {
      for (int j = 0; j < exchanges.length; j++) {
        if (i == j) continue;
        final buyExchange = prices[exchanges[i]]!;
        final sellExchange = prices[exchanges[j]]!;

        if (buyExchange.bestBuyPrice <= 0 || sellExchange.bestSellPrice <= 0) continue;
        if (buyExchange.error != null || sellExchange.error != null) continue;

        // Buy on exchange i (BUY price = what you pay to buy USDT)
        // Sell on exchange j (SELL price = what you receive when selling USDT)
        final buyPrice = buyExchange.bestBuyPrice;
        final sellPrice = sellExchange.bestSellPrice;

        if (sellPrice <= buyPrice) continue;

        final spreadPercent = ((sellPrice - buyPrice) / buyPrice) * 100;
        if (spreadPercent < minProfitPercent) continue;

        final profitPerUnit = sellPrice - buyPrice;
        final maxTradeAmount = _calculateMaxTradeAmount(buyExchange, sellExchange);
        final estimatedProfit = profitPerUnit * maxTradeAmount / buyPrice;

        // Find best matching listing
        final buyListing = buyExchange.buyListings.isNotEmpty
            ? buyExchange.buyListings.first
            : P2PListing(
                exchange: exchanges[i],
                asset: 'USDT',
                fiat: '',
                price: buyPrice,
                minAmount: 0,
                maxAmount: 0,
                availableAmount: 0,
                paymentMethod: '',
                advertiserName: '',
                completionRate: 0,
                ordersCount: 0,
                isBuy: true,
              );
        
        final sellListing = sellExchange.sellListings.isNotEmpty
            ? sellExchange.sellListings.first
            : P2PListing(
                exchange: exchanges[j],
                asset: 'USDT',
                fiat: '',
                price: sellPrice,
                minAmount: 0,
                maxAmount: 0,
                availableAmount: 0,
                paymentMethod: '',
                advertiserName: '',
                completionRate: 0,
                ordersCount: 0,
                isBuy: false,
              );

        opportunities.add(ArbitrageOpportunity(
          buyListing: buyListing,
          sellListing: sellListing,
          spreadPercent: spreadPercent,
          profitPerUnit: profitPerUnit,
          maxTradeAmount: maxTradeAmount,
          estimatedProfit: estimatedProfit,
        ));
      }
    }

    opportunities.sort((a, b) => b.spreadPercent.compareTo(a.spreadPercent));
    return opportunities;
  }

  double _calculateMaxTradeAmount(ExchangePrices buy, ExchangePrices sell) {
    double buyMax = double.infinity;
    double sellMax = double.infinity;

    if (buy.buyListings.isNotEmpty) {
      buyMax = buy.buyListings.first.maxAmount > 0
          ? buy.buyListings.first.maxAmount
          : buy.buyListings.first.availableAmount;
    }
    if (sell.sellListings.isNotEmpty) {
      sellMax = sell.sellListings.first.maxAmount > 0
          ? sell.sellListings.first.maxAmount
          : sell.sellListings.first.availableAmount;
    }

    if (buyMax == double.infinity && sellMax == double.infinity) return 100;
    if (buyMax == double.infinity) return sellMax;
    if (sellMax == double.infinity) return buyMax;
    return buyMax < sellMax ? buyMax : sellMax;
  }

  void dispose() {
    _timer?.cancel();
  }
}
