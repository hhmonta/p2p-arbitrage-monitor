/// Represents an arbitrage opportunity between two exchanges
class ArbitrageOpportunity {
  final String buyExchange;
  final String sellExchange;
  final String fiat;
  final double buyPrice;
  final double sellPrice;
  final double spreadPercent;
  final double netProfitPercent;
  final double estimatedFees;
  final double buyAvailableAmount;
  final double sellAvailableAmount;
  final double maxTradableAmount;
  final String buyMerchant;
  final String sellMerchant;
  final DateTime timestamp;

  ArbitrageOpportunity({
    required this.buyExchange,
    required this.sellExchange,
    required this.fiat,
    required this.buyPrice,
    required this.sellPrice,
    required this.spreadPercent,
    required this.netProfitPercent,
    this.estimatedFees = 0.5,
    required this.buyAvailableAmount,
    required this.sellAvailableAmount,
    required this.maxTradableAmount,
    required this.buyMerchant,
    required this.sellMerchant,
    required this.timestamp,
  });

  /// Calculate arbitrage from buy/sell prices
  factory ArbitrageOpportunity.calculate({
    required String buyExchange,
    required String sellExchange,
    required String fiat,
    required double buyPrice,
    required double sellPrice,
    required double buyAvailableAmount,
    required double sellAvailableAmount,
    required String buyMerchant,
    required String sellMerchant,
    double feePercent = 0.5,
  }) {
    final spreadPercent = ((sellPrice - buyPrice) / buyPrice) * 100;
    final netProfitPercent = spreadPercent - feePercent;
    final maxTradable = buyAvailableAmount < sellAvailableAmount 
        ? buyAvailableAmount 
        : sellAvailableAmount;

    return ArbitrageOpportunity(
      buyExchange: buyExchange,
      sellExchange: sellExchange,
      fiat: fiat,
      buyPrice: buyPrice,
      sellPrice: sellPrice,
      spreadPercent: spreadPercent,
      netProfitPercent: netProfitPercent,
      estimatedFees: feePercent,
      buyAvailableAmount: buyAvailableAmount,
      sellAvailableAmount: sellAvailableAmount,
      maxTradableAmount: maxTradable,
      buyMerchant: buyMerchant,
      sellMerchant: sellMerchant,
      timestamp: DateTime.now(),
    );
  }

  /// Whether this is a profitable opportunity
  bool get isProfitable => netProfitPercent > 0;

  /// Risk level based on spread
  String get riskLevel {
    if (spreadPercent > 5) return 'Very High';
    if (spreadPercent > 3) return 'High';
    if (spreadPercent > 1.5) return 'Medium';
    return 'Low';
  }

  /// Get severity color code
  String get severityColor {
    if (netProfitPercent > 3) return '#00C853'; // Green - very profitable
    if (netProfitPercent > 1.5) return '#64DD17'; // Light green
    if (netProfitPercent > 0.5) return '#FFD600'; // Yellow
    if (netProfitPercent > 0) return '#FF9100'; // Orange
    return '#FF1744'; // Red - not profitable after fees
  }

  Map<String, dynamic> toJson() => {
    'buyExchange': buyExchange,
    'sellExchange': sellExchange,
    'fiat': fiat,
    'buyPrice': buyPrice,
    'sellPrice': sellPrice,
    'spreadPercent': spreadPercent,
    'netProfitPercent': netProfitPercent,
    'estimatedFees': estimatedFees,
    'buyAvailableAmount': buyAvailableAmount,
    'sellAvailableAmount': sellAvailableAmount,
    'maxTradableAmount': maxTradableAmount,
    'buyMerchant': buyMerchant,
    'sellMerchant': sellMerchant,
    'timestamp': timestamp.toIso8601String(),
  };

  @override
  String toString() => 
    'ArbitrageOpportunity($buyExchange→$sellExchange ${fiat} spread: ${spreadPercent.toStringAsFixed(2)}% net: ${netProfitPercent.toStringAsFixed(2)}%)';
}
