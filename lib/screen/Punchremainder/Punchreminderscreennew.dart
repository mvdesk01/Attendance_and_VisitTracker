import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:workmanager/workmanager.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({Key? key}) : super(key: key);

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> with WidgetsBindingObserver {
  ReminderSettings? _punchInReminder;
  ReminderSettings? _punchOutReminder;

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Timer? _cleanupTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeNotifications();
    _loadReminderSettings().then((_) {
      _checkAndCleanExpiredReminders();
    });

    _cleanupTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        _checkAndCleanExpiredReminders();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadReminderSettings().then((_) {
        _checkAndCleanExpiredReminders();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanupTimer?.cancel();
    super.dispose();
  }

  void _initializeNotifications() async {
    tz.initializeTimeZones();
    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final initSettings =
    InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  void _checkAndCleanExpiredReminders() {
    final now = DateTime.now();
    bool needsRefresh = false;

    if (_punchInReminder != null &&
        !_punchInReminder!.isDaily &&
        _punchInReminder!.hasReminder) {
      final reminderTime = DateTime(now.year, now.month, now.day,
          _punchInReminder!.time.hour, _punchInReminder!.time.minute);
      if (now.isAfter(reminderTime)) {
        setState(() => _punchInReminder = null);
        _clearReminderSettings('punch_in');
        needsRefresh = true;
      }
    }

    if (_punchOutReminder != null &&
        !_punchOutReminder!.isDaily &&
        _punchOutReminder!.hasReminder) {
      final reminderTime = DateTime(now.year, now.month, now.day,
          _punchOutReminder!.time.hour, _punchOutReminder!.time.minute);
      if (now.isAfter(reminderTime)) {
        setState(() => _punchOutReminder = null);
        _clearReminderSettings('punch_out');
        needsRefresh = true;
      }
    }
  }

  Future<void> _loadReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _punchInReminder = _getSettingsFromPrefs(prefs, 'punch_in', 1001);
    _punchOutReminder = _getSettingsFromPrefs(prefs, 'punch_out', 1002);
    setState(() {});
  }

  ReminderSettings? _getSettingsFromPrefs(
      SharedPreferences prefs, String type, int defaultId) {
    final hasReminder = prefs.getBool('${type}_has_reminder') ?? false;
    if (hasReminder) {
      final hour = prefs.getInt('${type}_hour');
      final minute = prefs.getInt('${type}_minute');
      if (hour != null && minute != null) {
        return ReminderSettings(
          time: TimeOfDay(hour: hour, minute: minute),
          isDaily: prefs.getBool('${type}_is_daily') ?? false,
          alarmId: prefs.getInt('${type}_alarm_id') ?? defaultId,
          hasReminder: true,
        );
      }
    }
    return null;
  }

  Future<void> _saveReminderSettings(
      String type, ReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${type}_hour', settings.time.hour);
    await prefs.setInt('${type}_minute', settings.time.minute);
    await prefs.setBool('${type}_is_daily', settings.isDaily);
    await prefs.setInt('${type}_alarm_id', settings.alarmId);
    await prefs.setBool('${type}_has_reminder', true);
  }

  Future<void> _clearReminderSettings(String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${type}_has_reminder', false);
  }

  void _pickTime(String type) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        final newReminder = ReminderSettings(
          time: picked,
          isDaily: false,
          alarmId: type == 'punch_in' ? 1001 : 1002,
          hasReminder: false, // UI updates time, but buttons aren't grey yet
        );

        if (type == 'punch_in') {
          _punchInReminder = newReminder;
        } else {
          _punchOutReminder = newReminder;
        }
      });
    }
  }

  Future<void> _scheduleReminder(String type, bool isDaily) async {
    ReminderSettings? reminder =
    type == 'punch_in' ? _punchInReminder : _punchOutReminder;

    if (reminder == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please pick a time first')));
      return;
    }

    try {
      final now = DateTime.now();
      DateTime scheduledDateTime = DateTime(now.year, now.month, now.day,
          reminder.time.hour, reminder.time.minute);
      if (scheduledDateTime.isBefore(now))
        scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));

      final initialDelay = scheduledDateTime.difference(now);
      final workId = '${type}_reminder_${reminder.alarmId}';

      if (isDaily) {
        await Workmanager().registerOneOffTask(
          '${workId}_daily',
          'punch_reminder_daily',
          initialDelay: initialDelay,
          inputData: {
            'alarmId': reminder.alarmId,
            'type': type,
            'isDaily': true,
            'hour': reminder.time.hour,
            'minute': reminder.time.minute
          },
          existingWorkPolicy: ExistingWorkPolicy.replace,
        );
      } else {
        await Workmanager().registerOneOffTask(
          workId,
          'punch_reminder',
          initialDelay: initialDelay,
          inputData: {
            'alarmId': reminder.alarmId,
            'type': type,
            'isDaily': false
          },
          existingWorkPolicy: ExistingWorkPolicy.replace,
        );
      }

      final updatedReminder = ReminderSettings(
        time: reminder.time,
        isDaily: isDaily,
        alarmId: reminder.alarmId,
        hasReminder: true,
      );

      setState(() {
        if (type == 'punch_in')
          _punchInReminder = updatedReminder;
        else
          _punchOutReminder = updatedReminder;
      });

      await _saveReminderSettings(type, updatedReminder);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${isDaily ? "Daily" : "Once"} reminder set!')));
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _cancelReminder(String type) async {
    try {
      int alarmId = type == 'punch_in' ? 1001 : 1002;
      await Workmanager().cancelByUniqueName('${type}_reminder_$alarmId');
      await Workmanager()
          .cancelByUniqueName('${type}_reminder_${alarmId}_daily');
      await _flutterLocalNotificationsPlugin.cancel(alarmId);

      setState(() {
        if (type == 'punch_in')
          _punchInReminder = null;
        else
          _punchOutReminder = null;
      });
      await _clearReminderSettings(type);
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Reminders',
            style:
            TextStyle(fontWeight: FontWeight.w800, color: Colors.black87)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildPunchCard(
              title: "Punch In",
              reminder: _punchInReminder,
              icon: Icons.login_rounded,
              color: Colors.indigo,
              type: 'punch_in',
            ),
            const SizedBox(height: 20),
            _buildPunchCard(
              title: "Punch Out",
              reminder: _punchOutReminder,
              icon: Icons.logout_rounded,
              color: Colors.deepOrange,
              type: 'punch_out',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPunchCard({
    required String title,
    required ReminderSettings? reminder,
    required IconData icon,
    required Color color,
    required String type,
  }) {
    final bool isScheduled = reminder != null && reminder.hasReminder;
    final bool hasTimePicked = reminder != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 15),
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (isScheduled)
                Chip(
                  label: Text(reminder.isDaily ? "Daily" : "Once",
                      style:
                      const TextStyle(fontSize: 10, color: Colors.white)),
                  backgroundColor: color,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1),
          ),
          Text(
            hasTimePicked ? reminder.time.format(context) : "No time selected",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w300,
              color: hasTimePicked ? Colors.black87 : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _actionBtn("Time", Icons.timer_outlined, Colors.grey[800]!,
                      () => _pickTime(type)),
              _actionBtn("Once", Icons.event_available, Colors.green,
                  isScheduled ? null : () => _scheduleReminder(type, false)),
              _actionBtn("Daily", Icons.update, Colors.blue,
                  isScheduled ? null : () => _scheduleReminder(type, true)),
              _actionBtn("Clear", Icons.delete_sweep_outlined, Colors.red,
                  isScheduled ? () => _cancelReminder(type) : null),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(
      String label, IconData icon, Color color, VoidCallback? onTap) {
    bool isDisabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: isDisabled ? 0.3 : 1.0,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDisabled ? Colors.grey[200] : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
              Icon(icon, color: isDisabled ? Colors.grey : color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: isDisabled ? Colors.grey : Colors.black87,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    print('WorkManager task triggered: $taskName');

    if (taskName == 'punch_reminder') {
      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      final DarwinInitializationSettings iosSettings =
      DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      await flutterLocalNotificationsPlugin.initialize(
        InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        ),
      );

      final type = inputData?['type'] ?? 'punch';
      final isDaily = inputData?['isDaily'] ?? false;
      final title =
      type == 'punch_in' ? 'PUNCH IN REMINDER' : 'PUNCH OUT REMINDER';
      final body =
      type == 'punch_in' ? 'Time to punch in!' : 'Time to punch out!';

      await flutterLocalNotificationsPlugin.show(
        inputData?['alarmId'] ?? 0,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'punch_channel',
            'Punch Reminders',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
          ),
        ),
      );

      // If it's a one-time reminder, clear it after showing
      if (!isDaily) {
        final prefs = await SharedPreferences.getInstance();
        if (type == 'punch_in') {
          await prefs.remove('punch_in_hour');
          await prefs.remove('punch_in_minute');
          await prefs.remove('punch_in_is_daily');
          await prefs.remove('punch_in_alarm_id');
          await prefs.setBool('punch_in_has_reminder', false);
        } else {
          await prefs.remove('punch_out_hour');
          await prefs.remove('punch_out_minute');
          await prefs.remove('punch_out_is_daily');
          await prefs.remove('punch_out_alarm_id');
          await prefs.setBool('punch_out_has_reminder', false);
        }

        // Add this to refresh UI when app comes to foreground
        // Using WorkManager's native way to trigger UI update
        print('One-time reminder cleared after showing');
      }

      print('Reminder shown for $type');
    }
    if (taskName == 'punch_reminder_daily') {
      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      final DarwinInitializationSettings iosSettings =
      DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      await flutterLocalNotificationsPlugin.initialize(
        InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        ),
      );

      final type = inputData?['type'] ?? 'punch_in';
      final alarmId = inputData?['alarmId'] ?? 0;
      final hour = inputData?['hour'] ?? 9;
      final minute = inputData?['minute'] ?? 0;
      final isDaily = inputData?['isDaily'] ?? false;

      final title =
      type == 'punch_in' ? 'PUNCH IN REMINDER' : 'PUNCH OUT REMINDER';
      final body =
      type == 'punch_in' ? 'Time to punch in!' : 'Time to punch out!';

      // Show notification
      await flutterLocalNotificationsPlugin.show(
        alarmId,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'punch_channel',
            'Punch Reminders',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
          ),
        ),
      );

      // RESCHEDULE FOR TOMORROW if it's daily
      if (isDaily) {
        final now = DateTime.now();
        DateTime tomorrowScheduled = DateTime(
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        ).add(const Duration(days: 1));

        final delay = tomorrowScheduled.difference(now);
        final workId = '${type}_daily_reminder_$alarmId';

        await Workmanager().registerOneOffTask(
          workId,
          'punch_reminder_daily',
          initialDelay: delay,
          inputData: {
            'alarmId': alarmId,
            'type': type,
            'isDaily': true,
            'hour': hour,
            'minute': minute,
          },
          existingWorkPolicy: ExistingWorkPolicy.replace,
        );

        print('Rescheduled daily reminder for tomorrow at $tomorrowScheduled');
      }

      print('Reminder shown for $type');
    }
    if (taskName == 'subscription_expiry_reminder') {

      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      final DarwinInitializationSettings iosSettings =
      DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      await flutterLocalNotificationsPlugin.initialize(
        InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        ),
      );

      await flutterLocalNotificationsPlugin.show(
        7001,
        'Subscription Expiring Soon',
        'Your subscription will expire in 2 days. Renew now to continue using Attendance & Visit Tracking.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'subscription_channel',
            'Subscription Reminder',
            channelDescription: 'Subscription expiry reminders',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    }


    return Future.value(true);
  });
}

class ReminderSettings {
  final TimeOfDay time;
  final bool isDaily;
  final int alarmId;
  final bool hasReminder; // Changed from isActive to hasReminder

  ReminderSettings({
    required this.time,
    required this.isDaily,
    required this.alarmId,
    this.hasReminder = true,
  });

  Map<String, dynamic> toJson() => {
    'hour': time.hour,
    'minute': time.minute,
    'isDaily': isDaily,
    'alarmId': alarmId,
    'hasReminder': hasReminder,
  };

  factory ReminderSettings.fromJson(Map<String, dynamic> json) {
    return ReminderSettings(
      time: TimeOfDay(hour: json['hour'], minute: json['minute']),
      isDaily: json['isDaily'],
      alarmId: json['alarmId'],
      hasReminder: json['hasReminder'] ?? true,
    );
  }
}

///android alarm manager
// class _AlarmScreenState extends State<AlarmScreen> {
//   TimeOfDay? _punchInTime;
//   TimeOfDay? _punchOutTime;
//   final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();
//
//   @override
//   void initState() {
//     super.initState();
//     _requestExactAlarmPermission();
//     _initializeNotifications();
//   }
//
//   Future<void> _requestExactAlarmPermission() async {
//     if (Platform.isAndroid && await Permission.scheduleExactAlarm.isDenied) {
//       final status = await Permission.scheduleExactAlarm.request();
//       if (!status.isGranted) {
//         print("Exact alarm permission denied");
//       }
//     }
//   }
//
//   void _initializeNotifications() async {
//     const androidSettings =
//         AndroidInitializationSettings('@mipmap/ic_launcher');
//     // final iosSettings = DarwinInitializationSettings(
//     //   onDidReceiveLocalNotification: (id, title, body, payload) async {
//     //     print("iOS local notification received: $title");
//     //   },
//     // );
//     final iosSettings = DarwinInitializationSettings(
//       requestAlertPermission: true,
//       requestBadgePermission: true,
//       requestSoundPermission: true,
//       onDidReceiveLocalNotification: (id, title, body, payload) async {
//         // Handle notification when app is in foreground
//         showDialog(
//           context: context,
//           builder: (BuildContext context) => AlertDialog(
//             title: Text(title ?? 'Notification'),
//             content: Text(body ?? 'No message'),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.of(context).pop(),
//                 child: const Text('OK'),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//
//     final initSettings = InitializationSettings(
//       android: androidSettings,
//       iOS: iosSettings,
//     );
//
//     await _flutterLocalNotificationsPlugin.initialize(initSettings);
//
//     final iosPlugin =
//         _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
//             IOSFlutterLocalNotificationsPlugin>();
//
//     if (iosPlugin != null) {
//       final granted = await iosPlugin.requestPermissions(
//         alert: true,
//         badge: true,
//         sound: true,
//       );
//       print('Notification permission granted: $granted');
//     }
//
//     tz.initializeTimeZones();
//   }
//
//   void _pickTime(bool isPunchIn) async {
//     TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: TimeOfDay.now(),
//     );
//     if (picked != null) {
//       setState(() {
//         if (isPunchIn) {
//           _punchInTime = picked;
//         } else {
//           _punchOutTime = picked;
//         }
//       });
//     }
//   }
//
//   void _scheduleAlarm(TimeOfDay selectedTime, int alarmId) async {
//     if (Platform.isAndroid) {
//       final now = DateTime.now();
//       final scheduledTime = DateTime(
//         now.year,
//         now.month,
//         now.day,
//         selectedTime.hour,
//         selectedTime.minute,
//       );
//
//       await AndroidAlarmManager.oneShotAt(
//         scheduledTime,
//         alarmId,
//         alarmCallback,
//         exact: true,
//         wakeup: true,
//       );
//     } else if (Platform.isIOS) {
//       final scheduledDate = _nextInstanceOfTime(selectedTime);
//       print("Scheduling iOS notification at: $scheduledDate (local time)");
//       try {
//         await _flutterLocalNotificationsPlugin.zonedSchedule(
//           alarmId,
//           'PUNCH REMINDER',
//           'ITS TIME MARK YOUR PUNCH',
//           scheduledDate,
//           const NotificationDetails(
//             iOS: DarwinNotificationDetails(
//               sound: 'default', // Ensure sound is enabled
//               presentAlert: true,
//               presentBadge: true,
//               presentSound: true,
//             ),
//           ),
//           androidAllowWhileIdle: true,
//           uiLocalNotificationDateInterpretation:
//               UILocalNotificationDateInterpretation.absoluteTime,
//           payload: 'punch_reminder_$alarmId',
//         );
//         print('✅ Successfully scheduled notification');
//       } catch (e, stack) {
//         print('❌ Error scheduling notification: $e');
//         print(stack);
//       }
//     }
//
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Alarm set for ${selectedTime.format(context)}')),
//     );
//   }
//
//   void _scheduleRepeatingAlarm(TimeOfDay selectedTime, int alarmId) async {
//     if (Platform.isAndroid) {
//       final now = DateTime.now();
//       final firstTrigger = DateTime(
//         now.year,
//         now.month,
//         now.day,
//         selectedTime.hour,
//         selectedTime.minute,
//       );
//
//       await AndroidAlarmManager.periodic(
//         const Duration(days: 1),
//         alarmId,
//         alarmCallback,
//         startAt: firstTrigger,
//         exact: true,
//         wakeup: true,
//       );
//     } else if (Platform.isIOS) {
//       final scheduledDate = _nextInstanceOfTime(selectedTime);
//       print("Scheduling iOS repeating notification at: $scheduledDate");
//
//       await _flutterLocalNotificationsPlugin.zonedSchedule(
//         alarmId,
//         'PUNCH REMINDER',
//         'ITS TIME MARK YOUR PUNCH',
//         scheduledDate,
//         const NotificationDetails(
//           iOS: DarwinNotificationDetails(),
//         ),
//         androidAllowWhileIdle: true,
//         matchDateTimeComponents: DateTimeComponents.time,
//         uiLocalNotificationDateInterpretation:
//             UILocalNotificationDateInterpretation.absoluteTime,
//       );
//     }
//
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//           content: Text('Daily alarm set for ${selectedTime.format(context)}')),
//     );
//   }
//
//   void _cancelAlarm(int alarmId) async {
//     await AndroidAlarmManager.cancel(alarmId);
//     await _flutterLocalNotificationsPlugin.cancel(alarmId);
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Alarm with ID $alarmId cancelled')),
//     );
//   }
//
//   tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
//     final tz.Location localTz =
//         tz.getLocation('Asia/Kolkata'); // Replace with your timezone
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
//     print('Converted $time to $scheduled (ACTUAL LOCAL TIME)');
//     return scheduled;
//   }
//
//   void _testImmediateNotification() async {
//     await _flutterLocalNotificationsPlugin.show(
//       999,
//       'Test Notification',
//       'This is a test on iOS',
//       const NotificationDetails(
//         iOS: DarwinNotificationDetails(),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Punch Reminder',
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             _buildPunchCard(
//               context,
//               title: "Punch In Reminder",
//               time: _punchInTime,
//               icon: Icons.login,
//               primaryColor: Colors.green,
//               alarmId: 1001,
//               isPunchIn: true,
//             ),
//             const SizedBox(height: 20),
//             _buildPunchCard(
//               context,
//               title: "Punch Out Reminder",
//               time: _punchOutTime,
//               icon: Icons.logout,
//               primaryColor: Colors.red,
//               alarmId: 1002,
//               isPunchIn: false,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildPunchCard(
//     BuildContext context, {
//     required String title,
//     required TimeOfDay? time,
//     required IconData icon,
//     required Color primaryColor,
//     required int alarmId,
//     required bool isPunchIn,
//   }) {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(14),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             /// Header
//             Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(10),
//                   decoration: BoxDecoration(
//                     color: primaryColor.withOpacity(0.15),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Icon(icon, color: primaryColor, size: 26),
//                 ),
//                 const SizedBox(width: 12),
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ],
//             ),
//
//             const SizedBox(height: 14),
//
//             /// Selected Time
//             Text(
//               time != null
//                   ? "Selected Time: ${time.format(context)}"
//                   : "No time selected",
//               style: TextStyle(
//                 fontSize: 16,
//                 color: time != null ? Colors.black87 : Colors.black45,
//               ),
//             ),
//
//             const SizedBox(height: 16),
//
//             /// Action Buttons
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 _actionButton(
//                   label: "Pick Time",
//                   color: primaryColor,
//                   icon: Icons.access_time,
//                   onPressed: () => _pickTime(isPunchIn),
//                 ),
//                 _actionButton(
//                   label: "Once",
//                   color: primaryColor,
//                   icon: Icons.notifications_active,
//                   onPressed:
//                       time != null ? () => _scheduleAlarm(time, alarmId) : null,
//                 ),
//                 _actionButton(
//                   label: "Daily",
//                   color: primaryColor,
//                   icon: Icons.repeat,
//                   onPressed: time != null
//                       ? () => _scheduleRepeatingAlarm(time, alarmId)
//                       : null,
//                 ),
//                 _actionButton(
//                   label: "Delete",
//                   color: Colors.grey,
//                   icon: Icons.delete_outline,
//                   onPressed: () => _cancelAlarm(alarmId),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _actionButton({
//     required String label,
//     required IconData icon,
//     required Color color,
//     VoidCallback? onPressed,
//   }) {
//     return Column(
//       children: [
//         ElevatedButton(
//           onPressed: onPressed,
//           style: ElevatedButton.styleFrom(
//             backgroundColor: color,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//           ),
//           child: Icon(icon, size: 18),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           label,
//           style: const TextStyle(fontSize: 12),
//         ),
//       ],
//     );
//   }
// }
//
// @pragma('vm:entry-point')
// void alarmCallback() async {
//   print('Alarm callback triggered!');
//
//   final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
//
//   // 1. Initialize for both platforms
//   const AndroidInitializationSettings androidSettings =
//       AndroidInitializationSettings('@mipmap/ic_launcher');
//
//   final DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
//     requestAlertPermission: false, // Already requested in main app
//     requestBadgePermission: false,
//     requestSoundPermission: false,
//   );
//   await flutterLocalNotificationsPlugin.initialize(
//     InitializationSettings(
//       android: androidSettings,
//       iOS: iosSettings,
//     ),
//   );
//   // 2. Show notification for both platforms
//   await flutterLocalNotificationsPlugin.show(
//     0,
//     'PUNCH REMINDER',
//     'ITS TIME MARK YOUR PUNCH',
//     NotificationDetails(
//       android: AndroidNotificationDetails(
//         'alarm_channel',
//         'Alarm Channel',
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
//   print('Notification shown successfully');
// }

// Global callback for WorkManager

///work manager
// @pragma('vm:entry-point')
// void callbackDispatcher() {
//   Workmanager().executeTask((taskName, inputData) async {
//     print('WorkManager task triggered: $taskName');
//
//     if (taskName == 'punch_reminder') {
//       final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
//
//       // Initialize notifications
//       const AndroidInitializationSettings androidSettings =
//           AndroidInitializationSettings('@mipmap/ic_launcher');
//
//       final DarwinInitializationSettings iosSettings =
//           DarwinInitializationSettings(
//         requestAlertPermission: false,
//         requestBadgePermission: false,
//         requestSoundPermission: false,
//       );
//
//       await flutterLocalNotificationsPlugin.initialize(
//         InitializationSettings(
//           android: androidSettings,
//           iOS: iosSettings,
//         ),
//       );
//
//       // Show notification
//       await flutterLocalNotificationsPlugin.show(
//         inputData?['alarmId'] ?? 0,
//         'PUNCH REMINDER',
//         inputData?['type'] == 'punch_in'
//             ? 'Time to punch in!'
//             : 'Time to punch out!',
//         NotificationDetails(
//           android: AndroidNotificationDetails(
//             'punch_channel',
//             'Punch Reminders',
//             importance: Importance.high,
//             priority: Priority.high,
//             icon: '@mipmap/ic_launcher',
//           ),
//           iOS: DarwinNotificationDetails(
//             presentAlert: true,
//             presentBadge: true,
//             presentSound: true,
//             sound: 'default',
//           ),
//         ),
//       );
//
//       print('Punch reminder notification shown');
//     }
//
//     return Future.value(true);
//   });
// }
//
// class _AlarmScreenState extends State<AlarmScreen> {
//   TimeOfDay? _punchInTime;
//   TimeOfDay? _punchOutTime;
//   final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();
//
//   // Store scheduled work IDs
//   String? _punchInWorkId;
//   String? _punchOutWorkId;
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeNotifications();
//     _loadSavedTimes();
//   }
//
//   void _initializeNotifications() async {
//     tz.initializeTimeZones();
//
//     const androidSettings =
//         AndroidInitializationSettings('@mipmap/ic_launcher');
//
//     final iosSettings = DarwinInitializationSettings(
//       requestAlertPermission: true,
//       requestBadgePermission: true,
//       requestSoundPermission: true,
//       onDidReceiveLocalNotification: (id, title, body, payload) async {
//         if (mounted) {
//           showDialog(
//             context: context,
//             builder: (BuildContext context) => AlertDialog(
//               title: Text(title ?? 'Notification'),
//               content: Text(body ?? 'No message'),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.of(context).pop(),
//                   child: const Text('OK'),
//                 ),
//               ],
//             ),
//           );
//         }
//       },
//     );
//
//     final initSettings = InitializationSettings(
//       android: androidSettings,
//       iOS: iosSettings,
//     );
//
//     await _flutterLocalNotificationsPlugin.initialize(initSettings);
//
//     // Request iOS permissions
//     final iosPlugin =
//         _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
//             IOSFlutterLocalNotificationsPlugin>();
//     if (iosPlugin != null) {
//       await iosPlugin.requestPermissions(
//         alert: true,
//         badge: true,
//         sound: true,
//       );
//     }
//   }
//
//   void _loadSavedTimes() async {
//     // Load from SharedPreferences or your storage
//     // This is example - implement your own storage
//     // setState(() {
//     //   _punchInTime = savedPunchInTime;
//     //   _punchOutTime = savedPunchOutTime;
//     // });
//   }
//
//   void _pickTime(bool isPunchIn) async {
//     TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: TimeOfDay.now(),
//     );
//     if (picked != null) {
//       setState(() {
//         if (isPunchIn) {
//           _punchInTime = picked;
//         } else {
//           _punchOutTime = picked;
//         }
//       });
//
//       // Save to SharedPreferences
//       // await _saveTime(isPunchIn, picked);
//     }
//   }
//
//   // New method using WorkManager for exact time scheduling
//   Future<void> _scheduleReminder(
//       TimeOfDay selectedTime, int alarmId, String type) async {
//     try {
//       // Calculate next occurrence
//       final now = DateTime.now();
//       DateTime scheduledDateTime = DateTime(
//         now.year,
//         now.month,
//         now.day,
//         selectedTime.hour,
//         selectedTime.minute,
//       );
//
//       // If time has passed today, schedule for tomorrow
//       if (scheduledDateTime.isBefore(now)) {
//         scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
//       }
//
//       // Calculate delay in milliseconds
//       final delay = scheduledDateTime.difference(now);
//
//       // Create unique work ID
//       final workId = 'punch_reminder_${type}_$alarmId';
//
//       if (type == 'punch_in') {
//         _punchInWorkId = workId;
//       } else {
//         _punchOutWorkId = workId;
//       }
//
//       // Schedule one-time work with exact timing
//       await Workmanager().registerOneOffTask(
//         workId,
//         'punch_reminder',
//         initialDelay: delay,
//         inputData: {
//           'alarmId': alarmId,
//           'type': type,
//           'hour': selectedTime.hour,
//           'minute': selectedTime.minute,
//         },
//         constraints: Constraints(
//           networkType: NetworkType.notRequired,
//           requiresBatteryNotLow: false,
//           requiresCharging: false,
//           requiresDeviceIdle: false,
//           requiresStorageNotLow: false,
//         ),
//         existingWorkPolicy:
//             ExistingWorkPolicy.replace, // ✅ This is correct for one-off tasks
//       );
//
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//                 '${type == 'punch_in' ? 'Punch In' : 'Punch Out'} reminder set for ${selectedTime.format(context)}'),
//             duration: const Duration(seconds: 2),
//           ),
//         );
//       }
//
//       print('✅ Scheduled $type reminder for ${scheduledDateTime.toLocal()}');
//
//       // Also show test notification immediately (optional - for debugging)
//       // await _showTestNotification(type);
//     } catch (e) {
//       print('❌ Error scheduling reminder: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to schedule reminder: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }
//
//   // Schedule daily repeating reminder
//   Future<void> _scheduleDailyReminder(
//       TimeOfDay selectedTime, int alarmId, String type) async {
//     try {
//       final workId = 'daily_punch_reminder_${type}_$alarmId';
//
//       if (type == 'punch_in') {
//         _punchInWorkId = workId;
//       } else {
//         _punchOutWorkId = workId;
//       }
//
//       // Calculate first execution time
//       final now = DateTime.now();
//       DateTime firstExecution = DateTime(
//         now.year,
//         now.month,
//         now.day,
//         selectedTime.hour,
//         selectedTime.minute,
//       );
//
//       if (firstExecution.isBefore(now)) {
//         firstExecution = firstExecution.add(const Duration(days: 1));
//       }
//
//       final initialDelay = firstExecution.difference(now);
//
//       // Register periodic task with daily frequency
//       await Workmanager().registerPeriodicTask(
//         workId,
//         'punch_reminder',
//         frequency: const Duration(days: 1),
//         initialDelay: initialDelay,
//         inputData: {
//           'alarmId': alarmId,
//           'type': type,
//           'hour': selectedTime.hour,
//           'minute': selectedTime.minute,
//         },
//         constraints: Constraints(
//           networkType: NetworkType.notRequired,
//           requiresBatteryNotLow: false,
//           requiresCharging: false,
//           requiresDeviceIdle: false,
//         ),
//         existingWorkPolicy: ExistingPeriodicWorkPolicy
//             .replace, // ✅ Use ExistingPeriodicWorkPolicy for periodic
//       );
//
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//                 'Daily ${type == 'punch_in' ? 'Punch In' : 'Punch Out'} reminder set for ${selectedTime.format(context)}'),
//             duration: const Duration(seconds: 2),
//           ),
//         );
//       }
//
//       print('✅ Scheduled daily $type reminder');
//     } catch (e) {
//       print('❌ Error scheduling daily reminder: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to schedule daily reminder: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }
//
//   // Cancel reminder
//   Future<void> _cancelReminder(int alarmId, String type) async {
//     try {
//       final workId = type == 'punch_in'
//           ? 'punch_reminder_punch_in_$alarmId'
//           : 'punch_reminder_punch_out_$alarmId';
//
//       final dailyWorkId = type == 'punch_in'
//           ? 'daily_punch_reminder_punch_in_$alarmId'
//           : 'daily_punch_reminder_punch_out_$alarmId';
//
//       await Workmanager().cancelByUniqueName(workId);
//       await Workmanager().cancelByUniqueName(dailyWorkId);
//
//       // Cancel local notification as well
//       await _flutterLocalNotificationsPlugin.cancel(alarmId);
//
//       if (type == 'punch_in') {
//         _punchInWorkId = null;
//       } else {
//         _punchOutWorkId = null;
//       }
//
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//                 '${type == 'punch_in' ? 'Punch In' : 'Punch Out'} reminder cancelled'),
//             duration: const Duration(seconds: 2),
//           ),
//         );
//       }
//
//       print('✅ Cancelled $type reminder');
//     } catch (e) {
//       print('❌ Error cancelling reminder: $e');
//     }
//   }
//
//   // Optional: Show test notification to verify setup
//   Future<void> _showTestNotification(String type) async {
//     await _flutterLocalNotificationsPlugin.show(
//       DateTime.now().millisecondsSinceEpoch ~/ 1000,
//       'Test Reminder',
//       'Testing ${type == 'punch_in' ? 'Punch In' : 'Punch Out'} reminder',
//       const NotificationDetails(
//         android: AndroidNotificationDetails(
//           'punch_channel',
//           'Punch Reminders',
//           importance: Importance.high,
//           priority: Priority.high,
//         ),
//         iOS: DarwinNotificationDetails(
//           presentAlert: true,
//           presentBadge: true,
//           presentSound: true,
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Punch Reminder',
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             _buildPunchCard(
//               context,
//               title: "Punch In Reminder",
//               time: _punchInTime,
//               icon: Icons.login,
//               primaryColor: Colors.green,
//               alarmId: 1001,
//               type: 'punch_in',
//             ),
//             const SizedBox(height: 20),
//             _buildPunchCard(
//               context,
//               title: "Punch Out Reminder",
//               time: _punchOutTime,
//               icon: Icons.logout,
//               primaryColor: Colors.red,
//               alarmId: 1002,
//               type: 'punch_out',
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildPunchCard(
//     BuildContext context, {
//     required String title,
//     required TimeOfDay? time,
//     required IconData icon,
//     required Color primaryColor,
//     required int alarmId,
//     required String type,
//   }) {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(14),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(10),
//                   decoration: BoxDecoration(
//                     color: primaryColor.withOpacity(0.15),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Icon(icon, color: primaryColor, size: 26),
//                 ),
//                 const SizedBox(width: 12),
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 14),
//             Text(
//               time != null
//                   ? "Selected Time: ${time.format(context)}"
//                   : "No time selected",
//               style: TextStyle(
//                 fontSize: 16,
//                 color: time != null ? Colors.black87 : Colors.black45,
//               ),
//             ),
//             const SizedBox(height: 16),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 _actionButton(
//                   label: "Pick Time",
//                   color: primaryColor,
//                   icon: Icons.access_time,
//                   onPressed: () => _pickTime(type == 'punch_in'),
//                 ),
//                 _actionButton(
//                   label: "Once",
//                   color: primaryColor,
//                   icon: Icons.notifications_active,
//                   onPressed: time != null
//                       ? () => _scheduleReminder(time, alarmId, type)
//                       : null,
//                 ),
//                 _actionButton(
//                   label: "Daily",
//                   color: primaryColor,
//                   icon: Icons.repeat,
//                   onPressed: time != null
//                       ? () => _scheduleDailyReminder(time, alarmId, type)
//                       : null,
//                 ),
//                 _actionButton(
//                   label: "Delete",
//                   color: Colors.grey,
//                   icon: Icons.delete_outline,
//                   onPressed: () => _cancelReminder(alarmId, type),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _actionButton({
//     required String label,
//     required IconData icon,
//     required Color color,
//     VoidCallback? onPressed,
//   }) {
//     return Column(
//       children: [
//         ElevatedButton(
//           onPressed: onPressed,
//           style: ElevatedButton.styleFrom(
//             backgroundColor: color,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//           ),
//           child: Icon(icon, size: 18),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           label,
//           style: const TextStyle(fontSize: 12),
//         ),
//       ],

//     );
//   }
// }

// Initialize WorkManager in main.dart
///work manager working fine
// @pragma('vm:entry-point')
// void callbackDispatcher() {
//   Workmanager().executeTask((taskName, inputData) async {
//     print('WorkManager task triggered: $taskName');
//
//     if (taskName == 'punch_reminder') {
//       final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
//
//       const AndroidInitializationSettings androidSettings =
//           AndroidInitializationSettings('@mipmap/ic_launcher');
//
//       final DarwinInitializationSettings iosSettings =
//           DarwinInitializationSettings(
//         requestAlertPermission: false,
//         requestBadgePermission: false,
//         requestSoundPermission: false,
//       );
//
//       await flutterLocalNotificationsPlugin.initialize(
//         InitializationSettings(
//           android: androidSettings,
//           iOS: iosSettings,
//         ),
//       );
//
//       final type = inputData?['type'] ?? 'punch';
//       final title =
//           type == 'punch_in' ? 'PUNCH IN REMINDER' : 'PUNCH OUT REMINDER';
//       final body =
//           type == 'punch_in' ? 'Time to punch in!' : 'Time to punch out!';
//
//       await flutterLocalNotificationsPlugin.show(
//         inputData?['alarmId'] ?? 0,
//         title,
//         body,
//         NotificationDetails(
//           android: AndroidNotificationDetails(
//             'punch_channel',
//             'Punch Reminders',
//             importance: Importance.high,
//             priority: Priority.high,
//             icon: '@mipmap/ic_launcher',
//           ),
//           iOS: DarwinNotificationDetails(
//             presentAlert: true,
//             presentBadge: true,
//             presentSound: true,
//             sound: 'default',
//           ),
//         ),
//       );
//
//       print('Reminder shown for $type');
//     }
//
//     return Future.value(true);
//   });
// }
//
// // Model to store reminder settings
// class ReminderSettings {
//   final TimeOfDay time;
//   final bool isDaily;
//   final int alarmId;
//   final bool isActive;
//
//   ReminderSettings({
//     required this.time,
//     required this.isDaily,
//     required this.alarmId,
//     this.isActive = true,
//   });
//
//   Map<String, dynamic> toJson() => {
//         'hour': time.hour,
//         'minute': time.minute,
//         'isDaily': isDaily,
//         'alarmId': alarmId,
//         'isActive': isActive,
//       };
//
//   factory ReminderSettings.fromJson(Map<String, dynamic> json) {
//     return ReminderSettings(
//       time: TimeOfDay(hour: json['hour'], minute: json['minute']),
//       isDaily: json['isDaily'],
//       alarmId: json['alarmId'],
//       isActive: json['isActive'] ?? true,
//     );
//   }
// }
//
// class _AlarmScreenState extends State<AlarmScreen> {
//   ReminderSettings? _punchInReminder;
//   ReminderSettings? _punchOutReminder;
//
//   final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeNotifications();
//     _loadReminderSettings();
//   }
//
//   void _initializeNotifications() async {
//     tz.initializeTimeZones();
//
//     const androidSettings =
//         AndroidInitializationSettings('@mipmap/ic_launcher');
//
//     final iosSettings = DarwinInitializationSettings(
//       requestAlertPermission: true,
//       requestBadgePermission: true,
//       requestSoundPermission: true,
//       onDidReceiveLocalNotification: (id, title, body, payload) async {
//         if (mounted) {
//           showDialog(
//             context: context,
//             builder: (BuildContext context) => AlertDialog(
//               title: Text(title ?? 'Notification'),
//               content: Text(body ?? 'No message'),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.of(context).pop(),
//                   child: const Text('OK'),
//                 ),
//               ],
//             ),
//           );
//         }
//       },
//     );
//
//     final initSettings = InitializationSettings(
//       android: androidSettings,
//       iOS: iosSettings,
//     );
//
//     await _flutterLocalNotificationsPlugin.initialize(initSettings);
//
//     final iosPlugin =
//         _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
//             IOSFlutterLocalNotificationsPlugin>();
//     if (iosPlugin != null) {
//       await iosPlugin.requestPermissions(
//         alert: true,
//         badge: true,
//         sound: true,
//       );
//     }
//   }
//
//   Future<void> _loadReminderSettings() async {
//     final prefs = await SharedPreferences.getInstance();
//
//     // Load Punch In Reminder
//     final punchInJson = prefs.getString('punch_in_reminder');
//     if (punchInJson != null) {
//       try {
//         final Map<String, dynamic> json =
//             Map.from(await prefs.getString('punch_in_reminder') as Map);
//         // Actually parse properly:
//         final Map<String, dynamic> punchInMap = {
//           'hour': prefs.getInt('punch_in_hour') ?? 9,
//           'minute': prefs.getInt('punch_in_minute') ?? 0,
//           'isDaily': prefs.getBool('punch_in_is_daily') ?? false,
//           'alarmId': prefs.getInt('punch_in_alarm_id') ?? 1001,
//           'isActive': prefs.getBool('punch_in_is_active') ?? false,
//         };
//         if (punchInMap['isActive']) {
//           setState(() {
//             _punchInReminder = ReminderSettings.fromJson(punchInMap);
//           });
//         }
//       } catch (e) {
//         print('Error loading punch in reminder: $e');
//       }
//     }
//
//     // Load Punch Out Reminder
//     final punchOutHour = prefs.getInt('punch_out_hour');
//     if (punchOutHour != null) {
//       final punchOutMap = {
//         'hour': punchOutHour,
//         'minute': prefs.getInt('punch_out_minute') ?? 0,
//         'isDaily': prefs.getBool('punch_out_is_daily') ?? false,
//         'alarmId': prefs.getInt('punch_out_alarm_id') ?? 1002,
//         'isActive': prefs.getBool('punch_out_is_active') ?? false,
//       };
//       if (punchOutMap['isActive'] != null) {
//         setState(() {
//           _punchOutReminder = ReminderSettings.fromJson(punchOutMap);
//         });
//       }
//     }
//   }
//
//   Future<void> _saveReminderSettings(
//       String type, ReminderSettings settings) async {
//     final prefs = await SharedPreferences.getInstance();
//
//     if (type == 'punch_in') {
//       await prefs.setInt('punch_in_hour', settings.time.hour);
//       await prefs.setInt('punch_in_minute', settings.time.minute);
//       await prefs.setBool('punch_in_is_daily', settings.isDaily);
//       await prefs.setInt('punch_in_alarm_id', settings.alarmId);
//       await prefs.setBool('punch_in_is_active', settings.isActive);
//     } else {
//       await prefs.setInt('punch_out_hour', settings.time.hour);
//       await prefs.setInt('punch_out_minute', settings.time.minute);
//       await prefs.setBool('punch_out_is_daily', settings.isDaily);
//       await prefs.setInt('punch_out_alarm_id', settings.alarmId);
//       await prefs.setBool('punch_out_is_active', settings.isActive);
//     }
//   }
//
//   Future<void> _clearReminderSettings(String type) async {
//     final prefs = await SharedPreferences.getInstance();
//
//     if (type == 'punch_in') {
//       await prefs.remove('punch_in_hour');
//       await prefs.remove('punch_in_minute');
//       await prefs.remove('punch_in_is_daily');
//       await prefs.remove('punch_in_alarm_id');
//       await prefs.setBool('punch_in_is_active', false);
//     } else {
//       await prefs.remove('punch_out_hour');
//       await prefs.remove('punch_out_minute');
//       await prefs.remove('punch_out_is_daily');
//       await prefs.remove('punch_out_alarm_id');
//       await prefs.setBool('punch_out_is_active', false);
//     }
//   }
//
//   void _pickTime(String type) async {
//     TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: TimeOfDay.now(),
//     );
//
//     if (picked != null) {
//       setState(() {
//         if (type == 'punch_in') {
//           _punchInReminder = ReminderSettings(
//             time: picked,
//             isDaily: false,
//             alarmId: 1001,
//             isActive: false, // Not active until scheduled
//           );
//         } else {
//           _punchOutReminder = ReminderSettings(
//             time: picked,
//             isDaily: false,
//             alarmId: 1002,
//             isActive: false,
//           );
//         }
//       });
//     }
//   }
//
//   Future<void> _scheduleReminder(String type, bool isDaily) async {
//     ReminderSettings? reminder;
//
//     if (type == 'punch_in') {
//       reminder = _punchInReminder;
//     } else {
//       reminder = _punchOutReminder;
//     }
//
//     if (reminder == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please pick a time first')),
//       );
//       return;
//     }
//
//     try {
//       final now = DateTime.now();
//       DateTime scheduledDateTime = DateTime(
//         now.year,
//         now.month,
//         now.day,
//         reminder.time.hour,
//         reminder.time.minute,
//       );
//
//       if (scheduledDateTime.isBefore(now)) {
//         scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
//       }
//
//       final workId = '${type}_reminder_${reminder.alarmId}';
//
//       if (isDaily) {
//         // Schedule daily reminder
//         final initialDelay = scheduledDateTime.difference(now);
//
//         await Workmanager().registerPeriodicTask(
//           workId,
//           'punch_reminder',
//           frequency: const Duration(days: 1),
//           initialDelay: initialDelay,
//           inputData: {
//             'alarmId': reminder.alarmId,
//             'type': type,
//           },
//           existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
//         );
//
//         // Update reminder with daily flag
//         final updatedReminder = ReminderSettings(
//           time: reminder.time,
//           isDaily: true,
//           alarmId: reminder.alarmId,
//           isActive: true,
//         );
//
//         setState(() {
//           if (type == 'punch_in') {
//             _punchInReminder = updatedReminder;
//           } else {
//             _punchOutReminder = updatedReminder;
//           }
//         });
//
//         await _saveReminderSettings(type, updatedReminder);
//
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//                 'Daily ${type == 'punch_in' ? 'Punch In' : 'Punch Out'} reminder set for ${reminder.time.format(context)}'),
//           ),
//         );
//       } else {
//         // Schedule one-time reminder
//         final delay = scheduledDateTime.difference(now);
//
//         await Workmanager().registerOneOffTask(
//           workId,
//           'punch_reminder',
//           initialDelay: delay,
//           inputData: {
//             'alarmId': reminder.alarmId,
//             'type': type,
//           },
//           existingWorkPolicy: ExistingWorkPolicy.replace,
//         );
//
//         // Update reminder (one-time, active)
//         final updatedReminder = ReminderSettings(
//           time: reminder.time,
//           isDaily: false,
//           alarmId: reminder.alarmId,
//           isActive: true,
//         );
//
//         setState(() {
//           if (type == 'punch_in') {
//             _punchInReminder = updatedReminder;
//           } else {
//             _punchOutReminder = updatedReminder;
//           }
//         });
//
//         await _saveReminderSettings(type, updatedReminder);
//
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//                 '${type == 'punch_in' ? 'Punch In' : 'Punch Out'} reminder set for ${reminder.time.format(context)}'),
//           ),
//         );
//
//         // For one-time reminders, auto-deactivate after showing
//         // This will be handled by checking if the scheduled time has passed
//         _checkAndDeactivateOneTimeReminder(type, scheduledDateTime);
//       }
//
//       print('✅ Scheduled $type reminder');
//     } catch (e) {
//       print('❌ Error: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to schedule: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
//
//   Future<void> _checkAndDeactivateOneTimeReminder(
//       String type, DateTime scheduledTime) async {
//     // Check if the scheduled time has passed
//     Future.delayed(Duration(seconds: 5), () async {
//       final now = DateTime.now();
//       if (now.isAfter(scheduledTime)) {
//         // Time has passed, deactivate the reminder
//         setState(() {
//           if (type == 'punch_in' && _punchInReminder != null) {
//             _punchInReminder = ReminderSettings(
//               time: _punchInReminder!.time,
//               isDaily: false,
//               alarmId: _punchInReminder!.alarmId,
//               isActive: false,
//             );
//             _saveReminderSettings(type, _punchInReminder!);
//           } else if (type == 'punch_out' && _punchOutReminder != null) {
//             _punchOutReminder = ReminderSettings(
//               time: _punchOutReminder!.time,
//               isDaily: false,
//               alarmId: _punchOutReminder!.alarmId,
//               isActive: false,
//             );
//             _saveReminderSettings(type, _punchOutReminder!);
//           }
//         });
//       }
//     });
//   }
//
//   Future<void> _cancelReminder(String type) async {
//     try {
//       ReminderSettings? reminder;
//       int alarmId;
//
//       if (type == 'punch_in') {
//         reminder = _punchInReminder;
//         alarmId = 1001;
//       } else {
//         reminder = _punchOutReminder;
//         alarmId = 1002;
//       }
//
//       final workId = '${type}_reminder_$alarmId';
//       await Workmanager().cancelByUniqueName(workId);
//
//       // Cancel local notification too
//       await _flutterLocalNotificationsPlugin.cancel(alarmId);
//
//       // Clear the reminder
//       setState(() {
//         if (type == 'punch_in') {
//           _punchInReminder = null;
//         } else {
//           _punchOutReminder = null;
//         }
//       });
//
//       await _clearReminderSettings(type);
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//               '${type == 'punch_in' ? 'Punch In' : 'Punch Out'} reminder cancelled'),
//         ),
//       );
//
//       print('✅ Cancelled $type reminder');
//     } catch (e) {
//       print('❌ Error cancelling: $e');
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Punch Reminder',
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             _buildPunchCard(
//               context,
//               title: "Punch In Reminder",
//               reminder: _punchInReminder,
//               icon: Icons.login,
//               primaryColor: Colors.green,
//               type: 'punch_in',
//             ),
//             const SizedBox(height: 20),
//             _buildPunchCard(
//               context,
//               title: "Punch Out Reminder",
//               reminder: _punchOutReminder,
//               icon: Icons.logout,
//               primaryColor: Colors.red,
//               type: 'punch_out',
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildPunchCard(
//     BuildContext context, {
//     required String title,
//     required ReminderSettings? reminder,
//     required IconData icon,
//     required Color primaryColor,
//     required String type,
//   }) {
//     final bool hasReminder = reminder != null && reminder.isActive;
//     final bool isDaily = reminder?.isDaily ?? false;
//
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(14),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(10),
//                   decoration: BoxDecoration(
//                     color: primaryColor.withOpacity(0.15),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Icon(icon, color: primaryColor, size: 26),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         title,
//                         style: const TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       if (hasReminder)
//                         Container(
//                           margin: const EdgeInsets.only(top: 4),
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 8, vertical: 2),
//                           decoration: BoxDecoration(
//                             color: isDaily
//                                 ? Colors.blue.shade100
//                                 : Colors.green.shade100,
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Text(
//                             isDaily ? 'Daily' : 'One-time',
//                             style: TextStyle(
//                               fontSize: 11,
//                               fontWeight: FontWeight.w500,
//                               color: isDaily
//                                   ? Colors.blue.shade900
//                                   : Colors.green.shade900,
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 14),
//             Text(
//               hasReminder
//                   ? "Reminder at: ${reminder!.time.format(context)}"
//                   : "No reminder set",
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: hasReminder ? FontWeight.w500 : FontWeight.normal,
//                 color: hasReminder ? Colors.black87 : Colors.black45,
//               ),
//             ),
//             if (hasReminder && !isDaily)
//               Padding(
//                 padding: const EdgeInsets.only(top: 4),
//                 child: Text(
//                   'This reminder will automatically deactivate after showing once',
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Colors.grey.shade600,
//                   ),
//                 ),
//               ),
//             const SizedBox(height: 16),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 _actionButton(
//                   label: "Pick Time",
//                   color: primaryColor,
//                   icon: Icons.access_time,
//                   onPressed: () => _pickTime(type),
//                 ),
//                 _actionButton(
//                   label: "Once",
//                   color: Colors.green,
//                   icon: Icons.notifications_active,
//                   onPressed: () => _scheduleReminder(type, false),
//                 ),
//                 _actionButton(
//                   label: "Daily",
//                   color: Colors.blue,
//                   icon: Icons.repeat,
//                   onPressed: () => _scheduleReminder(type, true),
//                 ),
//                 _actionButton(
//                   label: "Delete",
//                   color: Colors.red,
//                   icon: Icons.delete_outline,
//                   onPressed: hasReminder ? () => _cancelReminder(type) : null,
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _actionButton({
//     required String label,
//     required IconData icon,
//     required Color color,
//     VoidCallback? onPressed,
//   }) {
//     return Column(
//       children: [
//         ElevatedButton(
//           onPressed: onPressed,
//           style: ElevatedButton.styleFrom(
//             backgroundColor: color,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//           ),
//           child: Icon(icon, size: 18, color: Colors.white),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           label,
//           style: const TextStyle(fontSize: 11),
//         ),
//       ],
//     );
//   }
// }

/*
class _AlarmScreenState extends State<AlarmScreen> with WidgetsBindingObserver {
  ReminderSettings? _punchInReminder;
  ReminderSettings? _punchOutReminder;

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Add a timer that checks every minute
  Timer? _cleanupTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeNotifications();
    _loadReminderSettings().then((_) {
      _checkAndCleanExpiredReminders();
    });

    // Start periodic cleanup timer
    _cleanupTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        _checkAndCleanExpiredReminders();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadReminderSettings().then((_) {
        _checkAndCleanExpiredReminders(); // Check when app returns to foreground
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanupTimer?.cancel(); // Cancel timer
    super.dispose();
  }

  void _initializeNotifications() async {
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: (id, title, body, payload) async {
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: Text(title ?? 'Notification'),
              content: Text(body ?? 'No message'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      },
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(initSettings);

    final iosPlugin =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  void _checkAndCleanExpiredReminders() {
    final now = DateTime.now();
    bool needsRefresh = false;

    // Check Punch In Reminder
    if (_punchInReminder != null && !_punchInReminder!.isDaily) {
      final reminderTime = DateTime(
        now.year,
        now.month,
        now.day,
        _punchInReminder!.time.hour,
        _punchInReminder!.time.minute,
      );

      // If reminder time has passed today
      if (now.isAfter(reminderTime)) {
        setState(() {
          _punchInReminder = null;
        });
        _clearReminderSettings('punch_in');
        needsRefresh = true;
      }
    }

    // Check Punch Out Reminder
    if (_punchOutReminder != null && !_punchOutReminder!.isDaily) {
      final reminderTime = DateTime(
        now.year,
        now.month,
        now.day,
        _punchOutReminder!.time.hour,
        _punchOutReminder!.time.minute,
      );

      // If reminder time has passed today
      if (now.isAfter(reminderTime)) {
        setState(() {
          _punchOutReminder = null;
        });
        _clearReminderSettings('punch_out');
        needsRefresh = true;
      }
    }

    if (needsRefresh) {
      print('Cleaned up expired one-time reminders');
    }
  }

  // Future<void> _loadReminderSettings() async {
  //   final prefs = await SharedPreferences.getInstance();
  //
  //   // Load Punch In Reminder
  //   final hasPunchInReminder = prefs.getBool('punch_in_has_reminder') ?? false;
  //   if (hasPunchInReminder) {
  //     final hour = prefs.getInt('punch_in_hour');
  //     final minute = prefs.getInt('punch_in_minute');
  //     if (hour != null && minute != null) {
  //       setState(() {
  //         _punchInReminder = ReminderSettings(
  //           time: TimeOfDay(hour: hour, minute: minute),
  //           isDaily: prefs.getBool('punch_in_is_daily') ?? false,
  //           alarmId: prefs.getInt('punch_in_alarm_id') ?? 1001,
  //           hasReminder: true,
  //         );
  //       });
  //       print(
  //           'Loaded punch in reminder: ${_punchInReminder?.time.format(context)}');
  //     }
  //   }
  //
  //   // Load Punch Out Reminder
  //   final hasPunchOutReminder =
  //       prefs.getBool('punch_out_has_reminder') ?? false;
  //   if (hasPunchOutReminder) {
  //     final hour = prefs.getInt('punch_out_hour');
  //     final minute = prefs.getInt('punch_out_minute');
  //     if (hour != null && minute != null) {
  //       setState(() {
  //         _punchOutReminder = ReminderSettings(
  //           time: TimeOfDay(hour: hour, minute: minute),
  //           isDaily: prefs.getBool('punch_out_is_daily') ?? false,
  //           alarmId: prefs.getInt('punch_out_alarm_id') ?? 1002,
  //           hasReminder: true,
  //         );
  //       });
  //       print(
  //           'Loaded punch out reminder: ${_punchOutReminder?.time.format(context)}');
  //     }
  //   }
  // }

  Future<void> _loadReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Load Punch In Reminder
    final hasPunchInReminder = prefs.getBool('punch_in_has_reminder') ?? false;
    if (hasPunchInReminder) {
      final hour = prefs.getInt('punch_in_hour');
      final minute = prefs.getInt('punch_in_minute');
      if (hour != null && minute != null) {
        setState(() {
          _punchInReminder = ReminderSettings(
            time: TimeOfDay(hour: hour, minute: minute),
            isDaily: prefs.getBool('punch_in_is_daily') ?? false,
            alarmId: prefs.getInt('punch_in_alarm_id') ?? 1001,
            hasReminder: true,
          );
        });
      }
    } else {
      setState(() {
        _punchInReminder = null; // Clear if no reminder exists
      });
    }

    // Load Punch Out Reminder
    final hasPunchOutReminder =
        prefs.getBool('punch_out_has_reminder') ?? false;
    if (hasPunchOutReminder) {
      final hour = prefs.getInt('punch_out_hour');
      final minute = prefs.getInt('punch_out_minute');
      if (hour != null && minute != null) {
        setState(() {
          _punchOutReminder = ReminderSettings(
            time: TimeOfDay(hour: hour, minute: minute),
            isDaily: prefs.getBool('punch_out_is_daily') ?? false,
            alarmId: prefs.getInt('punch_out_alarm_id') ?? 1002,
            hasReminder: true,
          );
        });
      }
    } else {
      setState(() {
        _punchOutReminder = null; // Clear if no reminder exists
      });
    }
  }

  Future<void> _saveReminderSettings(
      String type, ReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();

    if (type == 'punch_in') {
      await prefs.setInt('punch_in_hour', settings.time.hour);
      await prefs.setInt('punch_in_minute', settings.time.minute);
      await prefs.setBool('punch_in_is_daily', settings.isDaily);
      await prefs.setInt('punch_in_alarm_id', settings.alarmId);
      await prefs.setBool('punch_in_has_reminder', true);
    } else {
      await prefs.setInt('punch_out_hour', settings.time.hour);
      await prefs.setInt('punch_out_minute', settings.time.minute);
      await prefs.setBool('punch_out_is_daily', settings.isDaily);
      await prefs.setInt('punch_out_alarm_id', settings.alarmId);
      await prefs.setBool('punch_out_has_reminder', true);
    }
  }

  Future<void> _clearReminderSettings(String type) async {
    final prefs = await SharedPreferences.getInstance();

    if (type == 'punch_in') {
      await prefs.remove('punch_in_hour');
      await prefs.remove('punch_in_minute');
      await prefs.remove('punch_in_is_daily');
      await prefs.remove('punch_in_alarm_id');
      await prefs.setBool('punch_in_has_reminder', false);
    } else {
      await prefs.remove('punch_out_hour');
      await prefs.remove('punch_out_minute');
      await prefs.remove('punch_out_is_daily');
      await prefs.remove('punch_out_alarm_id');
      await prefs.setBool('punch_out_has_reminder', false);
    }
  }

  void _pickTime(String type) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        final newReminder = ReminderSettings(
          time: picked,
          isDaily: false,
          alarmId: type == 'punch_in' ? 1001 : 1002,
          hasReminder: false, // Not scheduled yet
        );

        if (type == 'punch_in') {
          _punchInReminder = newReminder;
        } else {
          _punchOutReminder = newReminder;
        }
      });
    }
  }

  Future<void> _scheduleReminder(String type, bool isDaily) async {
    ReminderSettings? reminder;

    if (type == 'punch_in') {
      reminder = _punchInReminder;
    } else {
      reminder = _punchOutReminder;
    }

    if (reminder == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a time first')),
      );
      return;
    }

    try {
      final now = DateTime.now();
      DateTime scheduledDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        reminder.time.hour,
        reminder.time.minute,
      );

      if (scheduledDateTime.isBefore(now)) {
        scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
      }

      final workId = '${type}_reminder_${reminder.alarmId}';

      // if (isDaily) {
      //   // Schedule daily reminder
      //   final initialDelay = scheduledDateTime.difference(now);
      //
      //   await Workmanager().registerPeriodicTask(
      //     workId,
      //     'punch_reminder',
      //     frequency: const Duration(days: 1),
      //     initialDelay: initialDelay,
      //     inputData: {
      //       'alarmId': reminder.alarmId,
      //       'type': type,
      //       'isDaily': true,
      //     },
      //     existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      //   );
      //
      //   // Update reminder with daily flag and mark as having reminder
      //   final updatedReminder = ReminderSettings(
      //     time: reminder.time,
      //     isDaily: true,
      //     alarmId: reminder.alarmId,
      //     hasReminder: true,
      //   );
      //
      //   setState(() {
      //     if (type == 'punch_in') {
      //       _punchInReminder = updatedReminder;
      //     } else {
      //       _punchOutReminder = updatedReminder;
      //     }
      //   });
      //
      //   await _saveReminderSettings(type, updatedReminder);
      //
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: Text(
      //           'Daily ${type == 'punch_in' ? 'Punch In' : 'Punch Out'} reminder set for ${reminder.time.format(context)}'),
      //     ),
      //   );
      // }
      if (isDaily) {
        // Use the same approach as _scheduleDailyReminder but with reminder object
        final initialDelay = scheduledDateTime.difference(now);
        final dailyWorkId = '${type}_daily_reminder_${reminder.alarmId}';

        await Workmanager().registerOneOffTask(
          dailyWorkId,
          'punch_reminder_daily', // Use daily task name
          initialDelay: initialDelay,
          inputData: {
            'alarmId': reminder.alarmId,
            'type': type,
            'isDaily': true,
            'hour': reminder.time.hour,
            'minute': reminder.time.minute,
          },
          existingWorkPolicy: ExistingWorkPolicy.replace,
        );

        // Update reminder with daily flag and mark as having reminder
        final updatedReminder = ReminderSettings(
          time: reminder.time,
          isDaily: true,
          alarmId: reminder.alarmId,
          hasReminder: true,
        );

        setState(() {
          if (type == 'punch_in') {
            _punchInReminder = updatedReminder;
          } else {
            _punchOutReminder = updatedReminder;
          }
        });

        await _saveReminderSettings(type, updatedReminder);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Daily ${type == 'punch_in' ? 'Punch In' : 'Punch Out'} reminder set for ${reminder.time.format(context)}'),
          ),
        );
      } else {
        // Schedule one-time reminder
        final delay = scheduledDateTime.difference(now);

        await Workmanager().registerOneOffTask(
          workId,
          'punch_reminder',
          initialDelay: delay,
          inputData: {
            'alarmId': reminder.alarmId,
            'type': type,
            'isDaily': false,
          },
          existingWorkPolicy: ExistingWorkPolicy.replace,
        );

        // Update reminder (one-time, has reminder)
        final updatedReminder = ReminderSettings(
          time: reminder.time,
          isDaily: false,
          alarmId: reminder.alarmId,
          hasReminder: true,
        );

        setState(() {
          if (type == 'punch_in') {
            _punchInReminder = updatedReminder;
          } else {
            _punchOutReminder = updatedReminder;
          }
        });

        await _saveReminderSettings(type, updatedReminder);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'One-time ${type == 'punch_in' ? 'Punch In' : 'Punch Out'} reminder set for ${reminder.time.format(context)}'),
          ),
        );
      }

      print('✅ Scheduled $type reminder (${isDaily ? "daily" : "one-time"})');
    } catch (e) {
      print('❌ Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to schedule: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cancelReminder(String type) async {
    try {
      ReminderSettings? reminder;
      int alarmId;

      if (type == 'punch_in') {
        reminder = _punchInReminder;
        alarmId = 1001;
      } else {
        reminder = _punchOutReminder;
        alarmId = 1002;
      }

      if (reminder != null) {
        final workId = '${type}_reminder_$alarmId';
        await Workmanager().cancelByUniqueName(workId);

        // Cancel local notification too
        await _flutterLocalNotificationsPlugin.cancel(alarmId);
      }

      // Clear the reminder from state and storage
      setState(() {
        if (type == 'punch_in') {
          _punchInReminder = null;
        } else {
          _punchOutReminder = null;
        }
      });

      await _clearReminderSettings(type);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${type == 'punch_in' ? 'Punch In' : 'Punch Out'} reminder cancelled'),
        ),
      );

      print('✅ Cancelled $type reminder');
    } catch (e) {
      print('❌ Error cancelling: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Punch Reminder',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPunchCard(
              context,
              title: "Punch In Reminder",
              reminder: _punchInReminder,
              icon: Icons.login,
              primaryColor: Colors.green,
              type: 'punch_in',
            ),
            const SizedBox(height: 20),
            _buildPunchCard(
              context,
              title: "Punch Out Reminder",
              reminder: _punchOutReminder,
              icon: Icons.logout,
              primaryColor: Colors.red,
              type: 'punch_out',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPunchCard(
    BuildContext context, {
    required String title,
    required ReminderSettings? reminder,
    required IconData icon,
    required Color primaryColor,
    required String type,
  }) {
    final bool hasReminder = reminder != null && reminder.hasReminder;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: primaryColor, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (hasReminder)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: reminder!.isDaily
                                ? Colors.blue.shade100
                                : Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            reminder.isDaily
                                ? 'Daily Reminder'
                                : 'One-time Reminder (Pending)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: reminder.isDaily
                                  ? Colors.blue.shade900
                                  : Colors.green.shade900,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              hasReminder
                  ? "Reminder at: ${reminder!.time.format(context)}"
                  : "No reminder set",
              style: TextStyle(
                fontSize: 16,
                fontWeight: hasReminder ? FontWeight.w500 : FontWeight.normal,
                color: hasReminder ? Colors.black87 : Colors.black45,
              ),
            ),
            if (hasReminder && reminder != null && !reminder.isDaily)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  // ✅ Use 'child' instead of 'children'
                  '⏰ This reminder will auto-delete after showing',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
            if (hasReminder && reminder != null && reminder.isDaily)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  // ✅ Use 'child' instead of 'children'
                  '🔄 This reminder repeats daily',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _actionButton(
                  label: "Pick Time",
                  color: primaryColor,
                  icon: Icons.access_time,
                  onPressed: () => _pickTime(type),
                ),
                _actionButton(
                  label: "Once",
                  color: Colors.green,
                  icon: Icons.notifications_active,
                  onPressed: hasReminder
                      ? null // Disable if reminder already exists
                      : () => _scheduleReminder(type, false),
                ),
                _actionButton(
                  label: "Daily",
                  color: Colors.blue,
                  icon: Icons.repeat,
                  onPressed: hasReminder
                      ? null // Disable if reminder already exists
                      : () => _scheduleReminder(type, true),
                ),
                _actionButton(
                  label: "Delete",
                  color: Colors.red,
                  icon: Icons.delete_outline,
                  onPressed: hasReminder ? () => _cancelReminder(type) : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }
}
*/
