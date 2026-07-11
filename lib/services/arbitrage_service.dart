import '../models/p2p_ad.dart';
import '../models/arbitrage_opportunity.dart';

/// Service for calculating arbitrage opportunities across exchanges
class ArbitrageService {
  /// Calculate all arbitrage opportunities for the given ads
  List<ArbitrageOpportunity> calculateOpportunities({
    required Map<String, List<P2PAd>> buyAds,
    required Map<String, List<P2PAd>> sellAds,
    required List<String> fiats,
    double feePercent = 0.5,
  }) {
    final opportunities = <ArbitrageOpportunity>[];

    for (final fiat in fiats) {
      // Get best buy and sell prices from each exchange
      final exchangePrices = <String, _ExchangePricing>{};

      for (final exchange in ['Binance', 'Bybit', 'BingX']) {
        final buyKey = '${exchange}_$fiat';
        final sellKey = '${exchange}_$fiat';
        
        final buyList = buyAds[buyKey] ?? [];
        final sellList = sellAds[sellKey] ?? [];

        if (buyList.isEmpty && sellList.isEmpty) continue;

        // Best buy price = lowest price to buy USDT
        P2PAd? bestBuy;
        if (buyList.isNotEmpty) {
          buyList.sort((a, b) => a.price.compareTo(b.price));
          bestBuy = buyList.first;
        }

        // Best sell price = highest price when selling USDT
        P2PAd? bestSell;
        if (sellList.isNotEmpty) {
          sellList.sort((a, b) => b.price.compareTo(a.price));
          bestSell = sellList.first;
        }

        exchangePrices[exchange] = _ExchangePricing(
          bestBuy: bestBuy,
          bestSell: bestSell,
        );
      }

      // Calculate cross-exchange arbitrage
      // Buy USDT cheap on Exchange A, sell USDT expensive on Exchange B
      final exchanges = exchangePrices.keys.toList();
      for (int i = 0; i < exchanges.length; i++) {
        for (int j = 0; j < exchanges.length; j++) {
          if (i == j) continue; // Skip same exchange
          
          final buyExchange = exchanges[i];
          final sellExchange = exchanges[j];
          
          final buyPricing = exchangePrices[buyExchange]!;
          final sellPricing = exchangePrices[sellExchange]!;
          
          if (buyPricing.bestBuy == null || sellPricing.bestSell == null) continue;

          final buyPrice = buyPricing.bestBuy!.price;
          final sellPrice = sellPricing.bestSell!.price;

          // Only include if there's a positive spread
          if (sellPrice <= buyPrice) continue;

          final opportunity = ArbitrageOpportunity.calculate(
            buyExchange: buyExchange,
            sellExchange: sellExchange,
            fiat: fiat,
            buyPrice: buyPrice,
            sellPrice: sellPrice,
            buyAvailableAmount: buyPricing.bestBuy!.availableAmount,
            sellAvailableAmount: sellPricing.bestSell!.availableAmount,
            buyMerchant: buyPricing.bestBuy!.merchantName,
            sellMerchant: sellPricing.bestSell!.merchantName,
            feePercent: feePercent,
          );

          opportunities.add(opportunity);
        }
      }
    }

    // Sort by net profit (highest first)
    opportunities.sort((a, b) => b.netProfitPercent.compareTo(a.netProfitPercent));

    return opportunities;
  }

  /// Calculate potential profit for a given amount
  static double calculateProfit({
    required double buyPrice,
    required double sellPrice,
    required double usdtAmount,
    double feePercent = 0.5,
  }) {
    final costInFiat = buyPrice * usdtAmount;
    final revenueInFiat = sellPrice * usdtAmount;
    final feeCost = costInFiat * (feePercent / 100);
    return revenueInFiat - costInFiat - feeCost;
  }

  /// Calculate effective fee for a transaction
  static double calculateFees({
    required double amount,
    required double feePercent,
  }) {
    return amount * (feePercent / 100);
  }
}

/// Helper class to store exchange pricing data
class _ExchangePricing {
  final P2PAd? bestBuy;
  final P2PAd? bestSell;

  _ExchangePricing({this.bestBuy, this.bestSell});
}
