import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/teddy_signal.dart';
import '../../core/providers/market_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/providers/teddy_signal_provider.dart';

class HistorySettingsScreen extends ConsumerStatefulWidget {
  const HistorySettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HistorySettingsScreen> createState() => _HistorySettingsScreenState();
}

class _HistorySettingsScreenState extends ConsumerState<HistorySettingsScreen> {
  late TextEditingController _urlController;
  late TextEditingController _geminiKeyController;

  @override
  void initState() {
    super.initState();
    final currentUrl = ref.read(settingsProvider).serverUrl;
    final currentKey = ref.read(settingsProvider).geminiApiKey;
    _urlController = TextEditingController(text: currentUrl);
    _geminiKeyController = TextEditingController(text: currentKey);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _geminiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final signalState = ref.watch(teddySignalProvider);

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: AppColors.surface,
            child: const TabBar(
              indicatorColor: AppColors.cyan,
              indicatorWeight: 3,
              labelColor: AppColors.cyan,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                Tab(text: 'Signal Audit Log'),
                Tab(text: 'Terminal Settings'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildAuditLogTab(signalState.history),
                _buildSettingsTab(settings),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLogTab(List<TeddySignal> history) {
    if (history.isEmpty) {
      return const Center(
        child: Text(
          'No signal history recorded yet.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final sig = history[index];
        final isBuyCe = sig.decision == 'BUY_CE';
        final isBuyPe = sig.decision == 'BUY_PE';
        final color = isBuyCe ? AppColors.green : (isBuyPe ? AppColors.red : AppColors.amber);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      sig.decision.replaceAll('_', ' '),
                      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    sig.timestamp,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                sig.recommendedStrike ?? sig.instrument,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Text(
                sig.setupType,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
              if (sig.decision != 'NO_TRADE') ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Entry: ₹${sig.optionEntryZone?[0] ?? '-'}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    Text('SL: ₹${sig.stopLossOption ?? '-'}', style: const TextStyle(color: AppColors.red, fontSize: 11)),
                    Text('T1: ₹${sig.targetsOption?[0] ?? '-'}', style: const TextStyle(color: AppColors.green, fontSize: 11)),
                    Text('Conf: ${sig.confidenceScore}%', style: const TextStyle(color: AppColors.cyan, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsTab(SettingsState settings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STANDALONE PHONE MODE (ZERO PC REQUIRED)',
            style: TextStyle(color: AppColors.cyan, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.6),
          ),
          const SizedBox(height: 8),

          _buildSettingTile(
            title: 'Run 100% on Phone (No PC)',
            subtitle: 'Calculates quant math and signals entirely on your Android device',
            trailing: Switch(
              value: settings.standalonePhoneMode,
              activeColor: AppColors.cyan,
              onChanged: (val) => ref.read(settingsProvider.notifier).toggleStandalonePhoneMode(val),
            ),
          ),
          const SizedBox(height: 10),

          // Gemini API Key Input
          TextField(
            controller: _geminiKeyController,
            obscureText: true,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surface,
              hintText: 'Paste Gemini API Key for direct AI reasoning',
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cyan)),
              suffixIcon: IconButton(
                icon: const Icon(Icons.key_rounded, color: AppColors.cyan),
                onPressed: () {
                  final key = _geminiKeyController.text.trim();
                  ref.read(settingsProvider.notifier).setGeminiApiKey(key);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gemini API Key saved for standalone mode!')),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 24),
          const Text(
            'OPTIONAL: BACKEND SERVER CONNECTION',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.6),
          ),
          const SizedBox(height: 8),

          // URL Input
          TextField(
            controller: _urlController,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surface,
              hintText: 'http://10.0.2.2:8000',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cyan)),
              suffixIcon: IconButton(
                icon: const Icon(Icons.check_circle_rounded, color: AppColors.cyan),
                onPressed: () {
                  final newUrl = _urlController.text.trim();
                  ref.read(settingsProvider.notifier).setServerUrl(newUrl);
                  ref.read(marketProvider.notifier).updateBackendUrl(newUrl);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Server URL updated! Reconnecting...')),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Quick Select Buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickPill('Android Emulator (10.0.2.2:8000)', 'http://10.0.2.2:8000'),
              _buildQuickPill('Desktop Localhost (127.0.0.1:8000)', 'http://127.0.0.1:8000'),
            ],
          ),

          const SizedBox(height: 24),
          const Text(
            'TRADING ENGINE PREFERENCES',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.6),
          ),
          const SizedBox(height: 10),

          // Feed Mode Toggle
          _buildSettingTile(
            title: 'Market Data Feed',
            subtitle: 'Toggle 24/7 Market Replay vs Live Broker Adapter',
            trailing: DropdownButton<String>(
              value: settings.feedMode,
              dropdownColor: AppColors.surfaceElevated,
              underline: const SizedBox(),
              style: const TextStyle(color: AppColors.cyan, fontWeight: FontWeight.bold),
              items: const [
                DropdownMenuItem(value: 'REPLAY', child: Text('Replay Mode (24/7)')),
                DropdownMenuItem(value: 'LIVE', child: Text('Live Broker Mode')),
              ],
              onChanged: (val) {
                if (val != null) ref.read(settingsProvider.notifier).setFeedMode(val);
              },
            ),
          ),

          const SizedBox(height: 10),

          // Auto-analyze switch
          _buildSettingTile(
            title: 'Auto-Analyze on Candle Close',
            subtitle: 'Automatically trigger Teddy AI analysis every 5 minutes',
            trailing: Switch(
              value: settings.autoAnalyze,
              activeColor: AppColors.cyan,
              onChanged: (val) => ref.read(settingsProvider.notifier).toggleAutoAnalyze(val),
            ),
          ),

          const SizedBox(height: 10),

          // Push Notifications switch
          _buildSettingTile(
            title: 'High-Confidence Local Alerts',
            subtitle: 'Trigger Android push notifications when confidence >= 75%',
            trailing: Switch(
              value: settings.pushNotifications,
              activeColor: AppColors.green,
              onChanged: (val) => ref.read(settingsProvider.notifier).togglePushNotifications(val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPill(String label, String url) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textPrimary)),
      backgroundColor: AppColors.surfaceElevated,
      side: const BorderSide(color: AppColors.border),
      onPressed: () {
        _urlController.text = url;
        ref.read(settingsProvider.notifier).setServerUrl(url);
        ref.read(marketProvider.notifier).updateBackendUrl(url);
      },
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
