import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/market_snapshot.dart';
import '../network/api_service.dart';
import '../network/websocket_service.dart';
import '../services/mock_data_generator.dart';
import 'settings_provider.dart';

class MarketState {
  final String selectedInstrument;
  final MarketSnapshot snapshot;
  final bool isConnected;
  final bool isOfflineDemo;
  final bool isLoading;
  final String? errorMessage;

  const MarketState({
    required this.selectedInstrument,
    required this.snapshot,
    required this.isConnected,
    required this.isOfflineDemo,
    required this.isLoading,
    this.errorMessage,
  });

  MarketState copyWith({
    String? selectedInstrument,
    MarketSnapshot? snapshot,
    bool? isConnected,
    bool? isOfflineDemo,
    bool? isLoading,
    String? errorMessage,
  }) {
    return MarketState(
      selectedInstrument: selectedInstrument ?? this.selectedInstrument,
      snapshot: snapshot ?? this.snapshot,
      isConnected: isConnected ?? this.isConnected,
      isOfflineDemo: isOfflineDemo ?? this.isOfflineDemo,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class MarketNotifier extends StateNotifier<MarketState> {
  final Ref ref;
  ApiService? _api;
  WebSocketService? _ws;
  StreamSubscription? _wsSubscription;
  Timer? _mockTickTimer;

  MarketNotifier(this.ref)
      : super(MarketState(
          selectedInstrument: 'NIFTY 50',
          snapshot: MockDataGenerator.generateMockSnapshot('NIFTY 50'),
          isConnected: false,
          isOfflineDemo: true,
          isLoading: false,
        )) {
    _initServices();
  }

  void _initServices() {
    final settings = ref.read(settingsProvider);
    _api = ApiService(baseUrl: settings.serverUrl);
    _ws = WebSocketService(wsUrl: settings.wsUrl);

    _wsSubscription = _ws!.stream.listen((message) {
      _handleWebSocketMessage(message);
    });

    _ws!.connect();
    fetchSnapshot(state.selectedInstrument);

    // If still offline after 3 seconds, start mock demo ticks
    _startOfflineDemoTicks();
  }

  void _startOfflineDemoTicks() {
    _mockTickTimer?.cancel();
    _mockTickTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (state.isOfflineDemo) {
        // Increment demo data so chart stays alive
        final updated = MockDataGenerator.generateMockSnapshot(state.selectedInstrument);
        state = state.copyWith(snapshot: updated);
      }
    });
  }

  void _handleWebSocketMessage(Map<String, dynamic> msg) {
    final type = msg['type'] as String?;
    final inst = msg['instrument'] as String?;

    if (inst == state.selectedInstrument && (type == 'MARKET_UPDATE' || type == 'INITIAL_SNAPSHOT')) {
      final snapData = msg['data'] as Map<String, dynamic>?;
      if (snapData != null) {
        final snap = MarketSnapshot.fromJson(snapData);
        state = state.copyWith(
          snapshot: snap,
          isConnected: true,
          isOfflineDemo: false,
        );
      }
    }
  }

  Future<void> selectInstrument(String instrument) async {
    if (state.selectedInstrument == instrument) return;
    state = state.copyWith(
      selectedInstrument: instrument,
      isLoading: true,
    );
    _ws?.subscribe(instrument);
    await fetchSnapshot(instrument);
  }

  Future<void> fetchSnapshot(String instrument) async {
    try {
      if (_api != null) {
        final snap = await _api!.getSnapshot(instrument);
        state = state.copyWith(
          snapshot: snap,
          isConnected: true,
          isOfflineDemo: false,
          isLoading: false,
        );
        return;
      }
    } catch (e) {
      // Backend not running; activate offline demo fallback
      state = state.copyWith(
        snapshot: MockDataGenerator.generateMockSnapshot(instrument),
        isConnected: false,
        isOfflineDemo: true,
        isLoading: false,
      );
    }
  }

  void updateBackendUrl(String newUrl) {
    _api?.updateBaseUrl(newUrl);
    final settings = ref.read(settingsProvider);
    _ws?.updateWsUrl(settings.wsUrl);
    fetchSnapshot(state.selectedInstrument);
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _mockTickTimer?.cancel();
    _ws?.dispose();
    super.dispose();
  }
}

final marketProvider = StateNotifierProvider<MarketNotifier, MarketState>((ref) {
  return MarketNotifier(ref);
});
