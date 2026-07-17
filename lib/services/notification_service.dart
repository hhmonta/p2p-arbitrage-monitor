import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/arbitrage_opportunity.dart';
import '../utils/formatters.dart';

/// Service for managing local push notifications
class NotificationService {
  static NotificationService? _instance;
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  
  // Track last notification time per pair for cooldown
  final Map<String, DateTime> _lastNotificationTime = {};

  NotificationService._();
  static NotificationService get instance => _instance ??= NotificationService._();

  /// Initialize the notification service
  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request Android 13+ notification permission
    await _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - could navigate to specific screen
    final payload = response.payload;
    if (payload != null) {
      // Parse payload and navigate accordingly
    }
  }

  /// Show arbitrage opportunity notification
  Future<void> showArbitrageNotification(
    ArbitrageOpportunity opportunity, {
    int cooldownMinutes = 15,
  }) async {
    // Check cooldown
    final key = '${opportunity.buyExchange}_${opportunity.sellExchange}_${opportunity.fiat}';
    final lastTime = _lastNotificationTime[key];
    
    if (lastTime != null) {
      final elapsed = DateTime.now().difference(lastTime);
      if (elapsed.inMinutes < cooldownMinutes) return;
    }

    const androidDetails = AndroidNotificationDetails(
      'arbitrage_channel',
      'Arbitrage Alerts',
      channelDescription: 'Notifications for P2P arbitrage opportunities',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      styleInformation: BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final title = '🔥 Arbitrage Alert: ${opportunity.fiat}';
    final body = '${opportunity.buyExchange} → ${opportunity.sellExchange}\n'
        'Spread: ${Formatters.formatSpread(opportunity.spreadPercent)} | '
        'Net: ${Formatters.formatSpread(opportunity.netProfitPercent)}\n'
        'Buy: ${Formatters.formatPrice(opportunity.buyPrice)} | '
        'Sell: ${Formatters.formatPrice(opportunity.sellPrice)}';

    await _plugin.show(
      key.hashCode,
      title,
      body,
      details,
      payload: 'arbitrage:${opportunity.fiat}:${opportunity.buyExchange}:${opportunity.sellExchange}',
    );

    _lastNotificationTime[key] = DateTime.now();
  }

  /// Show a price alert notification
  Future<void> showPriceAlertNotification({
    required String exchange,
    required String fiat,
    required String message,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'price_alert_channel',
      'Price Alerts',
      channelDescription: 'Notifications for P2P price changes',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: true,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      'price_${exchange}_$fiat'.hashCode,
      'Price Alert: $exchange $fiat',
      message,
      details,
    );
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Cancel a specific notification
  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }

  /// Clear cooldown tracking
  void clearCooldowns() {
    _lastNotificationTime.clear();
  }
}
