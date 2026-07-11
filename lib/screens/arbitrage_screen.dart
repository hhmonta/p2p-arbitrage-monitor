import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/p2p_provider.dart';
import '../models/p2p_models.dart';

class ArbitrageScreen extends StatelessWidget {
  const ArbitrageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<P2PProvider>(
      builder: (context, provider, child) {
        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Header with filter
            SliverToBoxAdapter(
              child: _ArbitrageHeader(provider: provider),
            ),

            // Summary stats
            SliverToBoxAdapter(
              child: _ArbitrageStats(provider: provider),
            ),

            // Opportunities list
            if (provider.isLoading && provider.opportunities.isEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => const _SkeletonOpportunityCard(),
                  childCount: 3,
                ),
              )
            else if (provider.opportunities.isEmpty)
              SliverToBoxAdapter(
                child: _NoOpportunitiesWidget(provider: provider),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= provider.opportunities.length) return null;
                    return _OpportunityCard(
                      opportunity: provider.opportunities[index],
                      fiat: provider.selectedFiat,
                    );
                  },
                  childCount: provider.opportunities.length,
                ),
              ),

            // Disclaimer
            const SliverToBoxAdapter(
              child: _ArbitrageDisclaimer(),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        );
      },
    );
  }
}

class _ArbitrageHeader extends StatelessWidget {
  final P2PProvider provider;
  const _ArbitrageHeader({required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, size: 24),
              const SizedBox(width: 8),
              Text(
                'Detector de Arbitraje',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Ganancia mínima: ',
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                '${provider.minProfitFilter.toStringAsFixed(1)}%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 200,
                child: Slider(
                  value: provider.minProfitFilter,
                  min: 0.0,
                  max: 10.0,
                  divisions: 100,
                  label: '${provider.minProfitFilter.toStringAsFixed(1)}%',
                  onChanged: provider.setMinProfitFilter,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArbitrageStats extends StatelessWidget {
  final P2PProvider provider;
  const _ArbitrageStats({required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final opps = provider.opportunities;
    final bestSpread = opps.isNotEmpty ? opps.first.spreadPercent : 0.0;
    final avgSpread = opps.isNotEmpty
        ? opps.map((o) => o.spreadPercent).reduce((a, b) => a + b) / opps.length
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          _StatCard(
            label: 'Oportunidades',
            value: '${opps.length}',
            icon: Icons.search,
            color: Colors.blue,
          ),
          const SizedBox(width: 8),
          _StatCard(
            label: 'Mejor Spread',
            value: '${bestSpread.toStringAsFixed(2)}%',
            icon: Icons.arrow_upward,
            color: Colors.green,
          ),
          const SizedBox(width: 8),
          _StatCard(
            label: 'Promedio',
            value: '${avgSpread.toStringAsFixed(2)}%',
            icon: Icons.analytics,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpportunityCard extends StatelessWidget {
  final ArbitrageOpportunity opportunity;
  final String fiat;

  const _OpportunityCard({
    required this.opportunity,
    required this.fiat,
  });

  Color get _profitColor {
    if (opportunity.spreadPercent >= 3) return const Color(0xFF00C853);
    if (opportunity.spreadPercent >= 1.5) return const Color(0xFF64DD17);
    if (opportunity.spreadPercent >= 0.5) return const Color(0xFFFFAB00);
    return const Color(0xFFFF6D00);
  }

  String get _profitLevel {
    if (opportunity.spreadPercent >= 3) return 'ALTA';
    if (opportunity.spreadPercent >= 1.5) return 'MEDIA';
    if (opportunity.spreadPercent >= 0.5) return 'BAJA';
    return 'MÍNIMA';
  }

  Color get _buyExchangeColor {
    switch (opportunity.buyListing.exchange) {
      case 'Binance': return const Color(0xFFF0B90B);
      case 'Bybit': return const Color(0xFFF7A600);
      case 'BingX': return const Color(0xFF00D4AA);
      default: return Colors.blue;
    }
  }

  Color get _sellExchangeColor {
    switch (opportunity.sellListing.exchange) {
      case 'Binance': return const Color(0xFFF0B90B);
      case 'Bybit': return const Color(0xFFF7A600);
      case 'BingX': return const Color(0xFF00D4AA);
      default: return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _profitColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row - profit badge & level
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _profitColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '+${opportunity.spreadPercent.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: _profitColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _profitColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _profitLevel,
                    style: TextStyle(
                      color: _profitColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${opportunity.estimatedProfit.toStringAsFixed(2)} $fiat',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: _profitColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Arbitrage route
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  // Buy exchange
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _buyExchangeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.arrow_downward,
                            color: _buyExchangeColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'COMPRAR',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          opportunity.buyListing.exchange,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${opportunity.buyListing.price.toStringAsFixed(2)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Arrow
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.arrow_forward,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),

                  // Sell exchange
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _sellExchangeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.arrow_upward,
                            color: _sellExchangeColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'VENDER',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          opportunity.sellListing.exchange,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${opportunity.sellListing.price.toStringAsFixed(2)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Details
            Row(
              children: [
                _DetailChip(
                  label: 'Ganancia/USDT',
                  value: '${opportunity.profitPerUnit.toStringAsFixed(2)} $fiat',
                ),
                const SizedBox(width: 8),
                _DetailChip(
                  label: 'Monto máx.',
                  value: '${opportunity.maxTradeAmount.toStringAsFixed(0)} USDT',
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _DetailChip(
                  label: 'Pago compra',
                  value: opportunity.buyListing.paymentMethod.isNotEmpty
                      ? opportunity.buyListing.paymentMethod
                      : 'Multiple',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final String label;
  final String value;

  const _DetailChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _NoOpportunitiesWidget extends StatelessWidget {
  final P2PProvider provider;
  const _NoOpportunitiesWidget({required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin oportunidades de arbitraje',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            provider.prices.isEmpty
                ? 'Esperando datos de los exchanges...'
                : 'No se detectaron spreads superiores a ${provider.minProfitFilter.toStringAsFixed(1)}% en ${provider.selectedFiat}',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: provider.refreshPrices,
            child: const Text('Actualizar precios'),
          ),
        ],
      ),
    );
  }
}

class _SkeletonOpportunityCard extends StatelessWidget {
  const _SkeletonOpportunityCard();

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
                  width: 80,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 60,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArbitrageDisclaimer extends StatelessWidget {
  const _ArbitrageDisclaimer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.orange.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber, size: 18, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Riesgos del arbitraje P2P: Los precios mostrados son indicativos y pueden no estar disponibles '
                'al momento de ejecutar la operación. Se deben considerar: comisiones de transferencia, '
                'tiempo de confirmación, riesgos de contraparte, fluctuaciones de precio durante la operación, '
                'y límites de transacción. Las ganancias estimadas son teóricas y no garantizadas.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.orange.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
