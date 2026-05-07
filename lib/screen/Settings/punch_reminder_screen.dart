import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:workmanager/workmanager.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../util/MyColor.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    final type = inputData?['type'] ?? 'punch';
    final isDaily = inputData?['isDaily'] ?? false;
    final alarmId = inputData?['alarmId'] ?? 0;

    final title = type == 'punch_in' ? '⏰ Punch-In Reminder' : '⏰ Punch-Out Reminder';
    final body = type == 'punch_in' 
        ? 'Good morning! It\'s time to mark your arrival.' 
        : 'Workday complete! Don\'t forget to punch out.';

    await flutterLocalNotificationsPlugin.show(
      alarmId,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'punch_channel',
          'Punch Reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'default',
        ),
      ),
    );

    if (!isDaily) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('${type}_has_reminder', false);
    } else {
      final hour = inputData!['hour'];
      final minute = inputData['minute'];
      final now = DateTime.now();
      DateTime tomorrow = DateTime(now.year, now.month, now.day, hour, minute).add(const Duration(days: 1));
      
      await Workmanager().registerOneOffTask(
        '${type}_daily_reminder_$alarmId',
        'punch_reminder',
        initialDelay: tomorrow.difference(now),
        inputData: {
          'alarmId': alarmId,
          'type': type,
          'isDaily': true,
          'hour': hour,
          'minute': minute,
        },
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );
    }

    return Future.value(true);
  });
}

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({Key? key}) : super(key: key);

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  ReminderSettings? _punchInReminder;
  ReminderSettings? _punchOutReminder;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic)),
    );
    
    _initializeNotifications();
    _loadSettings();
    _controller.forward();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadSettings();
    }
  }

  void _initializeNotifications() async {
    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _notificationsPlugin.initialize(const InitializationSettings(android: android, iOS: ios));
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _punchInReminder = _getReminder(prefs, 'punch_in', 1001);
      _punchOutReminder = _getReminder(prefs, 'punch_out', 1002);
    });
  }

  ReminderSettings? _getReminder(SharedPreferences prefs, String type, int id) {
    if (!(prefs.getBool('${type}_has_reminder') ?? false)) return null;
    return ReminderSettings(
      time: TimeOfDay(
        hour: prefs.getInt('${type}_hour') ?? 9,
        minute: prefs.getInt('${type}_minute') ?? 0,
      ),
      isDaily: prefs.getBool('${type}_is_daily') ?? false,
      alarmId: prefs.getInt('${type}_alarm_id') ?? id,
      hasReminder: true,
    );
  }

  Future<void> _schedule(String type, bool isDaily) async {
    final reminder = type == 'punch_in' ? _punchInReminder : _punchOutReminder;
    if (reminder == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please pick a time first')));
      return;
    }

    final now = DateTime.now();
    DateTime scheduled = DateTime(now.year, now.month, now.day, reminder.time.hour, reminder.time.minute);
    if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));

    await Workmanager().registerOneOffTask(
      '${type}_reminder_${reminder.alarmId}',
      'punch_reminder',
      initialDelay: scheduled.difference(now),
      inputData: {
        'alarmId': reminder.alarmId,
        'type': type,
        'isDaily': isDaily,
        'hour': reminder.time.hour,
        'minute': reminder.time.minute,
      },
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${type}_hour', reminder.time.hour);
    await prefs.setInt('${type}_minute', reminder.time.minute);
    await prefs.setBool('${type}_is_daily', isDaily);
    await prefs.setInt('${type}_alarm_id', reminder.alarmId);
    await prefs.setBool('${type}_has_reminder', true);

    _loadSettings();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${isDaily ? "Daily" : "One-time"} reminder set for ${reminder.time.format(context)}'),
      backgroundColor: Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<void> _cancel(String type) async {
    final id = type == 'punch_in' ? 1001 : 1002;
    await Workmanager().cancelByUniqueName('${type}_reminder_$id');
    await _notificationsPlugin.cancel(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${type}_has_reminder', false);
    _loadSettings();
    
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Reminder cleared'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _pickTime(String type) async {
    final picked = await showTimePicker(
      context: context, 
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: MyColors.appDefaultColorCode,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        final r = ReminderSettings(
          time: picked,
          isDaily: false,
          alarmId: type == 'punch_in' ? 1001 : 1002,
          hasReminder: false,
        );
        if (type == 'punch_in') _punchInReminder = r;
        else _punchOutReminder = r;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Punch Reminders",
          style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildCard("Punch In", _punchInReminder, Icons.login_rounded, MyColors.appDefaultColorCode, 'punch_in'),
                const SizedBox(height: 24),
                _buildCard("Punch Out", _punchOutReminder, Icons.logout_rounded, Colors.deepOrange, 'punch_out'),
                const SizedBox(height: 40),
                Text(
                  "Set automated reminders to ensure you never miss marking your attendance.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(String title, ReminderSettings? reminder, IconData icon, Color color, String type) {
    final bool isSet = reminder != null && reminder.hasReminder;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isSet ? color.withOpacity(0.3) : Colors.grey.shade100, width: 2),
        boxShadow: [
          BoxShadow(color: isSet ? color.withOpacity(0.1) : Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(18)),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                const Spacer(),
                if (isSet)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
                    child: Text(reminder.isDaily ? "DAILY" : "ONCE", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: () => _pickTime(type),
              child: Text(
                reminder?.time.format(context) ?? "--:--",
                style: GoogleFonts.poppins(fontSize: 54, fontWeight: FontWeight.w200, color: reminder != null ? Colors.black87 : Colors.grey.shade200),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildAction(Icons.timer_outlined, "Pick", () => _pickTime(type), Colors.grey.shade700, false),
                _buildAction(Icons.notifications_active_outlined, "Once", () => _schedule(type, false), Colors.green, isSet),
                _buildAction(Icons.repeat_rounded, "Daily", () => _schedule(type, true), MyColors.appDefaultColorCode, isSet),
                _buildAction(Icons.delete_outline_rounded, "Clear", () => _cancel(type), Colors.red, !isSet),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAction(IconData icon, String label, VoidCallback onTap, Color color, bool disabled) {
    return Expanded(
      child: Opacity(
        opacity: disabled ? 0.3 : 1.0,
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 6),
              Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }
}

class ReminderSettings {
  final TimeOfDay time;
  final bool isDaily;
  final int alarmId;
  final bool hasReminder;

  ReminderSettings({required this.time, required this.isDaily, required this.alarmId, this.hasReminder = true});
}
