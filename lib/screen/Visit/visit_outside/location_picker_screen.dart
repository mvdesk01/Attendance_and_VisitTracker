import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../../../util/MyColor.dart';

class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final String? initialAddress;

  const LocationPickerScreen({super.key, this.initialLocation, this.initialAddress});

  @override
  _LocationPickerScreenState createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  LatLng? _pickedLocation;
  LatLng? _currentLocation;
  String _pickedAddress = "Tap on map to select destination";
  String _currentAddress = '';
  final TextEditingController searchController = TextEditingController();
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _pickedLocation = widget.initialLocation;
    if (widget.initialAddress != null && widget.initialAddress != 'Select Location') {
      _pickedAddress = widget.initialAddress!;
      searchController.text = _pickedAddress;
    }
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    await _getCurrentLocation();
    if (_pickedLocation == null && widget.initialAddress != null && widget.initialAddress != 'Select Location') {
      await _geocodeInitialAddress();
    }
  }

  Future<void> _geocodeInitialAddress() async {
    try {
      List<Location> locations = await locationFromAddress(widget.initialAddress!);
      if (locations.isNotEmpty) {
        LatLng loc = LatLng(locations.first.latitude, locations.first.longitude);
        setState(() {
          _pickedLocation = loc;
          _addMarker(loc, "Destination", BitmapDescriptor.defaultMarker);
        });
        _moveCameraToLocation(loc);
        if (_currentLocation != null) _getDirections(_currentLocation!, loc);
      }
    } catch (e) {
      debugPrint("Geocoding initial address failed: $e");
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Fluttertoast.showToast(msg: "Please enable location services");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    setState(() => isLoading = true);
    try {
      Position position = await Geolocator.getCurrentPosition();
      _currentLocation = LatLng(position.latitude, position.longitude);

      _addMarker(_currentLocation!, "Current Location", BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue));

      if (_pickedLocation != null) {
        _addMarker(_pickedLocation!, "Destination", BitmapDescriptor.defaultMarker);
        _moveCameraToLocation(_pickedLocation!);
        _getDirections(_currentLocation!, _pickedLocation!);
      } else {
        _moveCameraToLocation(_currentLocation!);
      }

      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        _currentAddress = "${place.street ?? ""}, ${place.locality ?? ""}, ${place.country ?? ""}";
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _pickedLocation ?? _currentLocation ?? const LatLng(18.5204, 73.8567),
              zoom: 15.0,
            ),
            onMapCreated: (GoogleMapController controller) => _controller.complete(controller),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onTap: (LatLng location) {
              setState(() => _pickedLocation = location);
              _getAddress(location);
              _addMarker(location, "Destination", BitmapDescriptor.defaultMarker);
              if (_currentLocation != null) _getDirections(_currentLocation!, location);
            },
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 15,
            right: 15,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search for destination...',
                  prefixIcon: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search, color: MyColors.appDefaultColorCode),
                    onPressed: () => _searchLocation(searchController.text),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onSubmitted: _searchLocation,
              ),
            ),
          ),

          if (_pickedLocation != null)
            Positioned(
              bottom: 20,
              left: 15,
              right: 15,
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Destination Address", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(_pickedAddress, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MyColors.appDefaultColorCode,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop({
                              'pickedLocation': _pickedLocation,
                              'pickedAddress': _pickedAddress,
                              'currentLocation': _currentLocation,
                              'currentAddress': _currentAddress,
                            });
                          },
                          child: const Text("Confirm Destination", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          Positioned(
            bottom: _pickedLocation != null ? 180 : 20,
            right: 15,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: _getCurrentLocation,
              child: const Icon(Icons.my_location, color: MyColors.appDefaultColorCode),
            ),
          ),

          if (isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator(color: MyColors.appDefaultColorCode)),
            ),
        ],
      ),
    );
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;
    setState(() => isLoading = true);
    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        LatLng loc = LatLng(locations.first.latitude, locations.first.longitude);
        setState(() {
          _pickedLocation = loc;
          _pickedAddress = query;
        });
        _addMarker(loc, "Destination", BitmapDescriptor.defaultMarker);
        _moveCameraToLocation(loc);
        if (_currentLocation != null) _getDirections(_currentLocation!, loc);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Location not found");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _addMarker(LatLng position, String title, BitmapDescriptor icon) {
    setState(() {
      _markers.removeWhere((m) => m.markerId.value == title);
      _markers.add(Marker(markerId: MarkerId(title), position: position, icon: icon));
    });
  }

  Future<void> _getAddress(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(location.latitude, location.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          _pickedAddress = "${place.street ?? ""}, ${place.locality ?? ""}, ${place.administrativeArea ?? ""}";
          searchController.text = _pickedAddress;
        });
      }
    } catch (e) {
      setState(() => _pickedAddress = "Address not found");
    }
  }

  Future<void> _moveCameraToLocation(LatLng location) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(location, 15.0));
  }

  Future<void> _getDirections(LatLng origin, LatLng destination) async {
    setState(() {
      _polylines.clear();
      _polylines.add(Polyline(
        polylineId: const PolylineId('route'),
        color: MyColors.appDefaultColorCode,
        width: 4,
        points: [origin, destination],
      ));
    });
  }
}
