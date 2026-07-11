// App-wide constants
class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'P2P Arbitrage Monitor';
  static const String appVersion = '1.0.0';

  // Supported fiat currencies
  static const List<String> supportedFiats = ['VES', 'ARS', 'COP', 'MXN', 'BRL', 'CLP', 'PEN', 'USD'];
  
  // Default selected fiats
  static const List<String> defaultFiats = ['VES', 'ARS', 'COP', 'MXN'];

  // Supported exchanges
  static const List<String> exchanges = ['Binance', 'Bybit', 'BingX'];

  // API endpoints
  static const String binanceP2PEndpoint = 
      'https://p2p.binance.com/bapi/c2c/v2/friendly/c2c/adv/search';
  static const String bybitP2PEndpoint = 
      'https://api2.bybit.com/fiat/otc/item/online';
  static const String bingxP2PEndpoint = 
      'https://api-app.qq-os.com/api/c2c/v3/advert/list';

  // Rate limiting (milliseconds between calls)
  static const int binanceRateLimit = 2000;
  static const int bybitRateLimit = 2000;
  static const int bingxRateLimit = 3000;

  // Refresh interval
  static const int defaultRefreshIntervalSeconds = 15;
  static const int minRefreshIntervalSeconds = 10;
  static const int maxRefreshIntervalSeconds = 60;

  // Arbitrage thresholds
  static const double defaultArbitrageThreshold = 1.0; // 1%
  static const double minArbitrageThreshold = 0.1;
  static const double maxArbitrageThreshold = 10.0;

  // Notification
  static const int maxNotificationsPerHour = 10;

  // Database
  static const String dbName = 'p2p_arbitrage.db';
  static const int dbVersion = 1;

  // History retention
  static const int historyRetentionDays = 30;

  // Disclaimer
  static const String riskDisclaimer = 
      '⚠️ RISK DISCLAIMER: P2P arbitrage involves significant risks including '
      'price volatility, counterparty risk, transfer delays, and exchange rate '
      'fluctuations. The displayed arbitrage opportunities may not be realizable '
      'due to transfer times, fees, liquidity, and market conditions. Past '
      'performance does not guarantee future results. This app is for '
      'informational purposes only and does not constitute financial advice. '
      'Trade at your own risk.';

  // API limitations
  static const String apiLimitationsNote = 
      'NOTE: P2P APIs are unofficial endpoints used by exchange web frontends. '
      'They may change without notice, have rate limits, or require authentication. '
      'CORS restrictions prevent direct browser access; a proxy server is required. '
      'BingX requires a signed header for API access. Data accuracy depends on '
      'API availability and response time.';
}
