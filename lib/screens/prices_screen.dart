import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/p2p_provider.dart';
import '../models/p2p_models.dart';

class PricesScreen extends StatelessWidget {
  const PricesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<P2PProvider>(
      builder: (context, provider, child) {
        return RefreshIndicator(
          onRefresh: provider.refreshPrices,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Fiat selector
              SliverToBoxAdapter(
                child: _FiatSelector(provider: provider),
              ),
              
              // Last update indicator
              SliverToBoxAdapter(
                child: _LastUpdateBar(provider: provider),
              ),

              // Exchange price cards
              if (provider.prices.isEmpty && provider.isLoading)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const _SkeletonPriceCard(),
                    childCount: 3,
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final exchanges = ['Binance', 'Bybit', 'BingX'];
                      if (index >= exchanges.length) return null;
                      final prices = provider.prices[exchanges[index]];
                      return _ExchangePriceCard(
                        exchange: exchanges[index],
                        prices: prices,
                        fiat: provider.selectedFiat,
                      );
                    },
                    childCount: 3,
                  ),
                ),

              // Error display
              if (provider.error != null)
                SliverToBoxAdapter(
                  child: _ErrorBanner(error: provider.error!),
                ),

              // Disclaimer
              const SliverToBoxAdapter(
                child: _DisclaimerCard(),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FiatSelector extends StatelessWidget {
  final P2PProvider provider;
  const _FiatSelector({required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Moneda Fiat',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: P2PProvider.supportedFiats.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final fiat = P2PProvider.supportedFiats[index];
                final isSelected = fiat == provider.selectedFiat;
                return ChoiceChip(
                  label: Text(fiat),
                  selected: isSelected,
                  onSelected: (_) => provider.setFiat(fiat),
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  selectedColor: theme.colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LastUpdateBar extends StatelessWidget {
  final P2PProvider provider;
  const _LastUpdateBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lastUpdate = provider.lastUpdate;
    final isLoading = provider.isLoading;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          if (isLoading)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            )
          else
            Icon(
              Icons.check_circle,
              size: 14,
              color: theme.colorScheme.primary,
            ),
          const SizedBox(width: 6),
          Text(
            lastUpdate != null
                ? 'Actualizado: ${_formatTime(lastUpdate)}'
                : 'Sin datos aún',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const Spacer(),
          if (provider.isAutoRefresh)
            Text(
              'Auto: ${provider.refreshIntervalSeconds}s',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }
}

class _ExchangePriceCard extends StatelessWidget {
  final String exchange;
  final ExchangePrices? prices;
  final String fiat;

  const _ExchangePriceCard({
    required this.exchange,
    required this.prices,
    required this.fiat,
  });

  Color get _exchangeColor {
    switch (exchange) {
      case 'Binance':
        return const Color(0xFFF0B90B);
      case 'Bybit':
        return const Color(0xFFF7A600);
      case 'BingX':
        return const Color(0xFF00D4AA);
      default:
        return Colors.blue;
    }
  }

  IconData get _exchangeIcon {
    switch (exchange) {
      case 'Binance':
        return Icons.currency_bitcoin;
      case 'Bybit':
        return Icons.show_chart;
      case 'BingX':
        return Icons.swap_horiz;
      default:
        return Icons.currency_exchange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = prices?.error != null;
    final hasData = prices != null && prices!.bestBuyPrice > 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: hasError
            ? const BorderSide(color: Colors.redAccent, width: 1)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _exchangeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_exchangeIcon, color: _exchangeColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exchange,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (hasError)
                        Text(
                          'Error de conexión',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.redAccent,
                          ),
                        ),
                    ],
                  ),
                ),
                if (hasData)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: prices!.spread > 0
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${prices!.spread.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: prices!.spread > 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),

            if (hasData) ...[
              const SizedBox(height: 16),
              // Price rows
              Row(
                children: [
                  Expanded(
                    child: _PriceInfo(
                      label: 'COMPRA',
                      price: prices!.bestBuyPrice,
                      fiat: fiat,
                      color: Colors.green,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color: theme.dividerColor.withValues(alpha: 0.3),
                  ),
                  Expanded(
                    child: _PriceInfo(
                      label: 'VENTA',
                      price: prices!.bestSellPrice,
                      fiat: fiat,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
              // Listings count
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Anuncios compra: ${prices!.buyListings.length}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  Text(
                    'Anuncios venta: ${prices!.sellListings.length}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              // Top listings
              if (prices!.buyListings.isNotEmpty) ...[
                const SizedBox(height: 12),
                _TopListingsSection(listings: prices!.buyListings.take(3).toList(), isBuy: true),
              ],
              if (prices!.sellListings.isNotEmpty) ...[
                const SizedBox(height: 8),
                _TopListingsSection(listings: prices!.sellListings.take(3).toList(), isBuy: false),
              ],
            ],

            if (!hasData && !hasError)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Esperando datos...'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PriceInfo extends StatelessWidget {
  final String label;
  final double price;
  final String fiat;
  final Color color;

  const _PriceInfo({
    required this.label,
    required this.price,
    required this.fiat,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          child: Text(
            price > 0 ? '${price.toStringAsFixed(2)} $fiat' : '--',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _TopListingsSection extends StatelessWidget {
  final List<P2PListing> listings;
  final bool isBuy;

  const _TopListingsSection({required this.listings, required this.isBuy});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: listings.map((l) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(
              isBuy ? Icons.arrow_downward : Icons.arrow_upward,
              size: 14,
              color: isBuy ? Colors.green : Colors.redAccent,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '${l.price.toStringAsFixed(2)} | ${l.advertiserName} | ${l.availableAmount.toStringAsFixed(1)} USDT',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }
}

class _SkeletonPriceCard extends StatelessWidget {
  const _SkeletonPriceCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 120,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String error;
  const _ErrorBanner({required this.error});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: Colors.redAccent.withValues(alpha: 0.1),
      child: ListTile(
        leading: const Icon(Icons.error_outline, color: Colors.redAccent),
        title: const Text('Error de conexión'),
        subtitle: Text(
          error,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: TextButton(
          onPressed: () => context.read<P2PProvider>().refreshPrices(),
          child: const Text('Reintentar'),
        ),
      ),
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 18, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Los precios P2P pueden variar según el vendedor, método de pago y disponibilidad. '
                'El arbitraje P2P conlleva riesgos: fluctuaciones de precio, contraparte, y limitaciones de transferencia. '
                'Use esta información bajo su propia responsabilidad.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
