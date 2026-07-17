import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/hourly_capture_service.dart';
import '../utils/constants.dart';
import 'prices_screen.dart';
import 'arbitrage_screen.dart';
import 'capture_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

/// Main home screen with bottom navigation tabs
class HomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const HomeScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  Timer? _refreshTimer;
  bool _autoRefresh = true;

  final List<Widget> _screens = [
    const PricesScreen(),
    const ArbitrageScreen(),
    const CaptureScreen(),
    const HistoryScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    HourlyCaptureService.instance.stop();
    super.dispose();
  }

  /// Initialize app - load preferences and start first fetch
  Future<void> _initApp() async {
    final apiService = context.read<ApiService>();
    await apiService.loadPreferences();
    await apiService.fetchAllPrices();
    HourlyCaptureService.instance.start(apiService);
    _startAutoRefresh();
  }

  /// Start auto-refresh timer
  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    if (!_autoRefresh) return;

    final apiService = context.read<ApiService>();
    _refreshTimer = Timer.periodic(
      Duration(seconds: apiService.refreshInterval),
      (_) => apiService.fetchAllPrices(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh when app comes back to foreground
      context.read<ApiService>().fetchAllPrices();
      _startAutoRefresh();
    } else if (state == AppLifecycleState.paused) {
      // Pause refresh when app is in background (battery optimization)
      _refreshTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.show_chart,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('P2P Monitor'),
          ],
        ),
        actions: [
          // Connection status indicator
          Consumer<ApiService>(
            builder: (context, api, _) {
              if (api.isLoading) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              if (api.error != null) {
                return IconButton(
                  icon: const Icon(Icons.error_outline, color: Colors.redAccent),
                  tooltip: api.error,
                  onPressed: () => _showErrorDialog(context, api.error!),
                );
              }
              return IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh prices',
                onPressed: () => api.fetchAllPrices(),
              );
            },
          ),
          // Theme toggle
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: 'Toggle theme',
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.attach_money),
            selectedIcon: Icon(Icons.attach_money),
            label: 'Precios',
          ),
          NavigationDestination(
            icon: Icon(Icons.swap_horiz),
            selectedIcon: Icon(Icons.swap_horiz),
            label: 'Arbitraje',
          ),
          NavigationDestination(
            icon: Icon(Icons.schedule),
            selectedIcon: Icon(Icons.schedule),
            label: 'Captura',
          ),
          NavigationDestination(
            icon: Icon(Icons.timeline),
            selectedIcon: Icon(Icons.timeline),
            label: 'Historial',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error de Conexión'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ApiService>().fetchAllPrices();
            },
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
