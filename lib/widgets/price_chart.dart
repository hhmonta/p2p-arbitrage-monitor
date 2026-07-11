import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/price_record.dart';
import '../utils/formatters.dart';
import '../theme/app_theme.dart';

/// Price chart widget using fl_chart for historical price visualization
class PriceChart extends StatelessWidget {
  final List<PriceRecord> records;
  final String fiat;
  final String tradeType;

  const PriceChart({
    super.key,
    required this.records,
    required this.fiat,
    required this.tradeType,
  });

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const Center(child: Text('Sin datos'));
    }

    // Sort records by timestamp
    final sortedRecords = List<PriceRecord>.from(records)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Prepare chart data points
    final spots = <FlSpot>[];
    for (int i = 0; i < sortedRecords.length; i++) {
      spots.add(FlSpot(i.toDouble(), sortedRecords[i].price));
    }

    // Calculate min/max for Y axis
    final prices = sortedRecords.map((r) => r.price).toList();
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);
    final priceRange = maxPrice - minPrice;
    final yMin = (minPrice - priceRange * 0.1).toDouble();
    final yMax = (maxPrice + priceRange * 0.1).toDouble();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lineColor = tradeType == 'BUY' 
        ? const Color(0xFFFF5252) 
        : const Color(0xFF00E676);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart header
          Row(
            children: [
              Icon(
                tradeType == 'BUY' ? Icons.trending_down : Icons.trending_up,
                size: 16,
                color: lineColor,
              ),
              const SizedBox(width: 6),
              Text(
                '${tradeType == 'BUY' ? 'Compra' : 'Venta'} USDT/$fiat',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              Text(
                '${sortedRecords.length} puntos',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Line chart
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: priceRange > 0 ? priceRange / 5 : 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? const Color(0xFF30363D) : const Color(0xFFE0E0E0),
                    strokeWidth: 0.5,
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: (sortedRecords.length / 5).floorToDouble().clamp(1, double.infinity),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= sortedRecords.length) {
                          return const SizedBox();
                        }
                        final dt = sortedRecords[index].timestamp;
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            Formatters.formatTime(dt),
                            style: TextStyle(
                              fontSize: 9,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      interval: priceRange > 0 ? priceRange / 5 : 1,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            Formatters.formatPrice(value),
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (sortedRecords.length - 1).toDouble(),
                minY: yMin,
                maxY: yMax,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: lineColor,
                    barWidth: 2,
                    dotData: FlDotData(
                      show: sortedRecords.length < 50,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: lineColor,
                          strokeWidth: 1,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          lineColor.withOpacity(0.3),
                          lineColor.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (spot) => isDark 
                        ? const Color(0xFF1C2333) 
                        : Colors.white,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.x.toInt();
                        final dt = index < sortedRecords.length 
                            ? sortedRecords[index].timestamp 
                            : DateTime.now();
                        return LineTooltipItem(
                          '${Formatters.formatPrice(spot.y)} $fiat\n${Formatters.formatDateTime(dt)}',
                          TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
