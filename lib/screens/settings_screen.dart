import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../models/notification_config.dart';
import '../utils/constants.dart';
import '../services/bingx_service.dart';

/// Settings screen for configuring the app
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ApiService>(
      builder: (context, api, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Refresh settings
              _buildSection(
                context,
                title: 'Actualización',
                icon: Icons.sync,
                children: [
                  _buildRefreshIntervalSetting(context, api),
                  _buildAutoRefreshToggle(context, api),
                ],
              ),
              
              // Notification settings
              _buildSection(
                context,
                title: 'Notificaciones',
                icon: Icons.notifications,
                children: [
                  _buildNotificationToggle(context, api),
                  _buildArbitrageThresholdSetting(context, api),
                  _buildNotificationFiatsSetting(context, api),
                  _buildNotificationSoundToggle(context, api),
                  _buildNotificationVibrateToggle(context, api),
                  _buildCooldownSetting(context, api),
                ],
              ),
              
              // Fiat currencies
              _buildSection(
                context,
                title: 'Monedas fiat',
                icon: Icons.currency_exchange,
                children: [
                  _buildFiatSelection(context, api),
                ],
              ),
              
              // API Status
              _buildSection(
                context,
                title: 'Estado de APIs',
                icon: Icons.cloud,
                children: [
                  _buildApiStatusList(context),
                ],
              ),
              
              // About & Disclaimer
              _buildSection(
                context,
                title: 'Acerca de',
                icon: Icons.info,
                children: [
                  _buildDisclaimer(context),
                  _buildApiLimitations(context),
                  _buildAppInfo(context),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        ...children,
        const Divider(indent: 16, endIndent: 16),
      ],
    );
  }

  Widget _buildRefreshIntervalSetting(BuildContext context, ApiService api) {
    return ListTile(
      title: const Text('Intervalo de actualización'),
      subtitle: Text('${api.refreshInterval} segundos'),
      trailing: SizedBox(
        width: 150,
        child: Slider(
          value: api.refreshInterval.toDouble(),
          min: AppConstants.minRefreshIntervalSeconds.toDouble(),
          max: AppConstants.maxRefreshIntervalSeconds.toDouble(),
          divisions: 10,
          label: '${api.refreshInterval}s',
          onChanged: (value) => api.setRefreshInterval(value.round()),
        ),
      ),
    );
  }

  Widget _buildAutoRefreshToggle(BuildContext context, ApiService api) {
    return SwitchListTile(
      title: const Text('Auto-actualización'),
      subtitle: const Text('Actualizar precios automáticamente'),
      value: true,
      onChanged: (value) {
        // Toggle auto-refresh
      },
    );
  }

  Widget _buildNotificationToggle(BuildContext context, ApiService api) {
    return SwitchListTile(
      title: const Text('Alertas de arbitraje'),
      subtitle: const Text('Notificar cuando se detecten oportunidades'),
      value: api.notificationConfig.enabled,
      onChanged: (value) {
        api.updateNotificationConfig(
          api.notificationConfig.copyWith(enabled: value),
        );
      },
    );
  }

  Widget _buildArbitrageThresholdSetting(BuildContext context, ApiService api) {
    return ListTile(
      title: const Text('Umbral de spread mínimo'),
      subtitle: Text('${api.notificationConfig.arbitrageThreshold.toStringAsFixed(1)}%'),
      trailing: SizedBox(
        width: 150,
        child: Slider(
          value: api.notificationConfig.arbitrageThreshold,
          min: AppConstants.minArbitrageThreshold,
          max: AppConstants.maxArbitrageThreshold,
          divisions: 20,
          label: '${api.notificationConfig.arbitrageThreshold.toStringAsFixed(1)}%',
          onChanged: (value) {
            api.updateNotificationConfig(
              api.notificationConfig.copyWith(arbitrageThreshold: value),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationFiatsSetting(BuildContext context, ApiService api) {
    return ListTile(
      title: const Text('Monedas para notificar'),
      subtitle: Text(api.notificationConfig.selectedFiats.join(', ')),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showFiatSelectionDialog(context, api),
    );
  }

  Widget _buildNotificationSoundToggle(BuildContext context, ApiService api) {
    return SwitchListTile(
      title: const Text('Sonido'),
      value: api.notificationConfig.soundEnabled,
      onChanged: (value) {
        api.updateNotificationConfig(
          api.notificationConfig.copyWith(soundEnabled: value),
        );
      },
    );
  }

  Widget _buildNotificationVibrateToggle(BuildContext context, ApiService api) {
    return SwitchListTile(
      title: const Text('Vibración'),
      value: api.notificationConfig.vibrateEnabled,
      onChanged: (value) {
        api.updateNotificationConfig(
          api.notificationConfig.copyWith(vibrateEnabled: value),
        );
      },
    );
  }

  Widget _buildCooldownSetting(BuildContext context, ApiService api) {
    return ListTile(
      title: const Text('Enfriamiento entre notificaciones'),
      subtitle: Text('${api.notificationConfig.cooldownMinutes} minutos'),
      trailing: SizedBox(
        width: 150,
        child: Slider(
          value: api.notificationConfig.cooldownMinutes.toDouble(),
          min: 5,
          max: 60,
          divisions: 11,
          label: '${api.notificationConfig.cooldownMinutes}min',
          onChanged: (value) {
            api.updateNotificationConfig(
              api.notificationConfig.copyWith(cooldownMinutes: value.round()),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFiatSelection(BuildContext context, ApiService api) {
    return Wrap(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      spacing: 8,
      runSpacing: 4,
      children: AppConstants.supportedFiats.map((fiat) {
        final isSelected = api.selectedFiats.contains(fiat);
        return FilterChip(
          label: Text(fiat),
          selected: isSelected,
          onSelected: (selected) {
            final newList = List<String>.from(api.selectedFiats);
            if (selected) {
              newList.add(fiat);
            } else {
              newList.remove(fiat);
            }
            if (newList.isNotEmpty) {
              api.setSelectedFiats(newList);
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildApiStatusList(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          _buildApiStatusItem(context, 'Binance', true, AppTheme.binanceColor),
          _buildApiStatusItem(context, 'Bybit', true, AppTheme.bybitColor),
          _buildApiStatusItem(
            context, 
            'BingX', 
            BingXService().isAvailable, 
            AppTheme.bingxColor,
          ),
        ],
      ),
    );
  }

  Widget _buildApiStatusItem(BuildContext context, String name, bool available, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: available ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(name, style: TextStyle(fontWeight: FontWeight.w500, color: color)),
          const Spacer(),
          Text(
            available ? 'Disponible' : 'No disponible',
            style: TextStyle(
              fontSize: 12,
              color: available ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimer(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.withOpacity(0.2)),
        ),
        child: Text(
          AppConstants.riskDisclaimer,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.red[700],
          ),
        ),
      ),
    );
  }

  Widget _buildApiLimitations(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withOpacity(0.2)),
        ),
        child: Text(
          AppConstants.apiLimitationsNote,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.orange[700],
          ),
        ),
      ),
    );
  }

  Widget _buildAppInfo(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.info_outline),
      title: Text('P2P Arbitrage Monitor v${AppConstants.appVersion}'),
      subtitle: const Text('Monitor de precios P2P y detector de arbitraje'),
    );
  }

  void _showFiatSelectionDialog(BuildContext context, ApiService api) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final selected = List<String>.from(api.notificationConfig.selectedFiats);
          return AlertDialog(
            title: const Text('Monedas para notificar'),
            content: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: AppConstants.supportedFiats.map((fiat) {
                final isSelected = selected.contains(fiat);
                return FilterChip(
                  label: Text(fiat),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        selected.add(fiat);
                      } else {
                        selected.remove(fiat);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  api.updateNotificationConfig(
                    api.notificationConfig.copyWith(selectedFiats: selected),
                  );
                  Navigator.pop(ctx);
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }
}
