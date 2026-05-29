// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'dart:ui';
//
// import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
// import 'package:attendance_system_ios/service/workmanager_service.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';
// import 'package:timezone/data/latest.dart' as tz_data;
// import 'package:workmanager/workmanager.dart';
//
// import '../main.dart';
// import '../model/VisitData/fetch_visit_data.dart';
// import '../simple_bloc_observer.dart';
// import 'background_service.dart';
// import 'log_file_manager.dart';
//
// class AutoStartVisit {
//   late BackgroundServiceAutoStart backgroundService;
//
//     Future<void> startVisit(Data visit) async {
//     try {
//       backgroundService = BackgroundServiceAutoStart();
//       WidgetsFlutterBinding.ensureInitialized();
//       tz_data.initializeTimeZones();
//       HttpOverrides.global = MyHttpOverrides();
//       // await AndroidAlarmManager.initialize();
//       // await Workmanager.iOSBackgroundTask;
//       // await Workmanager().initialize(
//       //   callbackDispatcher,
//       //   isInDebugMode: true,
//       // );
//       // Bloc.observer = SimpleBlocObserver();
//       // ✅ Ensure background service is running
//       if (!await backgroundService.flutterBackgroundService.isRunning()) {
//         await backgroundService.initializeService();
//         bool started = await backgroundService.flutterBackgroundService.startService();
//         LogFileManager.writeLog("start background service stated.");
//         if (!started) {
//           LogFileManager.writeLog("Failed to start background service.");
//           // Fluttertoast.showToast(msg: "Failed to start background service.");
//           return;
//         }
//       }
//
//       // ✅ Handle battery optimization gracefully
//       await _handleBatteryOptimization(visit);
//
//       if (Platform.isIOS) {
//         await NativeLocationBridge.startNativeTracking(visit);
//       }
//       // visit running state store locally
//       await storage.write(key: 'isVisitRunning', value: true.toString());
//       // ✅ Update global state only
//       VisitState.isVisitRunning.value = true;
//       VisitState.isVisitStarted.value = true;
//
//
//       // Fluttertoast.showToast(msg: "Visit started successfully!");
//       print("Visit started successfully!");
//
//       // ✅ Delegate validation & scheduling
//       // _validateAndScheduleVisit(visit);
//     } catch (e) {
//       print("Error starting visit: $e");
//       Fluttertoast.showToast(msg: "Error starting visit: $e");
//       LogFileManager.writeLog("Error starting visit: $e");
//     }
//   }
//
//   Future<void> _handleBatteryOptimization(Data visit) async {
//
//     // ✅ Always continue visit start
//     await startLocationTracking(visit);
//     backgroundService.setServiceAsForeGround();
//     LogFileManager.writeLog("Visit auto-started ${visit.reason} At: ${DateTime.now()}");
//   }
//
//   Future<void> startLocationTracking(Data visit) async {
//
//     Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
//     if(visit.status == 'I'){
//       updateVisitStatusStartingLatLong(position.latitude, position.longitude, visit);
//     }
//     await sendLocation(position.latitude, position.longitude, visit);    // no need but for quickly receiving the first lat long
//
//     print("Tracking started for visit: ${visit.reason/*['VisitName']*/}");
//   }
//
//   Future<void> updateVisitStatusStartingLatLong(double latitude, double longitude, Data visit) async {
//     String? token = await storage.read(key: 'Auth_Token');
//
//     try {
//       // Create HttpClient with SSL bypass
//       final HttpClient client = HttpClient()
//         ..badCertificateCallback = (X509Certificate cert, String host, int port) {
//           print("⚠️ Bypassing SSL check for $host");
//           return true;
//         };
//
//       final uri = Uri.parse("http://114.143.140.28:8020/api/Visit/UpdateStatusStartLatLong/${visit.srNo}/${latitude.toStringAsFixed(8)}/${longitude.toStringAsFixed(8)}/S");
//
//       final HttpClientRequest request = await client.postUrl(uri);
//       request.headers.set(HttpHeaders.contentTypeHeader, "application/json");
//       request.headers.set(HttpHeaders.authorizationHeader, "Bearer $token");
//
//       final HttpClientResponse response = await request.close();
//       final String responseBody = await response.transform(utf8.decoder).join();
//
//       if (response.statusCode == 200) {
//         print('updateVisitStatusStartingLatLong body: $responseBody');
//         LogFileManager.writeLog('✅ updateVisitStatusStartingLatLong Success: $responseBody');
//       } else {
//         print('❌Failed to updateVisitStatusStartingLatLong: ${response.statusCode}, $responseBody');
//         LogFileManager.writeLog('❌ updateVisitStatusStartingLatLong Failure: ${response.statusCode}, $responseBody');
//       }
//     } catch (e) {
//       print('❌Error while calling updateVisitStatusStartingLatLong API: $e');
//       LogFileManager.writeLog('Error while calling updateVisitStatusStartingLatLong API: $e');
//     }
//   }
//
//   Future<void> stopVisit() async {
//     try {
//       await storage.delete(key: 'SelectedVisit');
//       await storage.delete(key: 'AutoStartVisit');
//       await storage.delete(key: 'isVisitRunning');
//       // ✅ Update global state only
//       VisitState.isVisitRunning.value = false;
//       VisitState.isVisitStarted.value = false;
//
//       BackgroundServiceAutoStart backgroundService = BackgroundServiceAutoStart();
//       backgroundService.stopService();
//       // ❗️ Manually cancel the notification (especially for iOS)
//       await FlutterLocalNotificationsPlugin().cancel(foregroundServiceNotificationId);
//       await FlutterLocalNotificationsPlugin().cancel(889);
//       await FlutterLocalNotificationsPlugin().cancelAll();
//       if (Platform.isIOS) {
//         await NativeLocationBridge.stopNativeTracking(); // 👈 Native ios stop tracking
//       }
//       Fluttertoast.showToast(msg: "Visit stopped.");
//       LogFileManager.writeLog("Visit Stopped At: ${DateTime.now()}");
//     } catch (e) {
//       Fluttertoast.showToast(msg: "Error stopping visit: $e");
//       LogFileManager.writeLog("Error stopping visit: $e");
//     }
//   }
//
// }
//
// @pragma('vm:entry-point')
// void onStartAutoStar(ServiceInstance service) async {
//   await service.stopSelf();
//
//   // DartPluginRegistrant.ensureInitialized();
//   print("✅ AutoStart background isolate initialized");
//   LogFileManager.writeLog("✅ AutoStart background isolate initialized");
//
//   if (service is AndroidServiceInstance) {
//     await service.setAsForegroundService();
//     await service.setForegroundNotificationInfo(
//       title: "TRACKING ACTIVE",
//       content: "Location service is running",
//     );
//   }
//
//   // Stop handler
//   service.on("stop_service").listen((event) async {
//     await service.stopSelf();
//     await locationStream?.cancel();
//     locationStream = null;
//   });
//
//   // ✅ Prevent multiple subscriptions
//   if (locationStream != null) {
//     LogFileManager.writeLog("Stream already active, skipping reinit");
//     return;
//   }
//
//   // Clear old data
//   lastPosition = null;
//   lastTime = null;
//   lastPositions.clear();
//
//   // ✅ Configure Android settings for stable GPS
//   // const locationSettings = LocationSettings(
//   //   accuracy: LocationAccuracy.bestForNavigation,
//   //   distanceFilter: 0,
//   // );
//   final androidSettings = AndroidSettings(
//       accuracy: LocationAccuracy.bestForNavigation, // high accuracy + fused provider if available
//       intervalDuration: const Duration(seconds: 7), // update interval
//       distanceFilter: 8,
//   );
//
//   try {
//     locationStream = Geolocator.getPositionStream(locationSettings: androidSettings)
//         .listen(
//           (Position position) async {
//         LogFileManager.writeLog("📍 Stream position: ${position.latitude}, ${position.longitude}");
//
//         final runningVisitId = await storage.read(key: 'runningVisitId');
//
//         // Pass to processing function
//         await _processPositionStream(position, service);
//       },
//       onError: (error) {
//         LogFileManager.writeLog("❌ Stream error: $error");
//       },
//       cancelOnError: false,
//     );
//
//     LogFileManager.writeLog("✅ Stream initialized successfully");
//   } catch (e, st) {
//     LogFileManager.writeLog("❌ Stream init failed: $e\n$st");
//   }
// }
//
// Future<void> _processPositionStream(Position position, ServiceInstance service) async {
//   DateTime now = DateTime.now();
//   final visitJson = await storage.read(key: 'AutoStartVisit');
//   if (visitJson == null) return;
//
//   final visit = Data.fromJson(jsonDecode(visitJson));
//
//   // ⏰ Auto-stop logic
//   try {
//     DateFormat dateFormatter = DateFormat('dd/MM/yyyy');
//     DateFormat timeFormatter12 = DateFormat('hh:mm a');
//     DateFormat timeFormatter24 = DateFormat('HH:mm');
//     DateTime parsedDate = dateFormatter.parse(visit.selectDate!);
//     DateTime parsedEndTime;
//
//     try {
//       parsedEndTime = timeFormatter12.parse(visit.totime!);
//     } catch (_) {
//       parsedEndTime = timeFormatter24.parse(visit.totime!);
//     }
//
//     DateTime visitEndTime = DateTime(
//       parsedDate.year,
//       parsedDate.month,
//       parsedDate.day,
//       parsedEndTime.hour,
//       parsedEndTime.minute,
//     );
//
//     if (now.isAfter(visitEndTime)) {
//       LogFileManager.writeLog("Auto-stopped visit: time expired at $visitEndTime");
//       await service.stopSelf();
//       await locationStream?.cancel();
//       locationStream = null;
//
//       await storage.delete(key: 'SelectedVisit');
//       await storage.delete(key: 'AutoStartVisit');
//       await storage.delete(key: 'isVisitRunning');
//
//       VisitState.isVisitRunning.value = false;
//       VisitState.isVisitStarted.value = false;
//
//       await FlutterLocalNotificationsPlugin().cancel(foregroundServiceNotificationId);
//       if (Platform.isIOS) await NativeLocationBridge.stopNativeTracking();
//
//       Fluttertoast.showToast(msg: "Visit auto-stopped (time ended)");
//       return;
//     }
//   } catch (e) {
//     LogFileManager.writeLog("Auto-stop validation failed: $e");
//   }
//
//   // ✅ Filters
//   if (position.accuracy > 80) {
//     LogFileManager.writeLog("Skipped poor accuracy: ${position.accuracy}m");
//     return;
//   }
//
//   if (lastTime != null && now.difference(lastTime!).inSeconds < 5) {
//     return;
//   }
//
//   double distance = lastPosition == null
//       ? 9999
//       : Geolocator.distanceBetween(
//     lastPosition!.latitude,
//     lastPosition!.longitude,
//     position.latitude,
//     position.longitude,
//   );
//
//   if (distance < 8) {
//     LogFileManager.writeLog("Skipping jitter point (moved $distance m)");
//     return;
//   }
//
//   // ✅ Speed check
//   if (lastPosition != null && lastTime != null) {
//     int timeDiff = now.difference(lastTime!).inSeconds;
//     if (timeDiff > 0) {
//       double speed = distance / timeDiff;
//       if (speed > 45) {
//         LogFileManager.writeLog("Skipped unrealistic speed: ${speed.toStringAsFixed(2)} m/s");
//         return;
//       }
//     }
//   }
//
//   // ✅ Smoothing
//   lastPositions.add(position);
//   if (lastPositions.length > 3) lastPositions.removeAt(0);
//   double avgLat =
//       lastPositions.map((p) => p.latitude).reduce((a, b) => a + b) / lastPositions.length;
//   double avgLng =
//       lastPositions.map((p) => p.longitude).reduce((a, b) => a + b) / lastPositions.length;
//
//   await sendLocation(avgLat, avgLng, visit);
//
//   await NotificationService(FlutterLocalNotificationsPlugin()).showNotification(
//     showNotificationId: foregroundServiceNotificationId,
//     title: "Tracking Active",
//     body:
//     'Lat: ${avgLat.toStringAsFixed(6)}, Long: ${avgLng.toStringAsFixed(6)}, Speed: ${position.speed.toStringAsFixed(2)}',
//     payload: "service",
//     androidNotificationDetails: const AndroidNotificationDetails(
//       notificationChannelId,
//       notificationChannelId,
//       ongoing: true,
//       playSound: false,
//     ),
//   );
//
//   lastPosition = position;
//   lastTime = now;
// }
//
// class BackgroundServiceAutoStart {
//   final FlutterBackgroundService flutterBackgroundService = FlutterBackgroundService();
//   FlutterBackgroundService get instance => flutterBackgroundService;
//
//   Future<void> initializeService() async {
//     await NotificationService(FlutterLocalNotificationsPlugin()).createChannel(
//       const AndroidNotificationChannel(
//         notificationChannelId,
//         notificationChannelId,
//         playSound: false,
//         sound: null,
//         enableVibration: false,
//       ),
//     );
//
//     await flutterBackgroundService.configure(
//       androidConfiguration: AndroidConfiguration(
//         onStart: onStartAutoStar,
//         autoStart: false,
//         isForegroundMode: true,
//         notificationChannelId: notificationChannelId,
//         foregroundServiceNotificationId: foregroundServiceNotificationId,
//         initialNotificationTitle: initialNotificationTitle,
//         initialNotificationContent: initialNotificationContent,
//       ),
//       iosConfiguration: IosConfiguration(
//         autoStart: false,
//         onForeground: onStartAutoStar,
//         onBackground: null,
//       ),
//     );
//     // await flutterBackgroundService.startService();
//   }
//
//   void setServiceAsForeGround() {
//     flutterBackgroundService.invoke("setAsForeground");
//     print("Service set as foreground");
//   }
//
//   void stopService() {
//     flutterBackgroundService.invoke("stop_service");
//     print("Service stopped");
//   }
// }




/*@pragma('vm:entry-point')
void onStartAutoStar(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  print("✅ AutoStart background isolate initialized");
  LogFileManager.writeLog("✅ AutoStart background isolate initialized");

  if (service is AndroidServiceInstance) {
    await service.setAsForegroundService();
    await service.setForegroundNotificationInfo(
      title: "TRACKING ACTIVE",
      content: "Location service is running",
    );
  }

  // Stop handler
  service.on("stop_service").listen((event) async {
    await service.stopSelf();
    _trackingTimer?.cancel();
  });

  if (_trackingTimer != null && _trackingTimer!.isActive) return;

  lastPosition = null;
  lastTime = null;
  lastPositions.clear();

  const Duration interval = Duration(seconds: 10); // safe interval
  const Duration locationTimeout = Duration(seconds: 8);

  _trackingTimer = Timer.periodic(interval, (timer) async {
    print("⏳ Skipping tick, previous location fetch in progress");
    if (_isGettingLocation) {
      LogFileManager.writeLog("⏳ Skipping tick, previous location fetch in progress");
      return;
    }

    _isGettingLocation = true;

    try {
      Position? position;

      try {
        // 💡 Wrapped with timeout-safe call
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          timeLimit: locationTimeout,
        );
      } on TimeoutException {
        LogFileManager.writeLog("⚠️ GPS fetch timed out (no fix within ${locationTimeout.inSeconds}s)");
        return; // Skip this tick gracefully
      } on Exception catch (e) {
        LogFileManager.writeLog("⚠️ Location error: $e");
        return; // skip this cycle safely
      }

      // If still null somehow, skip
      if (position == null) {
        LogFileManager.writeLog("⚠️ Position is null, skipping");
        return;
      }

      await _processPosition(position, service);

    } catch (e, st) {
      LogFileManager.writeLog("Timer tracking error: $e\n$st");
    } finally {
      _isGettingLocation = false;
    }
  });
}

Future<void> _processPosition(Position position, ServiceInstance service) async {
  DateTime now = DateTime.now();
  final Data visit;

  final visitJson = await storage.read(key: 'AutoStartVisit');
  if (visitJson == null) return;
  visit = Data.fromJson(jsonDecode(visitJson));

  // 🔁 Auto-stop logic
  try {
    DateFormat dateFormatter = DateFormat('dd/MM/yyyy');
    DateFormat timeFormatter12 = DateFormat('hh:mm a');
    DateFormat timeFormatter24 = DateFormat('HH:mm');

    DateTime parsedDate = dateFormatter.parse(visit.selectDate!);
    DateTime parsedEndTime;
    try {
      parsedEndTime = timeFormatter12.parse(visit.totime!);
    } catch (_) {
      parsedEndTime = timeFormatter24.parse(visit.totime!);
    }

    DateTime visitEndTime = DateTime(
      parsedDate.year,
      parsedDate.month,
      parsedDate.day,
      parsedEndTime.hour,
      parsedEndTime.minute,
    );

    if (now.isAfter(visitEndTime)) {
      LogFileManager.writeLog("Auto-stopped visit: time expired at $visitEndTime");
      await service.stopSelf();
      _trackingTimer?.cancel();
      await storage.delete(key: 'SelectedVisit');
      await storage.delete(key: 'AutoStartVisit');
      VisitState.isVisitRunning.value = false;
      VisitState.isVisitStarted.value = false;
      await FlutterLocalNotificationsPlugin().cancel(foregroundServiceNotificationId);
      if (Platform.isIOS) await NativeLocationBridge.stopNativeTracking();
      Fluttertoast.showToast(msg: "Visit auto-stopped (time ended)");
      return;
    }
  } catch (e) {
    LogFileManager.writeLog("Auto-stop validation failed: $e");
  }

  // 🔍 Accuracy & filters
  if (position.accuracy > 40) return;
  if (lastTime != null && now.difference(lastTime!).inSeconds < 5) return;

  double distance = lastPosition == null
      ? 9999
      : Geolocator.distanceBetween(
    lastPosition!.latitude,
    lastPosition!.longitude,
    position.latitude,
    position.longitude,
  );

  if (distance < 8) return;

  // 🔁 smoothing
  lastPositions.add(position);
  if (lastPositions.length > 3) lastPositions.removeAt(0);
  double avgLat =
      lastPositions.map((p) => p.latitude).reduce((a, b) => a + b) / lastPositions.length;
  double avgLng =
      lastPositions.map((p) => p.longitude).reduce((a, b) => a + b) / lastPositions.length;

  await sendLocation(avgLat, avgLng, visit);

  await NotificationService(FlutterLocalNotificationsPlugin()).showNotification(
    showNotificationId: foregroundServiceNotificationId,
    title: "Tracking Active",
    body:
    'Lat: ${avgLat.toStringAsFixed(6)}, Long: ${avgLng.toStringAsFixed(6)}, Speed: ${position.speed.toStringAsFixed(2)}',
    payload: "service",
    androidNotificationDetails: const AndroidNotificationDetails(
      notificationChannelId,
      notificationChannelId,
      ongoing: true,
      playSound: false,
    ),
  );

  lastPosition = position;
  lastTime = now;
}*/