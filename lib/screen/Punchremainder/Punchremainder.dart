import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:fluttertoast/fluttertoast.dart';

class PunchRemainderScreen extends StatefulWidget {
  const PunchRemainderScreen({super.key});

  @override
  State<PunchRemainderScreen> createState() => _PunchRemainderScreenState();
}

class _PunchRemainderScreenState extends State<PunchRemainderScreen> {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();
  List<String> alarms = [];

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    requestNotificationPermission();
  }

  // Initialize Notifications
  Future<void> _initializeNotifications() async {
    print('Initializing notifications...');
    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata')); // Set your desired timezone

      const AndroidInitializationSettings androidInitializationSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
      InitializationSettings(android: androidInitializationSettings);

      final bool? initialized =
      await _notificationsPlugin.initialize(initializationSettings,
          onDidReceiveNotificationResponse: _onSelectNotification);
      print('Notifications initialized: $initialized');
    } catch (e) {
      print('Error during notification initialization: $e');
    }
  }

  // Notification permission request
  Future<void> requestNotificationPermission() async {
    print('Requesting notification permission...');
    try {
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
      final status = await Permission.notification.status;
      print('Notification permission status: $status');
    } catch (e) {
      print('Error during permission request: $e');
    }
  }

  // Handle Notification Tap
  Future<void> _onSelectNotification(NotificationResponse response) async {
    if (response.payload != null) {
      Fluttertoast.showToast(
        msg: response.payload!, // Show message when notification tapped
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  // Schedule Alarm and Show Toast for Punch In/Out
  Future<void> _scheduleAlarm(
      TimeOfDay time, String message, String sound) async {
    print('Scheduling alarm: $message at ${time.format(context)}');
    try {
      final now = DateTime.now();
      final scheduleTime = DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      final tzTime = tz.TZDateTime.from(scheduleTime, tz.local);

      // Check if the time is before now, if so schedule for the next day
      final adjustedTime = tzTime.isBefore(tz.TZDateTime.now(tz.local))
          ? tzTime.add(const Duration(days: 1))
          : tzTime;

      print('Adjusted alarm time: $adjustedTime');

      final androidDetails = AndroidNotificationDetails(
        'alarm_channel',
        'Punch Alarms',
        channelDescription: 'Channel for punch alarms',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableLights: true,
      );

      final notificationDetails = NotificationDetails(android: androidDetails);

      await _notificationsPlugin.zonedSchedule(
        alarms.length + 1, // Unique ID for each alarm
        message,
        'It\'s time to $message!',
        adjustedTime,
        notificationDetails,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
        payload: message, // Payload to be passed to the onTap handler
      );

      setState(() {
        alarms.add('$message at ${time.format(context)}');
      });
      print('Alarm successfully scheduled.');
    } catch (e) {
      print('Error scheduling alarm: $e');
    }
  }

  // Cancel All Alarms
  Future<void> _cancelAllAlarms() async {
    print('Cancelling all alarms...');
    try {
      await _notificationsPlugin.cancelAll();
      setState(() {
        alarms.clear();
      });
      print('All alarms cancelled.');
    } catch (e) {
      print('Error cancelling alarms: $e');
    }
  }

  // Show Time Picker for Alarm
  Future<void> _showTimePicker(String message) async {
    print('Showing time picker for $message...');
    try {
      final TimeOfDay? selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (selectedTime != null) {
        print('Time selected: ${selectedTime.format(context)}');
        // Select sound (For simplicity, we use a default sound here)
        String sound = 'default_ringtone'; // Add your custom sound in `res/raw`
        await _scheduleAlarm(selectedTime, message, sound);
      } else {
        print('Time picker cancelled.');
      }
    } catch (e) {
      print('Error showing time picker: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Set Alarms',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _showTimePicker('Punch in now'),
                child: const Text('Set Punch In Alarm'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _showTimePicker('Punch out now'),
                child: const Text('Set Punch Out Alarm'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _cancelAllAlarms,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                child: const Text('Cancel All Alarms'),
              ),
              const SizedBox(height: 20),
              const Text(
                'Scheduled Alarms',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              alarms.isEmpty
                  ? const Text('No alarms set.')
                  : ListView.builder(
                shrinkWrap: true,
                itemCount: alarms.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(Icons.alarm),
                    title: Text(alarms[index]),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
