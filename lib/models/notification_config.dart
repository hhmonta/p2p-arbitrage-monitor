/// Configuration for push notifications
class NotificationConfig {
  final bool enabled;
  final double arbitrageThreshold; // Minimum spread % to trigger
  final List<String> selectedFiats; // Which fiats to monitor
  final List<String> selectedExchanges; // Which exchanges to monitor
  final bool soundEnabled;
  final bool vibrateEnabled;
  final int cooldownMinutes; // Minimum time between notifications for same pair
  final bool notifyOnPriceDrop;
  final double priceDropThreshold; // % drop to trigger

  NotificationConfig({
    this.enabled = true,
    this.arbitrageThreshold = 1.0,
    this.selectedFiats = const ['VES', 'ARS', 'COP', 'MXN'],
    this.selectedExchanges = const ['Binance', 'Bybit', 'BingX'],
    this.soundEnabled = true,
    this.vibrateEnabled = true,
    this.cooldownMinutes = 15,
    this.notifyOnPriceDrop = false,
    this.priceDropThreshold = 2.0,
  });

  /// Create from SharedPreferences
  factory NotificationConfig.fromPrefs(Map<String, dynamic> prefs) {
    return NotificationConfig(
      enabled: prefs['notif_enabled'] as bool? ?? true,
      arbitrageThreshold: prefs['notif_threshold'] as double? ?? 1.0,
      selectedFiats: (prefs['notif_fiats'] as String? ?? 'VES,ARS,COP,MXN').split(','),
      selectedExchanges: (prefs['notif_exchanges'] as String? ?? 'Binance,Bybit,BingX').split(','),
      soundEnabled: prefs['notif_sound'] as bool? ?? true,
      vibrateEnabled: prefs['notif_vibrate'] as bool? ?? true,
      cooldownMinutes: prefs['notif_cooldown'] as int? ?? 15,
      notifyOnPriceDrop: prefs['notif_price_drop'] as bool? ?? false,
      priceDropThreshold: prefs['notif_price_drop_threshold'] as double? ?? 2.0,
    );
  }

  /// Convert to SharedPreferences map
  Map<String, dynamic> toPrefs() => {
    'notif_enabled': enabled,
    'notif_threshold': arbitrageThreshold,
    'notif_fiats': selectedFiats.join(','),
    'notif_exchanges': selectedExchanges.join(','),
    'notif_sound': soundEnabled,
    'notif_vibrate': vibrateEnabled,
    'notif_cooldown': cooldownMinutes,
    'notif_price_drop': notifyOnPriceDrop,
    'notif_price_drop_threshold': priceDropThreshold,
  };

  NotificationConfig copyWith({
    bool? enabled,
    double? arbitrageThreshold,
    List<String>? selectedFiats,
    List<String>? selectedExchanges,
    bool? soundEnabled,
    bool? vibrateEnabled,
    int? cooldownMinutes,
    bool? notifyOnPriceDrop,
    double? priceDropThreshold,
  }) {
    return NotificationConfig(
      enabled: enabled ?? this.enabled,
      arbitrageThreshold: arbitrageThreshold ?? this.arbitrageThreshold,
      selectedFiats: selectedFiats ?? this.selectedFiats,
      selectedExchanges: selectedExchanges ?? this.selectedExchanges,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrateEnabled: vibrateEnabled ?? this.vibrateEnabled,
      cooldownMinutes: cooldownMinutes ?? this.cooldownMinutes,
      notifyOnPriceDrop: notifyOnPriceDrop ?? this.notifyOnPriceDrop,
      priceDropThreshold: priceDropThreshold ?? this.priceDropThreshold,
    );
  }
}
