import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/arbitrage_opportunity.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../theme/app_theme.dart';
import '../widgets/arbitrage_card.dart';
import '../widgets/skeleton_loader.dart';

/// Arbitrage detection screen showing cross-exchange opportunities
class ArbitrageScreen extends StatefulWidget {
  const ArbitrageScreen({super.key});

  @override
  State<ArbitrageScreen> createState() => _ArbitrageScreenState();
}

class _ArbitrageScreenState extends State<ArbitrageScreen> {
  String? _selectedFiat;
  bool _showOnlyProfitable = true;
  double _minSpread = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<ApiService>(
      builder: (context, api, _) {
        return Column(
          children: [
            // Filter bar
            _buildFilterBar(api),
            
            // Disclaimer banner
            _buildDisclaimerBanner(),
            
            // Opportunities list
            Expanded(
              child: api.isLoading && api.opportunities.isEmpty
                  ? const SkeletonLoader()
                  : _buildOpportunitiesList(api),
            ),
          ],
        );
      },
    );
  }

  /// Build filter bar with fiat filter and profitable-only toggle
  Widget _buildFilterBar(ApiService api) {
    final fiats = <String>['Todos', ...AppConstants.supportedFiats];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Fiat dropdown
          Expanded(
            child: DropdownButton<String>(
              value: _selectedFiat ?? 'Todos',
              isExpanded: true,
              underline: const SizedBox(),
              items: fiats.map((fiat) {
                return DropdownMenuItem(
                  value: fiat,
                  child: Text(
                    fiat == 'Todos' ? 'Todas las monedas' : '${Formatters.getFiatFlag(fiat)} $fiat',
                    style: const TextStyle(fontSize: 13),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFiat = value == 'Todos' ? null : value;
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          // Profitable only toggle
          FilterChip(
            label: const Text('Rentable', style: TextStyle(fontSize: 12)),
            selected: _showOnlyProfitable,
            onSelected: (value) {
              setState(() => _showOnlyProfitable = value);
            },
            selectedColor: AppTheme._accentColor.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  /// Build risk disclaimer banner
  Widget _buildDisclaimerBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Las oportunidades mostradas son estimaciones. Los costos de transferencia y tiempos pueden afectar la rentabilidad real.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.orange[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build the list of arbitrage opportunities
  Widget _buildOpportunitiesList(ApiService api) {
    var opportunities = api.opportunities;
    
    // Apply filters
    if (_selectedFiat != null) {
      opportunities = opportunities.where((o) => o.fiat == _selectedFiat).toList();
    }
    if (_showOnlyProfitable) {
      opportunities = opportunities.where((o) => o.isProfitable).toList();
    }
    if (_minSpread > 0) {
      opportunities = opportunities.where((o) => o.netProfitPercent >= _minSpread).toList();
    }

    if (opportunities.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.trending_flat, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No se encontraron oportunidades de arbitraje',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _showOnlyProfitable 
                  ? 'Desactiva el filtro "Rentable" para ver todas las combinaciones'
                  : 'Los precios se actualizarán automáticamente',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Stats summary
    final profitable = opportunities.where((o) => o.isProfitable).length;
    final bestOpp = opportunities.first;

    return RefreshIndicator(
      onRefresh: () => api.fetchAllPrices(),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 80),
        children: [
          // Stats header
          _buildStatsHeader(opportunities.length, profitable, bestOpp),
          const SizedBox(height: 4),
          // Opportunity cards
          ...opportunities.map((opp) => ArbitrageCard(opportunity: opp)),
        ],
      ),
    );
  }

  /// Build stats header
  Widget _buildStatsHeader(int total, int profitable, ArbitrageOpportunity best) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildStatItem('Total', '$total', Icons.list_alt),
          _buildStatItem('Rentables', '$profitable', Icons.trending_up),
          _buildStatItem(
            'Mejor spread',
            Formatters.formatSpread(best.netProfitPercent),
            Icons.star,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}
