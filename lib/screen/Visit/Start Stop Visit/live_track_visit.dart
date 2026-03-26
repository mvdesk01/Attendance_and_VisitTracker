import 'dart:async';
import 'dart:convert';

import 'package:attendance_system_ios/model/VisitData/fetch_visit_details_by_srno.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class LiveTrackVisit extends StatefulWidget {
  final String srno;
   const LiveTrackVisit({Key? key, required this.srno}): super(key: key);

  @override
  State<LiveTrackVisit> createState() => _LiveTrackVisitState();
}

class _LiveTrackVisitState extends State<LiveTrackVisit> {
  FlutterSecureStorage storage = FlutterSecureStorage();
  Completer<GoogleMapController> _controller = Completer();
  LatLng? _currentLocation;
  bool isLoading = false;
  String _destinationAddress = '';
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  String? token = '';
  final Set<Circle> _circles = {};

  String? startingLat = '';
  String? startingLong = '';
  String? destinationLat = '';
  String? destinationLong = '';

  @override
  void initState() {
    super.initState();
    initiallize();
  }

  Future<void> initiallize() async {
    token = await storage.read(key: 'Auth_Token');
    await GetVisitInfoBySrNo();
    await getCurrentLocation();
    if (startingLat != null && startingLong != null &&
        destinationLat != null && destinationLong != null) {
      _addMarkersAndRoute();
    }
  }

  @override
  Future<void> _addMarkersAndRoute() async {
    if (_currentLocation != null &&
        startingLat != null &&
        startingLong != null &&
        destinationLat != null &&
        destinationLong != null) {
      // Add starting location marker
      LatLng startingPoint =
      LatLng(double.parse(startingLat!), double.parse(startingLong!));
      _addMarker(
        startingPoint,
        "Starting Point",
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      );

      // Add destination location marker
      LatLng destinationPoint =
      LatLng(double.parse(destinationLat!), double.parse(destinationLong!));
      _addMarker(
        destinationPoint,
        "Destination Point",
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      );

      if (_currentLocation != null) {
        _addMarker(
          _currentLocation!,
          "Current Location",
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        );

        setState(() {
          _circles.add(
            Circle(
              circleId: const CircleId("current_location_circle"),
              center: _currentLocation!,
              radius: 20, // Radius in meters
              fillColor: Colors.blue.withOpacity(0.5),
              strokeColor: Colors.blue,
              strokeWidth: 1,
            ),
          );
        });
        _moveCameraToLocation(_currentLocation!);
      }

      // Fetch destination address
      _destinationAddress = await _getAddress(destinationPoint);

      // Add route between starting and destination points
      await _getDirections(startingPoint, destinationPoint);

      // Move the camera to include all markers
      // _moveCameraToLocation(_currentLocation!);
    } else {
      print("Starting or destination location is not available");
    }
  }

  Future<void> _moveCameraToBounds(LatLng startingPoint, LatLng destinationPoint) async {
    final GoogleMapController controller = await _controller.future;
    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(
        startingPoint.latitude < destinationPoint.latitude ? startingPoint.latitude : destinationPoint.latitude,
        startingPoint.longitude < destinationPoint.longitude ? startingPoint.longitude : destinationPoint.longitude,
      ),
      northeast: LatLng(
        startingPoint.latitude > destinationPoint.latitude ? startingPoint.latitude : destinationPoint.latitude,
        startingPoint.longitude > destinationPoint.longitude ? startingPoint.longitude : destinationPoint.longitude,
      ),
    );

    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  Future<void> getCurrentLocation() async {
    final hasPermission = await handleLocationPermission();
    if (!hasPermission) {
      Navigator.of(context).pop();
      Fluttertoast.showToast(
        msg: "Allow location permission from settings to use this feature!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 3,
        fontSize: 14.0,
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
        forceAndroidLocationManager: true,
        desiredAccuracy: LocationAccuracy.best,
      );
      _currentLocation = LatLng(position.latitude, position.longitude);

      // Add current location marker with a custom circular marker
      _addMarker(
        _currentLocation!,
        "Current Location",
        await BitmapDescriptor.fromAssetImage(
          ImageConfiguration(size: Size(24, 24)),
          'assets/circle_marker.png', // Ensure this asset exists in your app
        ),
      );

      _moveCameraToLocation(_currentLocation!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Try again"),
          action: SnackBarAction(label: "Retry", onPressed: getCurrentLocation),
          duration: const Duration(milliseconds: 3000),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<bool> handleLocationPermission() async {
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

  Future<void> GetVisitInfoBySrNo()async {
    if (widget.srno == null || widget.srno!.isEmpty) {
      print("Error: widget.srno is null or empty");
      return;
    }
    try{
      final response = await http.get(
        Uri.parse("http://114.143.140.28:8020/api/Visit/GetVisitInfoBySrNo?SrNo=${widget.srno}"),
        headers: <String, String>{
          'accept': '*/*', // Matches the cURL command
          'Authorization': 'Bearer $token', // Ensure token is valid
        },
      );

      if(response.statusCode == 200){
        FetchVisitDetailsBySrNo visitDetails = FetchVisitDetailsBySrNo.fromJson(json.decode(response.body));
        print('GetVisitInfoBySrNo Record fetched Successfully');
          startingLat = visitDetails.startingLat;
          startingLong = visitDetails.startingLong;
          destinationLat = visitDetails.stopLat;
          destinationLong = visitDetails.stopLon;
      }else {
        print('Failed to GetVisitInfoBySrNo');
      }
    } catch(e){
      print('Error while calling GetVisitInfoBySrNo API: $e');
    }
  }

  // Get address from coordinates
  Future<String> _getAddress(LatLng location) async {
      List<Placemark> placemarks =
      await placemarkFromCoordinates(location.latitude, location.longitude);
      Placemark place = placemarks.first;
      _destinationAddress = "${place.street}, ${place.locality}, ${place.country}";
      return _destinationAddress;
  }

  // Add marker on the map
  void _addMarker(LatLng position, String title, BitmapDescriptor icon) {
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId(title),
          position: position,
          infoWindow: InfoWindow(title: title),
          icon: icon,
        ),
      );
    });
  }

  // Move camera to new location
  Future<void> _moveCameraToLocation(LatLng location) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(location, 14.0));
  }

  // Get directions from Google Directions API and draw the polyline
  Future<void> _getDirections(LatLng origin, LatLng destination) async {
    String apiKey = "AIzaSyBC90u7o29p3ewzEWoTzXNlt1EQuYOZGV8";
    String url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$apiKey";

    var response = await http.get(Uri.parse(url));
    var json = jsonDecode(response.body);

    if (json['routes'].isNotEmpty) {
      var points = json['routes'][0]['overview_polyline']['points'];
      var decodedPoints = _decodePolyline(points);

      setState(() {
        _polylines.clear(); // Clear previous polylines
        _polylines.add(
          Polyline(
            polylineId: PolylineId('route'),
            color: Colors.blue,
            width: 5,
            points: decodedPoints,
          ),
        );
      });
    }
  }
  // Decode polyline from Google Directions API
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return polyline;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Visit Location'),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentLocation ?? const LatLng(0.0, 0.0), // Default location
                    zoom: 14.0,
                  ),
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                  },
                  markers: _markers,
                  polylines: _polylines,
                  circles: _circles,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Destination Address: $_destinationAddress",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
