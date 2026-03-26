import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class GlobalBatteryMonitor {
  static final Battery _battery = Battery();
  static Timer? _batteryTimer;
  static bool _lowBatteryNotified = false;

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> initializeNotifications() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);
  }

  static void startMonitoring() {
    _batteryTimer ??= Timer.periodic(const Duration(minutes: 5), (timer) async {
      final int level = await _battery.batteryLevel;
      final BatteryState state = await _battery.batteryState;

      debugPrint("Global Battery Level: $level% | State: $state");

      // Skip notification if charging or full
      if (state == BatteryState.charging || state == BatteryState.full) {
        _lowBatteryNotified = false; // Reset flag when charging
        return;
      }

      if (level < 20 && !_lowBatteryNotified) {
        _lowBatteryNotified = true;
        await _showLowBatteryNotification();
      }

      if (level > 21) {
        _lowBatteryNotified = false;
      }
    });
  }

  static void stopMonitoring() {
    _batteryTimer?.cancel();
    _batteryTimer = null;
    _lowBatteryNotified = false;
  }

  static Future<void> _showLowBatteryNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'battery_channel',
      'Battery Monitoring',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      100,
      'Low Battery',
      'Battery is below 20%. Tracking may stop unexpectedly.',
      platformDetails,
    );
  }
}
