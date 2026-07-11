import 'package:flutter/material.dart';
import '../models/p2p_ad.dart';
import '../utils/formatters.dart';
import '../theme/app_theme.dart';

/// Card widget displaying a single P2P advertisement
class PriceCard extends StatelessWidget {
  final P2PAd ad;

  const PriceCard({super.key, required this.ad});

  @override
  Widget build(BuildContext context) {
    final exchangeColor = AppTheme.getExchangeColor(ad.exchange);
    final isBuy = ad.tradeType == 'BUY';
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Price + Exchange badge
            Row(
              children: [
                // Price
                Text(
                  Formatters.formatPrice(ad.price),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isBuy ? Colors.redAccent : Colors.greenAccent,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  ad.fiat,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                const Spacer(),
                // Exchange badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: exchangeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: exchangeColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    ad.exchange,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: exchangeColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Merchant info row
            Row(
              children: [
                Icon(Icons.person_outline, size: 14, color: Theme.of(context).hintColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    ad.merchantName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (ad.completionRate > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline, size: 12, color: Colors.green[400]),
                      const SizedBox(width: 2),
                      Text(
                        '${ad.completionRate}%',
                        style: TextStyle(fontSize: 11, color: Colors.green[400]),
                      ),
                    ],
                  ),
                if (ad.orderCount > 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${ad.orderCount} órdenes',
                    style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            // Available amount and limits
            Row(
              children: [
                _buildInfoChip(
                  context,
                  Icons.account_balance_wallet_outlined,
                  '${Formatters.formatPrice(ad.availableAmount)} USDT',
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  context,
                  Icons.compare_arrows,
                  '${Formatters.formatPrice(ad.minAmount)} - ${Formatters.formatPrice(ad.maxAmount)} ${ad.fiat}',
                ),
              ],
            ),
            if (ad.paymentMethods.isNotEmpty) ...[
              const SizedBox(height: 6),
              // Payment methods
              Wrap(
                spacing: 4,
                runSpacing: 2,
                children: ad.paymentMethods.take(4).map((method) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      method,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Theme.of(context).hintColor),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }
}
