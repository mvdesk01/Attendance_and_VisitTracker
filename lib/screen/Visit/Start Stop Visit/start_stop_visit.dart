import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:attendance_system_ios/screen/Visit/Start%20Stop%20Visit/location_service_repository.dart';
import 'package:attendance_system_ios/service/log_file_manager.dart';
import 'package:battery_plus/battery_plus.dart' show Battery;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../database/database_helper.dart';
import '../../../main.dart';
import '../../../model/VisitData/fetch_visit_data.dart';
import '../../../service/auto_start_visit.dart';
import '../../../service/background_service.dart';
import '../../../service/battery_helper.dart';
import '../../../service/internet_service.dart';
import '../../Splash Screen/splash_screen.dart';

class VisitStartStopScreen extends StatefulWidget {
  final Data? visit;

  const VisitStartStopScreen({super.key, required this.visit});

  @override
  VisitDropdownScreenState createState() => VisitDropdownScreenState();
}

class VisitDropdownScreenState extends State<VisitStartStopScreen>
    with WidgetsBindingObserver {
  FlutterSecureStorage storage = FlutterSecureStorage();
  late SharedPreferences prefs;

  // late Timer _timer;
  bool isLoading = false;
  List<Data> visits = [];
  Data? selectedVisit;

  // final String empCode = "CD02714"; // Example Employee Code
  bool isVisitRunning = false;
  bool isServiceRunning = false;

  // late final Function(BuildContext) onReady;
  late BackgroundService backgroundService;
  LocationServiceRepository checkLocaitonPermission =
      LocationServiceRepository();
  Position? lastPosition;
  DateTime? lastTime;
  String lat = '';
  String lon = '';
  String? token = '';
  String? staffcode = '';

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializee();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final String? payload =
          ModalRoute.of(context)?.settings.arguments as String?;
      if (payload != null) {
        onNotificationClicked(context);
      }
    });
    backgroundService = BackgroundService();
    NativeLocationBridge.initialize(); // native ios tracking initiallization
    // backgroundService.initializeService();
  }

  Future<void> _initializee() async {
    prefs = await SharedPreferences.getInstance();
    await _fetchStorage(); // Wait for the storage fetching to complete

    // when the screen is build through start visit of visit outside
    if (widget.visit != null) {
      print('vist: ${widget.visit!.srNo}');
      setState(() {
        selectedVisit = widget.visit;
        visits.add(widget.visit!);
      });
      await storage.write(
          key: 'SelectedVisit', value: jsonEncode(widget.visit));
      return;
    }

    await fetchVisits();

    // Preselect if only one visit is available
    if (visits.length == 1) {
      Data? autoSelectedVisit = visits.first;

      // ✅ First, store visit data in shared storage (Async operation)
      await storage.write(
          key: 'SelectedVisit', value: jsonEncode(autoSelectedVisit));

      // ✅ Then, update UI inside `setState()`
      if (mounted) {
        setState(() {
          selectedVisit = autoSelectedVisit;
        });
      }
    } else {
      // ✅ Handle multiple visits
      if (mounted) {
        setState(() {
          visits = visits;
        });
      }
    }

    //if auto start - update UI
/*    final visitJson = await storage.read(key: 'SelectedVisit');
    if (visitJson == null) return;
    final Data visit = Data.fromJson(jsonDecode(visitJson));
    if(VisitState.isVisitRunning.value){
      isVisitRunning = true;
      selectedVisit = visit;
    }*/
  }

  Future<void> _fetchStorage() async {
    token = await storage.read(key: 'Auth_Token');
    staffcode = await storage.read(key: 'username');
  }

  @override
  void dispose() {
    // _timer.cancel();
    super.dispose();
  }

  ///current
  Future<void> fetchVisits() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'http://114.143.140.28:8020/api/Visit/GetAllVisit/$staffcode/1/50'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final VisitDataResoponse visitData =
            VisitDataResoponse.fromJson(json.decode(response.body));
        List<Data> allVisits = visitData.message!.data!;

        final DateTime now = DateTime.now();
        final DateFormat dateFormatter = DateFormat('dd/MM/yyyy');
        final DateFormat timeFormatter12 = DateFormat('hh:mm a');
        final DateFormat timeFormatter24 = DateFormat('HH:mm');

        // Restore the selected visit from storage
        String? storedVisitJson = await storage.read(key: 'SelectedVisit');
        Data? storedVisit;
        if (storedVisitJson != null) {
          storedVisit = Data.fromJson(json.decode(storedVisitJson));
        }
        print("storedvisit: +$storedVisit");

        setState(() {
          visits = allVisits.where((visit) {
            try {
              if (visit.selectDate == null || visit.totime == null) {
                return false;
              }
              DateTime parsedDate = dateFormatter.parse(visit.selectDate!);
              DateTime parsedEndTime;
              DateTime parsedStartTime;
              try {
                parsedEndTime = timeFormatter12.parse(visit.totime!);
              } catch (_) {
                parsedEndTime = timeFormatter24.parse(visit.totime!);
              }
              try {
                parsedStartTime = timeFormatter12.parse(visit.fromtime!);
              } catch (_) {
                parsedStartTime = timeFormatter24.parse(visit.fromtime!);
              }

              DateTime visitEndDateTime = DateTime(
                parsedDate.year,
                parsedDate.month,
                parsedDate.day,
                parsedEndTime.hour,
                parsedEndTime.minute,
              );
              DateTime visitStartDateTime = DateTime(
                parsedDate.year,
                parsedDate.month,
                parsedDate.day,
                parsedStartTime.hour,
                parsedStartTime.minute,
              );

              bool isVisitStillValid = (now.isAfter(visitStartDateTime) ||
                      now.isAtSameMomentAs(visitStartDateTime)) &&
                  (now.isBefore(visitEndDateTime) ||
                      now.isAtSameMomentAs(visitEndDateTime));
              return isVisitStillValid ||
                  (isVisitRunning && selectedVisit?.srNo == visit.srNo);
            } catch (e) {
              print("Error parsing visit: $e");
              LogFileManager.writeLog("Error parsing visit: $e");
              return false;
            }
          }).toList();

          // If visit is running, ensure it stays in the list
          if (isVisitRunning &&
              selectedVisit != null &&
              !visits.contains(selectedVisit)) {
            visits.add(selectedVisit!);
          }

          // Restore the running visit as selected
          if (isVisitRunning && storedVisit != null) {
            selectedVisit = visits.firstWhere(
                (visit) => visit.srNo == storedVisit!.srNo,
                orElse: () => storedVisit!);
          }
        });
      } else if (response.statusCode == 401) {
        LogFileManager.writeLog(
            "Unauthorized ${response.statusCode}, response body: ${response.body}");
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Unauthorized. Kindly Login Again!!'),
            action: SnackBarAction(
              label: 'Login Again',
              onPressed: () {
                isloggedIn = true;
                // Navigate using the global navigator key
                MyApp.navigatorKey.currentState?.pushReplacement(
                  MaterialPageRoute(builder: (context) => SplashScreen()),
                );
              },
            ),
            duration: Duration(minutes: 2), // Make it sticky
          ),
        );
      }
    } catch (e) {
      LogFileManager.writeLog("Fetch visit error: ${e}");
      print('Fetch visit error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Fetch visit error: Retry After Sometime!")));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> startVisit(Data visit) async {
    try {
      Future<PermissionStatus> status =
          checkAndRequestNotificationPermission(context);
      if (!await status.isGranted) {
        return;
      }

      bool confirm = await _showStartVisitDialog(visit);
      if (!confirm) return;
      bool userConcent = await showLocationDisclosure();
      if (!userConcent) return;

      if (!await enableGPSWithPermission(context)) return;

      prefs.setBool("isTrackingActive", true);
      // prefs.setBool("isRestartDuringTracking", true);

      // ✅ Ensure background service is running
      if (!await backgroundService.flutterBackgroundService.isRunning()) {
        await backgroundService.initializeService();
        bool started =
            await backgroundService.flutterBackgroundService.startService();
        if (!started) {
          LogFileManager.writeLog("Failed to start background service.");
          Fluttertoast.showToast(msg: "Failed to start background service.");
          return;
        }
      }

      // ✅ Handle battery optimization gracefully
      await _handleBatteryOptimization(visit);

      if (Platform.isIOS) {
        await NativeLocationBridge.startNativeTracking(visit);
      }

      setState(() {
        isLoading = true;
        isVisitRunning = true;
        selectedVisit = visit;
      });
      VisitState.runningVisitSrNo = visit.srNo;
      await storage.write(
        key: 'RunningVisitSrNo',
        value: visit.srNo.toString(),
      );
      // visit running state store locally
      await storage.write(key: 'isVisitRunning', value: true.toString());
      // ✅ Update global state only
      VisitState.isVisitRunning.value = true;

      Fluttertoast.showToast(msg: "Visit started successfully!");
      print("Visit started successfully!");

      // ✅ Delegate validation & scheduling
      _validateAndScheduleVisit(visit);
    } catch (e) {
      Fluttertoast.showToast(msg: "Error starting visit: $e");
      LogFileManager.writeLog("Error starting visit: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<bool> showLocationDisclosure() async {
    return await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: const Text("Allow Background Location"),
              content: const Text(
                "Attendance & Visit Tracker collects location data to track your visit route "
                "and verify field activities even when the app is closed or not in use. "
                "This helps maintain accurate visit history for official work.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Decline"),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Allow"),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _handleBatteryOptimization(Data visit) async {
    final ignoring = await BatteryOptimizationHelper.isIgnoring();

    if (!ignoring) {
      Fluttertoast.showToast(
        msg: "Battery optimization is ON. Tracking may be interrupted.",
        toastLength: Toast.LENGTH_LONG,
      );

      // Open settings, but don’t block visit start
      await BatteryOptimizationHelper.requestIgnore();
    } else {
      Fluttertoast.showToast(
        msg:
            "Battery optimization already disabled. Tracking will continue smoothly.",
        toastLength: Toast.LENGTH_SHORT,
      );
      LogFileManager.writeLog(
          "Battery optimization already disabled. Tracking will continue smoothly.");
    }

    // ✅ Always continue visit start
    await startLocationTracking(visit);
    backgroundService.setServiceAsForeGround();
    LogFileManager.writeLog(
        "Visit started ${visit.reason} At: ${DateTime.now()}");
  }

  Future<bool> _showStartVisitDialog(Data visit) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade50, Colors.blue.shade100],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Start Visit",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent)),
                    const SizedBox(height: 16),
                    Text("Visit Name: ${visit.reason}",
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 10),
                    Text("Start Time: ${visit.fromtime}",
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 10),
                    Text("End Time: ${visit.totime}",
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 10),
                    Text("Destination: ${visit.destination}",
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 20),
                    const Text(
                      "Caution: For better tracking of your visit, start your visit when you are ready to go.",
                      style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Cancel",
                                style: TextStyle(
                                    color: Colors.redAccent, fontSize: 16))),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("OK",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ) ??
        false;
  }

  void _validateAndScheduleVisit(Data visit) {
    try {
      DateTime now = DateTime.now();
      DateFormat dateFormatter = DateFormat('dd/MM/yyyy');
      DateFormat timeFormatter12 = DateFormat('hh:mm a'); // 12-hour format
      DateFormat timeFormatter24 = DateFormat('HH:mm'); // 24-hour format

      DateTime parsedDate = dateFormatter.parse(visit.selectDate!);

      DateTime parsedStartTime;
      DateTime parsedEndTime;

      try {
        parsedStartTime = timeFormatter12.parse(visit.fromtime!);
        parsedEndTime = timeFormatter12.parse(visit.totime!);
      } catch (_) {
        parsedStartTime = timeFormatter24.parse(visit.fromtime!);
        parsedEndTime = timeFormatter24.parse(visit.totime!);
      }

      DateTime visitStartTime = DateTime(
        parsedDate.year,
        parsedDate.month,
        parsedDate.day,
        parsedStartTime.hour,
        parsedStartTime.minute,
      );

      DateTime visitEndTime = DateTime(
        parsedDate.year,
        parsedDate.month,
        parsedDate.day,
        parsedEndTime.hour,
        parsedEndTime.minute,
      );

      print("Current Time: $now");
      print("Visit Start Time: $visitStartTime");
      print("Visit End Time: $visitEndTime");

      if (now.isBefore(visitStartTime)) {
        Fluttertoast.showToast(
            msg: "You cannot start the visit before its scheduled time.");
        setState(() {
          isVisitRunning = false;
          selectedVisit = null;
        });
        return;
      }

      if (now.isAfter(visitEndTime)) {
        Fluttertoast.showToast(msg: "Visit time already expired.");
        stopVisit();
        return;
      }

      // ✅ Auto-stop at scheduled end time
      Duration timeRemaining = visitEndTime.difference(now);
      Timer(timeRemaining, () {
        if (isVisitRunning) {
          stopVisit();
          Fluttertoast.showToast(msg: "Visit automatically stopped.");
        }
      });
    } catch (e) {
      print("Error validating/scheduling visit: $e");
      LogFileManager.writeLog("Error validating/scheduling visit: $e");
    }
  }

  Future<void> startLocationTracking(Data visit) async {
    // Add your location tracking logic here
    setState(() {
      isLoading = true;
    });

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    if (visit.status == 'I') {
      updateVisitStatusStartingLatLong(
          position.latitude, position.longitude, visit);
    }
    await sendLocation(position.latitude, position.longitude,
        visit); // no need but for quickly receiving the first lat long
    setState(() {
      isLoading = false;
    });
    // _timer = Timer.periodic(const Duration(seconds: 10), (_) async {
    //   Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    //   await sendLocation(position.latitude, position.longitude, visit);
    //   setState(() {
    //     lat = position.latitude.toString();
    //     lon = position.longitude.toString();
    //   });
    // });
    print("Tracking started for visit: ${visit.reason /*['VisitName']*/}");
  }

  Future<void> updateVisitStatusStartingLatLong(
      double latitude, double longitude, Data visit) async {
    try {
      final response = await http.post(
          Uri.parse(
              "http://114.143.140.28:8020/api/Visit/UpdateStatusStartLatLong/${visit.srNo}/${latitude.toStringAsFixed(8)}/${longitude.toStringAsFixed(8)}/S"),
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token', // Ensure token is valid
          });

      if (response.statusCode == 200) {
        print('updateVisitStatusStartingLatLong body: ' + response.body);
      } else {
        print('Failed to updateVisitStatusStartingLatLong');
      }
    } catch (e) {
      print('Error while calling updateVisitStatusStartingLatLong API: $e');
      LogFileManager.writeLog(
          'Error while calling updateVisitStatusStartingLatLong API: $e');
    }
  }

  ///newWithofflineSupport
  Future<void> sendLocation(
      double latitude, double longitude, Data visit) async {
    int? transactionId = visit.srNo;
    String actualDate =
        DateFormat('dd/MM/yyyy').format(DateTime.now()).split(" ").first;
    String stringTransactionId = transactionId.toString();
    String transactionTime =
        DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());
    String transactionDate = DateFormat('dd/MM/yyyy').format(DateTime.now());

    double speed = 0.0;
    double distanceInMeters = 0.0;
    double distanceInKm = 0.0;
    String address = "Unknown";

    DateTime currentTime = DateTime.now();

    final battery = Battery();
    final String batteryLevel = (await battery.batteryLevel).toString();

    if (lastPosition != null && lastTime != null) {
      distanceInMeters = Geolocator.distanceBetween(
          lastPosition!.latitude, lastPosition!.longitude, latitude, longitude);
      distanceInKm = distanceInMeters / 1000;
      double timeDiffInSeconds =
          currentTime.difference(lastTime!).inSeconds.toDouble();
      if (timeDiffInSeconds > 0) {
        speed = (distanceInMeters / timeDiffInSeconds) * 3.6;
      }
    }

    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        address = "${placemarks.first.name}, ${placemarks.first.locality}";
      }
    } catch (e) {
      print("📌 Address fetch error: $e");
      LogFileManager.writeLog(
          "Start-Stop --> SendLocation --> Address fetch error: $e");
    }

    lastPosition = Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: currentTime,
      accuracy: 0.0,
      altitude: 0.0,
      heading: 0.0,
      speed: speed,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );
    lastTime = currentTime;

    bool hasInternet =
        await InternetService().hasInternetAccess(); // ✅ Check internet

    if (!hasInternet) {
      print(
          "❌ No internet! Storing data in SQLite instead of making an API call.");
      await DatabaseHelper().insertLocation({
        "staffcode": staffcode,
        "latitude": latitude,
        "longitude": longitude,
        "address": address,
        "speed": speed,
        "distanceInMeters": distanceInMeters,
        "distanceInKm": distanceInKm,
        "srNo_Vo": stringTransactionId,
        "timestamp": transactionTime,
        "batteryPercentage": batteryLevel.toString()
      });

      print(
          "✅ Data stored in SQLite: LAT: $latitude, LONG: $longitude, ADDRESS: $address, SPEED: ${speed.toStringAsFixed(2)}, DISTANCE: ${distanceInMeters.toStringAsFixed(2)} meters,staffcode: $staffcode");
      LogFileManager.writeLog(
          "Data stored in SQLite: LAT: $latitude, LONG: $longitude, ADDRESS: $address, SPEED: ${speed.toStringAsFixed(2)}, DISTANCE: ${distanceInMeters.toStringAsFixed(2)} meters,staffcode: $staffcode");

      return; // 🚀 Exit function to prevent API call
    }
    await syncOfflineData();

    await LogManagerTrackingData.writeLog(
        "API request time - ${DateTime.now()}");
    // ✅ Internet is available, send data to server
    try {
      final response = await http.post(
        Uri.parse(
            'http://114.143.140.28:8020/api/Visit/InsertUpdateTrackingRecords'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "transactionId": 'string',
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
          "srNo_Vo": stringTransactionId,
          "status": "S",
          "distanceInKm": distanceInKm.toStringAsFixed(3),
          "gpsCheckFlag": "1",
          "batteryPercentage": batteryLevel.toString()
        }),
      );

      print("Save Location Details status code: ${response.statusCode}");
      // Fluttertoast.showToast(msg: "Save Location Details status code: ${response.statusCode}");
      print("Save Location Details body: ${response.body}");
      print("Speed: ${speed.toStringAsFixed(2)} km/h");
      print("Distance: ${distanceInMeters.toStringAsFixed(2)} meters");
      print("Distance in Km: ${distanceInKm.toStringAsFixed(3)} km");
      print("Address: $address");
      LogFileManager.writeLog(
          'Save Location Details body when nwt is available: ${response.body}');
      await LogManagerTrackingData.writeLog(
          "API success time - ${DateTime.now()}");
    } catch (e) {
      LogFileManager.writeLog(
          "Saving lat long Error when nwt is available:  $e");
      print("Saving lat long Error: $e");
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkBackgroundServiceStatus(); // Just checks, doesn't restart
  }

  Future<void> _checkBackgroundServiceStatus() async {
    final running = await backgroundService.instance.isRunning();

    if (mounted) {
      setState(() {
        isVisitRunning = running;
      });
    }
  }

  Future<void> stopVisit() async {
    setState(() {
      isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove("isTrackingActive");
      await prefs.remove("isRestartDuringTracking");
      await storage.delete(key: 'SelectedVisit');
      await storage.delete(key: 'AutoStartVisit');
      await storage.delete(key: 'isVisitRunning');
      // ✅ Update global state only
      VisitState.isVisitRunning.value = false;
      VisitState.isVisitStarted.value = false;

      setState(() {
        isVisitRunning = false;
        selectedVisit = null;
        fetchVisits(); // Refresh visit list
      });
      VisitState.runningVisitSrNo = null;
      await storage.delete(key: 'RunningVisitSrNo');
      backgroundService.stopService();
      BackgroundServiceAutoStart backgroundServiceAutoStart =
          BackgroundServiceAutoStart();
      backgroundServiceAutoStart.stopService();
      // ❗️ Manually cancel the notification (especially for iOS)
      await FlutterLocalNotificationsPlugin()
          .cancel(foregroundServiceNotificationId);
      await FlutterLocalNotificationsPlugin().cancel(889);
      await FlutterLocalNotificationsPlugin().cancelAll();
      if (Platform.isIOS) {
        await NativeLocationBridge
            .stopNativeTracking(); // 👈 Native ios stop tracking
      }
      Fluttertoast.showToast(msg: "Visit stopped.");
      LogFileManager.writeLog("Visit Stopped At: ${DateTime.now()}");
    } catch (e) {
      Fluttertoast.showToast(msg: "Error stopping visit: $e");
      LogFileManager.writeLog("Error stopping visit: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select a Visit"),
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated modern loader
                  SizedBox(
                    height: 100,
                    width: 100,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Subtle background circle
                        Container(
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.withOpacity(0.1),
                          ),
                        ),
                        // Actual spinner
                        const CircularProgressIndicator(
                          strokeWidth: 5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Loading visits...",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Please wait a moment! Do not close this screen",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  // const SizedBox(height: 8),
                  // Text(
                  //   "Do not close this screen until visit started",
                  //   style: TextStyle(
                  //     fontSize: 14,
                  //     color: Colors.grey[600],
                  //   ),
                  // ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  DropdownButton<Data>(
                    isExpanded: true,
                    value: (selectedVisit != null &&
                            visits.contains(selectedVisit))
                        ? selectedVisit
                        : null,
                    // ✅ avoid mismatch
                    hint: const Text("Select a Visit"),
                    items: visits.map((visit) {
                      return DropdownMenuItem<Data>(
                        value: visit,
                        child: Text(
                          "${visit.reason} (${visit.selectDate} -> ${visit.fromtime} - ${visit.totime})",
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        onVisitSelected(value);
                        setState(() {
                          selectedVisit = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    onPressed: selectedVisit == null || isVisitRunning
                        ? null
                        : () {
                            startVisit(selectedVisit!);
                          },
                    icon: const Icon(Icons.play_arrow, color: Colors.green),
                    label: Text(
                      isVisitRunning ? "Visit Running..." : "Start Visit",
                      style: const TextStyle(color: Colors.blue),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: isVisitRunning ? stopVisit : null,
                    icon: const Icon(Icons.stop_outlined, color: Colors.red),
                    label: const Text(
                      "Stop Visit",
                      style: TextStyle(color: Colors.blue),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FutureBuilder<LocationPermission>(
                    future: Geolocator.checkPermission(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done &&
                          snapshot.hasData &&
                          snapshot.data != LocationPermission.always) {
                        // Determine platform-specific message
                        final bool isIOS = Platform.isIOS;
                        final String title = isIOS
                            ? "Note for iPhone Users:"
                            : "Note for Android Users:";

                        final List<Widget> instructions = isIOS
                            ? [
                                Text(
                                  "To enable accurate background tracking, please ensure you’ve set location permission to 'Always'.",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white70
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Go to:",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.lightBlue,
                                  ),
                                ),
                                Text(
                                  "Settings > Attendance > Location > Select 'Always'",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white70
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Also ensure 'Precise Location' is enabled.",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white70
                                        : Colors.black87,
                                  ),
                                ),
                              ]
                            : [
                                Text(
                                  "To ensure continuous and accurate location tracking in the background, please allow the app to always access your location.",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white70
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Go to:",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.lightBlue,
                                  ),
                                ),
                                Text(
                                  "Settings > Apps > Attendance > Permissions > Location > Allow all the time",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white70
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Also ensure GPS is turned ON and battery optimization is disabled for this app.",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white70
                                        : Colors.black87,
                                  ),
                                ),
                              ];

                        return Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            border: Border.all(color: Colors.lightBlueAccent),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.lightBlue,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...instructions,
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  if (isVisitRunning) ...[
                    Expanded(
                      child: Lottie.asset(
                        'assets/animation/visit_tracking.json',
                        repeat: true,
                        animate: true,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Visit Tracking Started",
                          style: TextStyle(
                              fontSize: 22,
                              color: Colors.blue[800],
                              fontWeight: FontWeight.bold),
                        ),
                        Icon(
                          Icons.location_on_outlined,
                          size: 30,
                          color: Colors.blue[800],
                        ),
                        Text(
                          "..",
                          style: TextStyle(
                              fontSize: 22,
                              color: Colors.blue[800],
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 150),
                  ]
                ],
              ),
            ),
    );
  }

  void onVisitSelected(Data visit) async {
    try {
      // ✅ Perform async storage operation first
      await storage.write(key: 'SelectedVisit', value: jsonEncode(visit));
    } catch (e) {
      LogFileManager.writeLog("Error in onVisitSelected: $e");
    }

    try {
      // ✅ Then, update UI inside setState()
      if (mounted) {
        setState(() {
          selectedVisit = visit;
        });
      }
    } catch (e) {
      LogFileManager.writeLog("Error in onVisitSelected mount: $e");
    }
  }

  // Show a stop visit dialog box
  void showStopVisitDialogBox(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Stop Visit Tracking"),
          content:
              const Text("Are you sure you want to stop tracking the visit?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                // cancelNotification();
                stopVisit();
                Navigator.of(context).pop();
              },
              child: const Text("Ok"),
            ),
          ],
        );
      },
    );
  }

  Future<PermissionStatus> checkAndRequestNotificationPermission(
      BuildContext context) async {
    PermissionStatus status = await Permission.notification.status;

    // iOS specific handling
    if (Platform.isIOS) {
      final bool? result = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );

      if (result == false) {
        // User denied permission
        await _showPermissionDialog(context,
            "Notification permission denied on iOS. Please enable it from settings.");
        return status;
      } else {
        print(
            "iOS notification permission granted via flutter_local_notifications: $result");
        return PermissionStatus.granted;
      }
    }

    // Android specific handling
    if (Platform.isAndroid) {
      if (status.isDenied || status.isRestricted) {
        PermissionStatus result = await Permission.notification.request();

        if (result.isGranted) {
          print("Notification permission granted on Android.");
        } else if (result.isPermanentlyDenied) {
          await _showPermissionDialog(context,
              "Notification permission permanently denied. Enable it from settings.");
        } else {
          print("Notification permission denied on Android.");
        }
        return result;
      } else if (status.isPermanentlyDenied) {
        await _showPermissionDialog(context,
            "Notification permission permanently denied. Enable it from settings.");
      } else if (status.isGranted) {
        print("Notification permission already granted on Android.");
      }
      return status;
    }
    return status;
  }

  Future<bool> enableGPSWithPermission(BuildContext context) async {
    // ✅ Step 1: Check if location services (GPS) are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enable Location Services to start the visit."),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 3),
        ),
      );

      // Optionally open location settings for user
      await Geolocator.openLocationSettings();
      return false;
    }

    // ✅ Step 2: Check and request location permission
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      Fluttertoast.showToast(
        msg:
            "Location permission permanently denied. Please enable it in settings.",
        toastLength: Toast.LENGTH_LONG,
      );
      await Geolocator.openAppSettings();
      return false;
    }

    // ✅ Step 3: Ensure background location access (if required)
    if (permission != LocationPermission.always) {
      if (Platform.isAndroid) {
        final bgStatus = await Permission.locationAlways.request();
        if (!bgStatus.isGranted) {
          Fluttertoast.showToast(
            msg: "Please allow 'Always' location access to start visit.",
            toastLength: Toast.LENGTH_LONG,
          );
          await openAppSettings();
          return false;
        }
      } else if (Platform.isIOS) {
        Fluttertoast.showToast(
          msg:
              "Enable 'Always Allow' location access in Settings > App > Location.",
          toastLength: Toast.LENGTH_LONG,
        );
        await openAppSettings();
        return false;
      }
    }

    // ✅ If everything is fine
    return true;
  }

/*  Future<bool> enableGPSWithPermission() async {
    // Request foreground permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      await openAppSettings();
      return false;
    }

    // Request background permission (required on Android 10+ and iOS 13+)
    if (permission != LocationPermission.always) {
      if (Platform.isAndroid) {
        PermissionStatus bgStatus = await Permission.locationAlways.request();
        if (!bgStatus.isGranted) {
          await openAppSettings();
          return false;
        }
      } else if (Platform.isIOS) {
        // On iOS, background permission is prompted automatically after WhileInUse
        Fluttertoast.showToast(msg: "Enable 'Always Allow' location access in settings.");
        await openAppSettings();
        return false;
      }
    }

    return true;
  }*/

  Future<void> _showPermissionDialog(
      BuildContext context, String message) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Notification Permission"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Fluttertoast.showToast(
                  msg: message,
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                );
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
              child: const Text("Open Settings"),
            ),
          ],
        );
      },
    );
  }

  void onNotificationClicked(BuildContext context) {
    if (context != null) {
      showStopVisitDialogBox(context);
    } else {
      print("Error: Context is not available.");
    }
  }

  Future<void> cancelNotification() async {
    setState(() {
      isVisitRunning = false;
      isServiceRunning = false;
    });
    // notificationsPlugin.cancel(888); // Use the same notification ID
    // saveState();
    // _timer.cancel();
    backgroundService.stopService();
    // FlutterBackgroundService().invoke('stopTracking');
    // localNotifications.cancelAll(); // Remove notification
  }
}

///dropdown
///current
/*   DropdownButton<Data>(
              isExpanded: true,
              value: visits.length == 1 ? visits.first : (visits.contains(selectedVisit) ? selectedVisit : null),
              hint: const Text("Please Select"),  // Show hint only if multiple visits
              items: [
                if (visits.length > 1)  // ✅ Add "Please Select" only if there are multiple options
                  const DropdownMenuItem<Data>(
                    value: null,
                    child: Text("Please Select"),
                  ),
                ...visits.map((visit) {
                  return DropdownMenuItem<Data>(
                    value: visit,
                    child: Text(
                      "${visit.reason} (${visit.selectDate} -> ${visit.fromtime} - ${visit.totime})",
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
              ],
              onChanged: (value) async {
                if (value != null) {
                  await storage.write(key: 'SelectedVisit', value: jsonEncode(value));
                  setState(() {
                    selectedVisit = value;
                  });
                }
              },
            ),*/

///newold
// DropdownButton<Data>(
//   isExpanded: true,
//   value: visits.contains(selectedVisit) ? selectedVisit : null, // Ensure valid selection
//   hint: const Text("Select a Visit"),
//   items: visits.map((visit) {
//     return DropdownMenuItem<Data>(
//       value: visit,
//       child: Text(
//         "${visit.reason} (${visit.selectDate} -> ${visit.fromtime} - ${visit.totime})",
//         style: const TextStyle(fontSize: 14),
//       ),
//     );
//   }).toList(),
//   onChanged: (value) async {
//     if (value != null) {
//       await storage.write(key: 'SelectedVisit', value: jsonEncode(value));
//       setState(() {
//         selectedVisit = value;
//       });
//     }
//   },
// ),
///old
// DropdownButton<Data>(
//   isExpanded: true,
//   value: selectedVisit,
//   hint: const Text("Select a Visit"),
//   items: visits.map((visit) {
//     return DropdownMenuItem<Data>(
//       value: visit,
//       child: Text(
//         "${visit.reason} (${visit.selectDate} - ${visit.totime})",
//         style: const TextStyle(fontSize: 14),
//       ),
//     );
//   }).toList(),
//   onChanged: (value) {
//     setState(() async {
//       selectedVisit = value;
//       await storage.write(key: 'SelectedVisit', value: jsonEncode(selectedVisit));
//     });
//   },
// ),

/*Future<bool> enableGPSWithPermission() async {
    try {
      final status = await Permission.locationAlways.request();
      const permission = LocationPermission.always;
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        return true;
      } else {
        Fluttertoast.showToast(msg: "GPS permission not granted!, Set the location permissions to Always.");
        Fluttertoast.showToast(msg: "Try Again!!");
        if(!status.isGranted){
          bool res = await openAppSettings();
        }
        return false;
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error enabling GPS: $e");
      return false;
    }
  }*/
/*Future<bool> enableGPSWithPermission() async {
    try {
      // Request permission using permission_handler
      PermissionStatus status = await Permission.locationAlways.request();

      if (status.isGranted) {
        // Double-check actual permission level using geolocator
        LocationPermission permission = await Geolocator.checkPermission();

        if (permission == LocationPermission.always) {
          print("Location permission granted: Always");
          return true;
        } else if (permission == LocationPermission.whileInUse) {
          Fluttertoast.showToast(
              msg: "Location is only allowed While In Use. Set it to Always in settings.");
          await openAppSettings();
          return false;
        } else {
          LocationPermission result = await Geolocator.requestPermission();

          if (result == LocationPermission.always) {
            return true;
          } else {
            Fluttertoast.showToast(
                msg:
                "GPS permission not granted. Please allow 'Always' in settings.");
            await openAppSettings();
            return false;
          }
        }
      } else {
        Fluttertoast.showToast(
            msg: "Location permission not granted. Open settings to allow.");
        await openAppSettings();
        return false;
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error requesting GPS permission: $e");
      return false;
    }
  }*/

///old fetchvisit
//   Future<void> fetchVisits() async {
//     setState(() {
//       isLoading = true;
//     });
//     // if (await restoreState()) {
//     //   setState(() {
//     //     isLoading = false;
//     //   });
//     //   return;
//     // }
//
//     try{
//       final response = await http.get(
//         Uri.parse('http://114.143.140.28:8020/api/Visit/GetAllVisit/$staffcode/1/50'),
//         headers: <String, String>{
//           // 'accept': '*/*', // Matches the cURL command
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token', // Ensure token is valid
//         },
//       );
//
//       print('fetch api response code: ${response.statusCode}');
//       print('Response body: ${response.body}');
//       if(response.statusCode == 200){
//         // final request = json.decode(response.body);
//         // VisitDataResoponse.fromJson(json.decode(response.body))
//         final VisitDataResoponse visitData = VisitDataResoponse.fromJson(json.decode(response.body));
//         List<Data> allVisits = visitData.message!.data!;
//
//         final DateTime now = DateTime.now();
//         final DateFormat dateFormatter = DateFormat('dd/MM/yyyy');
//         final DateFormat timeFormatter12 = DateFormat('hh:mm a'); // For 12-hour format
//         final DateFormat timeFormatter24 = DateFormat('HH:mm'); // For 24-hour format
//
//         setState(() {
//           visits = allVisits.where((visit) {
//             try {
//               String? visitDate = visit.selectDate;
//               String? visitEndTime = visit.totime;
//
//               if (visitDate == null || visitEndTime == null) {
//                 return false;
//               }
//
//               DateTime parsedDate = dateFormatter.parse(visitDate);
//
//               DateTime parsedEndTime;
//               try {
//                 parsedEndTime = timeFormatter12.parse(visitEndTime);
//               } catch (_) {
//                 parsedEndTime = timeFormatter24.parse(visitEndTime);
//               }
//
//               DateTime visitDateTime = DateTime(
//                 parsedDate.year,
//                 parsedDate.month,
//                 parsedDate.day,
//                 parsedEndTime.hour,
//                 parsedEndTime.minute,
//               );
//
//               return visitDateTime.isAfter(now) || visitDateTime.isAtSameMomentAs(now);
//             } catch (e) {
//               print("Error parsing visit: $e");
//               return false;
//             }
//           }).toList();
//         });
//
//       }
//       else if (response.statusCode == 401) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('UnAuthorized. Kindly Login Again!!'),
//             action: SnackBarAction(
//               label: 'Login Again',
//               onPressed: () {
//                 Navigator.push(context,
//                     MaterialPageRoute(builder: (context) => SplashScreen()));
//               },
//             ),
//             duration: Duration(days: 365), // Make it sticky
//           ),
//         );
//       }
//     }catch(e){
//       print('Fetch visit error: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Error: $e")));
//       LogFileManager.writeLog('Fetch visit error: $e');
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

// abhishek api save lat long while tracking is started
// Future<void> sendLocation(double latitude, double longitude, Data visit) async {
//   int? transactionId = visit.srNo;
//   String stringTransactionId = transactionId.toString();
//   String transactionTime = DateFormat('dd/MM/yyy hh:mm:ss').format(DateTime.now());
//   String transactionDate = DateFormat('dd/MM/yyy').format(DateTime.now());
//   // print("save visit details: $token, $transactionId, $transactionDate, $transactionTime, $latitude, $longitude, $staffcode");
//   try{
//     final response = await http.post(
//       Uri.parse('http://114.143.140.28:8020/api/Visit/InsertUpdateTrackingRecords'),
//       headers: <String, String>{
//       'Content-Type': 'application/json',
//       // 'Authorization': 'Bearer $token', // Ensure token is valid
//       },
//       body: json.encode({
//         "transactionId":'string',
//         "transactionDate": transactionDate,
//         "transactionTime": transactionTime,
//         "latitude": latitude.toString(),
//         "longitude": longitude.toString(),
//         "staffCode": staffcode,
//         "deviceId": "11",
//         "uuidid": "11",
//         "process": "11",
//         "actualDate": "11",
//         "actualTime": "11",
//         "address": "11",
//         "speed": "11",
//         "distance": "11",
//         "srNo_Vo": stringTransactionId,
//         "status": "S",
//         "distanceInKm": "11",
//         "gpsCheckFlag": "1"
//       }),
//     );
//
//     print("save visit details: $transactionId, $transactionDate, $transactionTime, $latitude, $longitude, $staffcode");
//     print("Save Location Details status code: ${response.statusCode}");
//     print("Save Location Details body: ${response.body}");
//     if(response.statusCode == 200){
//       print("Location saved successfully");
//     } else{
//       print("Failed to save location");
//     }
//   }catch(e){
//     print("Saving lat long Error: $e");
//     LogFileManager.writeLog("Saving lat long Error: $e");
//   }
// }

///new
// Future<void> sendLocation(double latitude, double longitude, Data visit) async {
//   int? transactionId = visit.srNo;
//   String stringTransactionId = transactionId.toString();
//   String transactionTime = DateFormat('dd/MM/yyy hh:mm:ss').format(DateTime.now());
//   String transactionDate = DateFormat('dd/MM/yyy').format(DateTime.now());
//   String actualDate=DateFormat('dd/MM/yyy').format(DateTime.now()).split(" ").first;
//   // print("save visit details: $token, $transactionId, $transactionDate, $transactionTime, $latitude, $longitude, $staffcode");
//   double speed = 0.0;
//   double distanceInMeters = 0.0;
//   double distanceInKm = 0.0;
//   String address = "Unknown";
//
//   DateTime currentTime = DateTime.now();
//
//   if (lastPosition != null && lastTime != null) {
//     distanceInMeters = Geolocator.distanceBetween(
//         lastPosition!.latitude, lastPosition!.longitude, latitude, longitude);
//
//     distanceInKm = distanceInMeters / 1000;
//
//     int timeDiffInSeconds = currentTime.difference(lastTime!).inSeconds;
//     if (timeDiffInSeconds > 0) {
//       speed = (distanceInMeters / timeDiffInSeconds) * 3.6; // Convert m/s to km/h
//     }
//   }
//
//   // Get address from lat/lng
//   try {
//     List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
//     if (placemarks.isNotEmpty) {
//       address = "${placemarks.first.name}, ${placemarks.first.locality}";
//     }
//   } catch (e) {
//     print("Address fetch error: $e");
//   }
//
//   lastPosition = Position(
//     latitude: latitude,
//     longitude: longitude,
//     timestamp: currentTime,
//     accuracy: 0.0,
//     altitude: 0.0,
//     heading: 0.0,
//     speed: speed,
//     speedAccuracy: 0.0,
//     altitudeAccuracy: 0.0, // Added required parameter
//     headingAccuracy: 0.0,
//   );
//   lastTime = currentTime;
//
//   bool hasInternet = await InternetService().hasInternetAccess();  // Check internet using your class
//
//   if (!hasInternet) {
//     print("No internet. Storing data locally in SQLite...");
//     await DatabaseHelper().insertLocation({
//       "latitude": latitude,
//       "longitude": longitude,
//       "address": address,
//       "speed": speed.toString(),
//       "distanceInMeters": distanceInMeters.toString(),
//       "distanceInKm": distanceInKm.toString(),
//       "timestamp": transactionTime,
//     });
//     print("✅ Data stored in SQLite: LAT: $latitude,"
//         " LONG: $longitude, ADDRESS: $address, SPEED: ${speed.toStringAsFixed(2)},"
//         " DISTANCE: ${distanceInMeters.toStringAsFixed(2)} meters");
//     return;
//   }
//
//
//   // Send to server
//   try {
//     final response = await http.post(
//       Uri.parse('http://114.143.140.28:8020/api/Visit/InsertUpdateTrackingRecords'),
//       headers: {'Content-Type': 'application/json'},
//       body: json.encode({
//         "transactionId": 'string',
//         "transactionDate": transactionDate,
//         "transactionTime": transactionTime,
//         "latitude": latitude.toString(),
//         "longitude": longitude.toString(),
//         "staffCode": staffcode,
//         "deviceId": "11",
//         "uuidid": "11",
//         "process": "11",
//         "actualDate": actualDate,
//         "actualTime": "11",
//         "address": address,
//         "speed": speed.toStringAsFixed(2),
//         "distance": distanceInMeters.toStringAsFixed(2),
//         "srNo_Vo": stringTransactionId,
//         "status": "S",
//         "distanceInKm": distanceInKm.toStringAsFixed(3),
//         "gpsCheckFlag": "1"
//       }),
//     );
//
//     print("Save Location Details status code: ${response.statusCode}");
//     print("Save Location Details body: ${response.body}");
//     print("Speed: ${speed.toStringAsFixed(2)} km/h");
//     print("Distance: ${distanceInMeters.toStringAsFixed(2)} meters");
//     print("Distance in Km: ${distanceInKm.toStringAsFixed(3)} km");
//     print("Address: $address");
//
//   } catch (e) {
//     print("Saving lat long Error: $e");
//   }
// }

///old
//   Future<void> stopVisit() async {
//     setState(() {
//       isLoading = true;
//     });
//
//     try {
//       backgroundService.stopService();
//       await storage.delete(key: 'SelectedVisit');
//       // saveState();
//       // _timer.cancel();
//       // cancelNotification();
//       setState(() {
//         isVisitRunning = false;
//       });
//       Fluttertoast.showToast(msg: "Visit stopped.");
//     } catch (e) {
//       Fluttertoast.showToast(msg: "Error stopping visit: $e");
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

/*        final position = Position(
          longitude: double.tryParse(event['longitude'].toString()) ?? 0.0,
          latitude: double.tryParse(event['latitude'].toString()) ?? 0.0,
          timestamp: DateTime.fromMillisecondsSinceEpoch(
              event['timestamp'].toInt(),
              isUtc: true),
          accuracy: double.tryParse(event['accuracy'].toString()) ?? 0.0,
          altitude: double.tryParse(event['altitude'].toString()) ?? 0.0,
          heading: double.tryParse(event['heading'].toString()) ?? 0.0,
          speed: double.tryParse(event['speed'].toString()) ?? 0.0,
          speedAccuracy:
          double.tryParse(event['speed_accuracy'].toString()) ?? 0.0,
          altitudeAccuracy:
          double.tryParse(event['altitude_accuracy'].toString()) ?? 0.0,
          headingAccuracy:
          double.tryParse(event['heading_accuracy'].toString()) ?? 0.0,
        );*/
// Future<void> handleLocationChange(Position position) async {
//   // Handle location updates (e.g., send to server, update UI, etc.)
//   Data? visit;
//   final jsonString = await storage.read(key: 'SelectedVisit');
//   if (jsonString != null) {
//     final jsonMap = json.decode(jsonString);
//      visit = Data.fromJson(jsonMap);
//   }
//   await sendLocation(position.latitude, position.longitude, visit!);
//   print("Location changed: $position");
// }

/*  Future<Position?> fetchLocationByDeviceGPS() async {
    try {
      final location = await Geolocator.getCurrentPosition();
      Fluttertoast.showToast(
        msg: "Location fetched: Lat ${location.latitude}, Lng ${location.longitude}",
      );
      return location;
    } catch (e) {
      Fluttertoast.showToast(msg: "Error fetching location: $e");
      return null;
    }
  }*/

/// Show a notification
/*Future<void> showNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'visit_tracking',
      'Visit Tracking',
      channelDescription: 'Tracking your visit in the background',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: true,
      // playSound: false,
      // foregroundService: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics = DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await notificationsPlugin.show(
      0,
      'Visit Tracking Active 🔔',
      'Tap to stop the visit $lat',
      platformChannelSpecifics,
      payload: 'visit_tracking',
    );
    print("Notification shown: Visit is being tracked");
  }*/

///old UI logic with method name
/*@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text("Select a Visit"),
    ),
    body: isLoading
        ? Center(child: CircularProgressIndicator())
        : Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Dropdown for selecting visits
          DropdownButton<Data>(
            isExpanded: true,
            value: selectedVisit,
            hint: Text("Select a Visit"),
            items: visits.map((visit) {
              return DropdownMenuItem<Data>(
                value: visit,
                child: Text(
                  "${visit.reason} (${visit.selectDate} - ${visit.totime})",
                  style: TextStyle(fontSize: 14),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedVisit = value;
              });
            },
          ),

          SizedBox(height: 40),

          // Start Visit Button
          ElevatedButton.icon(
            onPressed: selectedVisit == null || isVisitRunning
                ? null
                : () {
              startVisit(selectedVisit!);
            },
            icon: Icon(Icons.play_arrow, color: Colors.green,),
            label: Text(isVisitRunning ? "Visit Running..." : "Start Visit", style: TextStyle(color: MyColors.fontBlue),),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 50),
              textStyle: TextStyle(fontSize: 16),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: isVisitRunning
                ? () {
              cancelNotification();
            } : null,
            icon: const Icon(Icons.stop_outlined, color: Colors.red),
            label: const Text("Stop Visit", style: TextStyle(color: MyColors.fontBlue),),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 50),
              textStyle: TextStyle(fontSize: 16),
            ),
          ),

        ],
      ),
    ),
  );
}*/

/// Restore State from SharedPreferences
// Future<bool> restoreState() async {
//   final prefs = await SharedPreferences.getInstance();
//   bool result = prefs.getBool('isVisitRunning') ?? false;
//   if(!result){
//     return false;
//   }
//
//   Data? selectedValue;
//   String? jsonString = prefs.getString('selectedVisit');
//
//   if (jsonString != null) {
//      //selectedValue =  jsonDecode(jsonString) as Data;
//
//
//     String? jsonString = prefs.getString('selectedVisit');
//
//      // Decode the JSON string
//      Map<String, dynamic> decodedJson = jsonDecode(jsonString!);
//
//      // Use the fromJson method to create an instance of Data
//      Data selectedValue = Data.fromJson(decodedJson);
//   }
//
//   setState(() {
//     isVisitRunning = result;
//       selectedVisit = selectedValue;
//   });
//
//   if(isVisitRunning){
//     return true;
//   }
//   return false;
// }

/// Persist State to SharedPreferences
// Future<void> saveState() async {
//   final prefs = await SharedPreferences.getInstance();
//   if(!isVisitRunning){
//     await prefs.remove('selectedVisit'); // Remove the key if the value is null
//     await prefs.setBool('isVisitRunning', false); // Remove if the visit if stoped
//     // selectedVisit!.clear();
//     setState(() {
//       selectedVisit = null;
//       fetchVisits();
//     });
//     // fetchVisits();
//     return;
//   }
//
//   prefs.setBool('isVisitRunning', isVisitRunning);
//   if (selectedVisit != null) {
//     String jsonString = jsonEncode(selectedVisit); // Convert map to JSON string
//     await prefs.setString('selectedVisit', jsonString);
//   }
// }

///background service configuration code
// void setupBackgroundService() async {
//   final service = FlutterBackgroundService();
//
//   await service.configure(
//     androidConfiguration: AndroidConfiguration(
//       onStart: onStart,
//       autoStart: true,
//       isForegroundMode: true,
//       notificationChannelId: 'visit_tracking',
//       initialNotificationTitle: 'Visit Tracking Active 🔔',
//       initialNotificationContent: 'Tap to stop the visit',
//       foregroundServiceNotificationId: 0,
//     ),
//     iosConfiguration: IosConfiguration(autoStart: true),
//   );
//
//   if (!await service.isRunning() || !isServiceRunning) {
//     service.startService();
//     setState(() {
//       isServiceRunning = true;
//     });
//   }
// }
//
// void onStart(ServiceInstance service) {
//   service.on('setAsForeground').listen((event) {
//     if (service is AndroidServiceInstance) {
//       service.setAsForegroundService();
//     }
//   });
//
//   /*  service.on('stopService').listen((event) {
//       service.stopSelf();
//     });*/
//
//   Timer.periodic(const Duration(seconds: 10), (timer) async {
//     // showNotification();
//     if (!isServiceRunning) {
//       timer.cancel(); // Stop the timer if the service is not running
//       print("Is service running: $isServiceRunning");
//       return;
//     }
//     // if (!(await service.isRunning())) timer.cancel();
//
//     // Fetch location
//     Position position = await Geolocator.getCurrentPosition(
//       desiredAccuracy: LocationAccuracy.high,
//     );
//     // Send to API
//     // await sendLocation(position.latitude, position.longitude);
//     print("Background Location: ${position.latitude}, ${position.longitude}");
//
//     // Update notification
//     service.invoke(
//       'updateNotification',
//       {
//         "latitude": position.latitude,
//         "longitude": position.longitude,
//       },
//     );
//   });
//
//   Timer.periodic(Duration(seconds: 10), (timer) async {
//     // Track location here
//     Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
//     // await sendLocation(position.latitude, position.longitude);
//     print("Background Location: ${position.latitude}, ${position.longitude}");
//   });
// }
