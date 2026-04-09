import 'dart:async';
import 'package:attendance_system_ios/bloc/main_bloc.dart';
import 'package:attendance_system_ios/bloc/main_event.dart';
import 'package:attendance_system_ios/bloc/main_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../model/RemoteLocation/RemoteLocation.dart';

class RemoteLocation extends StatefulWidget {
  const RemoteLocation({super.key});

  @override
  State<RemoteLocation> createState() => _RemoteLocationState();
}

class _RemoteLocationState extends State<RemoteLocation> {
  Completer<GoogleMapController> _controller = Completer();
  LatLng? _currentLocation;
  LatLng officeLocation = LatLng(18.5842, 73.7354); // Replace with actual office latitude and longitude
  String _address = "Fetching address...";
  bool _locationFetched = false;
  bool _isRemoteLocation = true; // Tracks if remote location is selected
  bool _isRemoteActive = false;
  bool _isLoading = false;
  String? approveflag = "";
  String? approveflag1 = "";
  LocationSettings? settings;
  LocationSettings? locationSettings;

  final storage = FlutterSecureStorage();
  String? staffcode = "";
  String? auth_token="";
  late MainBloc mainBloc;   // Tracks if remote location is active

  @override
  void initState() {
    super.initState();
    mainBloc = BlocProvider.of(context);
    _getCurrentLocation();  // Initial location fetch
    getdata();  // Fetch saved data (remote status, address, coordinates)
  }

  void getdata() async {
    staffcode = await storage.read(key: 'Staff_Code');
    auth_token = await storage.read(key: 'Auth_Token');
    mainBloc.add(GetUserInfoEvents(Staffcode: staffcode!, token: auth_token!));
  }

  static Future<bool> handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }


  Future<void> _getCurrentLocation() async {
    final hasPermission = await handleLocationPermission();

    if (!hasPermission) {
      Fluttertoast.showToast(msg: "Location permission required");
      return;
    }

    // try {
      Position position = await Geolocator.getCurrentPosition(
        // forceAndroidLocationManager: true,
        // desiredAccuracy: LocationAccuracy.high,
        // timeLimit: const Duration(seconds: 10),
      ).catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Try again"),
          action: SnackBarAction(label: "retry", onPressed: _getCurrentLocation),
          duration: Duration(milliseconds: 3000),
        ),
      );
    });

      LatLng newLocation = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentLocation = newLocation;
        _locationFetched = true; // IMPORTANT
      });

      _moveCameraToLocation(newLocation);
      _getAddressFromLatLng(newLocation);
  }

  Future<void> _moveCameraToLocation(LatLng location) async {
    if (!_controller.isCompleted) return;

    final controller = await _controller.future;

    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: location, zoom: 17),
      ),
    );
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks =
      await placemarkFromCoordinates(position.latitude, position.longitude)
          .timeout(const Duration(seconds: 5));

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;

        setState(() {
          _address =
          "${place.locality ?? ""}, ${place.administrativeArea ?? ""}, ${place.country ?? ""}";
        });
      }
    } catch (e) {
      debugPrint("Geocoding error: $e");
      setState(() {
        _address = "Location selected";
      });
    }
  }

  void _saveLocation() {
    print("Save button clicked");

    if (_currentLocation != null) {
      setState(() {
        // Prepare RemoteLocationResponse data
        final remoteLocationData = RemoteLocationResponse(
          staffCode: staffcode,
          approvedFlag: "P",
          remoteLocation: _address,
          remoteLatitude: _currentLocation!.latitude.toString(),
          remoteLongitude: _currentLocation!.longitude.toString(),
        );

        print(remoteLocationData);

        // Dispatch an event to trigger the API call
        mainBloc.add(Remotelocation(
            remotelocation: remoteLocationData, token: auth_token!));

        // Save latitude and longitude in secure storage
        storage.write(key: 'remoteLatitude',
            value: _currentLocation!.latitude.toString());
        storage.write(key: 'remoteLongitude',
            value: _currentLocation!.longitude.toString());

        // Update the UI to indicate saving state
        _isLoading = true;
        _isRemoteActive = true;
      });

      print("latitude: ${_currentLocation!
          .latitude}, longitude: ${_currentLocation!
          .longitude}, address: $_address");
    }
  }

  void _onMapTap(LatLng tappedLocation) {
    if (_isRemoteLocation) {
      setState(() {
        _currentLocation = tappedLocation;
        _getAddressFromLatLng(tappedLocation);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MainBloc, MainState>(
      listener: (context, state) async {

        if (state is GetUserinfoLoadingState) {
          setState(() {
            _isLoading = true;
          });
        }
        else if (state is GetUserinfoLoadedState) {
          String? savedStatus = state.profileuserinfo.message!.addressapproveFlag;
          String? savedAddress = state.profileuserinfo.message!.newRemoteLocation;
          String? savedLatitude = state.profileuserinfo.message!.remoteLatitude;
          String? savedLongitude = state.profileuserinfo.message!.remoteLongitude;

          setState(() {
            setState(() {
              if (savedStatus == 'Y') {
                _isRemoteActive = true; // Remote location active
              } else if (savedStatus == 'O') {
                _isRemoteActive = false; // Office location active
              }
            });

            // Set the status and address
            _address = savedAddress ?? "Fetching address...";

            if (_isRemoteActive) {
              // If remote location is active, set the saved latitude and longitude
              if (savedLatitude != null && savedLongitude != null) {
                _currentLocation = LatLng(
                  double.parse(savedLatitude),
                  double.parse(savedLongitude),
                );
                _moveCameraToLocation(_currentLocation!);  // Move camera to the saved location
              }
            }
          });
          print("Status: $_isRemoteActive, Address: $_address");
        }
        else if (state is GetUserinfoErrorState) {
          setState(() {
            _isLoading = false;
          });
          Fluttertoast.showToast(
            msg: "  Failed To Fetch Details...!   ",
            toastLength: Toast.LENGTH_SHORT,
            timeInSecForIosWeb: 1,
          );
        }

        if (state is remotelocationLoadingState) {
          setState(() {
            _isLoading = true;
          });
        } if (state is remotelocationLoadedState) {
          setState(() {
            _isLoading = false;
            _isRemoteActive = true; // Set status to ON
          });

          // Save status and address to secure storage
          await storage.write(key: 'remoteStatus', value: 'ON');
          await storage.write(key: 'remoteAddress', value: _address);

          // Fluttertoast.showToast(msg: 'location set successfully!');
        }

        else if (state is remotelocationErrorState) {
          setState(() {
            _isLoading = false;
          });
          Fluttertoast.showToast(msg: 'Error in requesting remote location');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _isRemoteActive
                ? "Remote Location: $_address"
                : "Select Location",
            style: TextStyle(fontSize: 16),
          ),
          backgroundColor: Colors.lightBlue,
        ),
        body: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition: CameraPosition(
                      target: _currentLocation ?? const LatLng(18.5834, 73.7358),
                      zoom: _currentLocation == null ? 12 : 17,
                    ),
                    onMapCreated: (GoogleMapController controller) {
                      if (!_controller.isCompleted) {
                        _controller.complete(controller);
                      }
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: true,
                    compassEnabled: true,
                    markers: {
                      if (_currentLocation != null)
                        Marker(
                          markerId: const MarkerId("currentLocation"),
                          position: _currentLocation!,
                          infoWindow: const InfoWindow(title: "Selected Location"),
                        ),
                    },
                    onTap: _onMapTap,
                  ),

                  if (_currentLocation == null || !_locationFetched)
                    Container(
                      color: Colors.black.withOpacity(0.3), // background dim effect
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.lightBlue,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text("Address: $_address",
                      style: TextStyle(fontSize: 16, color: Colors.lightBlue)),
                  SizedBox(height: 10),
                  Text(
                    _isRemoteActive ? "Location Status: Remote Location Active" : "Location Status: Pending Approval",
                    style: TextStyle(fontSize: 16, color: _isRemoteActive ? Colors.green : Colors.orange),
                  ),
                  SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed:() {
                            if (!_locationFetched || _currentLocation == null) {
                              _showLocationNotLoadedDialog();
                              return;
                            }
                              _showRemoteLocationDialog();

                              },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue),
                          child: const Text(
                            "Set Remote Location",
                            style: TextStyle(color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  )

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationNotLoadedDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titlePadding: EdgeInsets.zero,
          title: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              gradient: LinearGradient(
                colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Text(
              "Location Not Ready",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          content: const Text(
            "Your current location is not loaded properly yet. "
                "Please wait for GPS to load and try again.",
            style: TextStyle(fontSize: 14),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "OK",
                style: TextStyle(color: Colors.lightBlue),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showRemoteLocationDialog() {

    /// First check if location is ready
    if (!_locationFetched || _currentLocation == null) {
      _showLocationNotLoadedDialog();
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titlePadding: EdgeInsets.zero,
          title: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              gradient: LinearGradient(
                colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Text(
              "Request Remote Location",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          content: const Text(
            "If you send this request, you will be able to mark attendance "
                "after it is approved by the admin.",
            style: TextStyle(fontSize: 14),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                _saveLocation();
              },
              child: const Text("Send Request"),
            ),
          ],
        );
      },
    );
  }

}





















// import 'dart:async';
// import 'package:attendance_system_ios/bloc/main_bloc.dart';
// import 'package:attendance_system_ios/bloc/main_event.dart';
// import 'package:attendance_system_ios/bloc/main_state.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// // import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
//
// import '../../model/RemoteLocation/RemoteLocation.dart';
//
// class RemoteLocation extends StatefulWidget {
//   const RemoteLocation({super.key});
//
//   @override
//   State<RemoteLocation> createState() => _RemoteLocationState();
// }
//
// class _RemoteLocationState extends State<RemoteLocation> {
//   Completer<GoogleMapController> _controller = Completer();
//   LatLng? _currentLocation;
//   LatLng officeLocation = LatLng(18.5842, 73.7354); // Replace with actual office latitude and longitude
//   String _address = "Fetching address...";
//   bool _locationFetched = false;
//   bool _isRemoteLocation = true; // Tracks if remote location is selected
//   bool _isRemoteActive = false;
//   bool _isLoading = false;
//   String? approveflag = "";
//   String? approveflag1 = "";
//   LocationSettings? settings;
//   LocationSettings? locationSettings;
//
//   final storage = FlutterSecureStorage();
//   String? staffcode = "";
//   String? auth_token="";
//   late MainBloc mainBloc;   // Tracks if remote location is active
//
//   @override
//   void initState() {
//     super.initState();
//     mainBloc = BlocProvider.of(context);
//     _getCurrentLocation();  // Initial location fetch
//     getdata();  // Fetch saved data (remote status, address, coordinates)
//   }
//
//   void getdata() async {
//     staffcode = await storage.read(key: 'Staff_Code');
//     auth_token = await storage.read(key: 'Auth_Token');
//     mainBloc.add(GetUserInfoEvents(Staffcode: staffcode!, token: auth_token!));
//   }
//
//   static Future<bool> handleLocationPermission() async {
//     bool serviceEnabled;
//     LocationPermission permission;
//
//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       return false;
//     }
//     permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         return false;
//       }
//     }
//     if (permission == LocationPermission.deniedForever) {
//       return false;
//     }
//     return true;
//   }
//
//
//   Future<void> _getCurrentLocation() async {
//     final hasPermission = await handleLocationPermission();
//
//     if (!hasPermission) {
//       Fluttertoast.showToast(msg: "Location permission required");
//       return;
//     }
//
//     try {
//       Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//         timeLimit: const Duration(seconds: 10),
//       );
//
//       LatLng newLocation = LatLng(position.latitude, position.longitude);
//
//       setState(() {
//         _currentLocation = newLocation;
//         _locationFetched = true; // IMPORTANT
//       });
//
//       _moveCameraToLocation(newLocation);
//       _getAddressFromLatLng(newLocation);
//
//     } catch (e) {
//       debugPrint("Location error: $e");
//
//       setState(() {
//         _locationFetched = true; // prevent infinite loader
//       });
//
//       Fluttertoast.showToast(
//         msg: "Unable to get GPS location. Please try again.",
//       );
//     }
//   }
//
//   Future<void> _moveCameraToLocation(LatLng location) async {
//     if (!_controller.isCompleted) return;
//
//     final controller = await _controller.future;
//
//     controller.animateCamera(
//       CameraUpdate.newCameraPosition(
//         CameraPosition(target: location, zoom: 17),
//       ),
//     );
//   }
//
//   Future<void> _getAddressFromLatLng(LatLng position) async {
//     try {
//       List<Placemark> placemarks =
//       await placemarkFromCoordinates(position.latitude, position.longitude)
//           .timeout(const Duration(seconds: 5));
//
//       if (placemarks.isNotEmpty) {
//         Placemark place = placemarks.first;
//
//         setState(() {
//           _address =
//           "${place.locality ?? ""}, ${place.administrativeArea ?? ""}, ${place.country ?? ""}";
//         });
//       }
//     } catch (e) {
//       debugPrint("Geocoding error: $e");
//       setState(() {
//         _address = "Location selected";
//       });
//     }
//   }
//
//   void _showRemoteLocationDialog() {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text("Request Remote Location"),
//           content: const Text(
//             "If you send this request, you will be able to mark attendance "
//                 "after it is approved by the admin.",
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(context);
//               },
//               child: const Text("Cancel"),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.pop(context);
//                 _saveLocation();
//               },
//               child: const Text("Send Request"),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   void _saveLocation() {
//     print("Save button clicked");
//
//     if (_currentLocation != null) {
//       setState(() {
//         // Prepare RemoteLocationResponse data
//         final remoteLocationData = RemoteLocationResponse(
//           staffCode: staffcode,
//           approvedFlag: "P",
//           remoteLocation: _address,
//           remoteLatitude: _currentLocation!.latitude.toString(),
//           remoteLongitude: _currentLocation!.longitude.toString(),
//         );
//
//         print(remoteLocationData);
//
//         // Dispatch an event to trigger the API call
//         mainBloc.add(Remotelocation(
//             remotelocation: remoteLocationData, token: auth_token!));
//
//         // Save latitude and longitude in secure storage
//         storage.write(key: 'remoteLatitude',
//             value: _currentLocation!.latitude.toString());
//         storage.write(key: 'remoteLongitude',
//             value: _currentLocation!.longitude.toString());
//
//         // Update the UI to indicate saving state
//         _isLoading = true;
//         _isRemoteActive = true;
//       });
//
//       print("latitude: ${_currentLocation!
//           .latitude}, longitude: ${_currentLocation!
//           .longitude}, address: $_address");
//     }
//   }
//
//   void _setOfficeLocation() {
//     setState(() {
//       _currentLocation = officeLocation;
//       _isRemoteActive = false; // Indicate that remote location is not active
//       _address = "M-Tech Innovations Ltd. Hinjewadi"; // Placeholder while fetching address
//
//       // Move the camera to the office location
//       _moveCameraToLocation(officeLocation);
//
//       // Fetch the address of the office based on hardcoded lat/lng
//       _getAddressFromLatLng(officeLocation).then((_) {
//         setState(() {
//           _address = "Switched to Office Location: $_address"; // Update status message
//         });
//       });
//
//       // Save office latitude and longitude in secure storage
//       storage.write(key: 'remoteLatitude', value: officeLocation.latitude.toString());
//       storage.write(key: 'remoteLongitude', value: officeLocation.longitude.toString());
//
//       // Prepare data for API call
//       final officeLocationData = RemoteLocationResponse(
//         staffCode: staffcode,
//         approvedFlag: "PO",
//         remoteLocation: _address,
//         remoteLatitude: officeLocation.latitude.toString(),
//         remoteLongitude: officeLocation.longitude.toString(),
//       );
//
//       // Dispatch an event to update location status
//       mainBloc.add(Remotelocation(remotelocation: officeLocationData, token: auth_token!));
//     });
//
//     print("Office location set: Latitude: ${officeLocation.latitude}, Longitude: ${officeLocation.longitude}, Address: $_address");
//   }
//
//   void _toggleLocation() {
//     setState(() {
//       _isRemoteLocation = !_isRemoteLocation;
//       if (_isRemoteLocation) {
//         _getCurrentLocation();
//       } else {
//         _currentLocation = officeLocation;
//         _moveCameraToLocation(_currentLocation!);
//         _getAddressFromLatLng(_currentLocation!);
//       }
//     });
//   }
//
//   void _onMapTap(LatLng tappedLocation) {
//     if (_isRemoteLocation) {
//       setState(() {
//         _currentLocation = tappedLocation;
//         _getAddressFromLatLng(tappedLocation);
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return BlocListener<MainBloc, MainState>(
//       listener: (context, state) async {
//
//         if (state is GetUserinfoLoadingState) {
//           setState(() {
//             _isLoading = true;
//           });
//         }
//         else if (state is GetUserinfoLoadedState) {
//           String? savedStatus = state.profileuserinfo.message!.addressapproveFlag;
//           String? savedAddress = state.profileuserinfo.message!.newRemoteLocation;
//           String? savedLatitude = state.profileuserinfo.message!.remoteLatitude;
//           String? savedLongitude = state.profileuserinfo.message!.remoteLongitude;
//
//           setState(() {
//             setState(() {
//               if (savedStatus == 'Y') {
//                 _isRemoteActive = true; // Remote location active
//               } else if (savedStatus == 'O') {
//                 _isRemoteActive = false; // Office location active
//               }
//             });
//
//             // Set the status and address
//             _address = savedAddress ?? "Fetching address...";
//
//             if (_isRemoteActive) {
//               // If remote location is active, set the saved latitude and longitude
//               if (savedLatitude != null && savedLongitude != null) {
//                 _currentLocation = LatLng(
//                   double.parse(savedLatitude),
//                   double.parse(savedLongitude),
//                 );
//                 _moveCameraToLocation(_currentLocation!);  // Move camera to the saved location
//               }
//             }
//           });
//           print("Status: $_isRemoteActive, Address: $_address");
//         }
//         else if (state is GetUserinfoErrorState) {
//           setState(() {
//             _isLoading = false;
//           });
//           Fluttertoast.showToast(
//             msg: "  Failed To Fetch Details...!   ",
//             toastLength: Toast.LENGTH_SHORT,
//             timeInSecForIosWeb: 1,
//           );
//         }
//
//         if (state is remotelocationLoadingState) {
//           setState(() {
//             _isLoading = true;
//           });
//         } if (state is remotelocationLoadedState) {
//           setState(() {
//             _isLoading = false;
//             _isRemoteActive = true; // Set status to ON
//           });
//
//           // Save status and address to secure storage
//           await storage.write(key: 'remoteStatus', value: 'ON');
//           await storage.write(key: 'remoteAddress', value: _address);
//
//           // Fluttertoast.showToast(msg: 'location set successfully!');
//         }
//
//         else if (state is remotelocationErrorState) {
//           setState(() {
//             _isLoading = false;
//           });
//           Fluttertoast.showToast(msg: 'Error in requesting remote location');
//         }
//       },
//       child: Scaffold(
//         appBar: AppBar(
//           title: Text(
//             _isRemoteActive
//                 ? "Remote Location: $_address"
//                 : "Select Location",
//             style: TextStyle(fontSize: 16),
//           ),
//           backgroundColor: Colors.lightBlue,
//         ),
//         body: Column(
//           children: [
//             Expanded(
//               child: Stack(
//                 children: [
//                   GoogleMap(
//                     mapType: MapType.normal,
//                     initialCameraPosition: CameraPosition(
//                       target: _currentLocation ?? const LatLng(18.5834, 73.7358),
//                       zoom: _currentLocation == null ? 12 : 17,
//                     ),
//                     onMapCreated: (GoogleMapController controller) {
//                       if (!_controller.isCompleted) {
//                         _controller.complete(controller);
//                       }
//                     },
//                     myLocationEnabled: true,
//                     myLocationButtonEnabled: true,
//                     zoomControlsEnabled: true,
//                     compassEnabled: true,
//                     markers: {
//                       if (_currentLocation != null)
//                         Marker(
//                           markerId: const MarkerId("currentLocation"),
//                           position: _currentLocation!,
//                           infoWindow: const InfoWindow(title: "Selected Location"),
//                         ),
//                     },
//                     onTap: _onMapTap,
//                   ),
//
//                   if (_currentLocation == null)
//                     const Center(
//                       child: CircularProgressIndicator(color: Colors.lightBlue),
//                     ),
//                 ],
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 children: [
//                   Text("Address: $_address",
//                       style: TextStyle(fontSize: 16, color: Colors.lightBlue)),
//                   SizedBox(height: 10),
//                   Text(
//                     _isRemoteActive ? "Location Status: Remote Location" : "Location Status: Office Location",
//                     style: TextStyle(fontSize: 16, color: _isRemoteActive ? Colors.green : Colors.orange),
//                   ),
//                   SizedBox(height: 20),
//
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceAround,
//                     children: [
//                       Expanded(
//                         child: ElevatedButton(
//                           onPressed: _showRemoteLocationDialog,
//                           style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue),
//                           child: const Text(
//                             "Set Remote Location",
//                             style: TextStyle(color: Colors.white),
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                     ],
//                   )
//
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//








// import 'dart:async';
// import 'package:attendance_system_ios/bloc/main_bloc.dart';
// import 'package:attendance_system_ios/bloc/main_event.dart';
// import 'package:attendance_system_ios/bloc/main_state.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// // import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
//
// import '../../model/RemoteLocation/RemoteLocation.dart';
//
// class RemoteLocation extends StatefulWidget {
//   const RemoteLocation({super.key});
//
//   @override
//   State<RemoteLocation> createState() => _RemoteLocationState();
// }
//
// class _RemoteLocationState extends State<RemoteLocation> {
//   Completer<GoogleMapController> _controller = Completer();
//   LatLng? _currentLocation;
//   LatLng officeLocation = LatLng(18.5842, 73.7354); // Replace with actual office latitude and longitude
//   String _address = "Fetching address...";
//   bool _locationFetched = false;
//   bool _isRemoteLocation = true; // Tracks if remote location is selected
//   bool _isRemoteActive = false;
//   bool _isLoading = false;
//   String? approveflag = "";
//   String? approveflag1 = "";
//   LocationSettings? settings;
//   LocationSettings? locationSettings;
//
//   final storage = FlutterSecureStorage();
//   String? staffcode = "";
//   String? auth_token="";
//   late MainBloc mainBloc;// Tracks if remote location is active
//
//   @override
//   void initState() {
//     super.initState();
//     mainBloc = BlocProvider.of(context);
//     _getCurrentLocation();  // Initial location fetch
//     getdata();  // Fetch saved data (remote status, address, coordinates)
//   }
//
//   void getdata() async {
//     staffcode = await storage.read(key: 'Staff_Code');
//     auth_token = await storage.read(key: 'Auth_Token');
//     mainBloc.add(GetUserInfoEvents(Staffcode: staffcode!, token: auth_token!));
//   }
//
//   static Future<bool> handleLocationPermission() async {
//     bool serviceEnabled;
//     LocationPermission permission;
//
//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       return false;
//     }
//     permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         return false;
//       }
//     }
//     if (permission == LocationPermission.deniedForever) {
//       return false;
//     }
//     return true;
//   }
//
//
//   Future<void> _getCurrentLocation() async {
//     // if (!_isRemoteActive) {
//     //   Position position = await Geolocator.getCurrentPosition(
//     //       desiredAccuracy: LocationAccuracy.best);
//     //   setState(() {
//     //     _currentLocation = LatLng(position.latitude, position.longitude);
//     //     _locationFetched = true;
//     //   });
//    /* if (locationSettings != null) {
//       settings = locationSettings;
//     } else if (defaultTargetPlatform == TargetPlatform.android) {
//       settings = AndroidSettings(
//         accuracy: LocationAccuracy.best,
//         forceLocationManager: false,
//         // timeLimit: 10,
//       );
//     }
//
//     settings ??= LocationSettings(
//       accuracy: LocationAccuracy.best,
//       // timeLimit: 10,
//     );
//
//     Position position = await GeolocatorPlatform.instance
//         .getCurrentPosition(locationSettings: settings);*/
//
//     final hasPermission = await handleLocationPermission();
//     if (!hasPermission) {
//       Navigator.of(context).pop();
//       Fluttertoast.showToast(
//         msg: "Allow location permission from settings to use this feature!",
//         toastLength: Toast.LENGTH_SHORT,
//         gravity: ToastGravity.BOTTOM,
//         fontSize: 14.0,
//       );
//       return;
//     }
//
//     Position position = await Geolocator.getCurrentPosition(
//       // forceAndroidLocationManager: true,
//       desiredAccuracy: LocationAccuracy.bestForNavigation,
//       timeLimit: Duration(seconds: 10),
//     ).catchError((e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Try again"),
//           action: SnackBarAction(label: "retry", onPressed: _getCurrentLocation),
//           duration: Duration(milliseconds: 3000),
//         ),
//       );
//     });
//
//     setState(() {
//           _currentLocation = LatLng(position.latitude, position.longitude);
//           _locationFetched = true;
//           _moveCameraToLocation(_currentLocation!);
//           _getAddressFromLatLng(_currentLocation!);
//         });
//   }
// //the chaanges i want
//
//   Future<void> _moveCameraToLocation(LatLng location) async {
//     final GoogleMapController controller = await _controller.future;
//     controller.animateCamera(CameraUpdate.newLatLngZoom(location, 15));
//   }
//
//   Future<void> _getAddressFromLatLng(LatLng position) async {
//     try {
//       List<Placemark> placemarks = await placemarkFromCoordinates(
//           position.latitude, position.longitude);
//       Placemark place = placemarks[0];
//       setState(() {
//         _address = "${place.street}, ${place.locality}, ${place.country}";
//       });
//     } catch (e) {
//       setState(() {
//         _address = "Address not found";
//       });
//     }
//   }
//
//   // void _saveLocation() {
//   //   print("Save button clicked");
//   //
//   //   if (_currentLocation != null) {
//   //     setState(() {
//   //       // Prepare RemoteLocationResponse data
//   //       final remoteLocationData = RemoteLocationResponse(
//   //           staffCode: staffcode,
//   //           approvedFlag: "P",
//   //           remoteLocation: _address,
//   //           remoteLatitude: _currentLocation!.latitude.toString(),
//   //           remoteLongitude: _currentLocation!.longitude.toString()
//   //       );
//   //
//   //       print(remoteLocationData);
//   //
//   //       // Dispatch an event to trigger the API call
//   //       mainBloc.add(Remotelocation(remotelocation: remoteLocationData, token: auth_token!));
//   //       setState(() {
//   //
//   //       });
//   //       // Update the UI to indicate saving state
//   //       _isLoading = true;
//   //       _isRemoteActive=true;
//   //     });
//   //
//   //     print("latitude: ${_currentLocation!.latitude}, longitude: ${_currentLocation!.longitude}, address: $_address");
//   //   }
//   // }
//   void _saveLocation() {
//     print("Save button clicked");
//
//     if (_currentLocation != null) {
//       setState(() {
//         // Prepare RemoteLocationResponse data
//         final remoteLocationData = RemoteLocationResponse(
//           staffCode: staffcode,
//           approvedFlag: "P",
//           remoteLocation: _address,
//           remoteLatitude: _currentLocation!.latitude.toString(),
//           remoteLongitude: _currentLocation!.longitude.toString(),
//         );
//
//         print(remoteLocationData);
//
//         // Dispatch an event to trigger the API call
//         mainBloc.add(Remotelocation(
//             remotelocation: remoteLocationData, token: auth_token!));
//
//         // Save latitude and longitude in secure storage
//         storage.write(key: 'remoteLatitude',
//             value: _currentLocation!.latitude.toString());
//         storage.write(key: 'remoteLongitude',
//             value: _currentLocation!.longitude.toString());
//
//         // Update the UI to indicate saving state
//         _isLoading = true;
//         _isRemoteActive = true;
//       });
//
//       print("latitude: ${_currentLocation!
//           .latitude}, longitude: ${_currentLocation!
//           .longitude}, address: $_address");
//     }
//   }
//   // }
//   // void _setOfficeLocation(){
//   //   if (_currentLocation != null) {
//   //     setState(() {
//   //       // Prepare RemoteLocationResponse data
//   //       final officeLocationData = RemoteLocationResponse(
//   //         staffCode: staffcode,
//   //         approvedFlag: "PO",
//   //         remoteLocation: _address,
//   //         remoteLatitude: officeLocation.latitude.toString(),
//   //         remoteLongitude: officeLocation.longitude.toString(),
//   //       );
//   //
//   //       print(officeLocationData);
//   //
//   //       // Dispatch an event to trigger the API call
//   //       mainBloc.add(Remotelocation(remotelocation: officeLocationData, token: auth_token!));
//   //
//   //       // Save latitude and longitude in secure storage
//   //       storage.write(key: 'officelatitude', value: officeLocation.latitude.toString());
//   //       storage.write(key: 'officelongitude', value: officeLocation.longitude.toString());
//   //
//   //       // Update the UI to indicate saving state
//   //       _isLoading = true;
//   //       _isRemoteActive = true;
//   //     });
//   //
//   //     print("latitude: ${officeLocation.latitude}, longitude: ${officeLocation.longitude}, address: $_address");
//   //   }
//   // }
//
//   void _setOfficeLocation() {
//     setState(() {
//       _currentLocation = officeLocation;
//       _isRemoteActive = false; // Indicate that remote location is not active
//       _address = "M-Tech Innovations Ltd. Hinjewadi"; // Placeholder while fetching address
//
//       // Move the camera to the office location
//       _moveCameraToLocation(officeLocation);
//
//       // Fetch the address of the office based on hardcoded lat/lng
//       _getAddressFromLatLng(officeLocation).then((_) {
//         setState(() {
//           _address = "Switched to Office Location: $_address"; // Update status message
//         });
//       });
//
//       // Save office latitude and longitude in secure storage
//       storage.write(key: 'remoteLatitude', value: officeLocation.latitude.toString());
//       storage.write(key: 'remoteLongitude', value: officeLocation.longitude.toString());
//
//       // Prepare data for API call
//       final officeLocationData = RemoteLocationResponse(
//         staffCode: staffcode,
//         approvedFlag: "PO",
//         remoteLocation: _address,
//         remoteLatitude: officeLocation.latitude.toString(),
//         remoteLongitude: officeLocation.longitude.toString(),
//       );
//
//       // Dispatch an event to update location status
//       mainBloc.add(Remotelocation(remotelocation: officeLocationData, token: auth_token!));
//     });
//
//     print("Office location set: Latitude: ${officeLocation.latitude}, Longitude: ${officeLocation.longitude}, Address: $_address");
//   }
//
//   void _toggleLocation() {
//     setState(() {
//       _isRemoteLocation = !_isRemoteLocation;
//       if (_isRemoteLocation) {
//         _getCurrentLocation();
//       } else {
//         _currentLocation = officeLocation;
//         _moveCameraToLocation(_currentLocation!);
//         _getAddressFromLatLng(_currentLocation!);
//       }
//     });
//   }
//
//   void _onMapTap(LatLng tappedLocation) {
//     if (_isRemoteLocation) {
//       setState(() {
//         _currentLocation = tappedLocation;
//         _getAddressFromLatLng(tappedLocation);
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return BlocListener<MainBloc, MainState>(
//       listener: (context, state) async {
//
//       if (state is GetUserinfoLoadingState) {
//         setState(() {
//           _isLoading = true;
//         });
//       }
//       else if (state is GetUserinfoLoadedState) {
//         String? savedStatus = state.profileuserinfo.message!.addressapproveFlag;
//         String? savedAddress = state.profileuserinfo.message!.newRemoteLocation;
//         String? savedLatitude = state.profileuserinfo.message!.remoteLatitude;
//         String? savedLongitude = state.profileuserinfo.message!.remoteLongitude;
//
//         setState(() {
//           setState(() {
//             if (savedStatus == 'Y') {
//               _isRemoteActive = true; // Remote location active
//             } else if (savedStatus == 'O') {
//               _isRemoteActive = false; // Office location active
//             }
//           });
//
//           // Set the status and address
//           _address = savedAddress ?? "Fetching address...";
//
//           if (_isRemoteActive) {
//             // If remote location is active, set the saved latitude and longitude
//             if (savedLatitude != null && savedLongitude != null) {
//               _currentLocation = LatLng(
//                 double.parse(savedLatitude),
//                 double.parse(savedLongitude),
//               );
//               _moveCameraToLocation(_currentLocation!);  // Move camera to the saved location
//             }
//           }
//         });
//         print("Status: $_isRemoteActive, Address: $_address");
//       }
//         else if (state is GetUserinfoErrorState) {
//           setState(() {
//             _isLoading = false;
//           });
//           Fluttertoast.showToast(
//             msg: "  Failed To Fetch Details...!   ",
//             toastLength: Toast.LENGTH_SHORT,
//             timeInSecForIosWeb: 1,
//           );
//         }
//
//         if (state is remotelocationLoadingState) {
//           setState(() {
//             _isLoading = true;
//           });
//         } if (state is remotelocationLoadedState) {
//           setState(() {
//             _isLoading = false;
//             _isRemoteActive = true; // Set status to ON
//           });
//
//           // Save status and address to secure storage
//           await storage.write(key: 'remoteStatus', value: 'ON');
//           await storage.write(key: 'remoteAddress', value: _address);
//
//           // Fluttertoast.showToast(msg: 'location set successfully!');
//         }
//
//         else if (state is remotelocationErrorState) {
//           setState(() {
//             _isLoading = false;
//           });
//           Fluttertoast.showToast(msg: 'Error in requesting remote location');
//         }
//       },
//       child: Scaffold(
//         appBar: AppBar(
//           title: Text(
//             _isRemoteActive
//                 ? "Remote Location: $_address"
//                 : "Select Location",
//             style: TextStyle(fontSize: 16),
//           ),
//           backgroundColor: Colors.lightBlue,
//         ),
//         body: Column(
//           children: [
//             _locationFetched
//                 ? Expanded(
//               child: GoogleMap(
//                 mapType: MapType.normal,
//                 initialCameraPosition: CameraPosition(
//                   target: _currentLocation ?? LatLng(0, 0),
//                   zoom: 15,
//                 ),
//                 onMapCreated: (GoogleMapController controller) {
//                   _controller.complete(controller);
//                 },
//                 myLocationEnabled: true,     // works while tap the gps icon of map
//                 markers: {
//                   if (_currentLocation != null)
//                     Marker(
//                       markerId: MarkerId("currentLocation"),
//                       position: _currentLocation!,
//                       infoWindow: InfoWindow(title: "Selected Location"),
//                     ),
//                 },
//                 onTap: _onMapTap,
//               ),
//             )
//                 : Center(
//                 child: CircularProgressIndicator(color: Colors.lightBlue)),
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 children: [
//                   Text("Address: $_address",
//                       style: TextStyle(fontSize: 16, color: Colors.lightBlue)),
//                   SizedBox(height: 10),
//                   Text(
//                     _isRemoteActive ? "Location Status: Remote Location" : "Location Status: Office Location",
//                     style: TextStyle(fontSize: 16, color: _isRemoteActive ? Colors.green : Colors.orange),
//                   ),
//                   SizedBox(height: 20),
//                   // Row(
//                   //   mainAxisAlignment: MainAxisAlignment.spaceAround,
//                   //   children: [
//                   //     ElevatedButton(
//                   //       onPressed: _saveLocation,
//                   //       style: ElevatedButton.styleFrom(
//                   //           backgroundColor: Colors.lightBlue),
//                   //       child: Text(
//                   //           _isRemoteLocation
//                   //               ? "Save Remote Location"
//                   //             :" ",
//                   //           style: TextStyle(color: Colors.white)),
//                   //     ),
//                   //     ElevatedButton(
//                   //       onPressed: _saveLocation,
//                   //       style: ElevatedButton.styleFrom(
//                   //           backgroundColor: Colors.lightBlue),
//                   //       child: Text(
//                   //           _isRemoteLocation
//                   //               ? "Save Office Location"
//                   //               : " ",
//                   //           style: TextStyle(color: Colors.white)),
//                   //     ),
//                   //   ],
//                   // ),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceAround,
//                     children: [
//                       Expanded(
//                         child: ElevatedButton(
//                           onPressed: _saveLocation,
//                           style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue),
//                           child: const Text(
//                             "Set Remote Location",
//                             style: TextStyle(color: Colors.white),
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: ElevatedButton(
//                           onPressed: _setOfficeLocation,
//                           style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
//                           child: const Text(
//                             "Set Office Location",
//                             style: TextStyle(color: Colors.white),
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                       ),
//                     ],
//                   )
//
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
//
