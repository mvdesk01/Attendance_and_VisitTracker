import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';

import '../database/database_helper.dart';
import '../main.dart';
import '../util/MyColor.dart';
import 'package:http/http.dart' as http;

import 'log_file_manager.dart';

class InternetService {
  static final InternetService _instance = InternetService._internal();
  factory InternetService() => _instance;
  InternetService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _dialogShown = false;
  bool _isSyncing = false; // ✅ Prevent duplicate syncs

  void startListening(BuildContext context) {
    _subscription = _connectivity.onConnectivityChanged.listen((result) async {
      if (result != ConnectivityResult.none) {
        // Small delay to stabilize connection
        await Future.delayed(const Duration(seconds: 2));
        bool hasInternet = await hasInternetAccess();
        if (hasInternet) {
          _dismissDialog(context);
          await _syncDataOnce(); // ✅ Controlled sync execution
        } else {
          showNoInternetDialog(context);
        }
      } else {
        showNoInternetDialog(context);
      }
    });
  }

  Future<void> checkInternetAndProceed(BuildContext context) async {
    try {
      bool hasInternet = await hasInternetAccess();
      if (!hasInternet) {
        print("else: no internet");
        showNoInternetDialog(context);
      } else {
        return;
      }
    } catch (e) {
      debugPrint("Error checking internet: $e");
      startListening(context); // Restart listener if an error occurs
    }
  }

  Future<bool> hasInternetAccess() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  void showNoInternetDialog(BuildContext context) {
    if (_dialogShown) return;
    _dialogShown = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (dialogContext) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.withOpacity(0.1), Colors.blue.withOpacity(0.4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off, size: 60, color: MyColors.fontBlue),
                const SizedBox(height: 20),
                const Text(
                  "No Internet Connection",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: MyColors.fontBlue),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Please check your connection and try again.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MyColors.fontBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  ),
                  onPressed: () async {
                    bool hasInternet = await hasInternetAccess();
                    if (hasInternet) {
                      if (Navigator.of(context).canPop()) {
                        Navigator.pop(context);
                      }
                      await Future.delayed(const Duration(milliseconds: 500));
                      await _syncDataOnce();
                      startListening(context);
                    } else {
                      showNoInternetDialog(context);
                    }
                  },
                  child: const Text("Retry", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ).then((_) => _dialogShown = false);
    });
  }

  void _dismissDialog(BuildContext context) {
    if (!_dialogShown) return;
    _dialogShown = false;
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  void stopListening() {
    _subscription?.cancel();
  }

  /// **Ensure `syncOfflineData()` runs only once per internet reconnection**
  Future<void> _syncDataOnce() async {
    print("inside _syncDataOnce");
    if (_isSyncing) return;
    _isSyncing = true;
    await syncOfflineData();
    _isSyncing = false;
  }
}

// Sync offline data into persistant data/API
Future<void> syncOfflineData() async {
  await Future.delayed(const Duration(seconds: 2));    // for detection of low/weak network
  await syncOfflineDataa();
}

/// sync offline data with reverse geocoding
Future<void> syncOfflineDataa() async {
  bool hasInternet = await InternetService().hasInternetAccess();
  if (!hasInternet) {
    print("❌ No internet, skipping sync.");
    return;
  }

  List<Map<String, dynamic>> storedData = await DatabaseHelper().getStoredLocations();
  print("📌 Syncing ${storedData.length} stored records to server...");

  // Cache to avoid repeated reverse geocoding of same coordinates
  Map<String, String> addressCache = {};

  for (var data in storedData) {
    try {
      String actualDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
      String transactionDate = data['timestamp'].toString().split(" ").first;

      /// ✅ Smart reverse geocoding with retries and cache
      String address = data['address'] ?? "";
      bool needsGeocoding = address.trim().isEmpty || address.trim().toLowerCase() == "unknown";

      if (needsGeocoding) {
        String latLngKey = "${data['latitude']},${data['longitude']}";
        if (addressCache.containsKey(latLngKey)) {        //  use last address if address is same not need of reverse geocoding
          address = addressCache[latLngKey]!;
        } else {
          address = await getAddressFromLatLong(          // reverse geocoding from lat long
            double.parse(data['latitude'].toString()),
            double.parse(data['longitude'].toString()),
          );
          addressCache[latLngKey] = address;
        }
      }

      print("Sending offline data to server: $data");

        final uri = Uri.parse('http://114.143.140.28:8091/api/Visit/InsertUpdateTrackingRecords');
        final payload = {
          "transactionId": "string",
          "transactionDate": transactionDate,
          "transactionTime": data['timestamp'],
          "latitude": data['latitude'].toStringAsFixed(8),
          "longitude": data['longitude'].toStringAsFixed(8),
          "staffCode": data['staffcode'],
          "deviceId": "11",
          "uuidid": "11",
          "process": "11",
          "actualDate": actualDate,
          "actualTime": "11",
          "address": address,
          "speed": data['speed'].toStringAsFixed(2),
          "distance": data['distanceInMeters'].toString(),
          "srNo_Vo": data['srNo_Vo'],
          "status": "S",
          "distanceInKm": data['distanceInKm'].toStringAsFixed(2),
          "gpsCheckFlag": "1",
          "batteryPercentage": data['batteryPercentage']?.toString() ?? ""
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
        final String responseBody = await response
            .transform(utf8.decoder)
            .join();

        if (response.statusCode == 200) {
          await DatabaseHelper().markAsSynced(data['id']);
          //await DatabaseHelper().deleteLocation(data['id']);
          LogFileManager.writeLog("✅ Offline data sent to server: LAT:${data['latitude']}, LONG: ${data['longitude']}");
          print("✅ Offline data sent & deleted: LAT: ${data['latitude']}, LONG: ${data['longitude']}");
        }
        else {
          LogFileManager.writeLog("❌ Failed to send offline data. Status: ${response.statusCode}, Response: ${responseBody}");
          print("❌ Failed to send offline data. Status: ${response.statusCode}, Response: ${responseBody}");
          continue;
        }
    }catch (e) {
      LogFileManager.writeLog("❌ catch Error syncing offline data: $e");
      print("❌ Error syncing offline data: $e");
      continue;
    }
  }
  //print("✅ Sync complete!");
}

/// Address from lat long/ Reverse geocoding when online again then store at the place where miss the
Future<String> getAddressFromLatLong(double latitude, double longitude, {int retries = 3}) async {
  for (int attempt = 0; attempt < retries; attempt++) {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);    // address from lat-long using this method which uses google server to do the conversion
      if (placemarks.isNotEmpty) {
        Placemark p = placemarks.first;
        return "${p.name}, ${p.locality}";
      }
    } catch (e) {
      print("⚠️ Reverse geocoding attempt ${attempt + 1} failed: $e");
      if (attempt < retries - 1) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }
  return "Unknown";
}







/// old internet dialog box ui
/*void showNoInternetDialog(BuildContext context) {
  if (_dialogShown) return;
  _dialogShown = true;

  WidgetsBinding.instance.addPostFrameCallback((_) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.darkBlue.shade50, Colors.blue.shade200],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 50, color: Colors.white),
              const SizedBox(height: 16),
              const Text(
                "No Internet Connection",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                "Please try reconnecting to continue using the app.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black45),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  bool hasInternet = await hasInternetAccess();
                  if (hasInternet) {
                    // _dismissDialog(context);
                    if (Navigator.of(context).canPop()) {
                      Navigator.pop(context); // Auto-close after 60 seconds
                    }
                    await Future.delayed(const Duration(milliseconds: 500)); // Prevent immediate rebuild
                    await _syncDataOnce();
                    startListening(context); // ✅ Restart listener
                  } else {
                    showNoInternetDialog(context);
                  }
                },

                child: const Text("Retry", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    ).then((_) => _dialogShown = false);
  });
}*/

