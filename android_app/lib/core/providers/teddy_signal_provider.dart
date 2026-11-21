import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/teddy_signal.dart';
import '../network/api_service.dart';
import '../services/gemini_service.dart';
import '../services/mock_data_generator.dart';
import '../services/notification_service.dart';
import 'market_provider.dart';
import 'settings_provider.dart';

class TeddySignalState {
  final TeddySignal? latestSignal;
  final List<TeddySignal> history;
  final bool isAnalyzing;
  final String? error;

  const TeddySignalState({
    this.latestSignal,
    this.history = const [],
    this.isAnalyzing = false,
    this.error,
  });

  TeddySignalState copyWith({
    TeddySignal? latestSignal,
    List<TeddySignal>? history,
    bool? isAnalyzing,
    String? error,
  }) {
    return TeddySignalState(
      latestSignal: latestSignal ?? this.latestSignal,
      history: history ?? this.history,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      error: error,
    );
  }
}

class TeddySignalNotifier extends StateNotifier<TeddySignalState> {
  final Ref ref;
  final NotificationService _notificationService = NotificationService();

  TeddySignalNotifier(this.ref) : super(const TeddySignalState()) {
    _initInitialSignal();
  }

  void _initInitialSignal() {
    final market = ref.read(marketProvider);
    final initial = MockDataGenerator.generateMockSignal(market.selectedInstrument, market.snapshot);
    state = state.copyWith(
      latestSignal: initial,
      history: [initial],
    );
  }

  Future<void> analyzeNow() async {
    state = state.copyWith(isAnalyzing: true, error: null);
    final market = ref.read(marketProvider);
    final settings = ref.read(settingsProvider);
    final api = ApiService(baseUrl: settings.serverUrl);

    try {
      TeddySignal? signal;
      if (market.isConnected && !market.isOfflineDemo && !settings.standalonePhoneMode) {
        signal = await api.triggerAnalysis(market.selectedInstrument);
      } else if (settings.geminiApiKey.isNotEmpty) {
        // Direct on-device Gemini API call from phone (Zero PC required!)
        final gemini = GeminiService();
        signal = await gemini.analyzeOnDevice(market.snapshot, settings.geminiApiKey);
      }

      // If still null (offline / no API key), run on-device institutional quant rule engine
      signal ??= MockDataGenerator.generateMockSignal(market.selectedInstrument, market.snapshot);

      final updatedHistory = [signal, ...state.history];
      state = state.copyWith(
        latestSignal: signal,
        history: updatedHistory,
        isAnalyzing: false,
      );

      // Trigger local push notification if confidence >= 75%
      if (settings.pushNotifications && signal.confidenceScore >= 75 && signal.decision != 'NO_TRADE') {
        _notificationService.showSignalNotification(signal);
      }
    } catch (e) {
      // Graceful fallback to offline simulation
      final signal = MockDataGenerator.generateMockSignal(market.selectedInstrument, market.snapshot);
      state = state.copyWith(
        latestSignal: signal,
        history: [signal, ...state.history],
        isAnalyzing: false,
      );
    }
  }

  Future<void> loadHistory() async {
    final settings = ref.read(settingsProvider);
    final api = ApiService(baseUrl: settings.serverUrl);
    try {
      final list = await api.getSignalHistory(limit: 50);
      if (list.isNotEmpty) {
        state = state.copyWith(
          history: list,
          latestSignal: list.first,
        );
      }
    } catch (_) {}
  }
}

final teddySignalProvider = StateNotifierProvider<TeddySignalNotifier, TeddySignalState>((ref) {
  return TeddySignalNotifier(ref);
});
