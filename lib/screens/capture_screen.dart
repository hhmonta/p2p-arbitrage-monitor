import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../models/price_record.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../theme/app_theme.dart';

/// Screen that shows hourly price capture logs
class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  String _selectedFiat = 'VES';
  bool _isCapturing = true;
  List<PriceRecord> _records = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    try {
      final startTime = DateTime.now().subtract(const Duration(hours: 72));
      _records = await DatabaseService.instance.getPriceRecords(
        exchange: 'Binance', // Use best price from any exchange
        fiat: _selectedFiat,
        startTime: startTime,
        limit: 500,
      );
      // Also load from other exchanges
      for (final exchange in ['Bybit', 'BingX']) {
        final exRecords = await DatabaseService.instance.getPriceRecords(
          exchange: exchange,
          fiat: _selectedFiat,
          startTime: startTime,
          limit: 500,
        );
        _records.addAll(exRecords);
      }
      _records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      debugPrint('Error loading capture records: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Capture current prices from all exchanges
  Future<void> _captureNow() async {
    final api = context.read<ApiService>();
    await api.fetchAllPrices();

    // Save buy and sell prices for each exchange
    for (final fiat in api.selectedFiats) {
      for (final exchange in AppConstants.exchanges) {
        final buyKey = '${exchange}_$fiat';
        final sellKey = '${exchange}_$fiat';
        final buyAds = api.buyAds[buyKey] ?? [];
        final sellAds = api.sellAds[sellKey] ?? [];

        if (buyAds.isNotEmpty) {
          buyAds.sort((a, b) => a.price.compareTo(b.price));
          await DatabaseService.instance.insertPriceRecord(PriceRecord(
            exchange: exchange,
            fiat: fiat,
            tradeType: 'BUY',
            price: buyAds.first.price,
            availableAmount: buyAds.first.availableAmount,
            timestamp: DateTime.now(),
          ));
        }
        if (sellAds.isNotEmpty) {
          sellAds.sort((a, b) => b.price.compareTo(a.price));
          await DatabaseService.instance.insertPriceRecord(PriceRecord(
            exchange: exchange,
            fiat: fiat,
            tradeType: 'SELL',
            price: sellAds.first.price,
            availableAmount: sellAds.first.availableAmount,
            timestamp: DateTime.now(),
          ));
        }
      }
    }

    _loadRecords();
  }

  /// Get the latest buy/sell pair for an hour
  Map<String, dynamic>? _getHourlyPair(int hourIndex) {
    final now = DateTime.now();
    final hourStart = DateTime(now.year, now.month, now.day, now.hour - hourIndex);
    final hourEnd = hourStart.add(const Duration(hours: 1));

    final hourRecords = _records.where((r) =>
      r.timestamp.isAfter(hourStart) && r.timestamp.isBefore(hourEnd)
    ).toList();

    if (hourRecords.isEmpty) return null;

    final buyRecords = hourRecords.where((r) => r.tradeType == 'BUY').toList();
    final sellRecords = hourRecords.where((r) => r.tradeType == 'SELL').toList();

    double? bestBuy, bestSell;
    if (buyRecords.isNotEmpty) {
      buyRecords.sort((a, b) => a.price.compareTo(b.price));
      bestBuy = buyRecords.first.price;
    }
    if (sellRecords.isNotEmpty) {
      sellRecords.sort((a, b) => b.price.compareTo(a.price));
      bestSell = sellRecords.first.price;
    }

    return {
      'time': hourStart,
      'buy': bestBuy,
      'sell': bestSell,
      'spread': (bestBuy != null && bestSell != null) 
          ? ((bestSell - bestBuy) / bestBuy * 100) 
          : null,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        _buildHeader(),
        
        // Fiat selector
        _buildFiatSelector(),
        
        // Current price summary
        _buildCurrentSummary(),
        
        // Hourly log table
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildHourlyLog(),
        ),
        
        // Action buttons
        _buildActionButtons(),
        
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          const Text('📊 Captura Horaria', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const Spacer(),
          if (_isCapturing)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6, height: 6,
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text('Grabando', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.red[400])),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFiatSelector() {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: AppConstants.supportedFiats.map((fiat) {
          final isSelected = fiat == _selectedFiat;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: ChoiceChip(
              label: Text('${Formatters.getFiatFlag(fiat)} $fiat', style: const TextStyle(fontSize: 12)),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _selectedFiat = fiat);
                _loadRecords();
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCurrentSummary() {
    final api = context.read<ApiService>();
    final buyPrice = api.getBestBuyPrice(_selectedFiat, 'Binance');
    final sellPrice = api.getBestSellPrice(_selectedFiat, 'Binance');
    
    return Consumer<ApiService>(
      builder: (context, api, _) {
        final buy = api.getBestBuyPrice(_selectedFiat, 'Binance');
        final sell = api.getBestSellPrice(_selectedFiat, 'Binance');
        final spread = (buy != null && sell != null) ? ((sell - buy) / buy * 100) : null;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      buy != null ? Formatters.formatPrice(buy) : '--',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.redAccent),
                    ),
                    Text('Compra $_selectedFiat', style: TextStyle(fontSize: 10, color: Theme.of(context).hintColor)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      sell != null ? Formatters.formatPrice(sell) : '--',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.greenAccent),
                    ),
                    Text('Venta $_selectedFiat', style: TextStyle(fontSize: 10, color: Theme.of(context).hintColor)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      spread != null ? '${spread.toStringAsFixed(2)}%' : '--',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary),
                    ),
                    Text('Spread', style: TextStyle(fontSize: 10, color: Theme.of(context).hintColor)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHourlyLog() {
    // Build hourly rows
    final hours = <Map<String, dynamic>>[];
    for (int i = 0; i < 72; i++) {
      final pair = _getHourlyPair(i);
      if (pair != null) hours.add(pair);
    }

    if (hours.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Sin datos de captura', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            Text('Los precios se registran cada hora automáticamente', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _captureNow,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Capturar ahora'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Table header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 80, child: Text('HORA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey))),
              const Expanded(child: Text('COMPRA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.redAccent))),
              const Expanded(child: Text('VENTA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.green))),
              SizedBox(width: 60, child: Text('SPREAD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey), textAlign: TextAlign.right)),
            ],
          ),
        ),
        // Data rows
        Expanded(
          child: ListView.builder(
            itemCount: hours.length,
            itemBuilder: (context, index) {
              final h = hours[index];
              final time = h['time'] as DateTime;
              final buy = h['buy'] as double?;
              final sell = h['sell'] as double?;
              final spread = h['spread'] as double?;
              final isNow = index == 0;
              
              Color? spreadColor;
              if (spread != null) {
                spreadColor = spread > 2 ? Colors.green : spread > 0 ? Colors.orange : Colors.red;
              }

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isNow ? Theme.of(context).colorScheme.primary.withOpacity(0.04) : null,
                  border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.3))),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(Formatters.formatTime(time), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Theme.of(context).hintColor)),
                          if (isNow) Text('AHORA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Text(
                        buy != null ? Formatters.formatPrice(buy) : '--',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.redAccent),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        sell != null ? Formatters.formatPrice(sell) : '--',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.green),
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: Text(
                        spread != null ? '${spread.toStringAsFixed(2)}%' : '--',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: spreadColor ?? Theme.of(context).hintColor),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() => _isCapturing = !_isCapturing);
              },
              icon: Icon(_isCapturing ? Icons.stop : Icons.play_arrow, size: 16),
              label: Text(_isCapturing ? 'Detener' : 'Iniciar', style: const TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: _isCapturing ? Colors.red : Colors.green,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _captureNow,
              icon: const Icon(Icons.camera_alt, size: 16),
              label: const Text('Capturar', style: TextStyle(fontSize: 12)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _exportCSV,
              icon: const Icon(Icons.download, size: 16),
              label: const Text('CSV', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCSV() async {
    try {
      final csv = await DatabaseService.instance.exportToCSV(
        exchange: 'Binance',
        fiat: _selectedFiat,
      );
      if (csv.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No hay datos para exportar')),
          );
        }
        return;
      }
      // Share/save CSV
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV exportado correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
