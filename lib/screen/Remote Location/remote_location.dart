import 'dart:async';
import 'package:attendance_system_ios/bloc/main_bloc.dart';
import 'package:attendance_system_ios/bloc/main_event.dart';
import 'package:attendance_system_ios/bloc/main_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../model/RemoteLocation/RemoteLocation.dart';
import '../../service/WebService.dart';
import '../../util/MyColor.dart';
import '../Home/home.dart';

class RemoteLocation extends StatefulWidget {
  const RemoteLocation({super.key});

  @override
  State<RemoteLocation> createState() => _RemoteLocationState();
}

class _RemoteLocationState extends State<RemoteLocation> {
  final Completer<GoogleMapController> _mapController = Completer();
  LatLng? _currentLocation;
  String _address = "Fetching address...";
  String _primaryAddress = '';
  bool _isRemoteActive = false;
  bool _isLoading = false;
  bool _mapLoading = false;

  double? _primaryLat;
  double? _primaryLng;
  Timer? _debounce;

  final storage = const FlutterSecureStorage();
  String? staffcode = "";
  String? auth_token = "";
  late MainBloc mainBloc;
  List<Map<String, dynamic>> multiRemoteLocationList = [];

  @override
  void initState() {
    super.initState();
    mainBloc = BlocProvider.of(context);
    _initData();
  }

  void _initData() async {
    staffcode = await storage.read(key: 'Staff_Code');
    auth_token = await storage.read(key: 'Auth_Token');
    Future.wait([
      _getCurrentLocation(),
      _reloadPage(),
    ]);
  }

  static Future<bool> handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    return permission != LocationPermission.deniedForever;
  }

  Future<void> _getCurrentLocation() async {
    final hasPermission = await handleLocationPermission();
    if (!hasPermission) {
      Fluttertoast.showToast(msg: "Location permission required");
      return;
    }
    setState(() => _mapLoading = true);

    try {
      Position position = await Geolocator.getCurrentPosition();
      LatLng newLocation = LatLng(position.latitude, position.longitude);

      // setState(() {
      _currentLocation = newLocation;
      _mapLoading = false;
      // });
      setState(() {});
      _moveCameraToLocation(newLocation);
      _getAddressFromLatLng(newLocation);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Failed to get location"),
          action: SnackBarAction(label: "Retry", onPressed: _getCurrentLocation),
        ),
      );
    }
  }

  Future<void> _moveCameraToLocation(LatLng location) async {
    if (!_mapController.isCompleted) return;
    final controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: location, zoom: 16)));
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude).timeout(const Duration(seconds: 5));
      if (placemarks.isNotEmpty) {
        Placemark p = placemarks.first;
        setState(() {
          _address = "${p.name}, ${p.subLocality}, ${p.locality}, ${p.administrativeArea}";
        });
      }
    } catch (e) {
      setState(() => _address = "Location Selected");
    }
  }

  void _onMapTap(LatLng tappedLocation) {
    setState(() {
      _currentLocation = tappedLocation;
    });

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      _getAddressFromLatLng(tappedLocation);
    });
  }

  void _savePrimaryLocation() {
    if (_currentLocation != null) {
      final data = RemoteLocationResponse(
        staffCode: staffcode,
        approvedFlag: "P",
        remoteLocation: _address,
        remoteLatitude: _currentLocation!.latitude.toString(),
        remoteLongitude: _currentLocation!.longitude.toString(),
      );
      mainBloc.add(Remotelocation(remotelocation: data, token: auth_token!));
    }
  }

  void _addMultipleLocation() {
    if (_currentLocation != null) {
      mainBloc.add(AddMultipleRemoteLocation(auth_token!, _currentLocation!.latitude.toString(), _currentLocation!.longitude.toString(), staffcode!, "P", _address, "100"));
    }
  }

  void _deleteLocation(int srNo) {
    mainBloc.add(DeleteMultiRemoteLocation(auth_token!, staffcode!, srNo));
  }

  Future<void> _reloadPage() async {
    await Future.wait([
      _getUserInfo(),
      _getMultiRemoteLocation()
    ]
    );
  }

  Future<void> _getUserInfo() async {
    mainBloc.add(GetUserInfoEvents(Staffcode: staffcode!, token: auth_token!));
  }

  Future<void> _getMultiRemoteLocation() async {
    mainBloc.add(GetMultiRemoteLocation(auth_token!, staffcode!));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MainBloc, MainState>(
      listener: (context, state) {
        if (state is GetUserinfoLoadingState || state is remotelocationLoadingState || state is AddMultiRemoteLocationLoadingState || state is GetMultiRemoteLocationLoadingState || state is DeleteMultiRemoteLocationLoadingState) {
          setState(() => _isLoading = true);
        } else {
          setState(() => _isLoading = false);
        }

        if (state is GetUserinfoLoadedState) {
          final user = state.profileuserinfo.message;
          setState(() {
            _isRemoteActive = user?.addressapproveFlag == 'Y';
            _primaryAddress = user?.newRemoteLocation ?? _address;
            if (user?.remoteLatitude != null && user?.remoteLongitude != null) {
              _primaryLat = double.parse(user!.remoteLatitude!);
              _primaryLng = double.parse(user.remoteLongitude!);
              // _currentLocation = LatLng(double.parse(user!.remoteLatitude!), double.parse(user.remoteLongitude!));
              // _moveCameraToLocation(_currentLocation!);
            }
          });
        }

        if (state is remotelocationLoadedState) {
          Fluttertoast.showToast(msg: "Primary location request sent!");
          _reloadPage();
        }

        if (state is AddMultiRemoteLocationLoadedState) {
          _reloadPage();
          Fluttertoast.showToast(msg: "Project location added successfully!");
        }

        if (state is GetMultiRemoteLocationLoadedState) {
          setState(() => multiRemoteLocationList = List<Map<String, dynamic>>.from(state.response));
        }

        if (state is DeleteMultiRemoteLocationLoadedState) {
          Fluttertoast.showToast(msg: "Location removed");
          _reloadPage();
        }

        if (state is GetUserinfoErrorState || state is remotelocationErrorState || state is AddMultiRemoteLocationErrorState || state is GetMultiRemoteLocationErrorState || state is DeleteMultiRemoteLocationErrorState) {
          String msg = "Action failed";
          if (state is AddMultiRemoteLocationErrorState) msg = state.msg;
          if (state is GetMultiRemoteLocationErrorState) msg = state.msg;
          Fluttertoast.showToast(msg: msg);
        }
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: AppBar(
              elevation: 0,
              backgroundColor: MyColors.appDefaultColorCode,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => (Navigator.canPop(context)) ? Navigator.pop(context) : Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => BlocProvider(create: (_) => MainBloc(webService: WebService()), child: const HomeScreen()))),
              ),
              title: Text("Remote Locations", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 18)),
              centerTitle: true,
            ),
            body: Column(
              children: [
                Expanded(
                  flex: 4,
                  child: Stack(
                    children: [
                      _buildMap(),
                      Positioned(
                        top: 20,
                        right: 20,
                        child: FloatingActionButton.small(
                          heroTag: "recenter",
                          backgroundColor: Colors.white,
                          onPressed: _getCurrentLocation,
                          child: const Icon(Icons.my_location, color: MyColors.appDefaultColorCode),
                        ),
                      ),
                      if (_mapLoading) Container(color: Colors.black12, child: const Center(child: CircularProgressIndicator(color: MyColors.appDefaultColorCode))),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            _address,
                            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildSectionHeader("Primary Location", _isRemoteActive ? "APPROVED" : "PENDING", _isRemoteActive ? Colors.green : Colors.orange),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () {
                            if (_primaryLat != null && _primaryLng != null) {
                              LatLng target = LatLng(_primaryLat!, _primaryLng!);

                              setState(() {
                                _currentLocation = target;
                                _address = _primaryAddress;
                              });

                              _moveCameraToLocation(target);
                            }
                          },
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: MyColors.appDefaultColorCode,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _primaryAddress,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _showSetPrimaryLocationDialog,
                                icon: const Icon(Icons.home_work_rounded, size: 26),
                                label: Text("SET PRIMARY LOCATION", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: MyColors.appDefaultColorCode,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _showProjectLocationDialog,
                                icon: const Icon(Icons.add_location_alt_rounded, size: 26),
                                label: Text("ADD PROJECT LOCATIONS", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: MyColors.appDefaultColorCode,
                                  side: const BorderSide(color: MyColors.appDefaultColorCode),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          child: Text("Project Work Locations", style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                        ),
                        Expanded(
                          child: multiRemoteLocationList.isEmpty
                              ? Center(child: Text("No extra locations added", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13)))
                              : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: multiRemoteLocationList.length,
                            itemBuilder: (context, index) {
                              final loc = multiRemoteLocationList[index];
                              return _buildLocationCard(loc);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          if(_isLoading)
            Container(
                color: Colors.black12.withOpacity(0.5),
                child: const Center(
                  child:  CircularProgressIndicator(
                    color: MyColors.appDefaultColorCode,
                  ),
                )
            )
        ],
      ),

    );
  }

  Widget _buildSectionHeader(String title, String status, Color statusColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
          child: Text(status, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor, letterSpacing: 0.5)),
        ),
      ],
    );
  }

  Widget _buildLocationCard(Map<String, dynamic> loc) {
    final String status = (loc['flag'] ?? "").toString().toUpperCase();
    String statusText = "PENDING";
    Color statusColor = Colors.orange;

    if (status == "Y") {
      statusText = "APPROVED";
      statusColor = Colors.green;
    } else if (status == "N") {
      statusText = "INACTIVE";
      statusColor = Colors.red;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade100)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: MyColors.appDefaultColorCode.withOpacity(0.05), shape: BoxShape.circle),
          child: const Icon(Icons.location_on_rounded, color: MyColors.appDefaultColorCode, size: 20),
        ),
        title: Text(loc['locationName'] ?? "Unnamed Location", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Row(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
              child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
          onPressed: () => _deleteLocation(loc['srNo']),
        ),
        onTap: () {
          final lat = double.parse(loc['latitude']);
          final lng = double.parse(loc['longitude']);
          LatLng target = LatLng(lat, lng);
          setState(() {
            _currentLocation = target;
            _address = loc['locationName'] ?? _address;
          });
          _moveCameraToLocation(target);
        },
      ),
    );
  }

  Widget _buildMap(){
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: _currentLocation ?? const LatLng(18.5834, 73.7358), zoom: 15),
      onMapCreated: (c) => _mapController.complete(c),
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      markers: {
        if (_currentLocation != null) Marker(markerId: const MarkerId("current"), position: _currentLocation!),
      },
      onTap: _onMapTap,
    );
  }

  void _showProjectLocationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                /// Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: MyColors.appDefaultColorCode.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_location_alt_rounded,
                    color: MyColors.appDefaultColorCode,
                    size: 32,
                  ),
                ),

                const SizedBox(height: 16),

                /// Title
                Text(
                  "Add Project Location",
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 10),

                /// Description
                Text(
                  "Request this location point for marking attendance.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),

                const SizedBox(height: 16),

                /// Address box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: MyColors.appDefaultColorCode,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _address,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                /// Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: MyColors.appDefaultColorCode,
                          side: const BorderSide(
                              color: MyColors.appDefaultColorCode),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding:
                          const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          "Cancel",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _addMultipleLocation();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MyColors.appDefaultColorCode,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding:
                          const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          "Request",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSetPrimaryLocationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                /// Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: MyColors.appDefaultColorCode.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.home_work_rounded,
                    color: MyColors.appDefaultColorCode,
                    size: 32,
                  ),
                ),

                const SizedBox(height: 16),

                /// Title
                Text(
                  "Set Primary Location",
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 10),

                /// Description
                Text(
                  "Set this location as your primary office location.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),

                const SizedBox(height: 16),

                /// Address container
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: MyColors.appDefaultColorCode,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _address,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                /// Buttons
                Row(
                  children: [

                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: MyColors.appDefaultColorCode,
                          side: const BorderSide(
                              color: MyColors.appDefaultColorCode),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          "Cancel",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _savePrimaryLocation();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MyColors.appDefaultColorCode,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          "Set Location",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
