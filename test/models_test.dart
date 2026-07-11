import 'package:flutter_test/flutter_test.dart';
import 'package:p2p_arbitrage_monitor/models/p2p_ad.dart';
import 'package:p2p_arbitrage_monitor/models/arbitrage_opportunity.dart';
import 'package:p2p_arbitrage_monitor/utils/formatters.dart';

void main() {
  group('P2PAd Model', () {
    test('should create P2PAd from Binance JSON', () {
      final json = {
        'adv': {
          'advNo': '12345',
          'asset': 'USDT',
          'price': '36.50',
          'minSingleTransAmount': '100',
          'maxSingleTransAmount': '5000',
          'surplusAmount': '1200.5',
          'tradeMethods': [
            {'tradeMethodName': 'Bank Transfer'},
          ],
        },
        'advertiserNickName': 'TestMerchant',
        'monthOrderCount': '50',
        'monthFinishRate': '95.5',
      };

      final ad = P2PAd.fromBinance(json, 'VES', 'BUY');
      
      expect(ad.exchange, 'Binance');
      expect(ad.fiat, 'VES');
      expect(ad.tradeType, 'BUY');
      expect(ad.price, 36.50);
      expect(ad.merchantName, 'TestMerchant');
      expect(ad.paymentMethods.length, 1);
      expect(ad.paymentMethods[0], 'Bank Transfer');
    });

    test('should create P2PAd from Bybit JSON', () {
      final json = {
        'id': '67890',
        'tokenId': 'USDT',
        'price': '350.25',
        'minAmount': '500',
        'maxAmount': '10000',
        'remainingAmount': '5000',
        'nickName': 'BybitMerchant',
        'recentExecuteRate': '98.2',
        'recentOrderNum': 120,
        'payments': ['Wise', 'Bank Transfer'],
      };

      final ad = P2PAd.fromBybit(json, 'ARS', 'SELL');
      
      expect(ad.exchange, 'Bybit');
      expect(ad.fiat, 'ARS');
      expect(ad.price, 350.25);
      expect(ad.merchantName, 'BybitMerchant');
    });

    test('should create P2PAd from BingX JSON', () {
      final json = {
        'advertNo': '11111',
        'asset': 'USDT',
        'price': '4150.00',
        'minAmount': '50000',
        'maxAmount': '500000',
        'availableNumber': '3000',
        'merchantInfo': {
          'nickname': 'BingXMerchant',
        },
        'merchantStat': {
          'latestTradeSuccessRate': '97.5',
          'latestSuccessOrderCount': 85,
        },
        'paymentMethodList': [
          {'name': 'Mercado Pago'},
        ],
      };

      final ad = P2PAd.fromBingX(json, 'COP', 'BUY');
      
      expect(ad.exchange, 'BingX');
      expect(ad.fiat, 'COP');
      expect(ad.price, 4150.00);
      expect(ad.merchantName, 'BingXMerchant');
      expect(ad.completionRate, 97.5);
      expect(ad.orderCount, 85);
    });
  });

  group('ArbitrageOpportunity', () {
    test('should calculate arbitrage correctly', () {
      final opp = ArbitrageOpportunity.calculate(
        buyExchange: 'Binance',
        sellExchange: 'Bybit',
        fiat: 'VES',
        buyPrice: 36.50,
        sellPrice: 37.20,
        buyAvailableAmount: 1000,
        sellAvailableAmount: 500,
        buyMerchant: 'Merchant1',
        sellMerchant: 'Merchant2',
        feePercent: 0.5,
      );

      expect(opp.spreadPercent, closeTo(1.9178, 0.01));
      expect(opp.netProfitPercent, closeTo(1.4178, 0.01));
      expect(opp.isProfitable, true);
      expect(opp.maxTradableAmount, 500); // Limited by sell side
      expect(opp.riskLevel, 'Medium');
    });

    test('should identify unprofitable opportunity', () {
      final opp = ArbitrageOpportunity.calculate(
        buyExchange: 'Binance',
        sellExchange: 'BingX',
        fiat: 'ARS',
        buyPrice: 350.0,
        sellPrice: 351.0,
        buyAvailableAmount: 1000,
        sellAvailableAmount: 1000,
        buyMerchant: 'M1',
        sellMerchant: 'M2',
        feePercent: 0.5,
      );

      expect(opp.spreadPercent, closeTo(0.2857, 0.01));
      expect(opp.netProfitPercent, closeTo(-0.2143, 0.01));
      expect(opp.isProfitable, false);
      expect(opp.riskLevel, 'Low');
    });
  });

  group('Formatters', () {
    test('should format prices correctly', () {
      expect(Formatters.formatPrice(36.50), '36.50');
      expect(Formatters.formatPrice(4150.0), '4,150.00');
      expect(Formatters.formatPrice(0.0015), '0.0015');
    });

    test('should format spread with sign', () {
      expect(Formatters.formatSpread(1.5), '+1.50%');
      expect(Formatters.formatSpread(-0.5), '-0.50%');
      expect(Formatters.formatSpread(0.0), '+0.00%');
    });

    test('should format fiat with symbol', () {
      expect(Formatters.formatFiat(100, 'VES'), contains('Bs.'));
      expect(Formatters.formatFiat(500, 'ARS'), contains('\$'));
      expect(Formatters.formatFiat(1000, 'MXN'), contains('MX\$'));
    });

    test('should calculate net profit correctly', () {
      final profit = Formatters.calculateNetProfit(36.50, 37.20);
      expect(profit, closeTo(1.4178, 0.01));
    });
  });
}
