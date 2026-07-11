import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/p2p_provider.dart';
import '../utils/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _alertThreshold = 2.0;
  bool _notificationsEnabled = true;
  int _alertCooldownMinutes = 5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<P2PProvider>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(title: 'General', icon: Icons.settings),
        const SizedBox(height: 8),
        
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Actualización automática'),
                subtitle: Text(
                  provider.isAutoRefresh
                      ? 'Cada ${provider.refreshIntervalSeconds} segundos'
                      : 'Desactivada',
                ),
                value: provider.isAutoRefresh,
                onChanged: (_) => provider.toggleAutoRefresh(),
              ),
              if (provider.isAutoRefresh)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      const Text('Intervalo: '),
                      Expanded(
                        child: Slider(
                          value: provider.refreshIntervalSeconds.toDouble(),
                          min: 5,
                          max: 120,
                          divisions: 23,
                          label: '${provider.refreshIntervalSeconds}s',
                          onChanged: (v) => provider.setRefreshInterval(v.round()),
                        ),
                      ),
                      SizedBox(
                        width: 50,
                        child: Text(
                          '${provider.refreshIntervalSeconds}s',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        _SectionHeader(title: 'Notificaciones', icon: Icons.notifications),
        const SizedBox(height: 8),

        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Alertas de arbitraje'),
                subtitle: const Text('Notificar cuando el spread supere el umbral'),
                value: _notificationsEnabled,
                onChanged: (v) => setState(() => _notificationsEnabled = v),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    const Text('Umbral: '),
                    Expanded(
                      child: Slider(
                        value: _alertThreshold,
                        min: 0.5,
                        max: 10.0,
                        divisions: 19,
                        label: '${_alertThreshold.toStringAsFixed(1)}%',
                        onChanged: (v) => setState(() => _alertThreshold = v),
                      ),
                    ),
                    SizedBox(
                      width: 50,
                      child: Text(
                        '${_alertThreshold.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _alertThreshold >= 3 ? Colors.green : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    const Text('Frecuencia alertas: '),
                    Expanded(
                      child: Slider(
                        value: _alertCooldownMinutes.toDouble(),
                        min: 1,
                        max: 30,
                        divisions: 29,
                        label: '$_alertCooldownMinutes min',
                        onChanged: (v) => setState(() => _alertCooldownMinutes = v.round()),
                      ),
                    ),
                    SizedBox(
                      width: 50,
                      child: Text(
                        '$_alertCooldownMinutes min',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        _SectionHeader(title: 'Datos', icon: Icons.storage),
        const SizedBox(height: 8),

        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              ListTile(
                title: const Text('Registros históricos'),
                subtitle: Text('${provider.priceHistory.length} registros en ${provider.selectedFiat}'),
                trailing: const Icon(Icons.chevron_right),
              ),
              ListTile(
                title: const Text('Limpiar datos antiguos'),
                subtitle: const Text('Eliminar registros mayores a 30 días'),
                trailing: const Icon(Icons.delete_outline),
                onTap: () => _showCleanupDialog(context, provider),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        _SectionHeader(title: 'Tema', icon: Icons.palette),
        const SizedBox(height: 8),

        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return SwitchListTile(
                title: const Text('Modo oscuro'),
                subtitle: const Text('Cambiar entre tema claro y oscuro'),
                value: themeProvider.isDarkMode,
                onChanged: (_) => themeProvider.toggleTheme(),
                secondary: Icon(
                  themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 24),

        _SectionHeader(title: 'Acerca de', icon: Icons.info),
        const SizedBox(height: 8),

        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              const ListTile(
                title: Text('P2P Arbitrage Monitor'),
                subtitle: Text('Versión 1.0.0'),
                leading: Icon(Icons.swap_horiz),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('APIs utilizadas'),
                subtitle: const Text(
                  'Binance P2P, Bybit P2P, BingX P2P\n'
                  'Las APIs pueden tener limitaciones de CORS y rate limiting.\n'
                  'Se recomienda usar la app como herramienta informativa.',
                ),
                leading: const Icon(Icons.cloud),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Limitaciones'),
                subtitle: const Text(
                  '• Los precios son indicativos y pueden no estar disponibles\n'
                  '• Las APIs P2P no requieren autenticación para consulta\n'
                  '• Rate limiting: consultas cada 15s mínimo\n'
                  '• BingX endpoint puede requerir ajustes\n'
                  '• CORS puede bloquear desde navegador web',
                ),
                leading: const Icon(Icons.warning_amber),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        Card(
          color: Colors.red.withValues(alpha: 0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.redAccent, width: 0.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.dangerous, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Text(
                      'Descargo de Responsabilidad',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Esta aplicación es HERRAMIENTA INFORMATIVA y no constituye asesoría financiera. '
                  'El arbitraje P2P conlleva riesgos significativos incluyendo pero no limitados a:\n\n'
                  '• Riesgo de contraparte: el vendedor puede no completar la transacción\n'
                  '• Riesgo de precio: los precios fluctúan entre el momento de compra y venta\n'
                  '• Riesgo regulatorio: las operaciones P2P pueden estar sujetas a regulaciones locales\n'
                  '• Riesgo de liquidez: los montos disponibles pueden no ser suficientes\n'
                  '• Costos ocultos: comisiones de transferencia bancaria, spread cambiario, impuestos\n\n'
                  'Las ganancias mostradas son TEÓRICAS y no garantizadas. '
                  'Operar bajo su propia responsabilidad. No nos hacemos responsables de pérdidas derivadas '
                  'del uso de esta información.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.redAccent.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 80),
      ],
    );
  }

  void _showCleanupDialog(BuildContext context, P2PProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpiar datos'),
        content: const Text('¿Eliminar registros de precios mayores a 30 días? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final count = await provider.dbService.cleanupOldRecords();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$count registros antiguos eliminados')),
                );
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
