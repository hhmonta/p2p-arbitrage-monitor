import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/p2p_provider.dart';
import '../models/p2p_models.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedDays = 7;
  String? _selectedExchange;
  bool _showBuy = true;
  bool _showSell = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<P2PProvider>().loadPriceHistory(days: _selectedDays);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<P2PProvider>(
      builder: (context, provider, child) {
        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Controls
            SliverToBoxAdapter(
              child: _HistoryControls(
                selectedDays: _selectedDays,
                selectedExchange: _selectedExchange,
                showBuy: _showBuy,
                showSell: _showSell,
                onDaysChanged: (days) {
                  setState(() => _selectedDays = days);
                  provider.loadPriceHistory(days: days);
                },
                onExchangeChanged: (exchange) {
                  setState(() => _selectedExchange = exchange);
                  if (exchange != null) {
                    provider.loadExchangePriceHistory(exchange, days: _selectedDays);
                  } else {
                    provider.loadPriceHistory(days: _selectedDays);
                  }
                },
                onShowBuyChanged: (v) => setState(() => _showBuy = v),
                onShowSellChanged: (v) => setState(() => _showSell = v),
                onExport: () => _exportCSV(provider),
              ),
            ),

            // Chart
            SliverToBoxAdapter(
              child: _PriceChart(
                records: provider.priceHistory,
                showBuy: _showBuy,
                showSell: _showSell,
                selectedExchange: _selectedExchange,
              ),
            ),

            // Data table
            SliverToBoxAdapter(
              child: _HistoryTable(
                records: provider.priceHistory,
                fiat: provider.selectedFiat,
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportCSV(P2PProvider provider) async {
    try {
      final records = provider.priceHistory;
      if (records.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No hay datos para exportar')),
          );
        }
        return;
      }

      final rows = <List<dynamic>>[
        ['Exchange', 'Fiat', 'Asset', 'Precio Compra', 'Precio Venta', 'Spread %', 'Timestamp'],
      ];

      for (final r in records) {
        rows.add([
          r.exchange,
          r.fiat,
          r.asset,
          r.bestBuyPrice.toStringAsFixed(2),
          r.bestSellPrice.toStringAsFixed(2),
          r.spread.toStringAsFixed(4),
          r.timestamp.toIso8601String(),
        ]);
      }

      final csv = const ListToCsvConverter().convert(rows);
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/p2p_history_${provider.selectedFiat}_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv);

      if (mounted) {
        final result = await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'P2P Price History - ${provider.selectedFiat}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar: $e')),
        );
      }
    }
  }
}

class _HistoryControls extends StatelessWidget {
  final int selectedDays;
  final String? selectedExchange;
  final bool showBuy;
  final bool showSell;
  final ValueChanged<int> onDaysChanged;
  final ValueChanged<String?> onExchangeChanged;
  final ValueChanged<bool> onShowBuyChanged;
  final ValueChanged<bool> onShowSellChanged;
  final VoidCallback onExport;

  const _HistoryControls({
    required this.selectedDays,
    required this.selectedExchange,
    required this.showBuy,
    required this.showSell,
    required this.onDaysChanged,
    required this.onExchangeChanged,
    required this.onShowBuyChanged,
    required this.onShowSellChanged,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, size: 24),
              const SizedBox(width: 8),
              Text(
                'Historial de Precios',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton.filledTonal(
                onPressed: onExport,
                icon: const Icon(Icons.file_download, size: 20),
                tooltip: 'Exportar CSV',
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Time range
          Row(
            children: [
              Text('Período: ', style: theme.textTheme.bodyMedium),
              ...[1, 3, 7].map((days) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('${days}d'),
                  selected: selectedDays == days,
                  onSelected: (_) => onDaysChanged(days),
                ),
              )),
            ],
          ),
          const SizedBox(height: 8),
          // Exchange filter
          Row(
            children: [
              Text('Exchange: ', style: theme.textTheme.bodyMedium),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Todos'),
                selected: selectedExchange == null,
                onSelected: (_) => onExchangeChanged(null),
              ),
              const SizedBox(width: 4),
              ...['Binance', 'Bybit', 'BingX'].map((ex) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: ChoiceChip(
                  label: Text(ex),
                  selected: selectedExchange == ex,
                  onSelected: (_) => onExchangeChanged(ex),
                ),
              )),
            ],
          ),
          const SizedBox(height: 8),
          // Show buy/sell toggles
          Row(
            children: [
              FilterChip(
                label: const Text('Compra'),
                selected: showBuy,
                onSelected: onShowBuyChanged,
                selectedColor: Colors.green.withValues(alpha: 0.2),
                checkmarkColor: Colors.green,
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Venta'),
                selected: showSell,
                onSelected: onShowSellChanged,
                selectedColor: Colors.red.withValues(alpha: 0.2),
                checkmarkColor: Colors.redAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceChart extends StatelessWidget {
  final List<PriceRecord> records;
  final bool showBuy;
  final bool showSell;
  final String? selectedExchange;

  const _PriceChart({
    required this.records,
    required this.showBuy,
    required this.showSell,
    required this.selectedExchange,
  });

  Map<String, List<PriceRecord>> get _groupedByExchange {
    final map = <String, List<PriceRecord>>{};
    for (final r in records) {
      map.putIfAbsent(r.exchange, () => []).add(r);
    }
    return map;
  }

  Color _exchangeColor(String exchange) {
    switch (exchange) {
      case 'Binance': return const Color(0xFFF0B90B);
      case 'Bybit': return const Color(0xFFF7A600);
      case 'BingX': return const Color(0xFF00D4AA);
      default: return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (records.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          height: 250,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.show_chart,
                size: 48,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 12),
              Text(
                'Sin datos históricos',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Los datos se irán acumulando con cada actualización',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final grouped = _groupedByExchange;
    final exchanges = selectedExchange != null
        ? [selectedExchange!]
        : grouped.keys.toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Legend
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: exchanges.expand((ex) => [
                if (showBuy)
                  _LegendItem(color: _exchangeColor(ex), label: '$ex Compra', isDashed: false),
                if (showSell)
                  _LegendItem(color: _exchangeColor(ex).withValues(alpha: 0.5), label: '$ex Venta', isDashed: true),
              ]).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _calculateInterval(),
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: theme.dividerColor.withValues(alpha: 0.3),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              value.toStringAsFixed(0),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: _calculateBottomInterval(),
                        getTitlesWidget: (value, meta) {
                          final dt = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
                  lineBarsData: _buildLineBars(exchanges),
                  minX: _getMinX(),
                  maxX: _getMaxX(),
                  minY: _getMinY(),
                  maxY: _getMaxY(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<LineChartBarData> _buildLineBars(List<String> exchanges) {
    final bars = <LineChartBarData>[];
    final grouped = _groupedByExchange;

    for (final ex in exchanges) {
      final exRecords = grouped[ex] ?? [];
      if (exRecords.isEmpty) continue;

      final sorted = List<PriceRecord>.from(exRecords)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      if (showBuy) {
        bars.add(LineChartBarData(
          spots: sorted.map((r) => FlSpot(
            r.timestamp.millisecondsSinceEpoch.toDouble(),
            r.bestBuyPrice,
          )).toList(),
          isCurved: true,
          color: _exchangeColor(ex),
          barWidth: 2,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ));
      }

      if (showSell) {
        bars.add(LineChartBarData(
          spots: sorted.map((r) => FlSpot(
            r.timestamp.millisecondsSinceEpoch.toDouble(),
            r.bestSellPrice,
          )).toList(),
          isCurved: true,
          color: _exchangeColor(ex).withValues(alpha: 0.5),
          barWidth: 2,
          dashArray: [5, 3],
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ));
      }
    }

    return bars;
  }

  double _calculateInterval() {
    if (records.isEmpty) return 1;
    final prices = records.expand((r) => [r.bestBuyPrice, r.bestSellPrice]).where((p) => p > 0).toList();
    if (prices.isEmpty) return 1;
    final range = prices.reduce((a, b) => a > b ? a : b) - prices.reduce((a, b) => a < b ? a : b);
    return (range / 5).ceilToDouble();
  }

  double _calculateBottomInterval() {
    if (records.isEmpty) return 3600000;
    final timestamps = records.map((r) => r.timestamp.millisecondsSinceEpoch).toList();
    final range = timestamps.reduce((a, b) => a > b ? a : b) - timestamps.reduce((a, b) => a < b ? a : b);
    if (range < 3600000) return 900000; // 15 min
    if (range < 86400000) return 3600000; // 1 hour
    return 86400000; // 1 day
  }

  double _getMinX() {
    if (records.isEmpty) return 0;
    return records.map((r) => r.timestamp.millisecondsSinceEpoch).reduce((a, b) => a < b ? a : b).toDouble();
  }

  double _getMaxX() {
    if (records.isEmpty) return 0;
    return records.map((r) => r.timestamp.millisecondsSinceEpoch).reduce((a, b) => a > b ? a : b).toDouble();
  }

  double _getMinY() {
    if (records.isEmpty) return 0;
    final prices = records.expand((r) => [r.bestBuyPrice, r.bestSellPrice]).where((p) => p > 0).toList();
    if (prices.isEmpty) return 0;
    return prices.reduce((a, b) => a < b ? a : b) * 0.95;
  }

  double _getMaxY() {
    if (records.isEmpty) return 100;
    final prices = records.expand((r) => [r.bestBuyPrice, r.bestSellPrice]).where((p) => p > 0).toList();
    if (prices.isEmpty) return 100;
    return prices.reduce((a, b) => a > b ? a : b) * 1.05;
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDashed;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.isDashed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _HistoryTable extends StatelessWidget {
  final List<PriceRecord> records;
  final String fiat;

  const _HistoryTable({required this.records, required this.fiat});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final displayRecords = records.reversed.take(20).toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Últimos registros',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${records.length} registros',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Table header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  _tableHeaderCell('Exchange', 1),
                  _tableHeaderCell('Compra', 1.2),
                  _tableHeaderCell('Venta', 1.2),
                  _tableHeaderCell('Spread', 0.8),
                  _tableHeaderCell('Hora', 0.8),
                ],
              ),
            ),
            // Table rows
            ...displayRecords.map((r) => _tableRow(r, theme)),
          ],
        ),
      ),
    );
  }

  Widget _tableHeaderCell(String text, double flex) {
    return Expanded(
      flex: (flex * 10).round(),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _tableRow(PriceRecord r, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Row(
        children: [
          Expanded(
            flex: 10,
            child: Text(r.exchange, style: const TextStyle(fontSize: 11)),
          ),
          Expanded(
            flex: 12,
            child: Text(
              r.bestBuyPrice.toStringAsFixed(2),
              style: const TextStyle(fontSize: 11, color: Colors.green),
            ),
          ),
          Expanded(
            flex: 12,
            child: Text(
              r.bestSellPrice.toStringAsFixed(2),
              style: const TextStyle(fontSize: 11, color: Colors.redAccent),
            ),
          ),
          Expanded(
            flex: 8,
            child: Text(
              '${r.spread.toStringAsFixed(2)}%',
              style: TextStyle(
                fontSize: 11,
                color: r.spread > 0 ? Colors.green : Colors.redAccent,
              ),
            ),
          ),
          Expanded(
            flex: 8,
            child: Text(
              '${r.timestamp.hour.toString().padLeft(2, '0')}:${r.timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
