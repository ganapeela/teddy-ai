import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/market_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../screens/chart_screen.dart';
import '../screens/teddy_desk_screen.dart';
import '../screens/option_chain_screen.dart';
import '../screens/history_settings_screen.dart';
import '../widgets/ticker_strip.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ChartScreen(),
    TeddyDeskScreen(),
    OptionChainScreen(),
    HistorySettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final market = ref.watch(marketProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          titleSpacing: 14,
          title: Row(
            children: [
              // Instrument Selector Dropdown Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: market.selectedInstrument,
                    dropdownColor: AppColors.surfaceElevated,
                    icon: const Icon(Icons.arrow_drop_down, color: AppColors.cyan, size: 20),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'NIFTY 50', child: Text('NIFTY 50')),
                      DropdownMenuItem(value: 'BANKNIFTY', child: Text('BANKNIFTY')),
                      DropdownMenuItem(value: 'SENSEX', child: Text('SENSEX')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(marketProvider.notifier).selectInstrument(val);
                      }
                    },
                  ),
                ),
              ),

              const Spacer(),

              // Mode Badge (Live / Replay)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: settings.feedMode == 'LIVE'
                      ? AppColors.green.withOpacity(0.15)
                      : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: settings.feedMode == 'LIVE' ? AppColors.green : AppColors.border,
                  ),
                ),
                child: Text(
                  settings.feedMode == 'LIVE' ? '● LIVE' : 'REPLAY',
                  style: TextStyle(
                    color: settings.feedMode == 'LIVE' ? AppColors.green : AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Connection Status Indicator Dot
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: market.isConnected
                      ? AppColors.green
                      : (market.isOfflineDemo ? AppColors.amber : AppColors.red),
                  boxShadow: [
                    BoxShadow(
                      color: (market.isConnected ? AppColors.green : AppColors.amber).withOpacity(0.6),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Compact Ticker Strip showing LTP, VIX, PCR, Phase
            TickerStrip(snapshot: market.snapshot),

            // Active Screen
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.cyan,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.candlestick_chart_rounded),
              label: 'Chart & Signal',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.psychology_rounded),
              label: 'Teddy Desk',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.table_chart_rounded),
              label: 'Option Chain',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
