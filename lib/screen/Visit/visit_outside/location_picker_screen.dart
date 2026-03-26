import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../util/MyColor.dart';

class LocationPickerScreen extends StatefulWidget {
  @override
  _LocationPickerScreenState createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  Completer<GoogleMapController> _controller = Completer();
  LatLng? _pickedLocation;
  LatLng? _currentLocation;
  String _pickedAddress = "No location selected";
  String _currentAddress = '';
  TextEditingController searchController = TextEditingController();
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  bool isLoading = false;
  String lastSearch="";

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadLastSearch();
  }

  Future<void> _loadLastSearch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      lastSearch = prefs.getString('lastSearch') ?? ""; // Load saved search
      //
      // searchController.text = lastSearch; // Set text field with last search
    });
  }

  /// Save last searched location in SharedPreferences
  Future<void> _saveLastSearch(String query) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastSearch', query);
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
      Navigator.of(context).pop();
      Fluttertoast.showToast(
        msg: "Allow location permission from settings to use this feature!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        fontSize: 14.0,
      );
      return;
    }
    setState(() {
      isLoading = true;
    });
    Position position = await Geolocator.getCurrentPosition(
      // forceAndroidLocationManager: true,
      // desiredAccuracy: LocationAccuracy.medium,
      // timeLimit: Duration(seconds: 10),
    ).catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Try again"),
          action: SnackBarAction(label: "retry", onPressed: _getCurrentLocation),
          duration: Duration(milliseconds: 3000),
        ),
      );
    });
    setState(() {
      isLoading = false;
      _currentLocation = LatLng(position.latitude, position.longitude);
      _addMarker(_currentLocation!, "Current Location", BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue));
      _moveCameraToLocation(_currentLocation!);
    });
    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark place = placemarks.first;
    _currentAddress = "${place.street}, ${place.locality}, ${place.country}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pick a Destination'),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: () {
              if (_pickedLocation != null && _currentLocation != null) {
                Navigator.of(context).pop({
                  'pickedLocation': _pickedLocation,
                  'pickedAddress': _pickedAddress,
                  'currentLocation': _currentLocation,
                  'currentAddress': _currentAddress,
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please select a location')),
                );
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search Location',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(10),
                  ),
                  onTap: () {
                    print(lastSearch);
                    // When the user taps the field, show the last searched location
                    searchController.text = lastSearch;
                  },
                  onSubmitted: (value) {
                    _searchLocation(value);
                  },
                ),
              ),
              Expanded(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentLocation ?? LatLng(18.5834, 73.7358), // Default to your desired location
                    zoom: 14.0,
                  ),
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                  },
                  markers: _markers,
                  polylines: _polylines,
                  onTap: (LatLng location) {
                    setState(() {
                      _pickedLocation = location;
                    });
                    _getAddress(location);
                    _addMarker(location, "Picked Location", BitmapDescriptor.defaultMarker);
                    if (_currentLocation != null && _pickedLocation != null) {
                      _getDirections(_currentLocation!, _pickedLocation!);
                    }
                  },
                  zoomGesturesEnabled: true,   // Enable zooming
                  scrollGesturesEnabled: true, // Allow scrolling
                  rotateGesturesEnabled: true, // Allow rotating the map
                  tiltGesturesEnabled: true,   // Allow tilting the map
                  myLocationEnabled: true,     // Show user location
                  myLocationButtonEnabled: true,
                  gestureRecognizers: Set()
                    ..add(Factory<OneSequenceGestureRecognizer>(
                            () => ScaleGestureRecognizer())),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text("Selected Address: $_pickedAddress"),
              ),
            ],
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5), // Semi-transparent background
              child: const Center(
                child: CircularProgressIndicator(
                  color: MyColors.lightBlue,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _searchLocation(String query) async {
    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        LatLng location = LatLng(locations.first.latitude, locations.first.longitude);
        setState(() {
          _pickedLocation = location;
            lastSearch = query;
        });
        _getAddress(location);
        _addMarker(location, "Searched Location", BitmapDescriptor.defaultMarker);
        _moveCameraToLocation(location);

        if (_currentLocation != null) {
          _getDirections(_currentLocation!, location);
        }
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Location not found",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        fontSize: 14.0,
      );
    }
  }

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

  Future<void> _getAddress(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(location.latitude, location.longitude);
      Placemark place = placemarks.first;
      setState(() {
        _pickedAddress = "${place.street}, ${place.locality}, ${place.country}";
      });
    } catch (e) {
      setState(() {
        _pickedAddress = "Unable to fetch address";
      });
    }
  }

  Future<void> _moveCameraToLocation(LatLng location) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(location, 14.0));
  }

  Future<void> _getDirections(LatLng origin, LatLng destination) async {
    String apiKey = "YOUR_GOOGLE_MAPS_API_KEY";
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
}


/*
  import 'dart:async';
  import 'dart:convert';
  import 'package:flutter/material.dart';
  import 'package:fluttertoast/fluttertoast.dart';
  import 'package:geocoding/geocoding.dart';
  import 'package:google_maps_flutter/google_maps_flutter.dart';
  import 'package:geolocator/geolocator.dart';
  import 'package:google_places_flutter/google_places_flutter.dart';
  import 'package:google_places_flutter/model/prediction.dart';
  import 'package:http/http.dart' as http;
  
  import '../../../util/MyColor.dart';
  
  class LocationPickerScreen extends StatefulWidget {
    @override
    _LocationPickerScreenState createState() => _LocationPickerScreenState();
  }
  
  class _LocationPickerScreenState extends State<LocationPickerScreen> {
    Completer<GoogleMapController> _controller = Completer();
    LatLng? _pickedLocation;
    LatLng? _currentLocation;
    String _pickedaddress = "No location selected";
    String _currentAddress= '';
    TextEditingController searchController = TextEditingController();
    Set<Polyline> _polylines = {};
    Set<Marker> _markers = {};
    bool isLoading = false;
  
    @override
    void initState() {
      super.initState();
      _getCurrentLocation(); // Fetch current location
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
  
    // Get the current location of the user
    Future<void> _getCurrentLocation() async {
      final hasPermission = await handleLocationPermission();
      if (!hasPermission){
        Navigator.of(context).pop();
        Fluttertoast.showToast(
            msg: "Allow location permission from settings to use this feature!!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 3,
            // textColor: Colors.white,
            fontSize: 14.0
        );
      }
      setState(() {
        isLoading = true;
      });
      Position position = await Geolocator.getCurrentPosition(
        forceAndroidLocationManager: true,
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 10)
      ).catchError((e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Try again"),
          action: SnackBarAction(label: "retry", onPressed: _getCurrentLocation),
            duration: Duration(milliseconds: 3000),
          )
        );
      });
      setState(() {
        isLoading = false;
        _currentLocation = LatLng(position.latitude, position.longitude);
        _addMarker(_currentLocation!, "Current Location", BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue));
        _moveCameraToLocation(_currentLocation!);
      });
        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        Placemark place = placemarks.first;
        _currentAddress = "${place.street}, ${place.locality}, ${place.country}";
    }
  
    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Pick a destination'),
          actions: [
            IconButton(
              icon: Icon(Icons.check),
              onPressed: () {
                if (_pickedLocation != null && _currentLocation != null) {
                  // Return both current and picked location, along with the picked address
                  Navigator.of(context).pop({
                    'pickedLocation': _pickedLocation,
                    'pickedAddress': _pickedaddress,
                    'currentLocation': _currentLocation,
                    'currentAddress': _currentAddress
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please select a location')),
                  );
                }
              },
            ),
          ],
        ),
        body: Stack(children: [
          Column(
            children: [
              // Search Bar with Autocomplete
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: GooglePlaceAutoCompleteTextField(
                  textEditingController: searchController,
                  googleAPIKey: "AIzaSyBC90u7o29p3ewzEWoTzXNlt1EQuYOZGV8",
                  inputDecoration: InputDecoration(
                    hintText: 'Search Location',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(10),
                  ),
                  debounceTime: 800, // Controls debounce time for suggestions
                  countries: ["in"], // Limit search to certain countries
                  isLatLngRequired: true,
                  getPlaceDetailWithLatLng: (Prediction prediction) async {
                    _onSearchSuggestionTap(prediction);
                  },
                  itemClick: (Prediction prediction) async {
                    searchController.text = prediction.description!;
                    _onSearchSuggestionTap(prediction);
                  },
                ),
              ),
              Expanded(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentLocation ?? LatLng(18.5834, 73.7358), // Default to your desired location
                    zoom: 14.0,
                  ),
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                  },
                  markers: _markers,
                  polylines: _polylines,
                  onTap: (LatLng location) {
                    setState(() {
                      _pickedLocation = location;
                    });
                    _getAddress(location);
                    _addMarker(location, "Picked Location", BitmapDescriptor.defaultMarker);
                    if (_currentLocation != null && _pickedLocation != null) {
                      _getDirections(_currentLocation!, _pickedLocation!);
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text("Selected Address: $_pickedaddress"),
              ),
            ],
          ),
          if(isLoading)
            Container(
              color: Colors.black.withOpacity(0.5), // Semi-transparent background
              child: const Center(
                child: CircularProgressIndicator(
                  color: MyColors.lightBlue,
                ),
              ),),
        ],),
  
      );
    }
  
    // Handle search suggestion click
    Future<void> _onSearchSuggestionTap(Prediction prediction) async {
      if (prediction.lat != null && prediction.lng != null) {
        LatLng location = LatLng(double.parse(prediction.lat!), double.parse(prediction.lng!));
        setState(() {
          _pickedLocation = location;
        });
        _getAddress(location);
        _addMarker(location, "Picked Location", BitmapDescriptor.defaultMarker);
  
        // Move camera to the picked location
        _moveCameraToLocation(location);
  
        // Draw the route from current location to picked location
        if (_currentLocation != null && _pickedLocation != null) {
          _getDirections(_currentLocation!, _pickedLocation!);
        }
      }
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
  
    // Get address from coordinates
    Future<void> _getAddress(LatLng location) async {
      try {
        List<Placemark> placemarks =
        await placemarkFromCoordinates(location.latitude, location.longitude);
        Placemark place = placemarks.first;
        setState(() {
          _pickedaddress = "${place.street}, ${place.locality}, ${place.country}";
        });
      } catch (e) {
        setState(() {
          _pickedaddress = "Unable to fetch address";
        });
      }
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
  }*/
