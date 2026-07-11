import 'dart:core';

/// Utility class for formatting values throughout the app
class Formatters {
  Formatters._();

  /// Format a price value with appropriate decimal places
  static String formatPrice(double price, {int decimals = 2}) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(2)}M';
    }
    if (price >= 1000) {
      return _formatWithCommas(price, decimals);
    }
    if (price >= 1) {
      return price.toStringAsFixed(decimals);
    }
    // For very small prices, show more decimals
    return price.toStringAsFixed(4);
  }

  /// Format with thousands separator
  static String _formatWithCommas(double value, int decimals) {
    final parts = value.toStringAsFixed(decimals).split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? '.${parts[1]}' : '';
    final buffer = StringBuffer();
    int count = 0;
    for (int i = intPart.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(intPart[i]);
      count++;
    }
    return '${buffer.toString().split('').reversed.join()}$decPart';
  }

  /// Format spread percentage
  static String formatSpread(double spread) {
    final sign = spread >= 0 ? '+' : '';
    return '$sign${spread.toStringAsFixed(2)}%';
  }

  /// Format timestamp to readable date/time
  static String formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
           '${dt.month.toString().padLeft(2, '0')}/'
           '${dt.year} '
           '${dt.hour.toString().padLeft(2, '0')}:'
           '${dt.minute.toString().padLeft(2, '0')}:'
           '${dt.second.toString().padLeft(2, '0')}';
  }

  /// Format time only
  static String formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
           '${dt.minute.toString().padLeft(2, '0')}:'
           '${dt.second.toString().padLeft(2, '0')}';
  }

  /// Format duration in human-readable form
  static String formatDuration(Duration duration) {
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds}s ago';
    }
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m ago';
    }
    if (duration.inHours < 24) {
      return '${duration.inHours}h ago';
    }
    return '${duration.inDays}d ago';
  }

  /// Format USDT amount
  static String formatUsdt(double amount) {
    return '${amount.toStringAsFixed(2)} USDT';
  }

  /// Format fiat amount with currency symbol
  static String formatFiat(double amount, String fiat) {
    final symbols = {
      'VES': 'Bs.',
      'ARS': '\$',
      'COP': '\$',
      'MXN': 'MX\$',
      'BRL': 'R\$',
      'CLP': 'CLP\$',
      'PEN': 'S/.',
      'USD': '\$',
    };
    final symbol = symbols[fiat] ?? '$fiat ';
    return '$symbol${formatPrice(amount)}';
  }

  /// Get currency flag emoji for fiat
  static String getFiatFlag(String fiat) {
    final flags = {
      'VES': '🇻🇪',
      'ARS': '🇦🇷',
      'COP': '🇨🇴',
      'MXN': '🇲🇽',
      'BRL': '🇧🇷',
      'CLP': '🇨🇱',
      'PEN': '🇵🇪',
      'USD': '🇺🇸',
    };
    return flags[fiat] ?? '💰';
  }

  /// Calculate net profit after estimated fees
  static double calculateNetProfit(double buyPrice, double sellPrice, {double feePercent = 0.5}) {
    final grossSpread = ((sellPrice - buyPrice) / buyPrice) * 100;
    return grossSpread - feePercent;
  }
}
