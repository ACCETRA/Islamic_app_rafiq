import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static const String _prefsKey = 'prayer_notifications_enabled';

  // Prayer notification IDs
  static const int fajrId = 1;
  static const int dhuhrId = 2;
  static const int asrId = 3;
  static const int maghribId = 4;
  static const int ishaId = 5;

  static Future<void> init() async {
    if (_initialized || kIsWeb) return;

    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _initialized = true;
  }

  static void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap - navigate to prayer screen
    debugPrint('Notification tapped: ${response.payload}');
  }

  static Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    final ios = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return false;
  }

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? false;
  }

  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, enabled);

    if (!enabled) {
      await cancelAllPrayerNotifications();
    }
  }

  static Future<void> schedulePrayerNotifications({
    required DateTime fajr,
    required DateTime dhuhr,
    required DateTime asr,
    required DateTime maghrib,
    required DateTime isha,
  }) async {
    if (kIsWeb) return;
    if (!await isEnabled()) return;

    await _scheduleNotification(
      id: fajrId,
      title: '🌙 Fajr Prayer',
      body: 'Time for Fajr prayer. Start your day with remembrance of Allah.',
      scheduledTime: fajr,
      payload: 'fajr',
    );

    await _scheduleNotification(
      id: dhuhrId,
      title: '☀️ Dhuhr Prayer',
      body: 'Time for Dhuhr prayer. Take a break and connect with Allah.',
      scheduledTime: dhuhr,
      payload: 'dhuhr',
    );

    await _scheduleNotification(
      id: asrId,
      title: '🌤️ Asr Prayer',
      body: 'Time for Asr prayer. The middle prayer of the day.',
      scheduledTime: asr,
      payload: 'asr',
    );

    await _scheduleNotification(
      id: maghribId,
      title: '🌅 Maghrib Prayer',
      body: 'Time for Maghrib prayer. The sun has set.',
      scheduledTime: maghrib,
      payload: 'maghrib',
    );

    await _scheduleNotification(
      id: ishaId,
      title: '🌙 Isha Prayer',
      body: 'Time for Isha prayer. End your day with prayer.',
      scheduledTime: isha,
      payload: 'isha',
    );
  }

  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String payload,
  }) async {
    // Only schedule if the time is in the future
    if (scheduledTime.isBefore(DateTime.now())) return;

    final androidDetails = AndroidNotificationDetails(
      'prayer_channel',
      'Prayer Notifications',
      channelDescription: 'Notifications for prayer times',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  static Future<void> cancelAllPrayerNotifications() async {
    if (kIsWeb) return;

    await _notifications.cancel(fajrId);
    await _notifications.cancel(dhuhrId);
    await _notifications.cancel(asrId);
    await _notifications.cancel(maghribId);
    await _notifications.cancel(ishaId);
  }

  static Future<void> cancelNotification(int id) async {
    if (kIsWeb) return;
    await _notifications.cancel(id);
  }

  // Test notification
  static Future<void> showTestNotification() async {
    if (kIsWeb) return;

    const androidDetails = AndroidNotificationDetails(
      'prayer_channel',
      'Prayer Notifications',
      channelDescription: 'Notifications for prayer times',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      0,
      '🕌 Test Notification',
      'Prayer notifications are working!',
      details,
    );
  }
}
