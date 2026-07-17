import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/p2p_ad.dart';
import '../utils/constants.dart';

/// Service for Bybit P2P API
class BybitService {
  final http.Client _client = http.Client();
  DateTime? _lastCallTime;
  static const int _rateLimitMs = AppConstants.bybitRateLimit;

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

  /// Fetch P2P ads from Bybit
  Future<List<P2PAd>> fetchAds({
    required String fiat,
    required String tradeType,
    String asset = 'USDT',
    int page = 1,
    int size = 10,
  }) async {
    await _enforceRateLimit();

    // Bybit uses: side "1" = selling USDT (user gets fiat)
    //             side "0" = buying USDT (user pays fiat)
    final side = tradeType == 'SELL' ? '1' : '0';

    final body = jsonEncode({
      'tokenId': asset,
      'currencyId': fiat,
      'paymentMethodId': '',
      'side': side,
      'size': size,
      'page': page,
      'amount': '',
      'authZone': '',
      'language': 'es',
    });

    try {
      final response = await _client.post(
        Uri.parse(AppConstants.bybitP2PEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Linux; Android 12) AppleWebKit/537.36',
        },
        body: body,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Bybit API returned status ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      
      if (data['ret_code'] != 0 && data['ret_code'] != null) {
        final msg = data['ret_msg'] ?? 'Unknown error';
        throw Exception('Bybit API error: $msg');
      }

      final List<dynamic> itemList = data['result']?['items'] ?? [];
      
      return itemList.map((item) {
        return P2PAd.fromBybit(item as Map<String, dynamic>, fiat, tradeType);
      }).toList();
    } on TimeoutException {
      throw Exception('Bybit API request timed out');
    } on FormatException {
      throw Exception('Invalid response from Bybit API');
    } catch (e) {
      throw Exception('Bybit API error: $e');
    }
  }

  /// Fetch best buy price
  Future<double?> fetchBestBuyPrice(String fiat) async {
    final ads = await fetchAds(fiat: fiat, tradeType: 'BUY');
    if (ads.isEmpty) return null;
    ads.sort((a, b) => a.price.compareTo(b.price));
    return ads.first.price;
  }

  /// Fetch best sell price
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
