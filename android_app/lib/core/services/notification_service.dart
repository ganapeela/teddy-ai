import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/teddy_signal.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    try {
      await _notifications.initialize(initSettings);
      _initialized = true;
    } catch (e) {
      // Graceful fallback for web/desktop or pre-init environments
      print('Notification init error: $e');
    }
  }

  Future<void> showSignalNotification(TeddySignal signal) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'teddy_ai_signals',
      'Teddy AI Signals',
      channelDescription: 'High-confidence institutional F&O option signals',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      playSound: true,
      enableVibration: true,
    );

    const platformDetails = NotificationDetails(android: androidDetails);

    final title = '🚨 Teddy AI: ${signal.decision} (${signal.confidenceScore}%)';
    final body = signal.decision == 'NO_TRADE'
        ? '${signal.instrument}: Standing Aside (${signal.setupType})'
        : '${signal.recommendedStrike ?? signal.instrument} | R:R ${signal.riskReward} | Entry: ₹${signal.optionEntryZone?[0] ?? '-'}';

    try {
      await _notifications.show(
        signal.id ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        const NotificationDetails(android: androidDetails),
      );
    } catch (e) {
      print('Could not display local notification: $e');
    }
  }
}
