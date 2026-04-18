/*import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class PunchInOutScreen extends StatefulWidget {
  @override
  _PunchInOutScreenState createState() => _PunchInOutScreenState();
}

class _PunchInOutScreenState extends State<PunchInOutScreen> {
  TimeOfDay? punchInTime;
  TimeOfDay? punchOutTime;

  final FlutterSecureStorage secureStorage = FlutterSecureStorage();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    tz_data.initializeTimeZones();
    _loadPunchTimes();
  }

  void _initializeNotifications() {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(android: android);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _loadPunchTimes() async {
    final punchIn = await secureStorage.read(key: 'punchInTime');
    final punchOut = await secureStorage.read(key: 'punchOutTime');

    setState(() {
      punchInTime = punchIn != null ? _parseTime(punchIn) : null;
      punchOutTime = punchOut != null ? _parseTime(punchOut) : null;
    });
  }

  Future<void> _savePunchTime(String key, TimeOfDay? time) async {
    if (time != null) {
      await secureStorage.write(key: key, value: _formatTime(time));
    } else {
      await secureStorage.delete(key: key);
    }
  }

  Future<void> _scheduleNotification({
    required String title,
    required String body,
    required TimeOfDay time,
    required int notificationId,
  }) async {
    final now = DateTime.now();
    final scheduledDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    final notificationTime = scheduledDateTime.isBefore(now)
        ? scheduledDateTime.add(Duration(days: 1))
        : scheduledDateTime;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      title,
      body,
      tz.TZDateTime.from(notificationTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'punch_channel',
          'Punch Notifications',
          channelDescription: 'Notifications for punch in and out',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> _pickPunchInTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        punchInTime = time;
      });

      await _savePunchTime('punchInTime', time);

      await _scheduleNotification(
        title: "Punch IN Reminder",
        body: "Please Punch IN at ${time.format(context)}",
        time: time,
        notificationId: 1,
      );
    }
  }

  Future<void> _pickPunchOutTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        punchOutTime = time;
      });

      await _savePunchTime('punchOutTime', time);

      await _scheduleNotification(
        title: "Punch OUT Reminder",
        body: "Please Punch OUT at ${time.format(context)}",
        time: time,
        notificationId: 2,
      );
    }
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour}:${time.minute}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Punch Scheduler"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Set Your Punch Times",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _buildPunchSection(
              title: "Punch IN",
              time: punchInTime,
              color: Colors.blue,
              onTap: _pickPunchInTime,
              icon: Icons.arrow_upward_rounded,
            ),
            const SizedBox(height: 30),
            _buildPunchSection(
              title: "Punch OUT",
              time: punchOutTime,
              color: Colors.red,
              onTap: _pickPunchOutTime,
              icon: Icons.arrow_downward_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPunchSection({
    required String title,
    required TimeOfDay? time,
    required Color color,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 10),
              if (time != null)
                Text(
                  "Scheduled: ${time.format(context)}",
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                )
              else
                Text(
                  "No Time Set",
                  style: TextStyle(fontSize: 16, color: Colors.black38),
                ),
            ],
          ),
        ),
      ),
    );
  }
}*/






import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PunchInOutScreen extends StatefulWidget {
  @override
  _PunchInOutScreenState createState() => _PunchInOutScreenState();
}

class _PunchInOutScreenState extends State<PunchInOutScreen> {
  TimeOfDay? punchInTime;
  TimeOfDay? punchOutTime;
  Timer? punchInTimer;
  Timer? punchOutTimer;

  final FlutterSecureStorage secureStorage = FlutterSecureStorage();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadPunchTimes();
  }

  void _initializeNotifications() {
    var initializationSettingsAndroid = AndroidInitializationSettings('icon1');
    var initializationSettingsIOS = DarwinInitializationSettings();
    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);

    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showNotification(
      String title, String message, int notificationId) async {
    const androidDetails = AndroidNotificationDetails(
      'punch_channel',
      'Punch Notifications',
      channelDescription: 'Notifications for punch in and out',
      importance: Importance.max,
      priority: Priority.high,
    );
    var iOSDetails = const DarwinNotificationDetails();
    var notificationDetails =
    NotificationDetails(android: androidDetails, iOS: iOSDetails);

    await flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      message,
      notificationDetails,
    );
  }

  Future<void> _loadPunchTimes() async {
    final storedPunchInTime = await secureStorage.read(key: 'punchInTime');
    final storedPunchOutTime = await secureStorage.read(key: 'punchOutTime');

    setState(() {
      punchInTime = storedPunchInTime != null ? _parseTime(storedPunchInTime) : null;
      punchOutTime =
      storedPunchOutTime != null ? _parseTime(storedPunchOutTime) : null;
    });

    if (punchInTime != null) _startPunchInTimer();
    if (punchOutTime != null) _startPunchOutTimer();
  }

  Future<void> _savePunchTime(String key, TimeOfDay? time) async {
    if (time != null) {
      await secureStorage.write(key: key, value: _formatTime(time));
    } else {
      await secureStorage.delete(key: key);
    }
  }

  void _startPunchInTimer() {
    punchInTimer?.cancel();
    punchInTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      final now = TimeOfDay.now();
      if (punchInTime != null &&
          now.hour == punchInTime!.hour &&
          now.minute == punchInTime!.minute) {
        timer.cancel();
        final message = "Please Punch IN at ${punchInTime!.format(context)}";
        _showNotification("Punch IN Reminder", message, 1);
        _savePunchTime('punchInTime', null);
        setState(() {
          punchInTime = null;
        });
      }
    });
  }

  void _startPunchOutTimer() {
    punchOutTimer?.cancel();
    punchOutTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      final now = TimeOfDay.now();
      if (punchOutTime != null &&
          now.hour == punchOutTime!.hour &&
          now.minute == punchOutTime!.minute) {
        timer.cancel();
        final message = "Please Punch OUT at ${punchOutTime!.format(context)}";
        _showNotification("Punch OUT Reminder", message, 2);
        _savePunchTime('punchOutTime', null);
        setState(() {
          punchOutTime = null;
        });
      }
    });
  }

  Future<void> _pickPunchInTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        punchInTime = time;
      });
      await _savePunchTime('punchInTime', time);
      _startPunchInTimer();
    }
  }

  Future<void> _pickPunchOutTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        punchOutTime = time;
      });
      await _savePunchTime('punchOutTime', time);
      _startPunchOutTimer();
    }
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour}:${time.minute}';
  }

  @override
  void dispose() {
    punchInTimer?.cancel();
    punchOutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Punch Scheduler"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Set Your Punch Times",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _buildPunchSection(
              title: "Punch IN",
              time: punchInTime,
              color: Colors.blue,
              onTap: _pickPunchInTime,
              icon: Icons.arrow_upward_rounded,
            ),
            const SizedBox(height: 30),
            _buildPunchSection(
              title: "Punch OUT",
              time: punchOutTime,
              color: Colors.red,
              onTap: _pickPunchOutTime,
              icon: Icons.arrow_downward_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPunchSection({
    required String title,
    required TimeOfDay? time,
    required Color color,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 10),
              if (time != null)
                Text(
                  "Scheduled: ${time.format(context)}",
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                )
              else
                Text(
                  "No Time Set",
                  style: TextStyle(fontSize: 16, color: Colors.black38),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
