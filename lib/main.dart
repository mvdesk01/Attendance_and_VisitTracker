import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:attendance_system_ios/bloc/main_bloc.dart';
import 'package:attendance_system_ios/screen/AdminHomeScreen/AdminHome.dart';
import 'package:attendance_system_ios/screen/Home/home.dart';
import 'package:attendance_system_ios/screen/Login/login_screen.dart'; // Add LoginScreen import
import 'package:attendance_system_ios/screen/Splash%20Screen/splash_screen.dart';
import 'package:attendance_system_ios/screen/Visit/Start%20Stop%20Visit/start_stop_visit.dart';
import 'package:attendance_system_ios/service/internet_service.dart';
import 'package:attendance_system_ios/service/WebService.dart';
import 'package:attendance_system_ios/simple_bloc_observer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/data/latest.dart' as tz;
import 'package:http/http.dart' as http;

final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
// final service = FlutterBackgroundService();

bool isloggedIn=false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz_data.initializeTimeZones();
  HttpOverrides.global = MyHttpOverrides();
  // ✅ Initialize AlarmManager only on Android
  if (Platform.isAndroid) {
    await AndroidAlarmManager.initialize();
  }
  Bloc.observer = SimpleBlocObserver();

  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('icon1');
  const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();

  final NotificationAppLaunchDetails? notificationAppLaunchDetails =
  await notificationsPlugin.getNotificationAppLaunchDetails();

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await notificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {              // notification click response
      handleNotificationResponse(response.payload);
    },
  );

  // Check if app was launched via a notification
  String? initialPayload;
  if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {             // notificatioAppLaunch on click
    initialPayload = notificationAppLaunchDetails!.notificationResponse?.payload;
  }

  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );
  // Check if Firebase is already initialized
  // if (Firebase.apps.isEmpty) {
  //    Firebase.initializeApp(
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
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
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
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   Future.delayed(Duration(seconds: 1), () {
    //     InternetService().startListening(
    //       MyApp.navigatorKey.currentState!.overlay!.context,
    //     );
    //   });
    // });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      InternetService().startListening(MyApp.navigatorKey.currentState!.overlay!.context);
    });
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inactivityTimer?.cancel();
    InternetService().stopListening();
    super.dispose();
  }



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
              child: SplashScreen(initialPayload: widget.initialPayload)
          ),
            '/track_visit_location': (context) => VisitStartStopScreen(visit: null),
            '/Login': (context) => const LoginScreen(),
            '/Home': (context) => HomeScreen(initialPayload: widget.initialPayload),
            "/AdminHome": (context)=> const AdminHomeScreen(),
        },
        // routes: {
        //   '/track_visit_location': (context) => VisitStartStopScreen(),
        //   '/': (context) => SplashScreen(),
        //   '/Login': (context) => const LoginScreen(),
        //   '/Home': (context) => const HomeScreen(),
        //   "/AdminHome": (context)=> const AdminHomeScreen(),
        // },
        title: 'Attendance',
        theme: ThemeData(scaffoldBackgroundColor: Colors.blue[50]),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}


class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

class VisitState {
  static final ValueNotifier<bool> isVisitRunning = ValueNotifier(false);
  static final ValueNotifier<bool> isVisitStarted = ValueNotifier(false);
  static final ValueNotifier<int> countRemainingLatLong = ValueNotifier(0);
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

// void checkConnectivity() {
//   Connectivity().onConnectivityChanged.listen((ConnectivityResult result) async {
//     if (result != ConnectivityResult.none) {
//       await syncOfflineData(); //  Push stored data when internet is back
//     }
//   });
// }

/*Future<void> syncOfflineData() async {
  bool hasInternet = await InternetService().hasInternetAccess();
  if (!hasInternet) {
    print("❌ No internet, skipping sync.");
    return;
  }

  List<Map<String, dynamic>> storedData = await DatabaseHelper().getStoredLocations();
  print("📌 Syncing ${storedData.length} stored records to server...");

  for (var data in storedData) {
    try {
      String actualDate=DateFormat('dd/MM/yyy').format(DateTime.now()).split(" ").first;
      print("📤 Sending offline data to server: $data");

      final response = await http.post(
        Uri.parse('http://114.143.140.28:8020/api/Visit/InsertUpdateTrackingRecords'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "transactionId":"string",
          "transactionDate":data['timestamp'],
          "transactionTime":data['timestamp'],
          "latitude": data['latitude'].toString(),
          "longitude": data['longitude'].toString(),
          "staffCode": data['staffcode'],
          "deviceId":"11",
          "uuidid": "11",
          "process": "11",
          "actualDate":actualDate,
          "actualTime": "11",
          "address": data['address'],
          "speed": data['speed'].toString(),
          "distance": data['distanceInMeters'].toString(),
          "srNo_Vo":data['srNo_Vo'],
          "status": "S",
          "distanceInKm": data['distanceInKm'].toString(),
          "gpsCheckFlag": "1",
          "transactionTime": data['timestamp'],
        }),
      );

      if (response.statusCode == 200) {
        await DatabaseHelper().deleteLocation(data['id']);
        Fluttertoast.showToast(msg: "Offline data sent: ${data['latitude']}, LONG: ${data['longitude']}");
        // Remove after successful sync
        print("✅ Offline data sent & deleted: LAT: ${data['latitude']}, LONG: ${data['longitude']}");
      } else {
        print("❌ Failed to send offline data. Status: ${response.statusCode}, Response: ${response.body}");
      }
    } catch (e) {
      print("❌ Error syncing offline data: $e");
    }
  }

  //print("✅ Sync complete!");
}*/