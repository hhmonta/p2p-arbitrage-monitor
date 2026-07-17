/// Represents a single P2P advertisement from an exchange
class P2PAd {
  final String id;
  final String exchange;
  final String fiat;
  final String asset;
  final String tradeType; // 'BUY' or 'SELL'
  final double price;
  final double minAmount;
  final double maxAmount;
  final double availableAmount;
  final String merchantName;
  final double completionRate;
  final int orderCount;
  final List<String> paymentMethods;
  final DateTime timestamp;

  P2PAd({
    required this.id,
    required this.exchange,
    required this.fiat,
    required this.asset,
    required this.tradeType,
    required this.price,
    required this.minAmount,
    required this.maxAmount,
    required this.availableAmount,
    required this.merchantName,
    required this.completionRate,
    required this.orderCount,
    required this.paymentMethods,
    required this.timestamp,
  });

  /// Create from Binance API response
  factory P2PAd.fromBinance(Map<String, dynamic> json, String fiat, String tradeType) {
    final adv = json['adv'] ?? json;
    return P2PAd(
      id: (adv['advNo'] ?? '').toString(),
      exchange: 'Binance',
      fiat: fiat,
      asset: adv['asset'] ?? 'USDT',
      tradeType: tradeType,
      price: double.tryParse(adv['price']?.toString() ?? '0') ?? 0,
      minAmount: double.tryParse(adv['minSingleTransAmount']?.toString() ?? '0') ?? 0,
      maxAmount: double.tryParse(adv['maxSingleTransAmount']?.toString() ?? '0') ?? 0,
      availableAmount: double.tryParse(adv['surplusAmount']?.toString() ?? '0') ?? 0,
      merchantName: json['advertiserNickName']?.toString() ?? 'Unknown',
      completionRate: double.tryParse(json['monthOrderCount']?.toString() ?? '0') ?? 0,
      orderCount: int.tryParse(json['monthFinishRate']?.toString() ?? '0') ?? 0,
      paymentMethods: _extractPaymentMethods(adv['tradeMethods']),
      timestamp: DateTime.now(),
    );
  }

  /// Create from Bybit API response
  factory P2PAd.fromBybit(Map<String, dynamic> json, String fiat, String tradeType) {
    return P2PAd(
      id: (json['id'] ?? '').toString(),
      exchange: 'Bybit',
      fiat: fiat,
      asset: json['tokenId'] ?? 'USDT',
      tradeType: tradeType,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      minAmount: double.tryParse(json['minAmount']?.toString() ?? '0') ?? 0,
      maxAmount: double.tryParse(json['maxAmount']?.toString() ?? '0') ?? 0,
      availableAmount: double.tryParse(json['remainingAmount']?.toString() ?? '0') ?? 0,
      merchantName: json['nickName']?.toString() ?? 'Unknown',
      completionRate: double.tryParse(json['recentExecuteRate']?.toString() ?? '0') ?? 0,
      orderCount: json['recentOrderNum'] ?? 0,
      paymentMethods: _extractBybitPaymentMethods(json['payments']),
      timestamp: DateTime.now(),
    );
  }

  /// Create from BingX API response
  factory P2PAd.fromBingX(Map<String, dynamic> json, String fiat, String tradeType) {
    return P2PAd(
      id: (json['advertNo'] ?? json['orderNo'] ?? '').toString(),
      exchange: 'BingX',
      fiat: fiat,
      asset: json['asset'] ?? 'USDT',
      tradeType: tradeType,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      minAmount: double.tryParse(json['minAmount']?.toString() ?? '0') ?? 0,
      maxAmount: double.tryParse(json['maxAmount']?.toString() ?? '0') ?? 0,
      availableAmount: double.tryParse(json['availableNumber']?.toString() ?? '0') ?? 0,
      merchantName: json['merchantInfo']?['nickname']?.toString() ?? 'Unknown',
      completionRate: double.tryParse(
        json['merchantStat']?['latestTradeSuccessRate']?.toString() ?? '0'
      ) ?? 0,
      orderCount: json['merchantStat']?['latestSuccessOrderCount'] ?? 0,
      paymentMethods: _extractBingXPaymentMethods(json['paymentMethodList']),
      timestamp: DateTime.now(),
    );
  }

  static List<String> _extractPaymentMethods(dynamic methods) {
    if (methods == null) return [];
    if (methods is List) {
      return methods.map((m) => m['tradeMethodName']?.toString() ?? '').toList();
    }
    return [];
  }

  static List<String> _extractBybitPaymentMethods(dynamic methods) {
    if (methods == null) return [];
    if (methods is List) {
      return methods.map((m) {
        if (m is String) return m;
        return m['name']?.toString() ?? m['paymentType']?.toString() ?? '';
      }).toList();
    }
    return [];
  }

  static List<String> _extractBingXPaymentMethods(dynamic methods) {
    if (methods == null) return [];
    if (methods is List) {
      return methods.map((m) => m['name']?.toString() ?? '').toList();
    }
    return [];
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'exchange': exchange,
    'fiat': fiat,
    'asset': asset,
    'tradeType': tradeType,
    'price': price,
    'minAmount': minAmount,
    'maxAmount': maxAmount,
    'availableAmount': availableAmount,
    'merchantName': merchantName,
    'completionRate': completionRate,
    'orderCount': orderCount,
    'paymentMethods': paymentMethods,
    'timestamp': timestamp.toIso8601String(),
  };

  @override
  String toString() => 'P2PAd($exchange $tradeType $asset/$fiat @ $price)';
}
