import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:attendance_system_ios/service/log_file_manager.dart';
import 'package:attendance_system_ios/util/MyColor.dart';
import 'package:battery_plus/battery_plus.dart' show Battery;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
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
import '../../Splash Screen/splash_screen.dart';
import '../../../service/internet_service.dart';

class VisitStartStopScreen extends StatefulWidget {
  final Data? visit;
  const VisitStartStopScreen({super.key, required this.visit});
  @override
  VisitDropdownScreenState createState() => VisitDropdownScreenState();
}

class VisitDropdownScreenState extends State<VisitStartStopScreen> with WidgetsBindingObserver{

  FlutterSecureStorage storage = FlutterSecureStorage();
  late SharedPreferences prefs;
  bool isLoading = false;
  List<Data> visits = [];
  Data? selectedVisit;
  bool isVisitRunning = false;
  bool isServiceRunning = false;
  late BackgroundService backgroundService;
  Position? lastPosition;
  DateTime? lastTime;
  String lat = '';
  String lon = '';
  String? token = '';
  String? staffcode = '';

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializee();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final String? payload = ModalRoute.of(context)?.settings.arguments as String?;
      if (payload != null) {
        onNotificationClicked(context);
      }
    });
    backgroundService = BackgroundService();
    NativeLocationBridge.initialize();
  }

  Future<void> _initializee() async {
    prefs = await SharedPreferences.getInstance();
    await _fetchStorage();

    if(widget.visit != null){
      setState(() {
        selectedVisit = widget.visit;
        visits.add(widget.visit!);
      });
      await storage.write(key: 'SelectedVisit', value: jsonEncode(widget.visit));
      return;
    }

    await fetchVisits();

    if (visits.length == 1) {
      Data? autoSelectedVisit = visits.first;
      await storage.write(key: 'SelectedVisit', value: jsonEncode(autoSelectedVisit));
      if (mounted) {
        setState(() {
          selectedVisit = autoSelectedVisit;
        });
      }
    }
  }

  Future<void> _fetchStorage() async {
    token = await storage.read(key: 'Auth_Token');
    staffcode = await storage.read(key: 'username');
  }

  @override
  void dispose() {
    super.dispose();
  }

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

        String? storedVisitJson = await storage.read(key: 'SelectedVisit');
        Data? storedVisit;
        if (storedVisitJson != null) {
          storedVisit = Data.fromJson(json.decode(storedVisitJson));
        }

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
              return false;
            }
          }).toList();

          if (isVisitRunning &&
              selectedVisit != null &&
              !visits.contains(selectedVisit)) {
            visits.add(selectedVisit!);
          }

          if (isVisitRunning && storedVisit != null) {
            selectedVisit = visits.firstWhere(
                    (visit) => visit.srNo == storedVisit!.srNo,
                orElse: () => storedVisit!);
          }
        });
      } else if (response.statusCode == 401) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Unauthorized. Kindly Login Again!!'),
            action: SnackBarAction(
              label: 'Login Again',
              onPressed: () {
                isloggedIn = true;
                MyApp.navigatorKey.currentState?.pushReplacement(
                  MaterialPageRoute(builder: (context) => SplashScreen()),
                );
              },
            ),
            duration: Duration(minutes: 2),
          ),
        );
      }
    } catch (e) {
      LogFileManager.writeLog("Fetch visit error: ${e}");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Fetch visit error: Retry After Sometime!")));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> startVisit(Data visit) async {
    final prefs = await SharedPreferences.getInstance();
    bool accepted = prefs.getBool("location_disclosure_accepted") ?? false;
    try {
      Future<PermissionStatus> status = checkAndRequestNotificationPermission(context);
      if (!await status.isGranted) {
        return;
      }

      bool confirm = await _showStartVisitDialog(visit);
      if (!confirm) return;
      if(!accepted) {
        bool userConcent = await showLocationDisclosure();
        if (!userConcent) return;
        await prefs.setBool("location_disclosure_accepted", true);
      }

      if (!await enableGPSWithPermission(context)) return;

      prefs.setBool("isTrackingActive", true);

      if (!await backgroundService.flutterBackgroundService.isRunning()) {
        await backgroundService.initializeService();
        bool started = await backgroundService.flutterBackgroundService.startService();
        if (!started) {
          LogFileManager.writeLog("Failed to start background service.");
          Fluttertoast.showToast(msg: "Failed to start background service.");
          return;
        }
      }

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
      await storage.write(key: 'isVisitRunning', value: true.toString());
      await storage.write(key: 'activeVisit', value: visit.srNo.toString());
      VisitState.isVisitRunning.value = true;

      Fluttertoast.showToast(msg: "Visit started successfully!");

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

  Future<void> _handleBatteryOptimization(Data visit) async {
    final ignoring = await BatteryOptimizationHelper.isIgnoring();

    if (!ignoring) {
      Fluttertoast.showToast(
        msg: "Battery optimization is ON. Tracking may be interrupted.",
        toastLength: Toast.LENGTH_LONG,
      );
      await BatteryOptimizationHelper.requestIgnore();
    } else {
      LogFileManager.writeLog("Battery optimization already disabled. Tracking will continue smoothly.");
    }

    await startLocationTracking(visit);
    backgroundService.setServiceAsForeGround();
    LogFileManager.writeLog("Visit started ${visit.reason} At: ${DateTime.now()}");
  }

  Future<bool> _showStartVisitDialog(Data visit) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.play_circle_fill, color: Colors.green, size: 28),
                    const SizedBox(width: 12),
                    Text("Start Visit",
                        style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ],
                ),
                const SizedBox(height: 20),
                _buildDialogInfoRow(Icons.description_outlined, "Visit", visit.reason ?? ""),
                _buildDialogInfoRow(Icons.access_time, "Time", "${visit.fromtime} - ${visit.totime}"),
                _buildDialogInfoRow(Icons.place_outlined, "To", visit.destination ?? "N/A"),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Start your visit only when you are ready to depart.",
                          style: GoogleFonts.poppins(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text("CANCEL", style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.w600))),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MyColors.appDefaultColorCode,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: Text("START NOW", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ) ?? false;
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
    ) ?? false;
  }

  Widget _buildDialogInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                Text(value, style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _validateAndScheduleVisit(Data visit) {
    try {
      DateTime now = DateTime.now();
      DateFormat dateFormatter = DateFormat('dd/MM/yyyy');
      DateFormat timeFormatter12 = DateFormat('hh:mm a');
      DateFormat timeFormatter24 = DateFormat('HH:mm');

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

      if (now.isBefore(visitStartTime)) {
        Fluttertoast.showToast(msg: "You cannot start the visit before its scheduled time.");
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

      Duration timeRemaining = visitEndTime.difference(now);
      Timer(timeRemaining, () {
        if (isVisitRunning) {
          stopVisit();
          Fluttertoast.showToast(msg: "Visit automatically stopped.");
        }
      });
    } catch (e) {
      LogFileManager.writeLog("Error validating/scheduling visit: $e");
    }
  }

  Future<void> startLocationTracking(Data visit) async {
    setState(() {
      isLoading = true;
    });

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    if(visit.status == 'I'){
      updateVisitStatusStartingLatLong(position.latitude, position.longitude, visit);
    }
    await sendLocation(position.latitude, position.longitude, visit);
    setState(() {
      isLoading = false;
    });
  }

  Future<void> updateVisitStatusStartingLatLong(double latitude, double longitude, Data visit)async {
    try{
      final response = await http.post(
          Uri.parse("http://114.143.140.28:8020/api/Visit/UpdateStatusStartLatLong/${visit.srNo}/${latitude.toStringAsFixed(8)}/${longitude.toStringAsFixed(8)}/S"),
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          }
      );
    } catch(e){
      LogFileManager.writeLog('Error while calling updateVisitStatusStartingLatLong API: $e');
    }
  }

  Future<void> sendLocation(double latitude, double longitude, Data visit) async {
    int? transactionId = visit.srNo;
    String actualDate=DateFormat('dd/MM/yyyy').format(DateTime.now()).split(" ").first;
    String stringTransactionId = transactionId.toString();
    String transactionTime = DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());
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
          lastPosition!.latitude, lastPosition!.longitude, latitude, longitude
      );
      distanceInKm = distanceInMeters / 1000;
      double timeDiffInSeconds = currentTime.difference(lastTime!).inSeconds.toDouble();
      if (timeDiffInSeconds > 0) {
        speed = (distanceInMeters / timeDiffInSeconds) * 3.6;
      }
    }

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        address = "${placemarks.first.name}, ${placemarks.first.locality}";
      }
    } catch (e) {
      LogFileManager.writeLog("Start-Stop --> SendLocation --> Address fetch error: $e");
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

    bool hasInternet = await InternetService().hasInternetAccess();

    if (!hasInternet) {
      await DatabaseHelper().insertLocation({
        "staffcode":staffcode,
        "latitude": latitude,
        "longitude": longitude,
        "address": address,
        "speed": speed,
        "distanceInMeters": distanceInMeters,
        "distanceInKm": distanceInKm,
        "srNo_Vo":stringTransactionId,
        "timestamp": transactionTime,
        "batteryPercentage": batteryLevel.toString()
      });
      return;
    }
    await syncOfflineData();

    try {
      final response = await http.post(
        Uri.parse('http://114.143.140.28:8020/api/Visit/InsertUpdateTrackingRecords'),
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
    }
    catch (e) {
      LogFileManager.writeLog("Saving lat long Error when nwt is available:  $e");
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkBackgroundServiceStatus();
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
      await storage.delete(key: 'RunningVisitSrNo');
      VisitState.isVisitRunning.value = false;
      VisitState.isVisitStarted.value = false;
      VisitState.runningVisitSrNo = null;

      setState(() {
        isVisitRunning = false;
        selectedVisit = null;
        fetchVisits();
      });
      backgroundService.stopService();
      BackgroundServiceAutoStart backgroundServiceAutoStart = BackgroundServiceAutoStart();
      backgroundServiceAutoStart.stopService();
      await FlutterLocalNotificationsPlugin().cancel(foregroundServiceNotificationId);
      await FlutterLocalNotificationsPlugin().cancel(889);
      await FlutterLocalNotificationsPlugin().cancelAll();
      if (Platform.isIOS) {
        await NativeLocationBridge.stopNativeTracking();
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
      // backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_sharp, color: Colors.white, fontWeight: FontWeight.bold,),
        ),
        title: Text(
          "Start/Stop Visit",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
        ),
        backgroundColor: MyColors.lightBlue,
        centerTitle: true,
      ),
      body: isLoading ? _buildLoadingView() : _buildContentView(),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/animation/visit_tracking.json', height: 200, errorBuilder: (context, error, stackTrace) =>
          const CircularProgressIndicator(color: MyColors.appDefaultColorCode)),
          const SizedBox(height: 20),
          Text(
            "Processing visit data...",
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.blueGrey),
          ),
          const SizedBox(height: 8),
          Text(
            "Do not close this screen",
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildContentView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Select Visit", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Data>(
                isExpanded: true,
                value: (selectedVisit != null && visits.contains(selectedVisit)) ? selectedVisit : null,
                hint: Text("Choose a scheduled visit", style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey)),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: MyColors.appDefaultColorCode),
                items: visits.map((visit) {
                  return DropdownMenuItem<Data>(
                    value: visit,
                    child: Text(
                      "${visit.reason} (${visit.fromtime} - ${visit.totime})",
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    onVisitSelected(value);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 32),

          if (!isVisitRunning) ...[
            _buildActionButton(
              label: "START VISIT",
              icon: Icons.play_arrow_rounded,
              color: MyColors.appDefaultColorCode,
              onPressed: selectedVisit == null ? null : () => startVisit(selectedVisit!),
            ),
          ] else ...[
            _buildActionButton(
              label: "STOP VISIT",
              icon: Icons.stop_rounded,
              color: Colors.red.shade600,
              onPressed: stopVisit,
            ),
            const SizedBox(height: 30),
            Center(
              child: Column(
                children: [
                  Lottie.asset('assets/animation/visit_tracking.json', height: 180),
                  Text("Visit Tracking Active", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 4),
                  Text("Sending location updates periodically", style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey)),
                ],
              ),
            ),
          ],

          const SizedBox(height: 40),
          _buildPermissionNote(),
        ],
      ),
    );
  }

  Widget _buildActionButton({required String label, required IconData icon, required Color color, VoidCallback? onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }

  Widget _buildPermissionNote() {
    return FutureBuilder<LocationPermission>(
      future: Geolocator.checkPermission(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.data != LocationPermission.always) {
          final isIOS = Platform.isIOS;
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.blue.shade700, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      isIOS ? "Setting for iPhone" : "Setting for Android",
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "For continuous tracking in the background, location access must be set to 'Allow all the time'.",
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.blue.shade800, height: 1.5),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("HOW TO ENABLE:", style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                      const SizedBox(height: 4),
                      Text(
                        isIOS
                            ? "Settings > Attendance > Location > Always"
                            : "Settings > Apps > Attendance > Permissions > Location > Allow all the time",
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void onVisitSelected(Data visit) async {
    try{
      await storage.write(key: 'SelectedVisit', value: jsonEncode(visit));
      if (mounted) {
        setState(() {
          selectedVisit = visit;
        });
      }
    } catch(e){
      LogFileManager.writeLog("Error in onVisitSelected: $e");
    }
  }

  void showStopVisitDialogBox(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text("Stop Tracking?", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: Text("Are you sure you want to stop tracking this visit?", style: GoogleFonts.poppins()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("CANCEL", style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                stopVisit();
                Navigator.of(context).pop();
              },
              child: Text("STOP", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<PermissionStatus> checkAndRequestNotificationPermission(BuildContext context) async {
    PermissionStatus status = await Permission.notification.status;
    if (Platform.isIOS) {
      final bool? result = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return result == true ? PermissionStatus.granted : status;
    }
    if (Platform.isAndroid) {
      if (status.isDenied || status.isRestricted) {
        status = await Permission.notification.request();
      }
    }
    return status;
  }

  Future<bool> enableGPSWithPermission(BuildContext context) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enable Location Services."), backgroundColor: Colors.redAccent));
      await Geolocator.openLocationSettings();
      return false;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return false;
    }
    return true;
  }

  void onNotificationClicked(BuildContext context) {
    showStopVisitDialogBox(context);
  }
}
