import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({Key? key}) : super(key: key);

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  TimeOfDay? _punchInTime;
  TimeOfDay? _punchOutTime;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _requestExactAlarmPermission();
    _initializeNotifications();
  }

  Future<void> _requestExactAlarmPermission() async {
    if (Platform.isAndroid &&
        await Permission.scheduleExactAlarm.isDenied) {
      final status = await Permission.scheduleExactAlarm.request();
      if (!status.isGranted) {
        print("Exact alarm permission denied");
      }
    }
  }

  void _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    // final iosSettings = DarwinInitializationSettings(
    //   onDidReceiveLocalNotification: (id, title, body, payload) async {
    //     print("iOS local notification received: $title");
    //   },
    // );
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: (id, title, body, payload) async {
        // Handle notification when app is in foreground
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
      },
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(initSettings);

    final iosPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      print('Notification permission granted: $granted');
    }

    tz.initializeTimeZones();
  }

  void _pickTime(bool isPunchIn) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isPunchIn) {
          _punchInTime = picked;
        } else {
          _punchOutTime = picked;
        }
      });
    }
  }

  void _scheduleAlarm(TimeOfDay selectedTime, int alarmId) async {
    if (Platform.isAndroid) {
      final now = DateTime.now();
      final scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      await AndroidAlarmManager.oneShotAt(
        scheduledTime,
        alarmId,
        alarmCallback,
        exact: true,
        wakeup: true,
      );
    }

    else if (Platform.isIOS) {
      final scheduledDate = _nextInstanceOfTime(selectedTime);
      print("Scheduling iOS notification at: $scheduledDate (local time)");
      try {
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          alarmId,
          'PUNCH REMINDER',
          'ITS TIME MARK YOUR PUNCH',
          scheduledDate,
          const NotificationDetails(
            iOS: DarwinNotificationDetails(
              sound: 'default', // Ensure sound is enabled
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidAllowWhileIdle: true,
          uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'punch_reminder_$alarmId',
        );
        print('✅ Successfully scheduled notification');
      } catch (e, stack) {
        print('❌ Error scheduling notification: $e');
        print(stack);
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Alarm set for ${selectedTime.format(context)}')),
    );
  }

  void _scheduleRepeatingAlarm(TimeOfDay selectedTime, int alarmId) async {
    if (Platform.isAndroid) {
      final now = DateTime.now();
      final firstTrigger = DateTime(
        now.year,
        now.month,
        now.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      await AndroidAlarmManager.periodic(
        const Duration(days: 1),
        alarmId,
        alarmCallback,
        startAt: firstTrigger,
        exact: true,
        wakeup: true,
      );
    } else if (Platform.isIOS) {
      final scheduledDate = _nextInstanceOfTime(selectedTime);
      print("Scheduling iOS repeating notification at: $scheduledDate");

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        alarmId,
        'PUNCH REMINDER',
        'ITS TIME MARK YOUR PUNCH',
        scheduledDate,
        const NotificationDetails(
          iOS: DarwinNotificationDetails(),
        ),
        androidAllowWhileIdle: true,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Daily alarm set for ${selectedTime.format(context)}')),
    );
  }

  void _cancelAlarm(int alarmId) async {
    await AndroidAlarmManager.cancel(alarmId);
    await _flutterLocalNotificationsPlugin.cancel(alarmId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Alarm with ID $alarmId cancelled')),
    );
  }


  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final tz.Location localTz = tz.getLocation('Asia/Kolkata'); // Replace with your timezone
    final now = tz.TZDateTime.now(localTz);

    var scheduled = tz.TZDateTime(
      localTz,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    print('Converted $time to $scheduled (ACTUAL LOCAL TIME)');
    return scheduled;
  }

  void _testImmediateNotification() async {
    await _flutterLocalNotificationsPlugin.show(
      999,
      'Test Notification',
      'This is a test on iOS',
      const NotificationDetails(
        iOS: DarwinNotificationDetails(),
      ),
    );
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
              time: _punchInTime,
              icon: Icons.login,
              primaryColor: Colors.green,
              alarmId: 1001,
              isPunchIn: true,
            ),
            const SizedBox(height: 20),
            _buildPunchCard(
              context,
              title: "Punch Out Reminder",
              time: _punchOutTime,
              icon: Icons.logout,
              primaryColor: Colors.red,
              alarmId: 1002,
              isPunchIn: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPunchCard(
      BuildContext context, {
        required String title,
        required TimeOfDay? time,
        required IconData icon,
        required Color primaryColor,
        required int alarmId,
        required bool isPunchIn,
      }) {
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
            /// Header
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            /// Selected Time
            Text(
              time != null
                  ? "Selected Time: ${time.format(context)}"
                  : "No time selected",
              style: TextStyle(
                fontSize: 16,
                color: time != null ? Colors.black87 : Colors.black45,
              ),
            ),

            const SizedBox(height: 16),

            /// Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _actionButton(
                  label: "Pick Time",
                  color: primaryColor,
                  icon: Icons.access_time,
                  onPressed: () => _pickTime(isPunchIn),
                ),
                _actionButton(
                  label: "Once",
                  color: primaryColor,
                  icon: Icons.notifications_active,
                  onPressed: time != null
                      ? () => _scheduleAlarm(time, alarmId)
                      : null,
                ),
                _actionButton(
                  label: "Daily",
                  color: primaryColor,
                  icon: Icons.repeat,
                  onPressed: time != null
                      ? () => _scheduleRepeatingAlarm(time, alarmId)
                      : null,
                ),
                _actionButton(
                  label: "Delete",
                  color: Colors.grey,
                  icon: Icons.delete_outline,
                  onPressed: () => _cancelAlarm(alarmId),
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
          child: Icon(icon, size: 18),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

}



@pragma('vm:entry-point')
void alarmCallback() async {
  print('Alarm callback triggered!');

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // 1. Initialize for both platforms
  const AndroidInitializationSettings androidSettings =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  final DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
    requestAlertPermission: false, // Already requested in main app
    requestBadgePermission: false,
    requestSoundPermission: false,
  );

  await flutterLocalNotificationsPlugin.initialize(
    InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    ),
  );

  // 2. Show notification for both platforms
  await flutterLocalNotificationsPlugin.show(
    0,
    'PUNCH REMINDER',
    'ITS TIME MARK YOUR PUNCH',
    NotificationDetails(
      android: AndroidNotificationDetails(
        'alarm_channel',
        'Alarm Channel',
        importance: Importance.max,
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

  print('Notification shown successfully');
}




/*  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set Punch Reminders')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ElevatedButton(
            //   onPressed: _testImmediateNotification,
            //   child: const Text("Test iOS Notification"),
            // ),
            // const SizedBox(height: 20),

            // Punch In
            Card(
              color: Colors.green.shade50,
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      _punchInTime != null
                          ? 'Punch In Time: ${_punchInTime!.format(context)}'
                          : 'No Punch In Time Selected',
                      style: const TextStyle(color: Colors.green),
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => _pickTime(true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('Pick'),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _punchInTime != null
                            ? () => _scheduleAlarm(_punchInTime!, 1001)
                            : null,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text('Once'),
                      ),
                      ElevatedButton(
                        onPressed: _punchInTime != null
                            ? () => _scheduleRepeatingAlarm(_punchInTime!, 1001)
                            : null,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text('Daily'),
                      ),
                      ElevatedButton(
                        onPressed: () => _cancelAlarm(1001),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Punch Out
            Card(
              color: Colors.red.shade50,
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      _punchOutTime != null
                          ? 'Punch Out Time: ${_punchOutTime!.format(context)}'
                          : 'No Punch Out Time Selected',
                      style: const TextStyle(color: Colors.red),
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => _pickTime(false),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Pick'),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _punchOutTime != null
                            ? () => _scheduleAlarm(_punchOutTime!, 1002)
                            : null,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Once'),
                      ),
                      ElevatedButton(
                        onPressed: _punchOutTime != null
                            ? () => _scheduleRepeatingAlarm(_punchOutTime!, 1002)
                            : null,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Daily'),
                      ),
                      ElevatedButton(
                        onPressed: () => _cancelAlarm(1002),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }*/