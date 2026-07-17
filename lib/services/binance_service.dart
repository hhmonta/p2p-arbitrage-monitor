import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/p2p_ad.dart';
import '../utils/constants.dart';

/// Service for Binance P2P API
class BinanceService {
  final http.Client _client = http.Client();
  DateTime? _lastCallTime;
  static const int _rateLimitMs = AppConstants.binanceRateLimit;

  /// Enforce rate limiting
  Future<void> _enforceRateLimit() async {
    if (_lastCallTime != null) {
      final elapsed = DateTime.now().difference(_lastCallTime!);
      if (elapsed.inMilliseconds < _rateLimitMs) {
        await Future.delayed(Duration(milliseconds: _rateLimitMs - elapsed.inMilliseconds));
      }
    }
    _lastCallTime = DateTime.now();
  }

  /// Fetch P2P ads from Binance
  Future<List<P2PAd>> fetchAds({
    required String fiat,
    required String tradeType,
    String asset = 'USDT',
    int page = 1,
    int rows = 10,
  }) async {
    await _enforceRateLimit();

    // Binance uses 'BUY' for buying crypto, 'SELL' for selling crypto
    // In their API: tradeType "BUY" = user buys USDT (sells fiat)
    //               tradeType "SELL" = user sells USDT (receives fiat)
    final body = jsonEncode({
      'asset': asset,
      'fiat': fiat,
      'tradeType': tradeType,
      'page': page,
      'rows': rows,
      'filterByAllMakerCommission': false,
      'publisherType': null,
      'payTypes': [],
      'countries': [],
      'transAmount': null,
    });

    try {
      final response = await _client.post(
        Uri.parse(AppConstants.binanceP2PEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Linux; Android 12) AppleWebKit/537.36',
        },
        body: body,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Binance API returned status ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      
      if (data['code'] != '000000') {
        final msg = data['message'] ?? 'Unknown error';
        throw Exception('Binance API error: $msg');
      }

      final List<dynamic> advList = data['data'] ?? [];
      
      return advList.map((item) {
        return P2PAd.fromBinance(item as Map<String, dynamic>, fiat, tradeType);
      }).toList();
    } on TimeoutException {
      throw Exception('Binance API request timed out');
    } on FormatException {
      throw Exception('Invalid response from Binance API');
    } catch (e) {
      throw Exception('Binance API error: $e');
    }
  }

  /// Fetch best buy price (lowest price to buy USDT)
  Future<double?> fetchBestBuyPrice(String fiat) async {
    final ads = await fetchAds(fiat: fiat, tradeType: 'BUY');
    if (ads.isEmpty) return null;
    ads.sort((a, b) => a.price.compareTo(b.price));
    return ads.first.price;
  }

  /// Fetch best sell price (highest price when selling USDT)
  Future<double?> fetchBestSellPrice(String fiat) async {
    final ads = await fetchAds(fiat: fiat, tradeType: 'SELL');
    if (ads.isEmpty) return null;
    ads.sort((a, b) => b.price.compareTo(a.price));
    return ads.first.price;
  }

  void dispose() {
    _client.close();
  }
}
