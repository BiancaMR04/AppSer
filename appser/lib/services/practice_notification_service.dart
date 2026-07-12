import 'dart:async';

import 'package:appser/core/constants/session_defaults.dart';
import 'package:appser/presentation/controllers/home_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class PracticeNotificationService {
  PracticeNotificationService({required HomeController homeController})
      : _homeController = homeController;

  final HomeController _homeController;
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const int _dailyReminderId = 7101;
  static const int _reminderHour = 8;
  static const int _reminderMinute = 0;
  static const String _channelId = 'weekly_practice_reminders';
  static const String _channelName = 'Lembretes de pratica';
  static const String _channelDescription =
      'Lembretes diarios para realizar a sessao liberada do protocolo.';

  bool _initialized = false;
  bool _timezoneReady = false;

  Future<void> initialize() async {
    if (_initialized) return;

    await _configureTimezone();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
    _initialized = true;
  }

  Future<void> requestPermissionAndScheduleDailyReminder() async {
    if (kIsWeb) return;

    try {
      await initialize();

      final granted = await _requestNotificationPermission();
      if (!granted) {
        await cancelDailyReminder();
        return;
      }

      final status = await _homeController.fetchSessionStatus();
      final sessionNumber = _latestUnlockedProtocolSession(status);
      if (sessionNumber == null) {
        await cancelDailyReminder();
        return;
      }

      await scheduleDailyReminderForSession(sessionNumber);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Notificacoes: erro ao agendar lembrete: $e');
      }
    }
  }

  Future<void> cancelDailyReminder() async {
    try {
      await initialize();
      await _notifications.cancel(_dailyReminderId);
    } catch (_) {
      // Best-effort.
    }
  }

  Future<bool> _requestNotificationPermission() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final androidGranted = await android?.requestNotificationsPermission();

    final ios = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final iosGranted = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    return androidGranted ?? iosGranted ?? true;
  }

  Future<void> scheduleDailyReminderForSession(int sessionNumber) async {
    await initialize();

    final content = _contentForSession(sessionNumber);
    final nextMorning = _nextMorning();

    await _notifications.cancel(_dailyReminderId);
    await _notifications.zonedSchedule(
      _dailyReminderId,
      content.title,
      content.body,
      nextMorning,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          category: AndroidNotificationCategory.reminder,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'session_$sessionNumber',
    );
  }

  int? _latestUnlockedProtocolSession(Map<String, bool> status) {
    for (var i = SessionDefaults.totalSessions - 1; i >= 1; i--) {
      if (status['session$i'] == true) return i;
    }
    return null;
  }

  ({String title, String body}) _contentForSession(int sessionNumber) {
    final messages = <String>[
      'Nao esqueca de fazer suas praticas semanais.',
      'Lembre-se de realizar a sessao $sessionNumber do protocolo.',
      'Um pequeno momento de pratica pode cuidar bem do seu dia.',
      'Sua sessao $sessionNumber ja esta te esperando.',
    ];

    final index = sessionNumber % messages.length;
    return (
      title: '🌱 App Ser',
      body: '${messages[index]} 💛',
    );
  }

  Future<void> _configureTimezone() async {
    if (_timezoneReady) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));

    _timezoneReady = true;
  }

  tz.TZDateTime _nextMorning() {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      _reminderHour,
      _reminderMinute,
    );

    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }
}
