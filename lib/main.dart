import 'dart:async';
import 'dart:io';

import 'package:attendance_system_ios/bloc/main_bloc.dart';
import 'package:attendance_system_ios/screen/AdminHomeScreen/AdminHome.dart';
import 'package:attendance_system_ios/screen/Home/home.dart';
import 'package:attendance_system_ios/screen/Login/login_screen.dart'; // Add LoginScreen import
import 'package:attendance_system_ios/screen/Punchremainder/Punchreminderscreennew.dart';
import 'package:attendance_system_ios/screen/Splash%20Screen/splash_screen.dart';
import 'package:attendance_system_ios/screen/Visit/Start%20Stop%20Visit/start_stop_visit.dart';
import 'package:attendance_system_ios/service/WebService.dart';
import 'package:attendance_system_ios/service/internet_service.dart';
import 'package:attendance_system_ios/simple_bloc_observer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:workmanager/workmanager.dart';

final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
// final service = FlutterBackgroundService();

bool isloggedIn = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz_data.initializeTimeZones();
  HttpOverrides.global = MyHttpOverrides();
  // ✅ Initialize AlarmManager only on Android
  // if (Platform.isAndroid) {
  //   await AndroidAlarmManager.initialize();
  // }

  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true,
  );

  Bloc.observer = SimpleBlocObserver();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('icon1');
  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings();

  final NotificationAppLaunchDetails? notificationAppLaunchDetails =
      await notificationsPlugin.getNotificationAppLaunchDetails();

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await notificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      // notification click response
      handleNotificationResponse(response.payload);
    },
  );

  // Check if app was launched via a notification
  String? initialPayload;
  if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
    // notificatioAppLaunch on click
    initialPayload =
        notificationAppLaunchDetails!.notificationResponse?.payload;
  }

  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );
  // Check if Firebase is already initialized
  // if (Firebase.apps.isEmpty) {
  //   Firebase.initializeApp(
  //     options: DefaultFirebaseOptions.currentPlatform,
  //   );
  // }
  tz.initializeTimeZones();

  runApp(MyApp(initialPayload: initialPayload));
}

void handleNotificationResponse(String? payload) {
  if (payload != null && !payload.startsWith('alarm')) {
    MyApp.navigatorKey.currentState?.pushNamed(
      '/track_visit_location',
      arguments: payload,
    );
  }
}

class MyApp extends StatefulWidget {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  final String? initialPayload;

  const MyApp({super.key, this.initialPayload});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Timer? _inactivityTimer;
  DateTime? _lastActiveTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // _resetInactivityTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inactivityTimer?.cancel();
    InternetService().stopListening();
    super.dispose();
  }

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   if (state == AppLifecycleState.paused) {
  //     _startLogoutTimer();
  //   } else if (state == AppLifecycleState.resumed) {
  //     if (_inactivityTimer?.isActive == false) {
  //       _logoutUser();
  //     } else {
  //       _resetInactivityTimer();
  //     }
  //   }
  // }

  // void _resetInactivityTimer() {
  //   _inactivityTimer?.cancel();
  //   _inactivityTimer = Timer(Duration(minutes: 30), _logoutUser);
  // }
  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   if (state == AppLifecycleState.paused) {
  //     _lastActiveTime = DateTime.now();
  //     _startLogoutTimer();
  //   } else if (state == AppLifecycleState.resumed) {
  //     final now = DateTime.now();
  //     if (_lastActiveTime != null &&
  //         now.difference(_lastActiveTime!).inMinutes > 30) {
  //       _logoutUser();
  //     } else {
  //       _resetInactivityTimer();
  //     }
  //   }
  // }
  //
  // void _resetInactivityTimer() {
  //   _lastActiveTime = DateTime.now();
  //   _inactivityTimer?.cancel();
  //   _inactivityTimer = Timer(const Duration(minutes: 30), _logoutUser);
  // }
  //
  // void _startLogoutTimer() {
  //   _inactivityTimer?.cancel();
  //   _inactivityTimer = Timer(Duration(minutes: 30), _logoutUser);
  // }

  // void _logoutUser() {
  //   _inactivityTimer?.cancel();
  //     isloggedIn=true;
  //   MyApp.navigatorKey.currentState?.pushAndRemoveUntil(
  //
  //     MaterialPageRoute(builder: (context) => SplashScreen()),
  //         (Route<dynamic> route) => false, // Clears all previous routes
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MainBloc(webService: WebService()),
      child: MaterialApp(
        navigatorKey: MyApp.navigatorKey,
        scaffoldMessengerKey: scaffoldMessengerKey,
        initialRoute: '/',
        routes: {
          '/': (context) => BlocProvider(
              create: (context) {
                return MainBloc(webService: WebService());
              },
              child: SplashScreen(initialPayload: widget.initialPayload)),
          '/track_visit_location': (context) =>
              VisitStartStopScreen(visit: null),
          '/Login': (context) => const LoginScreen(),
          '/Home': (context) =>
              HomeScreen(initialPayload: widget.initialPayload),
          "/AdminHome": (context) => const AdminHomeScreen(),
        },
        title: 'Attendance',
        theme: ThemeData(scaffoldBackgroundColor: Colors.blueGrey[50]),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class VisitState {
  static final ValueNotifier<bool> isVisitRunning = ValueNotifier(false);
  static final ValueNotifier<bool> isVisitStarted = ValueNotifier(false);
  static final ValueNotifier<int> countRemainingLatLong = ValueNotifier(0);
  static int? runningVisitSrNo;
}
