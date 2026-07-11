import 'package:flutter/material.dart';
import '../models/arbitrage_opportunity.dart';
import '../utils/formatters.dart';
import '../theme/app_theme.dart';

/// Card widget displaying an arbitrage opportunity
class ArbitrageCard extends StatelessWidget {
  final ArbitrageOpportunity opportunity;

  const ArbitrageCard({super.key, required this.opportunity});

  @override
  Widget build(BuildContext context) {
    final buyColor = AppTheme.getExchangeColor(opportunity.buyExchange);
    final sellColor = AppTheme.getExchangeColor(opportunity.sellExchange);
    final spreadColor = AppTheme.getSpreadColor(opportunity.netProfitPercent);
    final isProfitable = opportunity.isProfitable;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isProfitable
              ? Border.all(color: spreadColor.withOpacity(0.5), width: 1.5)
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Fiat + Spread badge
              Row(
                children: [
                  Text(
                    '${Formatters.getFiatFlag(opportunity.fiat)} ${opportunity.fiat}/USDT',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const Spacer(),
                  // Spread badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: spreadColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: spreadColor.withOpacity(0.4)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          Formatters.formatSpread(opportunity.netProfitPercent),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: spreadColor,
                          ),
                        ),
                        Text(
                          'Neto',
                          style: TextStyle(fontSize: 9, color: spreadColor.withOpacity(0.8)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Exchange flow: Buy → Sell
              Row(
                children: [
                  // Buy exchange
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: buyColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: buyColor.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.arrow_downward, size: 14, color: buyColor),
                              const SizedBox(width: 4),
                              Text(
                                'COMPRAR',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: buyColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            opportunity.buyExchange,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                          Text(
                            Formatters.formatPrice(opportunity.buyPrice),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          Text(
                            '${Formatters.formatPrice(opportunity.buyAvailableAmount)} USDT disp.',
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Arrow
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      children: [
                        Icon(
                          Icons.swap_horiz,
                          size: 28,
                          color: spreadColor,
                        ),
                        Text(
                          Formatters.formatSpread(opportunity.spreadPercent),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: spreadColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Sell exchange
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: sellColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: sellColor.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'VENDER',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: sellColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.arrow_upward, size: 14, color: sellColor),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            opportunity.sellExchange,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                          Text(
                            Formatters.formatPrice(opportunity.sellPrice),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          Text(
                            '${Formatters.formatPrice(opportunity.sellAvailableAmount)} USDT disp.',
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 10),
              
              // Bottom row: Max trade amount + Fees + Risk
              Row(
                children: [
                  _buildDetailItem(
                    context,
                    'Máx. operable',
                    '${Formatters.formatPrice(opportunity.maxTradableAmount)} USDT',
                  ),
                  _buildDetailItem(
                    context,
                    'Comisiones est.',
                    '~${opportunity.estimatedFees.toStringAsFixed(1)}%',
                  ),
                  _buildDetailItem(
                    context,
                    'Riesgo',
                    opportunity.riskLevel,
                    valueColor: _getRiskColor(opportunity.riskLevel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(BuildContext context, String label, String value, {Color? valueColor}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).hintColor,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: valueColor ?? Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel) {
      case 'Low': return Colors.green;
      case 'Medium': return Colors.orange;
      case 'High': return Colors.deepOrange;
      case 'Very High': return Colors.red;
      default: return Colors.grey;
    }
  }
}
