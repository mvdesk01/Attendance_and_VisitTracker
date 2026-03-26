import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:attendance_system_ios/main.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart' hide ServiceStatus;
import '../database/database_helper.dart';
import '../model/VisitData/fetch_visit_data.dart';
import 'internet_service.dart';
import 'log_file_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';


const String notificationChannelId = "foreground_service";
const int foregroundServiceNotificationId = 888;
const String initialNotificationTitle = "TRACK YOUR LOCATION";
const String initialNotificationContent = "Initializing...";
const int timeInterval = 30; // API call interval in seconds
FlutterSecureStorage storage = FlutterSecureStorage();
String? staffcode;
Position? lastPosition;
// Position? lastPosition;
DateTime? lastTime;
StreamSubscription<Position>? locationStream;
// StreamSubscription<Position>? _locationStream;
List<Position> lastPositions = [];
List<Map<String, dynamic>> _syncQueue = [];
bool _isSyncing = false;
bool isTrackingActive = false;
bool isRestartDuringTracking = false;

/// Adaptive indoor/outdoor state
/*bool isIndoor = false;
int indoorCounter = 0;
int outdoorCounter = 0;

bool hasSmoothed = false;
double smoothLat = 0.0;
double smoothLng = 0.0;

// Indoor/outdoor detection thresholds
const int kIndoorAccuracyEnter = 70;  // accuracy > 70m → likely indoor
const int kOutdoorAccuracyExit = 40;  // accuracy < 40m → likely outdoor*/

/*@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized(); // <-- Add this line
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
    service.setForegroundNotificationInfo(
      title: "TRACKING ACTIVE",
      content: "Location service is running",
    );
  }

  service.on("stop_service").listen((event) async {
    await service.stopSelf();
    await locationStream?.cancel();
    locationStream = null;
  });

  if (locationStream != null) return; // prevent multiple listeners

  // ✅ Optimized Android location settings
  final androidSettings = AndroidSettings(
    accuracy: LocationAccuracy.bestForNavigation,
  );

  // lastPosition = null;
  // lastTime = null;

  try{
    locationStream = Geolocator.getPositionStream(locationSettings: androidSettings)
        .listen((Position position) async {
       print("getPositionStream lat long ${position.latitude}, ${position.longitude}");
    });
  } catch (e){
    print("onstart exception $e");
  }
}*/

/// ✅ Updated onStart with speed-based dynamic intervals
/*@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
    service.setForegroundNotificationInfo(
      title: "Tracking Active",
      content: "Location service running...",
    );
  }

  service.on("stop_service").listen((event) async {
    await service.stopSelf();
    await locationStream?.cancel();
    locationStream = null;
  });

  if (locationStream != null) return;

  // 🚀 Start in idle mode
  AndroidSettings currentSettings = AndroidSettings(
    accuracy: LocationAccuracy.best,
    intervalDuration: const Duration(seconds: 20),
    distanceFilter: 15,
    forceLocationManager: true,
    foregroundNotificationConfig: const ForegroundNotificationConfig(
      notificationTitle: "Tracking Active",
      notificationText: "Stationary - saving battery",
      enableWakeLock: true,
    ),
  );

  lastPosition = null;
  lastTime = null;

  void restartStream(AndroidSettings newSettings) async {
    await locationStream?.cancel();
    locationStream = Geolocator.getPositionStream(locationSettings: newSettings)
        .listen((Position position) async {
      if (position.accuracy > 40) return;

      DateTime now = DateTime.now();

      // Time filter
      if (lastTime != null && now.difference(lastTime!).inSeconds < 2) return;

      double distance = lastPosition == null
          ? 9999
          : Geolocator.distanceBetween(
        lastPosition!.latitude, lastPosition!.longitude,
        position.latitude, position.longitude,
      );

      // ✅ SPEED-BASED SWITCH
      double speed = position.speed; // m/s

      if (speed < 0.5) {
        // Idle
        if (newSettings.intervalDuration != const Duration(seconds: 20)) {
          print("🛑 Idle mode → low updates");
          restartStream(AndroidSettings(
            accuracy: LocationAccuracy.best,
            intervalDuration: const Duration(seconds: 20),
            distanceFilter: 15,
            forceLocationManager: true,
            foregroundNotificationConfig: const ForegroundNotificationConfig(
              notificationTitle: "Tracking Active",
              notificationText: "Stationary - saving battery",
              enableWakeLock: true,
            ),
          ));
        }
      } else if (speed >= 0.5 && speed <= 3) {
        // Walking
        if (newSettings.intervalDuration != const Duration(seconds: 5)) {
          print("🚶 Walking mode → medium updates");
          restartStream(AndroidSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            intervalDuration: const Duration(seconds: 5),
            distanceFilter: 5,
            forceLocationManager: true,
            foregroundNotificationConfig: const ForegroundNotificationConfig(
              notificationTitle: "Tracking Active",
              notificationText: "Walking - high precision",
              enableWakeLock: true,
            ),
          ));
        }
      } else {
        // Driving
        if (newSettings.intervalDuration != const Duration(seconds: 2)) {
          print("🚗 Driving mode → max updates");
          restartStream(AndroidSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            intervalDuration: const Duration(seconds: 2),
            distanceFilter: 10,
            forceLocationManager: true,
            foregroundNotificationConfig: const ForegroundNotificationConfig(
              notificationTitle: "Tracking Active",
              notificationText: "Driving - ultra precision",
              enableWakeLock: true,
            ),
          ));
        }
      }

      // ✅ Smoothing (average last 3 points)
      lastPositions.add(position);
      if (lastPositions.length > 3) lastPositions.removeAt(0);
      double avgLat = lastPositions.map((p) => p.latitude).reduce((a, b) => a + b) / lastPositions.length;
      double avgLng = lastPositions.map((p) => p.longitude).reduce((a, b) => a + b) / lastPositions.length;

      final visitJson = await storage.read(key: 'SelectedVisit');
      if (visitJson != null) {
        final Data visit = Data.fromJson(jsonDecode(visitJson));
        await sendLocation(avgLat, avgLng, visit);
      }

      lastPosition = position;
      lastTime = now;
    });
  }

  // Start first stream
  restartStream(currentSettings);
}*/


/*@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
    service.setForegroundNotificationInfo(
      title: "Tracking Active",
      content: "Location service running...",
    );
  }

  service.on("stop_service").listen((event) async {
    await service.stopSelf();
    await locationStream?.cancel();
    locationStream = null;
  });

  if (locationStream != null) return;

  // 🚀 Start in "stationary mode" (battery saver)
  AndroidSettings currentSettings = AndroidSettings(
    accuracy: LocationAccuracy.best,
    intervalDuration: const Duration(seconds: 20),
    distanceFilter: 15,
    forceLocationManager: true,
    foregroundNotificationConfig: const ForegroundNotificationConfig(
      notificationTitle: "Tracking Active",
      notificationText: "Running in background",
      enableWakeLock: true,
    ),
  );

  lastPosition = null;
  lastTime = null;

  void restartStream(AndroidSettings newSettings) async {
    await locationStream?.cancel();
    locationStream = Geolocator.getPositionStream(locationSettings: newSettings)
        .listen((Position position) async {
      if (position.accuracy > 40) return;

      DateTime now = DateTime.now();

      // Time filter
      if (lastTime != null && now.difference(lastTime!).inSeconds < 3) return;

      // Distance
      double distance = lastPosition == null
          ? 9999
          : Geolocator.distanceBetween(
        lastPosition!.latitude, lastPosition!.longitude,
        position.latitude, position.longitude,
      );

      // 🚀 Dynamic adaptation
      if (distance > 10) {
        // User is moving → switch to high-frequency mode
        if (newSettings.intervalDuration != const Duration(seconds: 5)) {
          print("⚡ Switching to MOVING mode");
          restartStream(AndroidSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            intervalDuration: const Duration(seconds: 5),
            distanceFilter: 5,
            forceLocationManager: true,
            foregroundNotificationConfig: const ForegroundNotificationConfig(
              notificationTitle: "Tracking Active",
              notificationText: "Moving - high precision",
              enableWakeLock: true,
            ),
          ));
        }
      } else {
        // User is stationary → switch to low-frequency mode
        if (newSettings.intervalDuration != const Duration(seconds: 20)) {
          print("🛑 Switching to STATIONARY mode");
          restartStream(AndroidSettings(
            accuracy: LocationAccuracy.best,
            intervalDuration: const Duration(seconds: 20),
            distanceFilter: 15,
            forceLocationManager: true,
            foregroundNotificationConfig: const ForegroundNotificationConfig(
              notificationTitle: "Tracking Active",
              notificationText: "Stationary - saving battery",
              enableWakeLock: true,
            ),
          ));
        }
      }

      // Smoothing (average last 3 positions)
      lastPositions.add(position);
      if (lastPositions.length > 3) lastPositions.removeAt(0);
      double avgLat = lastPositions.map((p) => p.latitude).reduce((a, b) => a + b) / lastPositions.length;
      double avgLng = lastPositions.map((p) => p.longitude).reduce((a, b) => a + b) / lastPositions.length;

      final visitJson = await storage.read(key: 'SelectedVisit');
      if (visitJson != null) {
        final Data visit = Data.fromJson(jsonDecode(visitJson));
        await sendLocation(avgLat, avgLng, visit);
      }

      lastPosition = position;
      lastTime = now;
    });
  }

  // Start first stream
  restartStream(currentSettings);
}*/

/// new onStart with all filters and including all android settings
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  try{
    // WidgetsFlutterBinding.ensureInitialized(); // <-- Add this line
    DartPluginRegistrant.ensureInitialized();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    isTrackingActive = await prefs.getBool("isTrackingActive")?? false;
    isRestartDuringTracking = await prefs.getBool("isRestartDuringTracking")?? false;
    if(isTrackingActive){
      if (service is AndroidServiceInstance) {
        service.setAsForegroundService();
        service.setForegroundNotificationInfo(
          title: "TRACKING ACTIVE",
          content: "Location service is running",
        );
      }
      if(isRestartDuringTracking){
        await LogFileManager.writeLog("Device Restarted during tracking");
      }
      prefs.setBool("isRestartDuringTracking", true);
    }else{
      await LogFileManager.writeLog("Device Restarted");
      await service.stopSelf();
      await locationStream?.cancel();
      locationStream = null;
      return;
    }

    service.on("stop_service").listen((event) async {
      await service.stopSelf();
      await locationStream?.cancel();
      locationStream = null;
    });

    if (locationStream != null) return; // prevent multiple listeners

    // ✅ Optimized Android location settings
    final androidSettings = AndroidSettings(
      accuracy: LocationAccuracy.bestForNavigation, // high accuracy + fused provider if available
      intervalDuration: const Duration(seconds: 7), // update interval
      distanceFilter: 8, // increased from 5 to 8, to overcome the speed inconsistancy due to frequent updates // frequent updates may cause speed inaccuracy
      // ❌ Removed forceLocationManager,   //let system choose fused/GPS(fused usually better)
      // foregroundNotificationConfig: const ForegroundNotificationConfig(
      //   notificationTitle: "Tracking Active",
      //   notificationText: "Your location is being tracked",
      //   enableWakeLock: true,   // keeps CPU awake even if screen is off
      // ),
    );

    // ✅ Force Android-specific settings
/*  final androidSettings = AndroidSettings(
    accuracy: LocationAccuracy.bestForNavigation, // high but less battery-drain than high
    intervalDuration: const Duration(seconds: 5), // periodic update
    distanceFilter: 8, // reduce jitter (ignore micro-movements)
    forceLocationManager: true,
  );*/

    // final androidSettings = AndroidSettings(
    //   accuracy: LocationAccuracy.bestForNavigation, // GPS + sensors
    //   intervalDuration: const Duration(seconds: 5), // frequent updates
    //   distanceFilter: 5, // only when moved 5m+
    //   forceLocationManager: true, // bypass fused provider (better for GPS lock)
    //   foregroundNotificationConfig: const ForegroundNotificationConfig(
    //     notificationTitle: "Tracking Active",
    //     notificationText: "Your location is being tracked",
    //     notificationIcon: AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
    //     enableWakeLock: true,   // prevents CPU from sleeping
    //   ),
    // );

    lastPosition = null;
    lastTime = null;

    // Notify if Location Service Disabled and Enabled again
    Geolocator.getServiceStatusStream().listen((ServiceStatus status) async {
      if (status == ServiceStatus.disabled) {
        LogFileManager.writeLog("GPS turned OFF by user");

        // 🚫 Notify user that tracking is paused
        await NotificationService(FlutterLocalNotificationsPlugin())
            .showNotification(
          showNotificationId: foregroundServiceNotificationId,
          title: "Location Service Disabled",
          body:
          "Your location service has been turned off. Visit tracking is paused. Please enable GPS to continue tracking your visit.",
          payload: "service",
          androidNotificationDetails: const AndroidNotificationDetails(
            notificationChannelId,
            notificationChannelId,
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          ),
        );
      } else if (status == ServiceStatus.enabled) {
        LogFileManager.writeLog("GPS turned ON again by user");

        // ✅ Notify user that tracking has resumed
        await NotificationService(FlutterLocalNotificationsPlugin())
            .showNotification(
          showNotificationId: foregroundServiceNotificationId,
          title: "Location Service Enabled",
          body:
          "Your location service has been turned on. Visit tracking has resumed successfully.",
          payload: "service",
          androidNotificationDetails: const AndroidNotificationDetails(
            notificationChannelId,
            notificationChannelId,
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          ),
        );
      }
    });

    locationStream = Geolocator.getPositionStream(locationSettings: androidSettings)
        .listen((Position position) async {

      DateTime now = DateTime.now();
      final Data visit;

      if(VisitState.isVisitStarted.value) {
        final visitJson = await storage.read(key: 'AutoStartVisit');
        if (visitJson == null) return;
        visit = Data.fromJson(jsonDecode(visitJson));
      } else {
        final visitJson = await storage.read(key: 'SelectedVisit');
        if (visitJson == null) return;
        visit = Data.fromJson(jsonDecode(visitJson));
      }

      // ✅ Auto-stop logic added here
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

          // Stop tracking service
          await service.stopSelf();
          await locationStream?.cancel();
          locationStream = null;

          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.remove("isTrackingActive");
          await prefs.remove("isRestartDuringTracking");
          await storage.delete(key: 'SelectedVisit');
          await storage.delete(key: 'AutoStartVisit');
          await storage.delete(key: 'isVisitRunning');
          // ✅ Update global state only
          VisitState.isVisitRunning.value = false;
          VisitState.isVisitStarted.value = false;

          BackgroundService backgroundService = BackgroundService();
          backgroundService.stopService();
          // ❗️ Manually cancel the notification (especially for iOS)
          await FlutterLocalNotificationsPlugin().cancel(foregroundServiceNotificationId);
          await FlutterLocalNotificationsPlugin().cancel(889);
          await FlutterLocalNotificationsPlugin().cancelAll();
          if (Platform.isIOS) {
            await NativeLocationBridge.stopNativeTracking(); // 👈 Native ios stop tracking
          }

          Fluttertoast.showToast(msg: "The visit has stopped automatically because its scheduled time has ended.");
          LogFileManager.writeLog("Visit Stopped Automatically '${visit.reason}' At: ${DateTime.now()}");
          return;
        }
      } catch (e) {
        print("Auto-stop validation failed: $e");
        LogFileManager.writeLog("Auto-stop validation failed: $e");
      }

      /// ✅ Filter to overcome position data inconcistancy, or smoothning raw location data

      if (position.accuracy > 60) {
        LogFileManager.writeLog("Skipped due to poor accuracy: ${position.accuracy}m");
        print("⛔️ Skipped due to poor accuracy: ${position.accuracy}m");
        return;
      }

      // ✅ time filter (ignore too frequent updates)
      if (lastTime != null && now.difference(lastTime!).inSeconds < 5) {
        LogFileManager.writeLog("Skipped due to frequest update ${lastPosition!.latitude}: ${lastPosition!.longitude}  m");
        return;
      }

      // ✅ distance filter
      double distance = lastPosition == null
          ? 9999
          : Geolocator.distanceBetween(
        lastPosition!.latitude, lastPosition!.longitude,
        position.latitude, position.longitude,
      );

      if (distance < 8) {
        LogFileManager.writeLog("Skipping jitter point ${lastPosition!.latitude}: ${lastPosition!.longitude}  m");
        print("🧠 Skipping jitter point (moved only $distance m)");
        return;
      }

      // ✅ speed sanity check (ignore unrealistic jumps)
      if (lastPosition != null && lastTime != null) {
        int timeDiff = now.difference(lastTime!).inSeconds;
        if (timeDiff > 0) {
          double speed = distance / timeDiff; // m/s
          if (speed > 45) {
            LogFileManager.writeLog("Skipped unrealistic speed ${lastPosition!.latitude}: ${lastPosition!.longitude}:${speed}  m");
            print("⚠️ Skipped unrealistic speed: $speed m/s");
            return;
          }
        }
      }

      // ✅ smoothing → average with last 3 positions
      lastPositions.add(position);
      if (lastPositions.length > 3) lastPositions.removeAt(0);
      double avgLat = lastPositions.map((p) => p.latitude).reduce((a, b) => a + b) / lastPositions.length;
      double avgLng = lastPositions.map((p) => p.longitude).reduce((a, b) => a + b) / lastPositions.length;
      LogFileManager.writeLog("smoothing ${avgLat}: ${avgLng}");

      await sendLocation(avgLat, avgLng, visit);

      await NotificationService(FlutterLocalNotificationsPlugin()).showNotification(
        showNotificationId: foregroundServiceNotificationId,
        title: "Tracking Active",
        body: 'Lat: ${avgLat.toStringAsFixed(6)}, Long: ${avgLng.toStringAsFixed(6)}, Speed: ${position.speed.toStringAsFixed(2)}',
        payload: "service",
        androidNotificationDetails: const AndroidNotificationDetails(
          notificationChannelId,
          notificationChannelId,
          ongoing: true,
          playSound: false,
          // importance: Importance.low,
          // priority: Priority.low,
        ),
      );

      lastPosition = position;
      lastTime = now;
    } , onError: (error) async {
      // Catch when user disables location service
      if (error is LocationServiceDisabledException ||
          error.toString().contains("disabled")) {
        print("🚫 Location service disabled");

        // Log this event
        await LogFileManager.writeLog("(LOCATION OFF)Location service turned OFF by user.");

        // Show a notification to alert user
        await NotificationService(FlutterLocalNotificationsPlugin())
            .showNotification(
          showNotificationId: foregroundServiceNotificationId,
          title: "Location Disabled",
          body:
          "Your location service has been turned off. Please enable GPS to continue tracking your visit.",
          payload: "service",
          androidNotificationDetails: const AndroidNotificationDetails(
            notificationChannelId,
            notificationChannelId,
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          ),
        );

        // Optionally stop the background service gracefully
        /*   try {
          await service.stopSelf();
          await locationStream?.cancel();
          locationStream = null;
          LogFileManager.writeLog("Tracking stopped due to location service OFF");
        } catch (e) {
          LogFileManager.writeLog("Error stopping service after GPS off: $e");
        }*/
      } else {
        // other error types
        print("Unknown location error: $error");
        await LogFileManager.writeLog("Unknown location error: $error");
      }
    }
    );
  } catch (e){
    print("Error in onStart: $e");
    LogFileManager.writeLog("Error in onStart $e");
  }
}

/// with indoor and outdoor logic
/*@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  try {
    DartPluginRegistrant.ensureInitialized();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    isTrackingActive = await prefs.getBool("isTrackingActive") ?? false;
    isRestartDuringTracking = await prefs.getBool("isRestartDuringTracking") ?? false;

    if (isTrackingActive) {
      if (service is AndroidServiceInstance) {
        service.setAsForegroundService();
        service.setForegroundNotificationInfo(
          title: "TRACKING ACTIVE",
          content: "Location service is running",
        );
      }
      if (isRestartDuringTracking) {
        await LogFileManager.writeLog("Device Restarted during tracking");
      }
      prefs.setBool("isRestartDuringTracking", true);
    } else {
      await LogFileManager.writeLog("Device Restarted");
      await service.stopSelf();
      await locationStream?.cancel();
      locationStream = null;
      return;
    }

    service.on("stop_service").listen((event) async {
      await service.stopSelf();
      await locationStream?.cancel();
      locationStream = null;
    });

    if (locationStream != null) return; // prevent multiple listeners

    // ✅ Optimized Android location settings (good for outdoor + general use)
    final androidSettings = AndroidSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      intervalDuration: const Duration(seconds: 7),
      distanceFilter: 8,
    );

    lastPosition = null;
    lastTime = null;
    hasSmoothed = false;
    isIndoor = false;
    indoorCounter = 0;
    outdoorCounter = 0;

    // Notify if Location Service Disabled and Enabled again
    Geolocator.getServiceStatusStream().listen((ServiceStatus status) async {
      if (status == ServiceStatus.disabled) {
        LogFileManager.writeLog("GPS turned OFF by user");

        await NotificationService(FlutterLocalNotificationsPlugin())
            .showNotification(
          showNotificationId: foregroundServiceNotificationId,
          title: "Location Service Disabled",
          body:
          "Your location service has been turned off. Visit tracking is paused. Please enable GPS to continue tracking your visit.",
          payload: "service",
          androidNotificationDetails: const AndroidNotificationDetails(
            notificationChannelId,
            notificationChannelId,
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          ),
        );
      } else if (status == ServiceStatus.enabled) {
        LogFileManager.writeLog("GPS turned ON again by user");

        await NotificationService(FlutterLocalNotificationsPlugin())
            .showNotification(
          showNotificationId: foregroundServiceNotificationId,
          title: "Location Service Enabled",
          body:
          "Your location service has been turned on. Visit tracking has resumed successfully.",
          payload: "service",
          androidNotificationDetails: const AndroidNotificationDetails(
            notificationChannelId,
            notificationChannelId,
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          ),
        );
      }
    });

    locationStream = Geolocator.getPositionStream(locationSettings: androidSettings)
        .listen((Position position) async {
      DateTime now = DateTime.now();
      final Data visit;

      /// 🔹 Get active visit (same as your existing logic)
      if (VisitState.isVisitStarted.value) {
        final visitJson = await storage.read(key: 'AutoStartVisit');
        if (visitJson == null) return;
        visit = Data.fromJson(jsonDecode(visitJson));
      } else {
        final visitJson = await storage.read(key: 'SelectedVisit');
        if (visitJson == null) return;
        visit = Data.fromJson(jsonDecode(visitJson));
      }

      // 🔹 Auto-stop logic (unchanged)
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
          await locationStream?.cancel();
          locationStream = null;

          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.remove("isTrackingActive");
          await prefs.remove("isRestartDuringTracking");
          await storage.delete(key: 'SelectedVisit');
          await storage.delete(key: 'AutoStartVisit');
          await storage.delete(key: 'isVisitRunning');

          VisitState.isVisitRunning.value = false;
          VisitState.isVisitStarted.value = false;

          BackgroundService backgroundService = BackgroundService();
          backgroundService.stopService();

          await FlutterLocalNotificationsPlugin().cancel(foregroundServiceNotificationId);
          await FlutterLocalNotificationsPlugin().cancel(889);
          await FlutterLocalNotificationsPlugin().cancelAll();
          if (Platform.isIOS) {
            await NativeLocationBridge.stopNativeTracking();
          }

          Fluttertoast.showToast(
              msg: "The visit has stopped automatically because its scheduled time has ended.");
          LogFileManager.writeLog(
              "Visit Stopped Automatically '${visit.reason}' At: ${DateTime.now()}");
          return;
        }
      } catch (e) {
        print("Auto-stop validation failed: $e");
        LogFileManager.writeLog("Auto-stop validation failed: $e");
      }

      // =====================================================================
      //  ✅ ADAPTIVE INDOOR / OUTDOOR LOGIC STARTS HERE
      // =====================================================================

      double accuracy = position.accuracy;

      // 🔍 1. Detect indoor/outdoor based on accuracy trend
      if (accuracy > kIndoorAccuracyEnter) {
        indoorCounter++;
        outdoorCounter = 0;
      } else if (accuracy < kOutdoorAccuracyExit) {
        outdoorCounter++;
        indoorCounter = 0;
      }

      if (!isIndoor && indoorCounter >= 3) {
        isIndoor = true;
        LogFileManager.writeLog("📡 Switched to INDOOR mode (accuracy: $accuracy m)");
      }

      if (isIndoor && outdoorCounter >= 3) {
        isIndoor = false;
        LogFileManager.writeLog("🛰️ Switched to OUTDOOR mode (accuracy: $accuracy m)");
      }

      // 🔧 2. Mode-specific thresholds
      final int maxAllowedAccuracy = isIndoor ? 120 : 60;   // your outdoor 60 preserved
      final int minDistanceMeters = isIndoor ? 4 : 8;       // tighter for indoor
      final int minTimeGapSec = isIndoor ? 8 : 5;           // slower updates indoor
      final double maxSpeedMs = isIndoor ? 25.0 : 45.0;     // indoor speeds are naturally lower

      // ⛔ 3. Accuracy filter (adaptive)
      if (accuracy > maxAllowedAccuracy) {
        LogFileManager.writeLog(
            "⛔ Skipped due to poor accuracy: ${accuracy}m [mode: ${isIndoor ? "INDOOR" : "OUTDOOR"}]");
        return;
      }

      // ⛔ 4. Time filter (adaptive)
      if (lastTime != null && now.difference(lastTime!).inSeconds < minTimeGapSec) {
        LogFileManager.writeLog(
            "⛔ Skipped due to frequent update (<${minTimeGapSec}s) [mode: ${isIndoor ? "INDOOR" : "OUTDOOR"}]");
        return;
      }

      // ⛔ 5. Distance filter (adaptive)
      double distance = lastPosition == null
          ? 9999
          : Geolocator.distanceBetween(
        lastPosition!.latitude,
        lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );

      if (distance < minDistanceMeters && lastPosition != null) {
        LogFileManager.writeLog(
            "⛔ Skipped jitter (distance: ${distance.toStringAsFixed(2)} m, min: $minDistanceMeters m) "
                "[mode: ${isIndoor ? "INDOOR" : "OUTDOOR"}]");
        return;
      }

      // ⛔ 6. Speed sanity filter
      if (lastPosition != null && lastTime != null) {
        int timeDiff = now.difference(lastTime!).inSeconds;
        if (timeDiff > 0) {
          double speed = distance / timeDiff; // m/s
          if (speed > maxSpeedMs) {
            LogFileManager.writeLog(
                "⚠️ Skipped unrealistic speed: ${speed.toStringAsFixed(2)} m/s [mode: ${isIndoor ? "INDOOR" : "OUTDOOR"}]");
            return;
          }
        }
      }

      // 🧠 7. Adaptive smoothing
      double alpha = isIndoor ? 0.25 : 0.55; // indoor = heavier smoothing

      if (!hasSmoothed) {
        smoothLat = position.latitude;
        smoothLng = position.longitude;
        hasSmoothed = true;
      } else {
        smoothLat = (smoothLat * (1 - alpha)) + (position.latitude * alpha);
        smoothLng = (smoothLng * (1 - alpha)) + (position.longitude * alpha);
      }

      LogFileManager.writeLog(
          "✨ Smoothed → $smoothLat , $smoothLng [mode: ${isIndoor ? "INDOOR" : "OUTDOOR"}, acc: ${accuracy}m]");

      // =====================================================================
      //  ✅ ADAPTIVE LOGIC ENDS – SEND SMOOTHED LOCATION
      // =====================================================================

      await sendLocation(smoothLat, smoothLng, visit);

      await NotificationService(FlutterLocalNotificationsPlugin()).showNotification(
        showNotificationId: foregroundServiceNotificationId,
        title: "Tracking Active",
        body:
        'Lat: ${smoothLat.toStringAsFixed(6)}, Long: ${smoothLng.toStringAsFixed(6)}, '
            'Speed: ${position.speed.toStringAsFixed(2)} m/s, '
            'Mode: ${isIndoor ? "Indoor" : "Outdoor"}',
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
    }, onError: (error) async {
      if (error is LocationServiceDisabledException ||
          error.toString().contains("disabled")) {
        print("🚫 Location service disabled");

        await LogFileManager.writeLog("(LOCATION OFF)Location service turned OFF by user.");

        await NotificationService(FlutterLocalNotificationsPlugin())
            .showNotification(
          showNotificationId: foregroundServiceNotificationId,
          title: "Location Disabled",
          body:
          "Your location service has been turned off. Please enable GPS to continue tracking your visit.",
          payload: "service",
          androidNotificationDetails: const AndroidNotificationDetails(
            notificationChannelId,
            notificationChannelId,
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          ),
        );
      } else {
        print("Unknown location error: $error");
        await LogFileManager.writeLog("Unknown location error: $error");
      }
    });
  } catch (e) {
    print("Error in onStart: $e");
    LogFileManager.writeLog("Error in onStart $e");
  }
}*/

class BackgroundService {
  final FlutterBackgroundService flutterBackgroundService = FlutterBackgroundService();
  FlutterBackgroundService get instance => flutterBackgroundService;

  Future<void> initializeService() async {
    await NotificationService(FlutterLocalNotificationsPlugin()).createChannel(
      const AndroidNotificationChannel(
        notificationChannelId,
        notificationChannelId,
        playSound: false,
        sound: null,
        enableVibration: false,
      ),
    );

    await flutterBackgroundService.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: notificationChannelId,
        foregroundServiceNotificationId: foregroundServiceNotificationId,
        initialNotificationTitle: initialNotificationTitle,
        initialNotificationContent: initialNotificationContent,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: null,
      ),
    );
    // await flutterBackgroundService.startService();
  }

  void setServiceAsForeGround() {
    flutterBackgroundService.invoke("setAsForeground");
    print("Service set as foreground");
  }

  void stopService() {
    flutterBackgroundService.invoke("stop_service");
    print("Service stopped");
  }
}

/// Call this from your location stream instead of the old sendLocation.
/// It saves locally first, then triggers background sync if network present.
Future<void> sendLocation(double latitude, double longitude, Data visit) async {
  try {
    DateTime now = DateTime.now();
    String transactionTime = DateFormat('dd/MM/yyyy HH:mm:ss').format(now);
    String transactionDate = DateFormat('dd/MM/yyyy').format(now);

    staffcode ??= await storage.read(key: 'username');
    if (staffcode == null) {
      print("❗ staffcode is null, cannot send location");
      LogFileManager.writeLog("❗ staffcode is null, aborting sendLocation");
      return;
    }

    final battery = Battery();
    final String batteryLevel = (await battery.batteryLevel).toString();

    // Distance / speed computation as before
    double speed = 0;
    double distanceInMeters = 0;
    double distanceInKm = 0;
    if (lastPosition != null && lastTime != null) {
      distanceInMeters = Geolocator.distanceBetween(
          lastPosition!.latitude, lastPosition!.longitude, latitude, longitude);
      distanceInKm = distanceInMeters / 1000;
      int seconds = now.difference(lastTime!).inSeconds;
      if (seconds > 0) {
        speed = (distanceInMeters / seconds) * 3.6;
      }
    }

    // Prepare local row (address = "Unknown" for now; will be resolved during sync)
    Map<String, dynamic> locationData = {
      "latitude": latitude.toStringAsFixed(8),
      "longitude": longitude.toStringAsFixed(8),
      "address": "Unknown",
      "speed": speed,
      "distanceInMeters": distanceInMeters,
      "distanceInKm": distanceInKm,
      "srNo_Vo": visit.srNo.toString(),
      "timestamp": transactionTime,
      "datestamp": transactionDate,
      "staffcode": staffcode,
      "batteryPercentage": batteryLevel.toString(),
      "synced": 0,
    };

    // Always save locally first
    await DatabaseHelper().insertLocation(locationData);
    LogFileManager.writeLog("📦 Local save complete: $locationData");
    print("📦 Local save complete: $locationData");

    // Update lastPosition/lastTime as before
    lastPosition = Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: now,
      accuracy: 0.0,
      altitude: 0.0,
      heading: 0.0,
      speed: speed,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );
    lastTime = now;

    // Non-blocking: trigger a background sync if we have internet
    if (await InternetService().hasInternetAccess()) {
      // fire-and-forget
      unawaited(syncOfflineData2());
    } else {
      // Fluttertoast.showToast(msg: "Offline saved: $latitude, $longitude");
      LogFileManager.writeLog("Offline saved: $latitude, $longitude, $transactionTime");
    }
  } catch (e) {
    LogFileManager.writeLog("❌ sendLocation error: $e");
    print("❌ sendLocation error: $e");
  }
}
/*
Future<void> sendLocation(double latitude, double longitude, Data visit) async {
  DateTime now = DateTime.now();
  String transactionTime = DateFormat('dd/MM/yyyy HH:mm:ss').format(now);
  String transactionDate = DateFormat('dd/MM/yyyy').format(now);
  String actualDate = transactionDate;
  String address = "Unknown";

  staffcode ??= await storage.read(key: 'username');
  if (staffcode == null) {
    print("❗ staffcode is null, cannot send location");
    LogFileManager.writeLog("❗ staffcode is null, aborting sendLocation");
    return;
  }

  final battery = Battery();
  final String batteryLevel = (await battery.batteryLevel).toString();

  // String? token = await storage.read(key: 'Auth_Token');

  double speed = 0;
  double distanceInMeters = 0;
  double distanceInKm = 0;
  if (lastPosition != null && lastTime != null) {
    distanceInMeters = Geolocator.distanceBetween(
        lastPosition!.latitude, lastPosition!.longitude, latitude, longitude);
    distanceInKm = distanceInMeters / 1000;

    int seconds = now.difference(lastTime!).inSeconds;
    if (seconds > 0) {
      speed = (distanceInMeters / seconds) * 3.6;
    }
  }

  try {
    List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
    if (placemarks.isNotEmpty) {
      address = "${placemarks.first.name}, ${placemarks.first.locality}";
    }
  } catch (e) {
    print("📍 Reverse geocoding failed: $e");
  }

  lastPosition = Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: now,
    accuracy: 0.0,
    altitude: 0.0,
    heading: 0.0,
    speed: speed,
    speedAccuracy: 0.0,
    altitudeAccuracy: 0.0,
    headingAccuracy: 0.0,
  );
  lastTime = now;

  Map<String, dynamic> locationData = {
    "staffcode": staffcode,
    "latitude": latitude,
    "longitude": longitude,
    "address": address,
    "speed": speed,
    "distanceInMeters": distanceInMeters,
    "distanceInKm": distanceInKm,
    "srNo_Vo": visit.srNo.toString(),
    "timestamp": transactionTime,
    "datestamp": transactionDate,
    "batteryPercentage": batteryLevel.toString(),
  };

  final bool online = await InternetService().hasInternetAccess();
  await syncOfflineData();

  if (!online) {
    print("📦 Offline - saving to SQLite");
    await DatabaseHelper().insertLocation(locationData);
    LogFileManager.writeLog("📦 Offline Data Saved: $locationData");
    Fluttertoast.showToast(msg: "Offline saved: $latitude, $longitude");
    return;
  }

  try {
    final uri = Uri.parse('http://114.143.140.28:8020/api/Visit/InsertUpdateTrackingRecords');
    final payload = {
      "transactionId": "string",
      "transactionDate": transactionDate,
      "transactionTime": transactionTime,
      "latitude": latitude.toStringAsFixed(8),
      "longitude": longitude.toStringAsFixed(8),
      "staffCode": staffcode,
      "deviceId": "11",
      "uuidid": "11",
      "process": "11",
      "actualDate": actualDate,
      "actualTime": "11",
      "address": address,
      "speed": speed.toStringAsFixed(2),
      "distance": distanceInMeters.toStringAsFixed(2),
      "srNo_Vo": visit.srNo.toString(),
      "status": "S",
      "distanceInKm": distanceInKm.toStringAsFixed(2),
      "gpsCheckFlag": "1",
      "batteryPercentage": batteryLevel.toString()
    };

    print("📤 Sending to API with SSL bypass: $payload");

    final HttpClient client = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        print("⚠️ Bypassing SSL check for $host");
        return true; // Accept any cert
      };

    final HttpClientRequest request = await client.postUrl(uri);
    request.headers.set(HttpHeaders.contentTypeHeader, "application/json");
    request.add(utf8.encode(jsonEncode(payload)));

    final HttpClientResponse response = await request.close();
    final String responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode == 200) {
      print("✅ API Success: $responseBody");
      LogFileManager.writeLog("✅ API Response: $responseBody");
    } else {
      print("❌ API Failure: ${response.statusCode}, $responseBody");
      LogFileManager.writeLog("❌ API Failure: ${response.statusCode}, $responseBody");
      Fluttertoast.showToast(msg: "❌ API Failure:${response.statusCode},");
    }
  } catch (e) {
    print("❌ SSL-Bypass Exception during API call: $e");
    LogFileManager.writeLog("❌ SSL-Bypass Exception: $e");
  }
}
*/

/// Sync unsynced rows. This will:
///  - reverse geocode rows with address "Unknown"
///  - attempt to send each row with retry/backoff
///  - mark row as synced on success
Future<void> syncOfflineData2() async {
  final bool online = await InternetService().hasInternetAccess();
  if (!online) {
    print("❌ No internet, skipping syncOfflineData.");
    return;
  }

  List<Map<String, dynamic>> storedData = await DatabaseHelper().getStoredLocations();
  print("📌 Syncing ${storedData.length} stored records...");

  VisitState.countRemainingLatLong.value = storedData.length;

  // Cache reverse-geocode results to avoid repeat lookups
  final Map<String, String> addressCache = {};

  for (final row in storedData) {
    try {
      final id = row['id'];

      // If address is unknown, try reverse geocoding before sending
      String address = row['address']?.toString() ?? "";
      bool needsGeocoding = address.trim().isEmpty || address.trim().toLowerCase() == 'unknown';

      if (needsGeocoding) {
        final lat = double.parse(row['latitude'].toString());
        final lng = double.parse(row['longitude'].toString());
        final key = "$lat,$lng";
        if (addressCache.containsKey(key)) {
          address = addressCache[key]!;
        } else {
          address = await getAddressFromLatLong(lat, lng);
          addressCache[key] = address;
        }
      }

      // Build payload exactly as your API expects
      final String transactionDate = row['datestamp'] ?? DateFormat('dd/MM/yyyy').format(DateTime.now());
      final String transactionTime = row['timestamp'] ?? DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());
      final payload = {
        "transactionId": "string",
        "transactionDate": transactionDate,
        "transactionTime": transactionTime,
        "latitude": double.parse(row['latitude'].toString()).toStringAsFixed(7),
        "longitude": double.parse(row['longitude'].toString()).toStringAsFixed(7),
        "staffCode": row['staffcode'].toString(),
        "deviceId": "11",
        "uuidid": "11",
        "process": "11",
        "actualDate": transactionDate,
        "actualTime": "11",
        "address": address,
        "speed": (row['speed'] is num) ? (row['speed'] as num).toStringAsFixed(2) : row['speed'].toString(),
        "distance": (row['distanceInMeters'] is num) ? (row['distanceInMeters'] as num).toStringAsFixed(2) : row['distanceInMeters'].toString(),
        "srNo_Vo": row['srNo_Vo'].toString(),
        "status": "S",
        "distanceInKm": (row['distanceInKm'] is num) ? (row['distanceInKm'] as num).toStringAsFixed(2) : row['distanceInKm'].toString(),
        "gpsCheckFlag": "1",
        "batteryPercentage": row['batteryPercentage']?.toString() ?? ""
      };

      await LogManagerTrackingData.writeLog("API request time - ${DateTime.now()}");
      LogFileManager.writeLog("Tracking data: $transactionTime, ${double.parse(row['latitude'].toString()).toStringAsFixed(6)}, ${double.parse(row['longitude'].toString()).toStringAsFixed(6)}, ${(row['speed'] is num) ? (row['speed'] as num).toStringAsFixed(2) : row['speed'].toString()}, ${(row['distanceInMeters'] is num) ? (row['distanceInMeters'] as num).toStringAsFixed(2) : row['distanceInMeters'].toString()}");
      // Try to send with retry/backoff
      bool success = await _trySendToApiWithRetries(payload);

      if (success) {
        // await DatabaseHelper().markAsSynced(id);
        // LogFileManager.writeLog("✅ Synced id=$id successfully.");
        // print("✅ Synced id=$id successfully.");
        // Decrement the counter safely
        // VisitState.countRemainingLatLong.value =
        //     (VisitState.countRemainingLatLong.value - 1).clamp(0, 999999);
          await DatabaseHelper().deleteLocation(id);  // ✅ delete synced row
          LogFileManager.writeLog("✅ Synced id=$id and deleted locally.");
          print("✅ Synced id=$id and deleted locally.");

          // Update remaining count
          VisitState.countRemainingLatLong.value--;
      } else {
        LogFileManager.writeLog("⚠️ Failed to sync id=$id; will retry later.");
        print("⚠️ Failed to sync id=$id; will retry later.");
      }
    } catch (e) {
      LogFileManager.writeLog("❌ Error while syncing row: $e");
      print("❌ Error while syncing row: $e");
      // continue with next row
      continue;
    }
  }
}

Future<bool> _trySendToApiWithRetries(Map<String, dynamic> payload, {int maxAttempts = 4}) async {
  int attempt = 0;
  while (attempt < maxAttempts) {
    attempt++;
    try {
      final uri = Uri.parse('http://114.143.140.28:8020/api/Visit/InsertUpdateTrackingRecords');

      final HttpClient client = HttpClient()
        ..badCertificateCallback = (X509Certificate cert, String host, int port) {
          print("⚠️ Bypassing SSL check for $host");
          return true;
        };

      final HttpClientRequest request = await client.postUrl(uri);
      request.headers.set(HttpHeaders.contentTypeHeader, "application/json");
      request.add(utf8.encode(jsonEncode(payload)));

      final HttpClientResponse response = await request.close();
      final String responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        print("✅ API Success (sync): $responseBody");
        LogFileManager.writeLog("✅ API Success (sync): $responseBody");
        await LogManagerTrackingData.writeLog("API success time - ${DateTime.now()}");
        return true;
      } else {
        print("❌ API Failure: ${response.statusCode}, $responseBody");
        LogFileManager.writeLog("❌ API Failure: ${response.statusCode}, $responseBody");
      }
    } catch (e) {
      print("⚠️ Network/API attempt $attempt failed: $e");
      LogFileManager.writeLog("⚠️ Network/API attempt $attempt failed: $e");
    }

    // backoff before next attempt
    final backoffMs = 500 * (1 << (attempt > 0 ? attempt - 1 : 0)); // 500ms, 1s, 2s, 4s...
    await Future.delayed(Duration(milliseconds: backoffMs));
  }
  return false;
}

/// Working!
/// Local storage based Avrage machenism added for spike old ios functionality
class NativeLocationBridge {
  static const MethodChannel _channel = MethodChannel('location_channel');

  static Data? _activeVisit;
  static DateTime? _lastDartTime;
  static LatLng? _lastDartPoint;

  static void initialize() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == "nativeLocationUpdate" && _activeVisit != null) {
        final lat = call.arguments['lat'] as double;
        final lng = call.arguments['lng'] as double;
        final speed = (call.arguments['speed'] ?? 0).toDouble();
        final distance = (call.arguments['distance'] ?? 0).toDouble();

        // if (!_shouldAcceptPoint(lat, lng, distance, speed)) return;   // check the points before sending to api

        print("📍 Native iOS Location: $lat, $lng, Speed: ${speed.toStringAsFixed(2)} km/h, Distance: ${distance.toStringAsFixed(2)} m");

        await sendLocationIOS(lat, lng, _activeVisit!, speedOverride: speed, distanceOverride: distance);

        await NotificationService(FlutterLocalNotificationsPlugin()).showNotification(
          showNotificationId: foregroundServiceNotificationId,
          title: "Tracking Active",
          body: 'Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}, Speed: ${speed.toStringAsFixed(1)} km/h',
          payload: "service",
          androidNotificationDetails: const AndroidNotificationDetails(
            notificationChannelId,
            notificationChannelId,
            ongoing: true,
            playSound: false,
          ),
        );
      }
    });
  }

  static bool _shouldAcceptPoint(double lat, double lng, final distance, final speed) {
    final now = DateTime.now();

    if (_lastDartPoint != null && _lastDartTime != null) {
      final dist = Geolocator.distanceBetween(
          _lastDartPoint!.latitude, _lastDartPoint!.longitude, lat, lng);
      final seconds = now.difference(_lastDartTime!).inSeconds;

      if (dist < 5 || seconds < 10) {
        print("⛔️ Skipped in Dart: distance < 5m or duration < 10s");
        return false;
      }
    }
    // Filter sudden long jumps (e.g., >150m in 5s implies >100 km/h — usually invalid)
    if (distance > 150 && speed > 60) {
      print("❌ Spike detected — distance too large too fast. Distance: $distance, Speed: $speed");
      LogFileManager.writeLog("❌ Spike filtered in iOS: $distance m, $speed km/h");
      return false;
    }
    if ((distance / (now.difference(lastTime!).inSeconds)) > 20) {
      // Speed > 72 km/h (20 m/s)
      print("❌ Unrealistic speed, likely spike. Skipped.");
      return false;
    }

    _lastDartTime = now;
    _lastDartPoint = LatLng(lat, lng);
    return true;
  }

  static Future<void> startNativeTracking(Data visit) async {
    _activeVisit = visit;
    try {
      await _channel.invokeMethod("startNativeTracking");
      print("✅ Native tracking started");

      // 🔔 Show "Tracking started" only once
      await NotificationService(FlutterLocalNotificationsPlugin()).showNotification(
        showNotificationId: foregroundServiceNotificationId,
        title: "Tracking Started",
        body: "We’re now tracking your location.",
        payload: "service",
        androidNotificationDetails: const AndroidNotificationDetails(
          notificationChannelId,
          notificationChannelId,
          ongoing: true,
          playSound: false,
        ),
      );
    } catch (e) {
      print("❌ Failed to start native tracking: $e");
    }
  }

  static Future<void> stopNativeTracking() async {
    _activeVisit = null;
    try {
      await _channel.invokeMethod("stopNativeTracking");
      print("🛑 Native tracking stopped");

      // 🔔 Show "Tracking stopped"
      await NotificationService(FlutterLocalNotificationsPlugin()).showNotification(
        showNotificationId: foregroundServiceNotificationId,
        title: "Tracking Stopped",
        body: "Location tracking has ended.",
        payload: "service",
        androidNotificationDetails: const AndroidNotificationDetails(
          notificationChannelId,
          notificationChannelId,
          ongoing: false,
          playSound: false,
        ),
      );

      // Optionally clear it completely
      await FlutterLocalNotificationsPlugin().cancel(foregroundServiceNotificationId);
    } catch (e) {
      print("❌ Failed to stop native tracking: $e");
    }
  }
}

Future<void>  sendLocationIOS(
    double latitude,
    double longitude,
    Data visit, {
      double? speedOverride,
      double? distanceOverride,
    }) async
{
  DateTime now = DateTime.now();
  String transactionTime = DateFormat('dd/MM/yyyy HH:mm:ss').format(now);
  String transactionDate = DateFormat('dd/MM/yyyy').format(now);
  String actualDate = transactionDate;
  String address = "Unknown";

  final battery = Battery();
  final String batteryLevel = (await battery.batteryLevel).toString();

  staffcode ??= await storage.read(key: 'username');
  if (staffcode == null) {
    print("❗ staffcode is null, cannot send location (iOS)");
    LogFileManager.writeLog("❗ staffcode is null, aborting sendLocationIOS");
    return;
  }

  double speed = 0;
  double distanceInMeters = 0;
  double distanceInKm = 0;

  if (lastPosition != null && lastTime != null) {
    distanceInMeters = Geolocator.distanceBetween(
        lastPosition!.latitude, lastPosition!.longitude, latitude, longitude);
    distanceInKm = distanceInMeters / 1000;

    int seconds = now.difference(lastTime!).inSeconds;
    if (seconds > 0) {
      speed = (distanceInMeters / seconds) * 3.6;
    }
  }

  if (speedOverride != null) speed = speedOverride;
  if (distanceOverride != null) distanceInMeters = distanceOverride;
  distanceInKm = distanceInMeters / 1000;

  /// ---------------- SPIKE FILTERING ---------------- ///
  if (lastPositions.length >= 2) {
    double avgLastSpeed = lastPositions
        .map((p) => p.speed)
        .where((s) => s > 0)
        .fold(0.0, (a, b) => a + b) /
        lastPositions.length;

    bool isSpike = speed > 15 &&
        avgLastSpeed < 3 &&
        distanceInMeters > 30;

    if (isSpike) {
      print("⚠️ Spike detected. Skipping this point: Speed=$speed, Distance=$distanceInMeters, AvgSpeed=$avgLastSpeed");
      LogFileManager.writeLog("⚠️ Skipped spiked point: $latitude, $longitude, Speed: $speed");
      return;
    }
  }

  /// Save current to buffer
  lastPositions.add(Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: now,
    accuracy: 0.0,
    altitude: 0.0,
    heading: 0.0,
    speed: speed,
    speedAccuracy: 0.0,
    altitudeAccuracy: 0.0,
    headingAccuracy: 0.0,
  ));
  if (lastPositions.length > 3) {
    lastPositions.removeAt(0); // Keep only last 3
  }
  /// ------------------------------------------------- ///

  try {
    List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
    if (placemarks.isNotEmpty) {
      address = "${placemarks.first.name}, ${placemarks.first.locality}";
    }
  } catch (e) {
    print("📍 Reverse geocoding failed (iOS): $e");
  }

  lastPosition = Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: now,
    accuracy: 0.0,
    altitude: 0.0,
    heading: 0.0,
    speed: speed,
    speedAccuracy: 0.0,
    altitudeAccuracy: 0.0,
    headingAccuracy: 0.0,
  );
  lastTime = now;

  Map<String, dynamic> locationData = {
    "staffcode": staffcode,
    "latitude": latitude,
    "longitude": longitude,
    "address": address,
    "speed": speed,
    "distanceInMeters": distanceInMeters,
    "distanceInKm": distanceInKm,
    "srNo_Vo": visit.srNo.toString(),
    "timestamp": transactionTime,
    "datestamp": transactionDate,
    "batteryPercentage": batteryLevel.toString(),
  };

  final bool online = await InternetService().hasInternetAccess();
  await syncOfflineData();

  if (!online) {
    // if (distanceInMeters < 5 || speed > 180 || speed < 0) {
    //   print("⛔️ Invalid data skipped in iOS sender. Distance: $distanceInMeters, Speed: $speed");
    //   return;
    // }
    print("📦 Offline - lat long saving to SQLite (iOS)");
    await DatabaseHelper().insertLocation(locationData);
    LogFileManager.writeLog("📦 lat long Offline iOS Data Saved: $locationData");
    Fluttertoast.showToast(msg: "lat long Offline saved (iOS): $latitude, $longitude");
    return;
  }

  try {
    final uri = Uri.parse('http://114.143.140.28:8020/api/Visit/InsertUpdateTrackingRecords');
    final payload = {
      "transactionId": "string",
      "transactionDate": transactionDate,
      "transactionTime": transactionTime,
      "latitude": latitude.toStringAsFixed(8),
      "longitude": longitude.toStringAsFixed(8),
      "staffCode": staffcode,
      "deviceId": "11",
      "uuidid": "11",
      "process": "11",
      "actualDate": actualDate,
      "actualTime": "11",
      "address": address,
      "speed": speed.toStringAsFixed(2),
      "distance": distanceInMeters.toStringAsFixed(2),
      "srNo_Vo": visit.srNo.toString(),
      "status": "S",
      "distanceInKm": distanceInKm.toStringAsFixed(2),
      "gpsCheckFlag": "1",
      "batteryPercentage": batteryLevel.toString(),
    };

    print("📤 Sending iOS data to API with SSL bypass: $payload");

    final HttpClient client = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        print("⚠️ Bypassing SSL check for $host (iOS)");
        return true;
      };

    final HttpClientRequest request = await client.postUrl(uri);
    request.headers.set(HttpHeaders.contentTypeHeader, "application/json");
    request.add(utf8.encode(jsonEncode(payload)));

    final HttpClientResponse response = await request.close();
    final String responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode == 200) {
      print("✅ API Success (iOS): $responseBody");
      LogFileManager.writeLog("✅ API iOS Response: $responseBody");
    } else {
      print("❌ API Failure (iOS): ${response.statusCode}, $responseBody");
      LogFileManager.writeLog("❌ API iOS Failure: ${response.statusCode}, $responseBody");
      Fluttertoast.showToast(msg: "❌ API Failure (iOS): ${response.statusCode}");
    }
  } catch (e) {
    print("❌ SSL-Bypass Exception during API call (iOS): $e");
    LogFileManager.writeLog("❌ SSL-Bypass iOS Exception: $e");
  }
}

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;

  NotificationService(this._plugin);

  Future<void> createChannel(AndroidNotificationChannel channel) async {
    await _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Request iOS permissions with sound disabled
    await _plugin
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
      alert: true,
      badge: true,
      sound: false, // Disable sound on iOS
    );
  }

  Future<void> showNotification({
    required int showNotificationId,
    required String title,
    required String body,
    required String payload,
    required AndroidNotificationDetails androidNotificationDetails,
  }) async {
    final notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: const DarwinNotificationDetails(
        threadIdentifier: "tracking",   // 🔑 group & update notifications
        presentAlert: false,         // alert displays or not
        presentSound: false,       // sound when it is in foreground
        presentBanner: false,      // notification displayed as an banner
        presentBadge: false,      // ❌ No badge update
        interruptionLevel: InterruptionLevel.passive,
        sound: null,
      ), // Disable sound on iOS
    );

    await _plugin.show(
      showNotificationId,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
}

/*@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: initialNotificationTitle,
      content: initialNotificationContent,
    );
  }

  service.on("stop_service").listen((event) async {
    await service.stopSelf();
    await locationStream?.cancel();
    locationStream = null;
  });

  if (locationStream != null) return; // prevent multiple listeners

  LocationSettings locationSettings = const LocationSettings(
    // accuracy: LocationAccuracy.bestForNavigation,
    accuracy: LocationAccuracy.high, // more stable than bestForNavigation
    distanceFilter: 5, // Only trigger when moved 8+ meters
    timeLimit: Duration(seconds: 10), // force regular updates
    // forceLocationManager: true,
  );

  AndroidSettings androidSettings = AndroidSettings(
    accuracy: LocationAccuracy.high,
    // intervalDuration: Duration(seconds: 15),
    distanceFilter: 10,
    forceLocationManager: true, // use LocationManager for more consistent GPS lock
    // foregroundNotificationConfig: ForegroundNotificationConfig(
    //   notificationTitle: 'Tracking Active',
    //   notificationText: 'Location service is running',
    //   notificationIcon: AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
    // ),
  );

  locationStream = Geolocator.getPositionStream(locationSettings: androidSettings)
      .listen((Position position) async {
    if (position.accuracy > 50) {
      print("⛔️ Skipped due to poor accuracy: ${position.accuracy}m");
      return;
    }

    final visitJson = await storage.read(key: 'SelectedVisit');
    if (visitJson == null) return;
    final Data visit = Data.fromJson(jsonDecode(visitJson));

    double distance = lastPosition == null
        ? 1000
        : Geolocator.distanceBetween(
      lastPosition!.latitude, lastPosition!.longitude,
      position.latitude, position.longitude,
    );

    if (distance < 10) {
      // print("🧠 Skipping jitter point (moved only $distance m)");
      return;
    }

    // // If distance is too large for time gap → probably GPS glitch
    // int timeDiff = DateTime.now().difference(lastTime!).inSeconds;
    // double maxPossibleDistance = timeDiff * 50; // 50 m/s ≈ 180 km/h
    // if (distance > maxPossibleDistance) return;

    await sendLocation(position.latitude, position.longitude, visit);

    await NotificationService(FlutterLocalNotificationsPlugin())
        .showNotification(
      showNotificationId: foregroundServiceNotificationId,
      title: "Location Tracking Active",
      body: 'Lat: ${position.latitude}, Long: ${position.longitude}',
      payload: "service",
      androidNotificationDetails: const AndroidNotificationDetails(
        notificationChannelId,
        notificationChannelId,
        ongoing: true,
        playSound: false,
      ),
    );
  });
}*/


/// Working! ( one when offline address stores N/A, because reconversion/reverseGeocoding of address when again online is not added in this )
/// Sync Queue based ios functionality
/*
class NativeLocationBridge {
  static const MethodChannel _channel = MethodChannel('location_channel');

  static Data? _activeVisit;
  static DateTime? _lastDartTime;
  static LatLng? _lastDartPoint;

  static void initialize() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == "nativeLocationUpdate" && _activeVisit != null) {
        final lat = call.arguments['lat'] as double;
        final lng = call.arguments['lng'] as double;
        final speed = (call.arguments['speed'] ?? 0).toDouble();
        final distance = (call.arguments['distance'] ?? 0).toDouble();

        print("📍 Native iOS Location: $lat, $lng, Speed: ${speed.toStringAsFixed(2)} km/h, Distance: ${distance.toStringAsFixed(2)} m");

        final now = DateTime.now();
        String transactionTime = DateFormat('dd/MM/yyyy HH:mm:ss').format(now);
        String transactionDate = DateFormat('dd/MM/yyyy').format(now);
        final battery = Battery();
        final String batteryLevel = (await battery.batteryLevel).toString();

        staffcode ??= await storage.read(key: 'username');
        if (staffcode == null) {
          print("❗ staffcode is null, skipping point");
          return;
        }

        Map<String, dynamic> locationData = {
          "staffcode": staffcode,
          "latitude": lat,
          "longitude": lng,
          "speed": speed,
          "distanceInMeters": distance,
          "srNo_Vo": _activeVisit!.srNo.toString(),
          "timestamp": transactionTime,
          "datestamp": transactionDate,
          "batteryPercentage": batteryLevel,
        };

        enqueueLocation(locationData);

        await NotificationService(FlutterLocalNotificationsPlugin()).showNotification(
          showNotificationId: foregroundServiceNotificationId,
          title: "Tracking Active",
          body: 'Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}, Speed: ${speed.toStringAsFixed(1)} km/h',
          payload: "service",
          androidNotificationDetails: const AndroidNotificationDetails(
            notificationChannelId,
            notificationChannelId,
            ongoing: true,
            playSound: false,
            enableVibration: false,
            onlyAlertOnce: true,
            silent: true,
          ),
        );
      }
    });
  }

  static Future<void> startNativeTracking(Data visit) async {
    _activeVisit = visit;
    try {
      await _channel.invokeMethod("startNativeTracking");
      print("✅ Native tracking started");
    } catch (e) {
      print("❌ Failed to start native tracking: $e");
    }
  }

  static Future<void> stopNativeTracking() async {
    _activeVisit = null;
    try {
      await _channel.invokeMethod("stopNativeTracking");
      print("🛑 Native tracking stopped");
    } catch (e) {
      print("❌ Failed to stop native tracking: $e");
    }
  }
}

void enqueueLocation(Map<String, dynamic> locationData) {
  _syncQueue.add(locationData);
  _processQueue();
}

// take first data send to server then remove first
Future<void> _processQueue() async {
  if (_isSyncing || _syncQueue.isEmpty) return;
  _isSyncing = true;

  while (_syncQueue.isNotEmpty) {
    final current = _syncQueue.first;      // take first data from queue
    final bool online = await InternetService().hasInternetAccess();
    if (!online) {                         // check if online
      print("🚫 Offline — stopping sync");
      break;
    }

    try {
      bool success = await _sendToServer(current);  // if online send rto server
      if (success) {       // Don't delete, will retry on next attempt, if not successfull
        _syncQueue.removeAt(0);             // remove first data from queue
      } else {
        print("❌ Sync failed for: $current");
        break;
      }
    } catch (e) {
      print("❗ Sync Exception: $e");
      break;
    }
  }
  _isSyncing = false;
}

Future<bool> _sendToServer(Map<String, dynamic> data) async {
  try {
    final uri = Uri.parse('http://114.143.140.28:8020/api/Visit/InsertUpdateTrackingRecords');
    final payload = {
      "transactionId": "string",
      "transactionDate": data["datestamp"],
      "transactionTime": data["timestamp"],
      "latitude": data["latitude"].toStringAsFixed(8),
      "longitude": data["longitude"].toStringAsFixed(8),
      "staffCode": data["staffcode"],
      "deviceId": "11",
      "uuidid": "11",
      "process": "11",
      "actualDate": data["datestamp"],
      "actualTime": "11",
      "address": "N/A",
      "speed": (data["speed"] as double).toStringAsFixed(2),
      "distance": (data["distanceInMeters"] as double).toStringAsFixed(2),
      "srNo_Vo": data["srNo_Vo"],
      "status": "S",
      "distanceInKm": ((data["distanceInMeters"] as double) / 1000).toStringAsFixed(2),
      "gpsCheckFlag": "1",
      "batteryPercentage": data["batteryPercentage"],
    };

    final HttpClient client = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    final HttpClientRequest request = await client.postUrl(uri);
    request.headers.set(HttpHeaders.contentTypeHeader, "application/json");
    request.add(utf8.encode(jsonEncode(payload)));
    final HttpClientResponse response = await request.close();
    final String responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode == 200) {
      print("✅ API Success: $responseBody");
      return true;
    } else {
      print("❌ API Failure: ${response.statusCode}, $responseBody");
      return false;
    }
  } catch (e) {
    print("❌ API Exception: $e");
    return false;
  }
}*/

/// Globle Queue for add data at one place sync in sequence at once
/*class SyncQueueManager {
  static final List<Map<String, dynamic>> _queue = [];
  static bool _isSyncing = false;
  static final Map<String, String> _addressCache = {};

  static Future<void> enqueue(Map<String, dynamic> data) async {
    // Save to SQLite (persistent layer)
    await DatabaseHelper().insertLocation(data);

    // Add to memory queue if online
    _queue.add(data);
    await _processQueue();
  }

  static Future<void> _processQueue() async {
    if (_isSyncing || _queue.isEmpty) return;

    bool hasInternet = await InternetService().hasInternetAccess();
    if (!hasInternet) return;

    _isSyncing = true;

    while (_queue.isNotEmpty) {
      final item = _queue.first;

      try {
        // Optional reverse geocoding (deferred until online)
        String address = item['address'] ?? "";
        if (address.trim().isEmpty || address == "unknown") {
          final key = "${item['latitude']},${item['longitude']}";
          if (_addressCache.containsKey(key)) {
            address = _addressCache[key]!;
          } else {
            address = await getAddressFromLatLong(
              double.parse(item['latitude'].toString()),
              double.parse(item['longitude'].toString()),
            );
            _addressCache[key] = address;
          }
          item['address'] = address;
        }

        final sent = await _sendToServer(item);

        if (sent) {
          _queue.removeAt(0);
          await DatabaseHelper().deleteLocation(item['id']);
        } else {
          print("❌ Sending failed, retry later");
          break;
        }
      } catch (e) {
        print("❗ Sync exception: $e");
        break;
      }
    }

    _isSyncing = false;
  }

  static Future<void> resumeFromDatabase() async {
    final offlineData = await DatabaseHelper().getStoredLocations();
    _queue.addAll(offlineData);
    await _processQueue();
  }

  static Future<bool> _sendToServer(Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse('http://114.143.140.28:8020/api/Visit/InsertUpdateTrackingRecords');
      final payload = {
        "transactionId": "string",
        "transactionDate": data["datestamp"],
        "transactionTime": data["timestamp"],
        "latitude": data["latitude"].toStringAsFixed(8),
        "longitude": data["longitude"].toStringAsFixed(8),
        "staffCode": data["staffcode"],
        "deviceId": "11",
        "uuidid": "11",
        "process": "11",
        "actualDate": data["datestamp"],
        "actualTime": "11",
        "address": "N/A",
        "speed": (data["speed"] as double).toStringAsFixed(2),
        "distance": (data["distanceInMeters"] as double).toStringAsFixed(2),
        "srNo_Vo": data["srNo_Vo"],
        "status": "S",
        "distanceInKm": ((data["distanceInMeters"] as double) / 1000).toStringAsFixed(2),
        "gpsCheckFlag": "1",
        "batteryPercentage": data["batteryPercentage"],
      };

      final HttpClient client = HttpClient()
        ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      final HttpClientRequest request = await client.postUrl(uri);
      request.headers.set(HttpHeaders.contentTypeHeader, "application/json");
      request.add(utf8.encode(jsonEncode(payload)));
      final HttpClientResponse response = await request.close();
      final String responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        print("✅ API Success: $responseBody");
        return true;
      } else {
        print("❌ API Failure: ${response.statusCode}, $responseBody");
        return false;
      }
    } catch (e) {
      print("❌ API Exception: $e");
      return false;
    }
  }
  }*/

/*class SyncQueueManager {
  static final List<Map<String, dynamic>> _queue = [];
  static bool _isSyncing = false;
  static final Map<String, String> _addressCache = {};

  static Future<void> enqueue(Map<String, dynamic> data) async {
    // Save to SQLite (persistent layer)
    await DatabaseHelper().insertLocation(data);

    // Add to memory queue if online
    _queue.add(data);
    await _processQueue();
  }

  static Future<void> _processQueue() async {
    if (_isSyncing || _queue.isEmpty) return;

    bool hasInternet = await InternetService().hasInternetAccess();
    if (!hasInternet) return;

    _isSyncing = true;

    while (_queue.isNotEmpty) {
      final item = _queue.first;

      try {
        // Optional reverse geocoding (deferred until online)
        String address = item['address'] ?? "";
        if (address.trim().isEmpty || address == "unknown") {
          final key = "${item['latitude']},${item['longitude']}";
          if (_addressCache.containsKey(key)) {
            address = _addressCache[key]!;
          } else {
            address = await getAddressFromLatLong(
              double.parse(item['latitude'].toString()),
              double.parse(item['longitude'].toString()),
            );
            _addressCache[key] = address;
          }
          item['address'] = address;
        }

        final sent = await _sendToServer(item);

        if (sent) {
          _queue.removeAt(0);
          await DatabaseHelper().deleteLocation(item['id']);
        } else {
          print("❌ Sending failed, retry later");
          break;
        }
      } catch (e) {
        print("❗ Sync exception: $e");
        break;
      }
    }
    _isSyncing = false;
  }

  static Future<void> resumeFromDatabase() async {
    final offlineData = await DatabaseHelper().getStoredLocations();
    _queue.addAll(offlineData);
    await _processQueue();
  }

  static Future<bool> _sendToServer(Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse('http://114.143.140.28:8020/api/Visit/InsertUpdateTrackingRecords');
      final payload = {
        "transactionId": "string",
        "transactionDate": data["datestamp"],
        "transactionTime": data["timestamp"],
        "latitude": data["latitude"].toStringAsFixed(8),
        "longitude": data["longitude"].toStringAsFixed(8),
        "staffCode": data["staffcode"],
        "deviceId": "11",
        "uuidid": "11",
        "process": "11",
        "actualDate": data["datestamp"],
        "actualTime": "11",
        "address": "N/A",
        "speed": (data["speed"] as double).toStringAsFixed(2),
        "distance": (data["distanceInMeters"] as double).toStringAsFixed(2),
        "srNo_Vo": data["srNo_Vo"],
        "status": "S",
        "distanceInKm": ((data["distanceInMeters"] as double) / 1000).toStringAsFixed(2),
        "gpsCheckFlag": "1",
        "batteryPercentage": data["batteryPercentage"],
      };

      final HttpClient client = HttpClient()
        ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      final HttpClientRequest request = await client.postUrl(uri);
      request.headers.set(HttpHeaders.contentTypeHeader, "application/json");
      request.add(utf8.encode(jsonEncode(payload)));
      final HttpClientResponse response = await request.close();
      final String responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        print("✅ API Success: $responseBody");
        return true;
      } else {
        print("❌ API Failure: ${response.statusCode}, $responseBody");
        return false;
      }
    } catch (e) {
      print("❌ API Exception: $e");
      return false;
    }
  }
  }*/

/// ios foreground and some sec of background operation using flutter background service
/*// @pragma('vm:entry-point')
// Future<bool> onIosBackground(ServiceInstance service) async {
//   DartPluginRegistrant.ensureInitialized();
//   return true;
// }
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final locationSettings = LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 10,
  );

  _locationStream = Geolocator.getPositionStream(locationSettings: locationSettings)
      .listen((Position position) async {
    final visitJson = await storage.read(key: 'SelectedVisit');
    if (visitJson == null) return;
    final Data visit = Data.fromJson(jsonDecode(visitJson));

    await sendLocation(position.latitude, position.longitude, visit);

    // Optional: Show a local notification for debugging/tracking
    await NotificationService(FlutterLocalNotificationsPlugin()).showNotification(
      showNotificationId: foregroundServiceNotificationId,
      title: "Tracking Active",
      body: 'Lat: ${position.latitude}, Lng: ${position.longitude}',
      payload: "service",
      androidNotificationDetails: const AndroidNotificationDetails(
        notificationChannelId,
        notificationChannelId,
        ongoing: true,
        playSound: false,
      ),
    );
  });

  return true;
}*/


/// Location permissions check logic
/*
Future<bool> enableGPSWithPermission() async {
  // ✅ Step 1: Check if location services (GPS) are enabled
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // ScaffoldMessenger.of(context).showSnackBar(
    //   const SnackBar(
    //     content: Text("Please enable Location Services to start the visit."),
    //     backgroundColor: Colors.redAccent,
    //     duration: Duration(seconds: 3),
    //   ),
    // );
    //
    // // Optionally open location settings for user
    // await Geolocator.openLocationSettings();
    return false;
  }

  // ✅ Step 2: Check and request location permission
  LocationPermission permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    // permission = await Geolocator.requestPermission();
    return false;
  }

  if (permission == LocationPermission.deniedForever) {
    // Fluttertoast.showToast(
    //   msg: "Location permission permanently denied. Please enable it in settings.",
    //   toastLength: Toast.LENGTH_LONG,
    // );
    // await Geolocator.openAppSettings();
    return false;
  }

  // ✅ Step 3: Ensure background location access (if required)
  if (permission != LocationPermission.always) {
    if (Platform.isAndroid) {
      final bgStatus = await Permission.locationAlways.request();
      if (!bgStatus.isGranted) {
        // Fluttertoast.showToast(
        //   msg: "Please allow 'Always' location access to start visit.",
        //   toastLength: Toast.LENGTH_LONG,
        // );
        // // await openAppSettings();
        return false;
      }
    } else if (Platform.isIOS) {
      // Fluttertoast.showToast(
      //   msg: "Enable 'Always Allow' location access in Settings > App > Location.",
      //   toastLength: Toast.LENGTH_LONG,
      // );
      // await openAppSettings();
      return false;
    }
  }

  // ✅ If everything is fine
  return true;
}
*/