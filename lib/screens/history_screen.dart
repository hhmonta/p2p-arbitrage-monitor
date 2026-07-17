import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../models/price_record.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../theme/app_theme.dart';
import '../widgets/price_chart.dart';

/// Price history screen with charts and CSV export
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedExchange = 'Binance';
  String _selectedFiat = 'VES';
  String _selectedTradeType = 'BUY';
  int _hoursBack = 168; // 7 days default
  bool _isLoading = false;
  List<PriceRecord> _records = [];

  final List<Map<String, dynamic>> _timeRanges = [
    {'label': '24h', 'hours': 24},
    {'label': '3 días', 'hours': 72},
    {'label': '7 días', 'hours': 168},
    {'label': '30 días', 'hours': 720},
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final startTime = DateTime.now().subtract(Duration(hours: _hoursBack));
      _records = await DatabaseService.instance.getPriceRecords(
        exchange: _selectedExchange,
        fiat: _selectedFiat,
        tradeType: _selectedTradeType,
        startTime: startTime,
        limit: 5000,
      );
    } catch (e) {
      debugPrint('Error loading history: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filters
        _buildFilters(),
        
        // Chart
        Expanded(
          flex: 3,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _records.isEmpty
                  ? _buildEmptyChart()
                  : PriceChart(
                      records: _records,
                      fiat: _selectedFiat,
                      tradeType: _selectedTradeType,
                    ),
        ),
        
        // Stats
        if (_records.isNotEmpty)
          _buildStats(),
        
        // Export buttons
        _buildExportButtons(),
        
        const SizedBox(height: 80),
      ],
    );
  }

  /// Build filter controls
  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          // Exchange and Fiat row
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedExchange,
                  decoration: const InputDecoration(
                    labelText: 'Exchange',
                    isDense: true,
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: AppConstants.exchanges.map((e) {
                    return DropdownMenuItem(
                      value: e,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                              color: AppTheme.getExchangeColor(e),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(e, style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedExchange = value);
                      _loadHistory();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedFiat,
                  decoration: const InputDecoration(
                    labelText: 'Moneda',
                    isDense: true,
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: AppConstants.supportedFiats.map((f) {
                    return DropdownMenuItem(
                      value: f,
                      child: Text('${Formatters.getFiatFlag(f)} $f', style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedFiat = value);
                      _loadHistory();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedTradeType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo',
                    isDense: true,
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'BUY', child: Text('Compra', style: TextStyle(fontSize: 13))),
                    DropdownMenuItem(value: 'SELL', child: Text('Venta', style: TextStyle(fontSize: 13))),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedTradeType = value);
                      _loadHistory();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Time range chips
          Row(
            children: _timeRanges.map((range) {
              final isSelected = range['hours'] == _hoursBack;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: ChoiceChip(
                    label: Text(range['label'], style: const TextStyle(fontSize: 12)),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _hoursBack = range['hours']);
                      _loadHistory();
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Build empty chart placeholder
  Widget _buildEmptyChart() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timeline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Sin datos históricos',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Los datos se registrarán a medida que la app se actualice',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build statistics summary
  Widget _buildStats() {
    final prices = _records.map((r) => r.price).toList();
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);
    final avgPrice = prices.reduce((a, b) => a + b) / prices.length;
    final latestPrice = _records.first.price;
    final firstPrice = _records.last.price;
    final change = ((latestPrice - firstPrice) / firstPrice) * 100;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildPriceStat('Mín', Formatters.formatPrice(minPrice)),
          _buildPriceStat('Máx', Formatters.formatPrice(maxPrice)),
          _buildPriceStat('Prom', Formatters.formatPrice(avgPrice)),
          _buildPriceStat('Cambio', Formatters.formatSpread(change)),
        ],
      ),
    );
  }

  Widget _buildPriceStat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).hintColor)),
        ],
      ),
    );
  }

  /// Build export buttons
  Widget _buildExportButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _exportCSV,
              icon: const Icon(Icons.download, size: 16),
              label: const Text('Exportar CSV', style: TextStyle(fontSize: 12)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _shareData,
              icon: const Icon(Icons.share, size: 16),
              label: const Text('Compartir', style: TextStyle(fontSize: 12)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _cleanupData,
              icon: const Icon(Icons.cleaning_services, size: 16),
              label: const Text('Limpiar', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCSV() async {
    try {
      final startTime = DateTime.now().subtract(Duration(hours: _hoursBack));
      final csv = await DatabaseService.instance.exportToCSV(
        exchange: _selectedExchange,
        fiat: _selectedFiat,
        startTime: startTime,
      );
      
      if (csv.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No hay datos para exportar')),
          );
        }
        return;
      }
      
      // Save CSV file using share_plus
      // In production, use path_provider to save to Downloads
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV generado correctamente')),
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

  Future<void> _shareData() async {
    // Use share_plus to share the CSV data
  }

  Future<void> _cleanupData() async {
    final count = await DatabaseService.instance.cleanupOldRecords();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$count registros antiguos eliminados')),
      );
    }
    _loadHistory();
  }
}
