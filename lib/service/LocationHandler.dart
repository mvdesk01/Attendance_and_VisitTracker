import 'package:attendance_system_ios/screen/Home/home.dart';
import 'package:attendance_system_ios/service/log_file_manager.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
// import 'package:location/location.dart';
// import 'dart:math';

class LocationHandler {
  static double? currentLat;  // Example zone center latitude
  static double? currentLon;
  static String? currentAddress;
  HomeScreen homeScreen = HomeScreen();

  static double? zoneLat;
  static double? zoneLon;
  static double? remoteZoneLat;
  static double? remoteZoneLon;
  static double radiusInMeters = 200;          //setting the redius in meter
  static bool _remoteLocationChange = false;


  static void changeToRemoteLocation () {
    _remoteLocationChange = true;
  }

  static void changeToOfficeLocation () {
    _remoteLocationChange = false;
  }

  static Future<bool> handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are disabled. Please enable the services
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Location permissions are denied
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      // Location permissions are permanently denied, we cannot request permissions.

      return false;
    }
    return true;
  }


  /*static Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await handleLocationPermission();
      if (!hasPermission) return null;{

         LocationSettings locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.best,
          // distanceFilter: 100,
          timeLimit: Duration(seconds: 10)
        );

        Position position = await Geolocator.getCurrentPosition(locationSettings: locationSettings)
            .catchError((e) {
          print('Error: $e');
          Fluttertoast.showToast(msg: "Please Try Again!!");
          return null;
        });
        return position;
      }
    } catch (e) {
      return null;
    }
  }*/

  static Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await handleLocationPermission();
      if (!hasPermission) return null;

      LocationSettings locationSettings = const LocationSettings(

        accuracy: LocationAccuracy.best, // Request the most accurate location
        timeLimit: Duration(seconds: 10), // Reduce time if needed
      );

      Position position = await Geolocator.getCurrentPosition(
        // forceAndroidLocationManager: true,
        // desiredAccuracy: LocationAccuracy.best,
        // timeLimit: Duration(seconds: 10),
      )
          .catchError((e) {
        print('Error: $e');
        Fluttertoast.showToast(msg: "Please Try Again!!");
        LogFileManager.writeLog('Error: LocationHandler ->getCurrentPosition: $e');
        return null;
      });

      return position;
    } catch (e) {
      print('Error while getting position: $e');
      LogFileManager.writeLog('LocationHandler: Error while getting position: $e');
      return null;
    }
  }


  static Future<String?> getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placeMarks =
      await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placeMarks[0];
      return "${place.street}, ${place.subLocality},${place.subAdministrativeArea}, ${place.postalCode}";
    } catch (e) {
      LogFileManager.writeLog('LocationHandler: Error while getting getAddressFromLatLng: $e');
      return null;
    }
  }


/*   static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295; // Math.PI / 180
    var a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km (Earth's radius)
  }*/


  static Future<bool> isUserInZone(Position userPosition, double zoneLat, double zoneLon, double radiusInMeters) async {
    double distance = Geolocator.distanceBetween(
      userPosition.latitude,
      userPosition.longitude,
      zoneLat,
      zoneLon,
    );

    // If distance is less than the radius, user is inside the zone
    return distance <= radiusInMeters; // Distance in meters
  }

  static Future<bool> checkIfInZone() async {
    Position? accuratePosition = await getCurrentPosition();
    if (accuratePosition == null) return false;

    String? currentAdd = await getAddressFromLatLng(accuratePosition);
    print("lat ${accuratePosition.latitude}");
    print("long ${accuratePosition.longitude}");
    print("address $currentAdd");

    // Update current location values
    currentLat = accuratePosition.latitude;
    currentLon = accuratePosition.longitude;
    currentAddress = currentAdd;

    // Zone definition (example values)
    if(_remoteLocationChange){
      zoneLat = remoteZoneLat;
      zoneLon = remoteZoneLon;
    }else{
      zoneLat = 18.5842;
      zoneLon = 73.7354;
    }

    bool inZone = await isUserInZone(accuratePosition, zoneLat!, zoneLon!, radiusInMeters);
    return inZone;
  }

// void startLocation(){
//
//
//   _serviceEnabled = await location.serviceEnabled();
//   if (!_serviceEnabled) {
//     _serviceEnabled = await location.requestService();
//     if (!_serviceEnabled) {
//       return;
//     }
//   }
//
//   _permissionGranted = await location.hasPermission();
//   if (_permissionGranted == PermissionStatus.denied) {
//     _permissionGranted = await location.requestPermission();
//     if (_permissionGranted != PermissionStatus.granted) {
//       return;
//     }
//   }
//
//   _locationData = await location.getLocation();
//   You can also get continuous callbacks when your position is changing:
//
//   location.onLocationChanged.listen((LocationData currentLocation) {
//   // Use current location
//   });
//   To receive location when application is in background you have to enable it:
//
//   location.enableBackgroundMode(enable: true)
//
// }

}



// import 'package:geolocator/geolocator.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// class LocationService {
//   // Function to check and request for location permission
//   Future<bool> _checkLocationPermission() async {
//     // Check if location services are enabled
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       // Location services are not enabled
//       return false;
//     }
//
//     // Check for location permissions
//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         return false; // Permissions denied
//       }
//     }
//
//     if (permission == LocationPermission.deniedForever) {
//       // Permissions are permanently denied
//       return false;
//     }
//
//     return true;
//   }
//
//   // Function to get the current location of the user
//   Future<Position?> getCurrentLocation() async {
//     final hasPermission = await _checkLocationPermission();
//     if (!hasPermission) {
//       print('Location permissions are denied');
//       return null;
//     }
//
//     try {
//       // Get the current location
//       Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );
//       return position;
//     } catch (e) {
//       print('Error getting location: $e');
//       return null;
//     }
//   }
//
//   // Function to listen for real-time location updates (optional)
//   // Stream<Position> getPositionStream() {
//   //   return Geolocator.getPositionStream(
//   //     locationSettings: LocationSettings(
//   //       accuracy: LocationAccuracy.high,
//   //       distanceFilter: 100, // Change this to how often you want updates (in meters)
//   //     ),
//   //   );
//   // }
// }
