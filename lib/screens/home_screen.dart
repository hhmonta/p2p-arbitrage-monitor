import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/p2p_provider.dart';
import '../services/p2p_api_service.dart';
import '../db/database_service.dart';
import 'prices_screen.dart';
import 'arbitrage_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late P2PProvider _provider;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    _provider = P2PProvider(
      serviceManager: P2PServiceManager.defaultServices(),
      dbService: DatabaseService(),
    );

    // Initial fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider.refreshPrices();
      _provider.startAutoRefresh();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        body: Column(
          children: [
            // Custom app bar with gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primaryContainer,
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // Title row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.swap_horiz,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'P2P Arbitrage Monitor',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Binance · Bybit · BingX',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Consumer<P2PProvider>(
                            builder: (context, provider, _) {
                              return IconButton(
                                onPressed: provider.isLoading
                                    ? null
                                    : provider.refreshPrices,
                                icon: provider.isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.refresh,
                                        color: Colors.white,
                                      ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Tab bar
                    TabBar(
                      controller: _tabController,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white60,
                      indicatorColor: Colors.white,
                      indicatorWeight: 3,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 12,
                      ),
                      tabs: const [
                        Tab(
                          icon: Icon(Icons.attach_money, size: 20),
                          text: 'Precios',
                        ),
                        Tab(
                          icon: Icon(Icons.trending_up, size: 20),
                          text: 'Arbitraje',
                        ),
                        Tab(
                          icon: Icon(Icons.show_chart, size: 20),
                          text: 'Historial',
                        ),
                        Tab(
                          icon: Icon(Icons.settings, size: 20),
                          text: 'Ajustes',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  PricesScreen(),
                  ArbitrageScreen(),
                  HistoryScreen(),
                  SettingsScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
