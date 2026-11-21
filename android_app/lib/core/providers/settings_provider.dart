import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsState {
  final String serverUrl;
  final String feedMode; // "REPLAY" or "LIVE"
  final bool autoAnalyze;
  final bool pushNotifications;
  final String geminiApiKey;
  final bool standalonePhoneMode;

  const SettingsState({
    required this.serverUrl,
    required this.feedMode,
    required this.autoAnalyze,
    required this.pushNotifications,
    this.geminiApiKey = '',
    this.standalonePhoneMode = true,
  });

  String get wsUrl {
    final uri = Uri.parse(serverUrl);
    final wsScheme = uri.scheme == 'https' ? 'wss' : 'ws';
    return '$wsScheme://${uri.host}:${uri.port}/ws';
  }

  SettingsState copyWith({
    String? serverUrl,
    String? feedMode,
    bool? autoAnalyze,
    bool? pushNotifications,
    String? geminiApiKey,
    bool? standalonePhoneMode,
  }) {
    return SettingsState(
      serverUrl: serverUrl ?? this.serverUrl,
      feedMode: feedMode ?? this.feedMode,
      autoAnalyze: autoAnalyze ?? this.autoAnalyze,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      standalonePhoneMode: standalonePhoneMode ?? this.standalonePhoneMode,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier()
      : super(const SettingsState(
          serverUrl: 'http://10.0.2.2:8000',
          feedMode: 'REPLAY',
          autoAnalyze: false,
          pushNotifications: true,
          geminiApiKey: '',
          standalonePhoneMode: true,
        ));

  void setServerUrl(String url) {
    state = state.copyWith(serverUrl: url.trim());
  }

  void setFeedMode(String mode) {
    state = state.copyWith(feedMode: mode);
  }

  void toggleAutoAnalyze(bool val) {
    state = state.copyWith(autoAnalyze: val);
  }

  void togglePushNotifications(bool val) {
    state = state.copyWith(pushNotifications: val);
  }

  void setGeminiApiKey(String key) {
    state = state.copyWith(geminiApiKey: key.trim());
  }

  void toggleStandalonePhoneMode(bool val) {
    state = state.copyWith(standalonePhoneMode: val);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
