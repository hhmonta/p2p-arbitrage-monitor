/// Represents a historical price record stored in the database
class PriceRecord {
  final int? id;
  final String exchange;
  final String fiat;
  final String tradeType; // 'BUY' or 'SELL'
  final double price;
  final double availableAmount;
  final DateTime timestamp;

  PriceRecord({
    this.id,
    required this.exchange,
    required this.fiat,
    required this.tradeType,
    required this.price,
    required this.availableAmount = 0,
    required this.timestamp,
  });

  /// Create from database row
  factory PriceRecord.fromMap(Map<String, dynamic> map) {
    return PriceRecord(
      id: map['id'] as int?,
      exchange: map['exchange'] as String,
      fiat: map['fiat'] as String,
      tradeType: map['trade_type'] as String,
      price: map['price'] as double,
      availableAmount: map['available_amount'] as double? ?? 0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }

  /// Convert to database row
  Map<String, dynamic> toMap() => {
    'id': id,
    'exchange': exchange,
    'fiat': fiat,
    'trade_type': tradeType,
    'price': price,
    'available_amount': availableAmount,
    'timestamp': timestamp.millisecondsSinceEpoch,
  };

  /// Get date only
  DateTime get date => DateTime(timestamp.year, timestamp.month, timestamp.day);

  /// Get hour bucket for aggregation
  DateTime get hourBucket => DateTime(
    timestamp.year, timestamp.month, timestamp.day, timestamp.hour
  );

  @override
  String toString() => 
    'PriceRecord($exchange $tradeType ${fiat} @ $price at ${timestamp.toIso8601String()})';

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is PriceRecord &&
      runtimeType == other.runtimeType &&
      id == other.id;

  @override
  int get hashCode => id.hashCode;
}
