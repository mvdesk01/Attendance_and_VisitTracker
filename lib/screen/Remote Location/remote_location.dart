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
import 'package:shimmer/shimmer.dart';

import '../../model/RemoteLocation/RemoteLocation.dart';
import '../../service/WebService.dart';
import '../../util/MyColor.dart';
import '../Home/home.dart';

class RemoteLocation extends StatefulWidget {
  const RemoteLocation({super.key});

  @override
  State<RemoteLocation> createState() => _RemoteLocationState();
}

class _RemoteLocationState extends State<RemoteLocation> with SingleTickerProviderStateMixin {
  final Completer<GoogleMapController> _mapController = Completer();
  LatLng? _currentLocation;

  // High-performance state management using ValueNotifiers
  // This prevents the heavy GoogleMap widget from rebuilding when address changes
  final ValueNotifier<String> _addressNotifier = ValueNotifier<String>("Fetching location details...");
  final ValueNotifier<bool> _isAddressLoading = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isMapReady = ValueNotifier<bool>(false);

  String _primaryAddress = 'No primary location set';
  bool _isRemoteActive = false;
  bool _isLoading = false;
  bool _mapLoading = false;

  double? _primaryLat;
  double? _primaryLng;
  Timer? _debounce;
  bool _isProjectLoading = true;

  final storage = const FlutterSecureStorage();
  String? staffcode = "";
  String? auth_token = "";
  late MainBloc mainBloc;
  List<Map<String, dynamic>> multiRemoteLocationList = [];

  // Animations for a premium "smother" feel
  late AnimationController _panelController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    mainBloc = context.read<MainBloc>();

    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _panelController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _panelController,
      curve: const Interval(0.2, 1.0, curve: Curves.bounceOut),
    ));

    _initData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _panelController.dispose();
    _addressNotifier.dispose();
    _isAddressLoading.dispose();
    _isMapReady.dispose();
    super.dispose();
  }

  void _initData() async {
    staffcode = await storage.read(key: 'Staff_Code');
    auth_token = await storage.read(key: 'Auth_Token');

    // Performance: Fast-track the UI
    _panelController.forward();

    // Optimized: Parallelize non-dependent async tasks
    unawaited(_getCurrentLocation());
    unawaited(_reloadPage());
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
      Fluttertoast.showToast(msg: "Location access denied");
      return;
    }

    setState(() => _mapLoading = true);

    try {
      // Smoother: Try last known position first for immediate UI snap
      Position? lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null && mounted) {
        _currentLocation = LatLng(lastKnown.latitude, lastKnown.longitude);
        _moveCameraToLocation(_currentLocation!);
      }

      // Then get precise position
      Position precise = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium, // Medium is often faster & sufficient for initial view
      );
      LatLng newLocation = LatLng(precise.latitude, precise.longitude);

      if (mounted) {
        setState(() {
          _currentLocation = newLocation;
          _mapLoading = false;
        });
        _moveCameraToLocation(newLocation);
        _getAddressFromLatLng(newLocation);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _mapLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("GPS Signal weak. Please retry."),
            action: SnackBarAction(label: "Retry", onPressed: _getCurrentLocation),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _moveCameraToLocation(LatLng location) async {
    if (!_mapController.isCompleted) return;
    final controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: location, zoom: 16),
    ));
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    _isAddressLoading.value = true;
    try {
      // Timeout ensures we don't hang if network is slow
      List<Placemark> marks = await placemarkFromCoordinates(
        position.latitude, position.longitude
      ).timeout(const Duration(seconds: 5));

      if (marks.isNotEmpty && mounted) {
        Placemark p = marks.first;
        _addressNotifier.value = "${p.name}, ${p.subLocality}, ${p.locality}, ${p.administrativeArea}";
      }
    } catch (e) {
      if (mounted) _addressNotifier.value = "Selected Map Coordinate";
    } finally {
      _isAddressLoading.value = false;
    }
  }

  void _onMapTap(LatLng tapped) {
    setState(() => _currentLocation = tapped);

    // Smother: Use debounce to prevent address flickering during quick multiple taps
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _getAddressFromLatLng(tapped);
    });
  }

  void _savePrimaryLocation() {
    if (_currentLocation != null) {
      final data = RemoteLocationResponse(
        staffCode: staffcode,
        approvedFlag: "P",
        remoteLocation: _addressNotifier.value,
        remoteLatitude: _currentLocation!.latitude.toString(),
        remoteLongitude: _currentLocation!.longitude.toString(),
      );
      mainBloc.add(Remotelocation(remotelocation: data, token: auth_token!));
    }
  }

  void _addProjectLocation() {
    if (_currentLocation != null) {
      mainBloc.add(AddMultipleRemoteLocation(
        auth_token!,
        _currentLocation!.latitude.toString(),
        _currentLocation!.longitude.toString(),
        staffcode!,
        "P",
        _addressNotifier.value,
        "100"
      ));
    }
  }

  void _deleteLocation(int srNo) {
    mainBloc.add(DeleteMultiRemoteLocation(auth_token!, staffcode!, srNo));
  }

  Future<void> _reloadPage() async {
    mainBloc.add(GetUserInfoEvents(Staffcode: staffcode!, token: auth_token!));
    mainBloc.add(GetMultiRemoteLocation(auth_token!, staffcode!));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MainBloc, MainState>(
      listener: (context, state) {
        if (state is GetUserinfoLoadingState ||
            state is remotelocationLoadingState ||
            state is AddMultiRemoteLocationLoadingState ||
            state is DeleteMultiRemoteLocationLoadingState) {
          setState(() => _isLoading = true);
        } else {
          setState(() => _isLoading = false);
        }

        if (state is GetUserinfoLoadedState) {
          final user = state.profileuserinfo.message;
          setState(() {
            _isRemoteActive = user?.addressapproveFlag == 'Y';
            _primaryAddress = user?.newRemoteLocation ?? 'Not Set';
            if (user?.remoteLatitude != null && user?.remoteLongitude != null) {
              _primaryLat = double.parse(user!.remoteLatitude!);
              _primaryLng = double.parse(user.remoteLongitude!);
            }
          });
        }

        if (state is remotelocationLoadedState) {
          Fluttertoast.showToast(msg: "Approval request sent!");
          _reloadPage();
        }

        if (state is AddMultiRemoteLocationLoadedState) {
          _reloadPage();
          Fluttertoast.showToast(msg: "Location added successfully!");
        }

        if (state is GetMultiRemoteLocationLoadedState) {
          setState(() {
            multiRemoteLocationList =
            List<Map<String, dynamic>>.from(state.response);
            _isProjectLoading = false;
          });
        }

        if (state is DeleteMultiRemoteLocationLoadedState) {
          Fluttertoast.showToast(msg: "Location removed");
          _reloadPage();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(flex: 8, child: _buildMapSection()),
                Expanded(flex: 9, child: _buildDetailsSection()),
              ],
            ),

            // Recenter Button with dynamic visibility
            Positioned(
              top: MediaQuery.of(context).padding.top + 70,
              right: 16,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: FloatingActionButton.small(
                  heroTag: "recenter",
                  backgroundColor: Colors.white,
                  elevation: 6,
                  onPressed: _getCurrentLocation,
                  child: const Icon(Icons.my_location, color: MyColors.appDefaultColorCode),
                ),
              ),
            ),

            if (_isLoading) _buildOverlayLoader(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.55), Colors.transparent],
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Text(
        "Remote Locations",
        style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 18)
      ),
      centerTitle: true,
    );
  }

  Widget _buildMapSection() {
    // Performance: Use RepaintBoundary to isolate the Map from UI rebuilds
    return RepaintBoundary(
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentLocation ?? const LatLng(18.5834, 73.7358),
              zoom: 15
            ),
            onMapCreated: (c) {
              _mapController.complete(c);
              _isMapReady.value = true;
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            markers: {
              if (_currentLocation != null)
                Marker(
                  markerId: const MarkerId("current"),
                  position: _currentLocation!,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                ),
            },
            onTap: _onMapTap,
          ),

          ValueListenableBuilder<bool>(
            valueListenable: _isMapReady,
            builder: (context, ready, _) {
              if (!ready || _mapLoading) {
                return Container(
                  color: Colors.grey[100],
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Floating HUD instruction
          Positioned(
            bottom: 40,
            left: 20, right: 20,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(20)),
                child: Text(
                  "Long press or tap map to adjust location",
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500)
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 30, offset: Offset(0, -10))],
        ),
        child: Column(
          children: [
            // Handle for "Sheet" look
            Container(
              margin: const EdgeInsets.symmetric(vertical: 14),
              width: 36, height: 4,
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(2)),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSelectionCard(),
                    const SizedBox(height: 10),
                    _buildStatusDashboard(),
                    const SizedBox(height: 32),
                    _buildProjectSectionHeader(),
                    const SizedBox(height: 12),
                    _buildProjectList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.blueGrey[50]?.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blueGrey[100]!.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.gps_fixed_rounded, color: Colors.redAccent, size: 16),
              const SizedBox(width: 8),
              Text("TARGET LOCATION", style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.blueGrey[300], letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<String>(
            valueListenable: _addressNotifier,
            builder: (context, addr, _) {
              return ValueListenableBuilder<bool>(
                valueListenable: _isAddressLoading,
                builder: (context, loading, _) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: loading
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(
                          addr,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600, height: 1.4),
                          maxLines: 2,
                        ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDashboard() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Primary Work Location", style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 0.5)),
              _buildBadge(_isRemoteActive ? "APPROVED" : "PENDING", _isRemoteActive ? Colors.green : Colors.orange),
            ],
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () {
              if (_primaryLat != null && _primaryLng != null) {
                final target = LatLng(_primaryLat!, _primaryLng!);
                _moveCameraToLocation(target);
                _addressNotifier.value = _primaryAddress;
                setState(() => _currentLocation = target);
              }
            },
            child: Row(
              children: [
                Icon(Icons.home_work_rounded, color: MyColors.appDefaultColorCode.withOpacity(0.4), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(_primaryAddress, style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
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
    );
  }

  Widget _buildProjectSectionHeader() {
    return Row(
      children: [
        Text("Project Work Locations", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(6)),
          child: Text("${multiRemoteLocationList.length}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildProjectList() {
    /// 🔥 SHOW SHIMMER WHILE LOADING
    if (_isProjectLoading) {
      return _buildShimmerList();
    }

    if (multiRemoteLocationList.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(Icons.location_off_outlined,
                color: Colors.grey[300], size: 32),
            const SizedBox(height: 12),
            Text(
              "No additional Location found",
              style: GoogleFonts.poppins(
                  color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: multiRemoteLocationList.length,
      itemBuilder: (context, index) =>
          _buildProjectTile(multiRemoteLocationList[index]),
    );
  }

  Widget _buildProjectTile(Map<String, dynamic> loc) {
    final String flag = (loc['flag'] ?? "").toString().toUpperCase();
    bool isApproved = flag == "Y";
    Color statusColor = isApproved ? Colors.green : (flag == "N" ? Colors.red : Colors.orange);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: MyColors.appDefaultColorCode.withOpacity(0.05), shape: BoxShape.circle),
          child: const Icon(Icons.business_rounded, color: MyColors.appDefaultColorCode, size: 20),
        ),
        title: Text(loc['locationName'] ?? "Site", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
        subtitle: Text(isApproved ? "Approved" : "Pending Verification", style: GoogleFonts.poppins(fontSize: 11, color: statusColor, fontWeight: FontWeight.w500)),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline_rounded, color: Colors.red[300], size: 20),
          onPressed: () => _deleteLocation(loc['srNo']),
        ),
        onTap: () {
          final target = LatLng(double.parse(loc['latitude']), double.parse(loc['longitude']));
          _moveCameraToLocation(target);
          _addressNotifier.value = loc['locationName'] ?? "Site Location";
          setState(() => _currentLocation = target);
        },
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5)),
    );
  }

  Widget _buildActionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 11)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildOverlayLoader() {
    return Container(
      color: Colors.black.withOpacity(0.4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
          child: const CircularProgressIndicator(color: MyColors.appDefaultColorCode, strokeWidth: 3),
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: 4,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (_, __) => _buildShimmerTile(),
    );
  }

  Widget _buildShimmerTile() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Row(
          children: [
            /// Circle icon placeholder
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),

            const SizedBox(width: 12),

            /// Text placeholders
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 12,
                    width: double.infinity,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 10,
                    width: 100,
                    color: Colors.white,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            /// Delete icon placeholder
            Container(
              width: 20,
              height: 20,
              color: Colors.white,
            ),
          ],
        ),
      ),
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
                          _addressNotifier.value,
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
                          _addProjectLocation();
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
                          _addressNotifier.value,
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
