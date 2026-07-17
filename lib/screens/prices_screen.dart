import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/p2p_ad.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../theme/app_theme.dart';
import '../widgets/price_card.dart';
import '../widgets/fiat_filter_chip.dart';
import '../widgets/skeleton_loader.dart';

/// Real-time price panel showing buy/sell prices across exchanges
class PricesScreen extends StatefulWidget {
  const PricesScreen({super.key});

  @override
  State<PricesScreen> createState() => _PricesScreenState();
}

class _PricesScreenState extends State<PricesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFiat = 'VES';
  bool _showBuy = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ApiService>(
      builder: (context, api, _) {
        return Column(
          children: [
            // Fiat currency filter chips
            _buildFiatFilter(api),
            
            // Buy/Sell toggle
            _buildBuySellToggle(),
            
            // Price list
            Expanded(
              child: api.isLoading && api.buyAds.isEmpty
                  ? const SkeletonLoader()
                  : _buildPriceList(api),
            ),
            
            // Last updated indicator
            if (api.lastRefresh != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Última actualización: ${Formatters.formatTime(api.lastRefresh!)}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
          ],
        );
      },
    );
  }

  /// Build fiat currency filter row
  Widget _buildFiatFilter(ApiService api) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: AppConstants.supportedFiats.map((fiat) {
          final isSelected = fiat == _selectedFiat;
          return FiatFilterChip(
            fiat: fiat,
            isSelected: isSelected,
            onTap: () => setState(() => _selectedFiat = fiat),
          );
        }).toList(),
      ),
    );
  }

  /// Build buy/sell toggle
  Widget _buildBuySellToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SegmentedButton<bool>(
        segments: const [
          ButtonSegment(value: true, label: Text('Comprar USDT'), icon: Icon(Icons.arrow_downward, size: 16)),
          ButtonSegment(value: false, label: Text('Vender USDT'), icon: Icon(Icons.arrow_upward, size: 16)),
        ],
        selected: {_showBuy},
        onSelectionChanged: (selection) {
          setState(() => _showBuy = selection.first);
        },
      ),
    );
  }

  /// Build the price list for the selected fiat
  Widget _buildPriceList(ApiService api) {
    final ads = _showBuy 
        ? api.getBuyAdsForFiat(_selectedFiat)
        : api.getSellAdsForFiat(_selectedFiat);

    if (ads.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay datos disponibles para $_selectedFiat',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Desliza hacia abajo para actualizar',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => api.fetchAllPrices(),
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
            ),
          ],
        ),
      );
    }

    // Group by exchange
    final groupedAds = <String, List<P2PAd>>{};
    for (final ad in ads) {
      groupedAds.putIfAbsent(ad.exchange, () => []).add(ad);
    }

    return RefreshIndicator(
      onRefresh: () => api.fetchAllPrices(),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 80),
        children: [
          // Best price summary cards
          _buildBestPriceSummary(api),
          const SizedBox(height: 8),
          // Exchange-grouped price cards
          for (final exchange in AppConstants.exchanges)
            if (groupedAds[exchange] != null && groupedAds[exchange]!.isNotEmpty)
              _buildExchangeSection(exchange, groupedAds[exchange]!),
        ],
      ),
    );
  }

  /// Build best price summary
  Widget _buildBestPriceSummary(ApiService api) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mejores precios $_selectedFiat/USDT',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: AppConstants.exchanges.map((exchange) {
              final price = _showBuy 
                  ? api.getBestBuyPrice(_selectedFiat, exchange)
                  : api.getBestSellPrice(_selectedFiat, exchange);
              final color = AppTheme.getExchangeColor(exchange);
              
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        exchange,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        price != null ? Formatters.formatPrice(price) : '--',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      Text(
                        _selectedFiat,
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Build exchange section with its ads
  Widget _buildExchangeSection(String exchange, List<P2PAd> ads) {
    final color = AppTheme.getExchangeColor(exchange);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                exchange,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const Spacer(),
              Text(
                '${ads.length} anuncios',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        ...ads.take(5).map((ad) => PriceCard(ad: ad)),
      ],
    );
  }
}
