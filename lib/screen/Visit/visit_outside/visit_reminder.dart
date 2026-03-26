// import 'dart:io';
// import 'dart:ui';
//
// import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:timezone/data/latest.dart' as tz;
// import 'package:timezone/timezone.dart' as tz;
//
// class VisitReminderScreen extends StatefulWidget {
//   const VisitReminderScreen({Key? key}) : super(key: key);
//
//   @override
//   State<VisitReminderScreen> createState() => _VisitReminderScreenState();
// }
// class _VisitReminderScreenState extends State<VisitReminderScreen> {
//   TimeOfDay? _visitTime;
//   final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
//   FlutterLocalNotificationsPlugin();
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeNotifications();
//   }
//
//   void _initializeNotifications() async {
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
//     await _flutterLocalNotificationsPlugin.initialize(initSettings);
//     tz.initializeTimeZones();
//   }
//
//   void _pickVisitTime() async {
//     TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: TimeOfDay.now(),
//     );
//
//     if (picked != null) {
//       setState(() {
//         _visitTime = picked;
//       });
//     }
//   }
//
//   /// Schedule reminder 5 minutes before the visit
//   Future<void> scheduleReminder(TimeOfDay visitTime, int id, String visitReason) async {
//     // Subtract 5 minutes
//     final adjustedTime = _subtractFiveMinutes(visitTime);
//
//     // Convert to tz.TZDateTime
//     final scheduledTime = _nextInstanceOfTime(adjustedTime);
//
//     await _flutterLocalNotificationsPlugin.zonedSchedule(
//       id, // use visit.srno in real case
//       'Visit Reminder',
//       'Upcoming visit: $visitReason',
//       scheduledTime,
//       const NotificationDetails(
//         android: AndroidNotificationDetails(
//           'visit_channel',
//           'Visit Reminders',
//           channelDescription: 'Reminders for upcoming visits',
//           importance: Importance.max,
//           priority: Priority.high,
//         ),
//         iOS: DarwinNotificationDetails(),
//       ),
//       androidAllowWhileIdle: true,
//       uiLocalNotificationDateInterpretation:
//       UILocalNotificationDateInterpretation.absoluteTime,
//       matchDateTimeComponents: DateTimeComponents.dateAndTime,
//     );
//   }
//
//   Future<void> _cancelVisitReminder(int id) async {
//     await _flutterLocalNotificationsPlugin.cancel(id);
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Visit reminder with ID $id cancelled')),
//     );
//   }
//
//   /// Utility → subtract 5 minutes from given TimeOfDay
//   TimeOfDay _subtractFiveMinutes(TimeOfDay time) {
//     final now = DateTime.now();
//     final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
//     final newDt = dt.subtract(const Duration(minutes: 5));
//     return TimeOfDay(hour: newDt.hour, minute: newDt.minute);
//   }
//
//   tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
//     final tz.Location localTz = tz.getLocation('Asia/Kolkata');
//     final now = tz.TZDateTime.now(localTz);
//
//     var scheduled = tz.TZDateTime(
//       localTz,
//       now.year,
//       now.month,
//       now.day,
//       time.hour,
//       time.minute,
//     );
//
//     if (scheduled.isBefore(now)) {
//       scheduled = scheduled.add(const Duration(days: 1));
//     }
//
//     return scheduled;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Visit Reminder')),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             Card(
//               color: Colors.blue.shade50,
//               child: Column(
//                 children: [
//                   ListTile(
//                     title: Text(
//                       _visitTime != null
//                           ? 'Visit Time: ${_visitTime!.format(context)}'
//                           : 'No Visit Time Selected',
//                       style: TextStyle(color: Colors.blue),
//                     ),
//                     trailing: ElevatedButton(
//                       onPressed: _pickVisitTime,
//                       style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.blue),
//                       child: const Text('Pick'),
//                     ),
//                   ),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     children: [
//                       ElevatedButton(
//                         onPressed: _visitTime != null
//                             ? () => scheduleReminder(_visitTime!, 2001, "Client Meeting")
//                             : null,
//                         style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.blue),
//                         child: const Text('Set Reminder'),
//                       ),
//                       ElevatedButton(
//                         onPressed: () => _cancelVisitReminder(2001),
//                         style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.grey),
//                         child: const Text('Delete'),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
// @pragma('vm:entry-point')
// void alarmCallback() async {
//   final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
//
//   const AndroidInitializationSettings androidSettings =
//   AndroidInitializationSettings('@mipmap/ic_launcher');
//   const iosSettings = DarwinInitializationSettings();
//
//   await flutterLocalNotificationsPlugin.initialize(
//     InitializationSettings(android: androidSettings, iOS: iosSettings),
//   );
//
//   await flutterLocalNotificationsPlugin.show(
//     2001,
//     'VISIT REMINDER',
//     'It’s time to start your scheduled visit!',
//     const NotificationDetails(
//       android: AndroidNotificationDetails(
//         'visit_channel',
//         'Visit Channel',
//         importance: Importance.max,
//         priority: Priority.high,
//         icon: '@mipmap/ic_launcher',
//       ),
//       iOS: DarwinNotificationDetails(
//         presentAlert: true,
//         presentBadge: true,
//         presentSound: true,
//         sound: 'default',
//       ),
//     ),
//   );
// }