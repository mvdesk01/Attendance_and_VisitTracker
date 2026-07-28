// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  NotificationService(
      this.flutterLocalNotificationsPlugin,
      );

  Future<void> createChannel( AndroidNotificationChannel notificationChannel ) async {
    return await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(notificationChannel);
  }

  void foregroundNotificationTap(NotificationResponse details) {
    print("*******************LOCAL FOREGROUND RECEIVED 1********************");
  }

  @pragma('vm:entry-point')
  static void backgroundNotificationTap(NotificationResponse details) {
    print("*******************LOCAL BACKGROUND RECEIVED 2********************");
  }

  Future initialize(BuildContext context) async {
    AndroidInitializationSettings androidInitializationSettings =
    const AndroidInitializationSettings(
        "@mipmap/ic_launcher"); //'@mipmap/ic_launcher'

    DarwinInitializationSettings darwinInitializationSettings =
    const DarwinInitializationSettings();

    final InitializationSettings initializationSettings =
    InitializationSettings(
      android: androidInitializationSettings,
      iOS: darwinInitializationSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: foregroundNotificationTap,
      onDidReceiveBackgroundNotificationResponse: backgroundNotificationTap,
    );
  }

  Future showNotification({
    int showNotificationId = 0,
    required AndroidNotificationDetails androidNotificationDetails,
    //
    String? title,
    String? body,
    String? payload,
  }) async {
    //Demo
    //  var androidPlatformChannelSpecifics = AndroidNotificationDetails(
    //   channelId,
    //   channelName,
    //   channelDescription: channelDescription,
    //   playSound: false,
    //   importance: Importance.max,
    //   priority: Priority.high,
    // );

    var platformChannelSpecifics = NotificationDetails(android: androidNotificationDetails);

    await flutterLocalNotificationsPlugin.show(
      showNotificationId,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }
}







// import 'package:flutter/cupertino.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:timezone/data/latest.dart' as tz;
// import 'package:timezone/timezone.dart' as tz;
//
// class NotificationService {
//   final FlutterLocalNotificationsPlugin notificationPlugin =
//   FlutterLocalNotificationsPlugin();
//
//   NotificationService() {
//     _initializeTimeZone();
//   }
//
//   /// Initialize timezone data
//   void _initializeTimeZone() {
//     tz.initializeTimeZones();
//   }
//
//   /// Initialize notifications
//   Future<void> initNotification() async {
//     const AndroidInitializationSettings initializationSettingsAndroid =
//     AndroidInitializationSettings('logonotify');
//
//     final DarwinInitializationSettings initializationSettingsIOS =
//     DarwinInitializationSettings(
//       requestAlertPermission: true,
//       requestBadgePermission: true,
//       requestSoundPermission: true,
//     );
//
//     final InitializationSettings initializationSettings = InitializationSettings(
//       android: initializationSettingsAndroid,
//       iOS: initializationSettingsIOS,
//     );
//
//     await notificationPlugin.initialize(
//       initializationSettings,
//       onDidReceiveNotificationResponse: (NotificationResponse response) async {
//         debugPrint('Notification clicked with payload: ${response.payload}');
//       },
//     );
//   }
//
//   /// Notification details
//   NotificationDetails _notificationDetails() {
//     return const NotificationDetails(
//       android: AndroidNotificationDetails(
//         'channelId',
//         'channelName',
//         importance: Importance.max,
//         priority: Priority.high,
//       ),
//       iOS: DarwinNotificationDetails(),
//     );
//   }
//
//   /// Show immediate notification
//   Future<void> showNotification({
//     int id = 0,
//     String? title,
//     String? body,
//     String? payload,
//   }) async {
//     await notificationPlugin.show(
//       id,
//       title,
//       body,
//       _notificationDetails(),
//       payload: payload,
//     );
//   }
//
//   /// Schedule notification
//   Future<void> scheduleNotification({
//     int id = 0,
//     String? title,
//     String? body,
//     String? payload,
//     required DateTime scheduledNotificationDateTime,
//   }) async {
//     await notificationPlugin.zonedSchedule(
//       id,
//       title,
//       body,
//       tz.TZDateTime.from(scheduledNotificationDateTime, tz.local),
//       _notificationDetails(),
//       androidAllowWhileIdle: true,
//       uiLocalNotificationDateInterpretation:
//       UILocalNotificationDateInterpretation.absoluteTime,
//     );
//   }
// }
