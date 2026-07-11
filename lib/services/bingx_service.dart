import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/p2p_ad.dart';
import '../utils/constants.dart';

/// Service for BingX P2P API
/// 
/// Note: BingX does not have an official public P2P API.
/// This uses the internal C2C endpoint discovered via network analysis.
/// The endpoint requires specific headers and may change without notice.
/// A signing mechanism may be required for authentication.
class BingXService {
  final http.Client _client = http.Client();
  DateTime? _lastCallTime;
  static const int _rateLimitMs = AppConstants.bingxRateLimit;
  bool _isAvailable = true;

  /// Whether the BingX API is currently available
  bool get isAvailable => _isAvailable;

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

  /// Fetch P2P ads from BingX
  Future<List<P2PAd>> fetchAds({
    required String fiat,
    required String tradeType,
    String asset = 'USDT',
    int pageSize = 10,
  }) async {
    await _enforceRateLimit();

    if (!_isAvailable) {
      return _fetchAdsFallback(fiat, tradeType, asset);
    }

    // BingX uses: type "1" = Buy USDT (pay fiat), type "2" = Sell USDT (receive fiat)
    final type = tradeType == 'BUY' ? 1 : 2;

    final body = jsonEncode({
      'type': type,
      'fiat': fiat,
      'asset': asset,
      'pageSize': pageSize,
      'paymentMethodIds': [],
      'paymentTimeLimits': [],
      'sortType': 0,
      'amount': 100,
      'pageId': 1,
      'advertFilter': {
        'matchUserCondition': 0,
        'noPaymentMethodVerification': 0,
        'tradedWithMerchantOnly': 0,
        'verifiedMerchantOnly': 0,
      },
    });

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      
      final response = await _client.post(
        Uri.parse(AppConstants.bingxP2PEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
          'platformId': '30',
          'appSiteId': '120002',
          'channel': 'official',
          'app_version': '14.1.0',
          'lang': 'en',
          'appId': '30004',
          'mainAppId': '10009',
          'timeZone': '0',
          'timestamp': timestamp,
          'User-Agent': 'Mozilla/5.0 (Linux; Android 12) AppleWebKit/537.36',
        },
        body: body,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 403 || response.statusCode == 401) {
        // BingX requires signed headers - fall back to scraping or skip
        _isAvailable = false;
        return _fetchAdsFallback(fiat, tradeType, asset);
      }

      if (response.statusCode != 200) {
        throw Exception('BingX API returned status ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      
      if (data['code'] != 0) {
        // API might require sign header - mark as unavailable and fallback
        _isAvailable = false;
        return _fetchAdsFallback(fiat, tradeType, asset);
      }

      final List<dynamic> resultList = data['data']?['result'] ?? [];
      
      if (resultList.isEmpty) {
        // Empty results might mean fiat not supported or API issue
        return [];
      }

      return resultList.map((item) {
        return P2PAd.fromBingX(item as Map<String, dynamic>, fiat, tradeType);
      }).toList();
    } on TimeoutException {
      throw Exception('BingX API request timed out');
    } on FormatException {
      throw Exception('Invalid response from BingX API');
    } catch (e) {
      // If there's a persistent error, mark as unavailable
      _isAvailable = false;
      throw Exception('BingX API error: $e');
    }
  }

  /// Fallback method when official API is not available
  /// Tries to use an alternative approach or returns empty list
  Future<List<P2PAd>> _fetchAdsFallback(String fiat, String tradeType, String asset) async {
    // Option 1: Try the BingX fiat page API (may also require auth)
    try {
      final response = await _client.get(
        Uri.parse('https://api-app.qq-os.com/api/c2c/v3/advert/list?fiat=$fiat&type=${tradeType == 'BUY' ? 1 : 2}&asset=$asset'),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Linux; Android 12) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 0) {
          final List<dynamic> resultList = data['data']?['result'] ?? [];
          return resultList.map((item) {
            return P2PAd.fromBingX(item as Map<String, dynamic>, fiat, tradeType);
          }).toList();
        }
      }
    } catch (_) {
      // Fallback also failed
    }
    
    // Return empty list with a note that BingX is unavailable
    // The UI should show a "BingX temporarily unavailable" indicator
    return [];
  }

  /// Reset availability (for retry)
  void resetAvailability() {
    _isAvailable = true;
  }

  void dispose() {
    _client.close();
  }
}
