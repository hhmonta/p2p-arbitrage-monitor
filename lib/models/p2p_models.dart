class P2PListing {
  final String exchange;
  final String asset;
  final String fiat;
  final double price;
  final double minAmount;
  final double maxAmount;
  final double availableAmount;
  final String paymentMethod;
  final String advertiserName;
  final int completionRate;
  final int ordersCount;
  final bool isBuy;

  P2PListing({
    required this.exchange,
    required this.asset,
    required this.fiat,
    required this.price,
    required this.minAmount,
    required this.maxAmount,
    required this.availableAmount,
    required this.paymentMethod,
    required this.advertiserName,
    required this.completionRate,
    required this.ordersCount,
    required this.isBuy,
  });

  Map<String, dynamic> toMap() {
    return {
      'exchange': exchange,
      'asset': asset,
      'fiat': fiat,
      'price': price,
      'minAmount': minAmount,
      'maxAmount': maxAmount,
      'availableAmount': availableAmount,
      'paymentMethod': paymentMethod,
      'advertiserName': advertiserName,
      'completionRate': completionRate,
      'ordersCount': ordersCount,
      'isBuy': isBuy ? 1 : 0,
    };
  }

  factory P2PListing.fromMap(Map<String, dynamic> map) {
    return P2PListing(
      exchange: map['exchange'] ?? '',
      asset: map['asset'] ?? 'USDT',
      fiat: map['fiat'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      minAmount: (map['minAmount'] ?? 0).toDouble(),
      maxAmount: (map['maxAmount'] ?? 0).toDouble(),
      availableAmount: (map['availableAmount'] ?? 0).toDouble(),
      paymentMethod: map['paymentMethod'] ?? '',
      advertiserName: map['advertiserName'] ?? '',
      completionRate: map['completionRate'] ?? 0,
      ordersCount: map['ordersCount'] ?? 0,
      isBuy: map['isBuy'] == 1,
    );
  }
}

class ArbitrageOpportunity {
  final P2PListing buyListing;
  final P2PListing sellListing;
  final double spreadPercent;
  final double profitPerUnit;
  final double maxTradeAmount;
  final double estimatedProfit;

  ArbitrageOpportunity({
    required this.buyListing,
    required this.sellListing,
    required this.spreadPercent,
    required this.profitPerUnit,
    required this.maxTradeAmount,
    required this.estimatedProfit,
  });

  String get route =>
      '${buyListing.exchange} (Comprar @ ${buyListing.price.toStringAsFixed(2)}) → ${sellListing.exchange} (Vender @ ${sellListing.price.toStringAsFixed(2)})';
}

class PriceRecord {
  final int? id;
  final String exchange;
  final String fiat;
  final String asset;
  final double bestBuyPrice;
  final double bestSellPrice;
  final double spread;
  final DateTime timestamp;

  PriceRecord({
    this.id,
    required this.exchange,
    required this.fiat,
    required this.asset,
    required this.bestBuyPrice,
    required this.bestSellPrice,
    required this.spread,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exchange': exchange,
      'fiat': fiat,
      'asset': asset,
      'bestBuyPrice': bestBuyPrice,
      'bestSellPrice': bestSellPrice,
      'spread': spread,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory PriceRecord.fromMap(Map<String, dynamic> map) {
    return PriceRecord(
      id: map['id'],
      exchange: map['exchange'],
      fiat: map['fiat'],
      asset: map['asset'],
      bestBuyPrice: map['bestBuyPrice'],
      bestSellPrice: map['bestSellPrice'],
      spread: map['spread'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }
}

class ExchangePrices {
  final String exchange;
  final double bestBuyPrice;
  final double bestSellPrice;
  final double spread;
  final DateTime lastUpdate;
  final List<P2PListing> buyListings;
  final List<P2PListing> sellListings;
  final bool isLoading;
  final String? error;

  ExchangePrices({
    required this.exchange,
    this.bestBuyPrice = 0,
    this.bestSellPrice = 0,
    this.spread = 0,
    DateTime? lastUpdate,
    this.buyListings = const [],
    this.sellListings = const [],
    this.isLoading = false,
    this.error,
  }) : lastUpdate = lastUpdate ?? DateTime.now();

  ExchangePrices copyWith({
    double? bestBuyPrice,
    double? bestSellPrice,
    double? spread,
    DateTime? lastUpdate,
    List<P2PListing>? buyListings,
    List<P2PListing>? sellListings,
    bool? isLoading,
    String? error,
  }) {
    return ExchangePrices(
      exchange: exchange,
      bestBuyPrice: bestBuyPrice ?? this.bestBuyPrice,
      bestSellPrice: bestSellPrice ?? this.bestSellPrice,
      spread: spread ?? this.spread,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      buyListings: buyListings ?? this.buyListings,
      sellListings: sellListings ?? this.sellListings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
