/*
import 'dart:convert';
import 'dart:io';
import 'package:attendance_system_ios/model/VisitData/fetch_visit_data.dart';
import 'package:attendance_system_ios/service/auto_start_visit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../../main.dart';
import '../../../service/background_service.dart';
import '../Start Stop Visit/start_stop_visit.dart';

/// Service to manage visit reminders
class VisitReminderService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  /// Initialize notifications + alarm manager
  static Future<void> init() async {
    // Timezones
    tz.initializeTimeZones();

    // Android init
    const androidSettings = AndroidInitializationSettings('icon1');

    // iOS init
    // final iosSettings = DarwinInitializationSettings(
    //   requestAlertPermission: true,
    //   requestBadgePermission: true,
    //   requestSoundPermission: true,
    // );

    final initSettings = InitializationSettings(android: androidSettings, );

    await _notificationsPlugin.initialize(initSettings);

    if (Platform.isAndroid) {
      await AndroidAlarmManager.initialize();
    }
    print("✅ VisitReminderService initialized");
  }

  /// Schedule reminder 2 mins before the visit
  static Future<void> scheduleVisitReminder(
      DateTime visitStartTime, int visitId)
  async {
    final reminderTime = visitStartTime.subtract(const Duration(minutes: 2));

    if (reminderTime.isBefore(DateTime.now())) {
      print("⚠️ Reminder skipped (time already passed): $reminderTime");
      return;
    }

    // Save visit time in SharedPreferences for callback isolate
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("visit_$visitId", visitStartTime.toIso8601String());

    if (Platform.isAndroid) {
      await AndroidAlarmManager.oneShotAt(
        reminderTime,
        visitId,
        _alarmCallback, // must be top-level
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,    /// uncomment when runs the code
      );
      print("⏰ Android reminder set for $reminderTime (visit $visitId)");
    }
  }

  /// Schedule auto start for visit at exact time
  static Future<void> scheduleAutoStartVisit( DateTime visitStartTime, int visitId, Data visit) async {

    if (visitStartTime.isBefore(DateTime.now())) {
      print("⚠️ Auto-start skipped (time already passed): $visitStartTime");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final alarmId = visitId + 100000;
    await prefs.setString("autoStart_$alarmId", visitStartTime.toIso8601String());
    await storage.write(key: 'AutoStartVisit', value: jsonEncode(visit));

    if (Platform.isAndroid) {
      await AndroidAlarmManager.oneShotAt(
        visitStartTime,
        alarmId, // Different ID from reminder
        _autoStartVisitCallback,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
      );


      print("🚀 Auto-start scheduled for $visitStartTime (visit $visitId)");
    }
  }
}


/// 🔔 Alarm callback (runs in background isolate)
@pragma('vm:entry-point')
void _alarmCallback(int id) async {
  // Retrieve saved visit time
  final prefs = await SharedPreferences.getInstance();
  final visitIso = prefs.getString("visit_$id");
  final visitTime = visitIso != null ? DateTime.parse(visitIso) : null;

  final notificationsPlugin = FlutterLocalNotificationsPlugin();

  // Minimal initialization (works in background isolate)
  await notificationsPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('icon1'),
      iOS: DarwinInitializationSettings(),
    ),
  );

  final timeText = visitTime != null
      ? "${visitTime.hour}:${visitTime.minute.toString().padLeft(2, '0')}"
      : "soon";

  await notificationsPlugin.show(
    889,
    "Upcoming Visit",
    "You have a visit at $timeText",
    const NotificationDetails(
      android: AndroidNotificationDetails(
        "visit_channel",
        "Visit Reminders",
        channelDescription: "Reminders for upcoming visits",
        importance: Importance.max,
        priority: Priority.high,
        icon: 'icon1',
      ),
      // iOS: DarwinNotificationDetails(
      //   presentAlert: true,
      //   presentBadge: true,
      //   presentSound: true,
      // ),
    ),
  );

  print("🔔 Visit reminder notification triggered for visit $id at $timeText");
}

@pragma('vm:entry-point')
void _autoStartVisitCallback(int id) async {
  print("🚀 Auto-start alarm triggered for visit $id");

  final prefs = await SharedPreferences.getInstance();
  final visitIso = prefs.getString("autoStart_$id");
  final visitTime = visitIso != null ? DateTime.parse(visitIso) : null;

  // Initialize notification plugin (so we can notify user too)
  final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();
  await notificationsPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('icon1'),
    ),
  );

  // Show a notification confirming auto start
  await notificationsPlugin.show(
    889,
    "Visit Started Automatically",
    "Your visit scheduled at ${visitTime?.hour}:${visitTime?.minute.toString().padLeft(2, '0')} has started.",
    const NotificationDetails(
      android: AndroidNotificationDetails(
        "visit_auto_channel",
        "Auto Start Visits",
        channelDescription: "Automatically starts visits at scheduled times",
        importance: Importance.max,
        priority: Priority.high,
        icon: 'icon1',
      ),
    ),
  );

  // Call your visit start logic here
  // ⚠️ This runs in a background isolate, so cannot call widget methods directly.
  final visitJson = await storage.read(key: 'AutoStartVisit');
  if (visitJson == null) return;
  final Data visit = Data.fromJson(jsonDecode(visitJson));
  // await prefs.setBool("auto_started_$id", true);
  AutoStartVisit autoStartVisit = AutoStartVisit();
  autoStartVisit.startVisit(visit);

  print("✅ Auto start completed for visit $id at $visitTime");
  await prefs.remove('autoStart_$id');
}
*/











// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:timezone/timezone.dart' as tz;
// import 'package:timezone/data/latest.dart' as tz;
//
// // class VisitReminderService {
// //   final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
// //   FlutterLocalNotificationsPlugin();
// //
// //   VisitReminderService() {
// //     _initializeNotifications();
// //   }
// //
// //   void _initializeNotifications() {
// //     const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
// //     const iosInit = DarwinInitializationSettings();
// //
// //     const initSettings = InitializationSettings(
// //       android: androidInit,
// //       iOS: iosInit,
// //     );
// //
// //     _flutterLocalNotificationsPlugin.initialize(initSettings);
// //
// //     // init timezone
// //     tz.initializeTimeZones();
// //
// //     // ask for permission (Android 13+ and iOS)
// //     // _flutterLocalNotificationsPlugin
// //     //     .resolvePlatformSpecificImplementation<
// //     //     AndroidFlutterLocalNotificationsPlugin>()
// //     //     ?.requestPermission();
// //
// //     _flutterLocalNotificationsPlugin
// //         .resolvePlatformSpecificImplementation<
// //         IOSFlutterLocalNotificationsPlugin>()
// //         ?.requestPermissions(alert: true, badge: true, sound: true);
// //
// //     print("✅ Notifications initialized");
// //   }
// //
// //   Future<void> scheduleReminder(
// //
// //       String title, String body, DateTime visitTime) async {
// //     final reminderTime = visitTime.subtract(const Duration(minutes: 2));
// //
// //     if (reminderTime.isBefore(DateTime.now())) {
// //       print("⚠️ Reminder time already passed, skipping");
// //       return;
// //     }
// //     try{
// //     await _flutterLocalNotificationsPlugin.zonedSchedule(
// //       visitTime.millisecondsSinceEpoch ~/ 1000, // unique ID
// //       title,
// //       body,
// //       tz.TZDateTime.from(reminderTime, tz.local),
// //       const NotificationDetails(
// //         android: AndroidNotificationDetails(
// //           'visit_channel',
// //           'Visit Reminders',
// //           channelDescription: 'Reminders before scheduled visits',
// //           importance: Importance.max,
// //           priority: Priority.high,
// //         ),
// //         iOS: DarwinNotificationDetails(),
// //       ),
// //       androidAllowWhileIdle: true,
// //       uiLocalNotificationDateInterpretation:
// //       UILocalNotificationDateInterpretation.absoluteTime,
// //     );
// //
// //     print("✅ Reminder scheduled at $reminderTime for visit $visitTime");
// //   }catch(e){
// //       print("✅ Reminder scheduled at  catche $e");
// //     }
// //   }
// // }
//
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
// import 'package:timezone/data/latest.dart' as tz;
// import 'package:timezone/timezone.dart' as tz;
//
// // class VisitReminderService {
// //   final FlutterLocalNotificationsPlugin _notificationsPlugin =
// //   FlutterLocalNotificationsPlugin();
// //
// //   Future<void> init() async {
// //     // Initialize timezone
// //     tz.initializeTimeZones();
// //
// //     // Android
// //     const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
// //
// //     // iOS
// //     final iosSettings = DarwinInitializationSettings(
// //       requestAlertPermission: true,
// //       requestBadgePermission: true,
// //       requestSoundPermission: true,
// //     );
// //
// //     final initSettings = InitializationSettings(
// //       android: androidSettings,
// //       iOS: iosSettings,
// //     );
// //
// //     await _notificationsPlugin.initialize(initSettings);
// //
// //     if (Platform.isAndroid) {
// //       await AndroidAlarmManager.initialize();
// //     }
// //
// //     print("✅ VisitReminderService initialized");
// //   }
// //
// //   Future<void> scheduleVisitReminder(
// //       DateTime visitStartTime, int visitId) async {
// //     final reminderTime = visitStartTime.subtract(const Duration(minutes: 2));
// //
// //     if (reminderTime.isBefore(DateTime.now())) {
// //       print("⚠️ Reminder skipped (time already passed): $reminderTime");
// //       return;
// //     }
// //
// //     if (Platform.isAndroid) {
// //       await AndroidAlarmManager.oneShotAt(
// //         reminderTime,
// //         visitId,
// //         _alarmCallback,
// //         exact: true,
// //         wakeup: true,
// //         rescheduleOnReboot: true,
// //       );
// //       print("⏰ Android reminder set for $reminderTime (visit $visitId)");
// //     } else if (Platform.isIOS) {
// //       final tz.TZDateTime tzReminderTime =
// //       tz.TZDateTime.from(reminderTime, tz.local);
// //
// //       await _notificationsPlugin.zonedSchedule(
// //         visitId,
// //         "Upcoming Visit",
// //         "You have a visit at ${visitStartTime.hour}:${visitStartTime.minute}",
// //         tzReminderTime,
// //         const NotificationDetails(
// //           iOS: DarwinNotificationDetails(
// //             presentAlert: true,
// //             presentBadge: true,
// //             presentSound: true,
// //           ),
// //         ),
// //         androidAllowWhileIdle: true,
// //         uiLocalNotificationDateInterpretation:
// //         UILocalNotificationDateInterpretation.absoluteTime,
// //       );
// //       print("⏰ iOS reminder set for $reminderTime (visit $visitId)");
// //     }
// //   }
// // }
//
// class VisitReminderService {
//   final FlutterLocalNotificationsPlugin _notificationsPlugin =
//   FlutterLocalNotificationsPlugin();
//
//   // 🔹 Store visit times for lookup in callback
//   static final Map<int, DateTime> _scheduledVisits = {};
//
//   Future<void> init() async {
//     tz.initializeTimeZones();
//
//     const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
//     final iosSettings = DarwinInitializationSettings(
//       requestAlertPermission: true,
//       requestBadgePermission: true,
//       requestSoundPermission: true,
//     );
//
//     final initSettings = InitializationSettings(
//       android: androidSettings,
//       iOS: iosSettings,
//     );
//
//     await _notificationsPlugin.initialize(initSettings);
//
//     if (Platform.isAndroid) {
//       await AndroidAlarmManager.initialize();
//     }
//
//     print("✅ VisitReminderService initialized");
//   }
//
//   Future<void> scheduleVisitReminder(DateTime visitStartTime, int visitId) async {
//     final reminderTime = visitStartTime.subtract(const Duration(minutes: 2));
//
//     if (reminderTime.isBefore(DateTime.now())) {
//       print("⚠️ Reminder skipped (time already passed): $reminderTime");
//       return;
//     }
//
//     // 🔹 Save visit details for callback lookup
//     _scheduledVisits[visitId] = visitStartTime;
//
//     if (Platform.isAndroid) {
//       await AndroidAlarmManager.oneShotAt(
//         reminderTime,
//         visitId,
//         _alarmCallback,
//         exact: true,
//         wakeup: true,
//         rescheduleOnReboot: true,
//       );
//       print("⏰ Android reminder set for $reminderTime (visit $visitId)");
//     } else if (Platform.isIOS) {
//       final tz.TZDateTime tzReminderTime =
//       tz.TZDateTime.from(reminderTime, tz.local);
//
//       await _notificationsPlugin.zonedSchedule(
//         visitId,
//         "Upcoming Visit",
//         "You have a visit at ${visitStartTime.hour}:${visitStartTime.minute.toString().padLeft(2, '0')}",
//         tzReminderTime,
//         const NotificationDetails(
//           iOS: DarwinNotificationDetails(
//             presentAlert: true,
//             presentBadge: true,
//             presentSound: true,
//           ),
//         ),
//         androidAllowWhileIdle: true,
//         uiLocalNotificationDateInterpretation:
//         UILocalNotificationDateInterpretation.absoluteTime,
//       );
//       print("⏰ iOS reminder set for $reminderTime (visit $visitId)");
//     }
//   }
//
//   // 🔹 Helper to access stored visit times (from callback)
//   static DateTime? getVisitTime(int id) => _scheduledVisits[id];
// }
//
// ///
// /// Alarm callback for Android (runs in background isolate)
// ///
// //@pragma('vm:entry-point')
// //@pragma('vm:entry-point')
// @pragma('vm:entry-point')
// void _alarmCallback(int id) async {
//   final notificationsPlugin = FlutterLocalNotificationsPlugin();
//
//   const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
//   final iosSettings = DarwinInitializationSettings();
//
//   await notificationsPlugin.initialize(
//     InitializationSettings(
//       android: androidSettings,
//       iOS: iosSettings,
//     ),
//   );
//
//   // 🔹 Lookup visit time
//   final visitTime = VisitReminderService.getVisitTime(id);
//   final timeText = visitTime != null
//       ? "${visitTime.hour}:${visitTime.minute.toString().padLeft(2, '0')}"
//       : "soon";
//
//   await notificationsPlugin.show(
//     id,
//     "Upcoming Visit",
//     "You have a visit at $timeText",
//     const NotificationDetails(
//       android: AndroidNotificationDetails(
//         "visit_channel",
//         "Visit Reminders",
//         channelDescription: "Reminders for upcoming visits",
//         importance: Importance.max,
//         priority: Priority.high,
//         icon: '@mipmap/ic_launcher',
//       ),
//       iOS: DarwinNotificationDetails(
//         presentAlert: true,
//         presentBadge: true,
//         presentSound: true,
//       ),
//     ),
//   );
//
//   print("🔔 Visit reminder notification triggered for visit $id at $timeText");
// }
