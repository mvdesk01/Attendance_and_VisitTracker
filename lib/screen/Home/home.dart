import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:attendance_system_ios/bloc/main_bloc.dart';
import 'package:attendance_system_ios/bloc/main_event.dart';
import 'package:attendance_system_ios/bloc/main_state.dart';
import 'package:attendance_system_ios/main.dart';
import 'package:attendance_system_ios/screen/Gate%20Pass/gate_pass.dart';
import 'package:attendance_system_ios/screen/Home/report.dart';
import 'package:attendance_system_ios/screen/Leave/leave.dart';
import 'package:attendance_system_ios/screen/Login/login_screen.dart';
import 'package:attendance_system_ios/screen/Profile/profile.dart';
import 'package:attendance_system_ios/screen/Remote%20Location/remote_location.dart';
import 'package:attendance_system_ios/screen/Visit%20History/Visit_History_Screen.dart';
import 'package:attendance_system_ios/service/LocationHandler.dart';
import 'package:attendance_system_ios/service/WebService.dart';
import 'package:attendance_system_ios/service/log_file_manager.dart';
import 'package:attendance_system_ios/util/MyColor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:local_auth/local_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../model/in_out_details.dart';
import '../../service/background_service.dart';
import '../../service/internet_service.dart';
import '../AdminProfile/Databasepunchout.dart';
import '../AdminProfile/Databsepunchin.dart';
import '../Expense/ExpenseScreen.dart';
import '../Settings/Timer.dart';
import '../Tour/TourmainScreen.dart';
import '../Transaction/COff Debit/CoffDebitScreen.dart';
import '../Transaction/CoffCreditScreen.dart';
import '../Visit/Start Stop Visit/start_stop_visit.dart';
import '../Visit/visit_outside/visit_outside.dart';

class HomeScreen extends StatefulWidget {
  final String? initialPayload;
  const HomeScreen({super.key, this.initialPayload});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- Constants & Controllers ---
  final PageController _pageController = PageController(viewportFraction: 0.85);
  final LocalAuthentication auth = LocalAuthentication();
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  // --- State Variables ---
  static bool isLoading = false;
  String todayDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
  bool _isGlobalLoading = false;
  int _selectedIndex = 0;
  int _currentPage = 0;
  Timer? _bannerTimer;

  String? _currentLat;
  String? _currentLon;
  String? _currentAddress;

  bool isButtonDisabledIn = false;
  bool isButtonDisabledOut = false;
  String? lastInTime;
  String? lastOutTime;
  static bool lastPunchIn = true;
  static bool lastPunchOut = true;

  String? staffCode = "";
  String? authToken = "";
  String? staffName = "";
  String? remoteLat = "";
  String? remoteLong = "";
  String? addressFlag = "";
  String? distanceCheckFlag = "";
  String? atsFlag = "";
  String? plantCode = "";
  String appVersion = "";
  bool isTablet = false;

  late MainBloc mainBloc;
  List<Map<String, dynamic>> multiLatLongList = [];

  final List<_BannerItem> attendanceBanners = [
    _BannerItem(image: "assets/banners/attendance_banner1.png", text: "Punch-In/Out with Location Verification"),
    _BannerItem(image: "assets/banners/attendance_banner2.png", text: "Track Visits & Field Work in Real-Time"),
    _BannerItem(image: "assets/banners/attendance_banner3.png", text: "Accurate Work Hours & Attendance Reports"),
  ];

  @override
  void initState() {
    super.initState();
    _startBannerAutoScroll();
    _handleInitialPayload();
    _initializeServices();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // --- Initialization Logic ---

  void _handleInitialPayload() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialPayload != null) {
        Navigator.of(context).pushReplacementNamed('/track_visit_location', arguments: widget.initialPayload);
      }
      InternetService().startListening(MyApp.navigatorKey.currentState!.overlay!.context);
    });
  }

  void _initializeServices() async {
    await _loadVersion();
    await _loadUserData();
    await _checkAndRequestLocationPermission();
    await _updateButtonInitialState();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => appVersion = info.version);
  }

  Future<void> _loadUserData() async {
    staffCode = await storage.read(key: 'Staff_Code');
    authToken = await storage.read(key: 'Auth_Token');
    staffName = await storage.read(key: 'Staff_Name');

    if (staffCode != null && authToken != null) {
      mainBloc.add(GetStaffDetailsEvents(StaffCode: staffCode!, token: authToken!));
      mainBloc.add(GetUserInfoEvents(Staffcode: staffCode!, token: authToken!));
      mainBloc.add(GetMultiRemoteLocation(authToken!, staffCode!));
    }
  }

  // --- Location & Permissions ---

  Future<void> _checkAndRequestLocationPermission() async {
    bool hasPermission = await handleLocationPermission();
    if (!hasPermission) {
      _showSnackbar("Location permission is required! Please allow from settings.");
    }
  }

  Future<bool> handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    return permission != LocationPermission.deniedForever;
  }

  // --- Attendance State & Logic ---

  Future<void> _updateButtonInitialState() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      String today = DateFormat('dd/MM/yyyy').format(DateTime.now());
      final response = await http.post(
        Uri.parse('http://114.143.140.28:8020/api/InOut/InOutDetails'),
        headers: {"Content-Type": "application/json", 'Authorization': 'Bearer $authToken'},
        body: jsonEncode({"staffCode": staffCode, "fromDate": today, "toDate": today}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body)['data'] ?? [];
        List<InOutDetail> details = (data as List).map((item) => InOutDetail.fromJson(item)).toList();
        if (mounted) {
          setState(() {
            isLoading = false;
            if (details.isNotEmpty) _processPunchDetails(details);
          });
        }
      } else if (response.statusCode == 400 && mounted) {
        setState(() {
          isLoading = false;
          isButtonDisabledIn = false;
          isButtonDisabledOut = true;
          lastInTime = "-";
          lastOutTime = "-";
        });
      }
    } catch (e) {
      LogFileManager.writeLog("Error updating punch state: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _processPunchDetails(List<InOutDetail> details) {
    String time1 = details[0].transactionTime!.substring(11, 19);
    String? time2 = details.length > 1 ? details[1].transactionTime!.substring(11, 19) : null;

    if (details[0].inOut == "IN") {
      isButtonDisabledIn = true;
      isButtonDisabledOut = false;
      lastPunchIn = false;
      lastPunchOut = true;
      lastInTime = time1;
      lastOutTime = time2;
    } else {
      isButtonDisabledIn = false;
      isButtonDisabledOut = true;
      lastPunchIn = true;
      lastPunchOut = false;
      lastOutTime = time1;
      lastInTime = time2;
    }
  }

  Future<void> punchIn() async {
    if (!await handleLocationPermission()) return;
    if (distanceCheckFlag == 'Y') {
      await _executePunch('001', 'Punch-in');
    } else if (addressFlag == 'Y') {
      await _executeRemotePunch('001', 'Punch-in');
    } else {
      Fluttertoast.showToast(msg: "Admin approval pending!");
    }
  }

  Future<void> punchOut() async {
    if (!await handleLocationPermission()) return;
    if (distanceCheckFlag == 'Y') {
      await _executePunch('000', 'Punch-out');
    } else if (addressFlag == 'Y') {
      await _executeRemotePunch('000', 'Punch-out');
    } else {
      Fluttertoast.showToast(msg: "Admin approval pending!");
    }
  }

  Future<void> _executePunch(String flag, String label) async {
    setState(() => isLoading = true);
    try {
      await LocationHandler.checkIfInZone();
      _currentLat = LocationHandler.currentLat.toString();
      _currentLon = LocationHandler.currentLon.toString();
      _currentAddress = LocationHandler.currentAddress;

      String date = DateFormat('dd-MM-yyyy').format(DateTime.now());
      String time = DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now());

      bool canProceed = flag == '001' ? await _checkLastFlag('000') : await _checkLastFlag('001');

      if (canProceed) {
        String? result = await _savePunchData(date, time, flag);
        if (result != null) {
          _showSuccessSnackbar("$label Successful!");
          _updateButtonInitialState();
        }
      } else {
        _showErrorSnackbar("Invalid punch sequence.");
      }
    } catch (e) {
      _showErrorSnackbar("$label failed. Try again.");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _executeRemotePunch(String flag, String label) async {
    LocationHandler.changeToRemoteLocation();
    LocationHandler.remoteZoneLat = double.tryParse(remoteLat ?? "0") ?? 0;
    LocationHandler.remoteZoneLon = double.tryParse(remoteLong ?? "0") ?? 0;
    LocationHandler.multiLatLong = multiLatLongList;

    if (await LocationHandler.checkIfInZone()) {
      await _executePunch(flag, label);
    } else {
      String date = DateFormat('dd-MM-yyyy').format(DateTime.now());
      String time = DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now());
      await _savePunchData(date, time, '002'); // Not in zone
      Fluttertoast.showToast(msg: "Not in zone!");
    }
  }

  Future<bool> _checkLastFlag(String expected) async {
    try {
      final response = await http.post(
        Uri.parse("http://114.143.140.28:8020/api/InOut/InOutLastFlag"),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $authToken'},
        body: jsonEncode({'TransactionDate': DateFormat('dd-MM-yyyy').format(DateTime.now()), 'StaffCode': staffCode}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body)['data'] == expected;
      }
      return response.statusCode == 400; // No records found, OK to punch in
    } catch (e) {
      return false;
    }
  }

  Future<String?> _savePunchData(String date, String time, String flag) async {
    final body = {
      'TransactionDate': date,
      'TransactionTime': time,
      'StaffCode': staffCode,
      'flagValue': flag,
      'address': _currentAddress ?? "Unknown",
      'latitude': _currentLat ?? "0",
      'longitude': _currentLon ?? "0",
      "plantCode": plantCode ?? "01"
    };

    try {
      final response = await http.post(
        Uri.parse("http://114.143.140.28:8020/api/InOut/InOutSaveData"),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $authToken'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (atsFlag == 'Y') await _saveExternalPunch(body);
        return response.body;
      } else {
        await _saveOfflinePunch(date, time, flag);
        return "offline";
      }
    } catch (e) {
      await _saveOfflinePunch(date, time, flag);
      return "offline";
    }
  }

  Future<void> _saveExternalPunch(Map<String, dynamic> data) async {
    try {
      await http.post(
        Uri.parse("https://m-techinnovations.co.in/PersonTrackingAPI/API/SaveDetailsTLS"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
    } catch (e) {
      LogFileManager.writeLog("External punch save error: $e");
    }
  }

  Future<void> _saveOfflinePunch(String date, String time, String flag) async {
    final row = {
      'transaction_date': date,
      'transaction_time': time,
      'staff_code': staffCode!,
      'flag_value': flag,
      'address': _currentAddress ?? "",
      'latitude': _currentLat ?? "0",
      'longitude': _currentLon ?? "0",
    };
    if (flag == '001') {
      await DatabaseHelper().insertPunchEntry(row);
    } else {
      await DatabaseHelperPunchout().insertPunchoutEntry(row);
    }
    Fluttertoast.showToast(msg: "Saved offline.");
  }

  // --- UI Structure ---

  @override
  Widget build(BuildContext context) {
    mainBloc = BlocProvider.of(context);
    isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      bottomNavigationBar: _buildBottomNav(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text("Attendance"),
      backgroundColor: MyColors.lightBlue,
      centerTitle: true,
      titleTextStyle: GoogleFonts.roboto(fontWeight: FontWeight.bold, fontSize: 20.0, color: Colors.white),
      iconTheme: const IconThemeData(color: Colors.white, size: 28),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () => Fluttertoast.showToast(msg: "No Notifications"),
        )
      ],
    );
  }

  Widget _buildBody() {
    return LoadingOverlay(
      isLoading: _isGlobalLoading,
      opacity: 0.5,
      color: Colors.white,
      progressIndicator: const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.grey)),
      child: BlocListener<MainBloc, MainState>(
        listener: _blocListener,
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildHomeContent(),
            const Center(child: AttendanceReport()),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserInfoTile(),
          _buildBannerPager(),
          const SizedBox(height: 10),
          if (addressFlag == 'Y') _buildAttendanceSection(),
          const SizedBox(height: 10),
          visitManagementUI(),
          _buildOtherSection(),
        ],
      ),
    );
  }

  Widget _buildUserInfoTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(staffName ?? "", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text("Staff Code: $staffCode", style: const TextStyle(fontSize: 13, color: Colors.black54)),
              ],
            ),
          ),
          IconButton(
            icon: CircleAvatar(backgroundColor: Colors.blue.shade100, child: const Icon(Icons.person, color: Colors.blue)),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const Profile())),
          )
        ],
      ),
    );
  }

  Widget _buildBannerPager() {
    return SizedBox(
      height: isTablet ? 300 : 210,
      child: PageView.builder(
        controller: _pageController,
        itemCount: attendanceBanners.length,
        onPageChanged: (i) => setState(() => _currentPage = i),
        itemBuilder: (_, i) => Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          elevation: 5,
          child: Stack(
            children: [
              Image.asset(attendanceBanners[i].image, width: double.infinity, fit: BoxFit.fill),
              Container(color: Colors.black.withValues(alpha: 0.2)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceSection() {
    return Card.outlined(
      color: Colors.transparent,
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child:Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 10,),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Daily Attendance", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(todayDate, style: GoogleFonts.poppins(fontSize: 12, color: Colors.black)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildPunchButton(true)),
              const SizedBox(width: 15),
              Expanded(child: _buildPunchButton(false)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPunchTimeInfo("IN Time", lastInTime ?? "--:--", lastPunchIn ? Colors.grey : Colors.green),
              Container(height: 30, width: 1, color: Colors.grey[200]),
              _buildPunchTimeInfo("OUT Time", lastOutTime ?? "--:--", lastPunchOut ? Colors.grey : Colors.redAccent),
            ],
          ),
        ],
      ),
    )
    );
  }

  Widget _buildPunchButton(bool isPunchIn) {
    bool isDisabled = isPunchIn ? isButtonDisabledIn : isButtonDisabledOut;
    Color color = isPunchIn ? Colors.green : Colors.redAccent;

    return InkWell(
      onTap: isDisabled ? null : () => _showPunchConfirmation(isPunchIn),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: isDisabled ? Colors.grey[100] : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDisabled ? Colors.grey[200]! : color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(isPunchIn ? Icons.login_rounded : Icons.logout_rounded, color: isDisabled ? Colors.grey : color, size: 28),
            const SizedBox(height: 8),
            Text(isPunchIn ? "PUNCH IN" : "PUNCH OUT", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: isDisabled ? Colors.grey : color)),
          ],
        ),
      ),
    );
  }

  void _showPunchConfirmation(bool isPunchIn) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isPunchIn ? "Punch In" : "Punch Out", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(isPunchIn ? "assets/icons/In01.png" : "assets/icons/out01.png", width: 80),
            const SizedBox(height: 15),
            Text("Ready to mark your ${isPunchIn ? 'In time' : 'Out time'}?", textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: MyColors.lightBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              Navigator.pop(context);
              // setState(() => _isOverlayLoading = true);
              isPunchIn ? await checkBiometrics() : await checkbiometricspunchout();
              // setState(() => _isOverlayLoading = false);
            },
            child: const Text("CONFIRM"),
          ),
        ],
      ),
    );
  }

  Widget _buildPunchTimeInfo(String label, String time, Color statusColor) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
        Text(time, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: statusColor)),
      ],
    );
  }

  Widget visitManagementUI() {
    return _sectionCard("Visit Management", [
      _tile(Icons.add_location_alt, "Visit Outside", "Schedule field work", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VisitOutside()))),
      _tile(Icons.location_on, "Start-Stop Visit", "Manage active tracking", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VisitStartStopScreen(visit: null)))),
      _tile(Icons.history, "Visit History", "Review past visits", () => Navigator.push(context, MaterialPageRoute(builder: (_) => _wrapped(const VisitHistoryScreen())))),
    ]);
  }

  Widget _buildOtherSection() {
    return _sectionCard("Others", [
      _tile(Icons.backpack, "Leave", "Apply/Check status", () => Navigator.push(context, MaterialPageRoute(builder: (_) => _wrapped(const PendingLeave())))),
      _tile(Icons.book, "Gate Pass", "Apply/Check status", () => Navigator.push(context, MaterialPageRoute(builder: (_) => _wrapped(const GatePass())))),
      _tile(Icons.money_off, "Expenses", "Manage claims", () => Navigator.push(context, MaterialPageRoute(builder: (_) => _wrapped(const Expensemanagmentscreen())))),
    ]);
  }

  // --- UI Helpers ---

  Widget _sectionCard(String title, List<Widget> children) {
    return Card.outlined(
      color: Colors.blue[50],
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.all(8.0), child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          ...children
        ]),
      ),
    );
  }

  Widget _tile(IconData i, String t, String s, VoidCallback o) {
    return Card.filled(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: ListTile(
        leading: Icon(i, color: Colors.blueAccent),
        title: Text(t, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(s, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, size: 16),
        onTap: o,
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: MyColors.lightBlue),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: MyColors.lightBlue),
            ),
            accountName: Text(staffName ?? "", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            accountEmail: Text("Staff Code: $staffCode", style: GoogleFonts.poppins(fontSize: 12)),
            onDetailsPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Profile())),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(Icons.home_outlined, "Home", () => Navigator.pop(context)),
                _buildDrawerItem(Icons.backpack_outlined, "Leave", () => Navigator.push(context, MaterialPageRoute(builder: (_) => BlocProvider(create: (_) => MainBloc(webService: WebService()), child: const PendingLeave())))),
                _buildDrawerItem(Icons.badge_outlined, "Gate Pass", () => Navigator.push(context, MaterialPageRoute(builder: (_) => BlocProvider(create: (_) => MainBloc(webService: WebService()), child: const GatePass())))),
                _buildDrawerItem(Icons.currency_exchange_outlined, "COff Credit", () => Navigator.push(context, MaterialPageRoute(builder: (_) => BlocProvider(create: (_) => MainBloc(webService: WebService()), child: const Coffcreditscreen())))),
                _buildDrawerItem(Icons.book_outlined, "COff Debit", () => Navigator.push(context, MaterialPageRoute(builder: (_) => BlocProvider(create: (_) => MainBloc(webService: WebService()), child: const CoffDebitscreen())))),

                _buildDrawerItem(Icons.receipt_long_outlined, "Expense Management", () => Navigator.push(context, MaterialPageRoute(builder: (_) => BlocProvider(create: (_) => MainBloc(webService: WebService()), child: const Expensemanagmentscreen())))),
                _buildDrawerItem(Icons.explore_outlined, "Tour Details", () => Navigator.push(context, MaterialPageRoute(builder: (_) => BlocProvider(create: (_) => MainBloc(webService: WebService()), child: const TourPendingScreen())))),
                _buildDrawerItem(Icons.location_on_outlined, "Remote Location", () => Navigator.push(context, MaterialPageRoute(builder: (_) => BlocProvider(create: (_) => MainBloc(webService: WebService()), child: const RemoteLocation())))),
                const Divider(),
                _buildDrawerItem(Icons.add_location_alt_outlined, "Plan Visit", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VisitOutside()))),
                _buildDrawerItem(Icons.history_rounded, "Visit History", () => Navigator.push(context, MaterialPageRoute(builder: (_) => BlocProvider(create: (_) => MainBloc(webService: WebService()), child: const VisitHistoryScreen())))),
                _buildDrawerItem(Icons.settings_outlined, "Settings", () => Navigator.push(context, MaterialPageRoute(builder: (_) => BlocProvider(create: (_) => MainBloc(webService: WebService()), child:  SettingsPage())))),
                _buildDrawerItem(Icons.logout_rounded, "Logout", onLogout, isDestructive: true),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    children: [
                      Divider(color: Colors.grey.shade300, thickness: 0.8),
                      Text(
                        "App Version $appVersion",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : Colors.grey[700]),
      title: Text(title, style: GoogleFonts.poppins(fontSize: 14, color: isDestructive ? Colors.red : Colors.black87)),
      onTap: onTap,
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (i) => setState(() => _selectedIndex = i),
      selectedItemColor: MyColors.lightBlue,
      items: const [BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"), BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Report")],
    );
  }

  // --- Logic Helpers ---

  void _blocListener(BuildContext context, MainState state) {
    if (state is GetStaffDetailsLoadingState || state is GetUserinfoLoadingState) {
      setState(() => _isGlobalLoading = true);
    } else if (state is GetUserinfoLoadedState) {
      final user = state.profileuserinfo.message;
      setState(() {
        _isGlobalLoading = false;
        remoteLat = user?.remoteLatitude;
        remoteLong = user?.remoteLongitude;
        distanceCheckFlag = user?.distanceCheckFlag;
        addressFlag = user?.addressapproveFlag;
        plantCode = user?.plantCode;
        atsFlag = user?.atsCheckflag;
      });
    } else {
      setState(() => _isGlobalLoading = false);
    }
  }

  void onLogout() async {
    if (VisitState.isVisitRunning.value && !await _confirmStopVisit()) return;
    await storage.deleteAll();
    if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => _wrapped(const LoginScreen())), (r) => false);
  }

  Future<bool> _confirmStopVisit() async {
    return await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text("Stop Visit"),
      content: const Text("Active visit found. Stop it and logout?"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("No")),
        TextButton(onPressed: () { _stopVisit(); Navigator.pop(context, true); }, child: const Text("Yes")),
      ],
    )) ?? false;
  }

  void _stopVisit() async {
    await storage.delete(key: 'SelectedVisit');
    VisitState.isVisitRunning.value = false;
    BackgroundService().stopService();
    await FlutterLocalNotificationsPlugin().cancel(foregroundServiceNotificationId);
    if (Platform.isIOS) NativeLocationBridge.stopNativeTracking();
  }

  void _startBannerAutoScroll() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (t) {
      if (_pageController.hasClients) {
        _currentPage = (_currentPage + 1) % attendanceBanners.length;
        _pageController.animateToPage(_currentPage, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      }
    });
  }

  Future<void> checkBiometrics() async {
    if (await auth.canCheckBiometrics && await auth.authenticate(localizedReason: "Punch In")) {
      await punchIn();
    } else {
      await punchIn();
    }
  }

  Future<void> checkbiometricspunchout() async {
    if (await auth.canCheckBiometrics && await auth.authenticate(localizedReason: "Punch Out")) {
      await punchOut();
    } else {
      await punchOut();
    }
  }

  Widget _wrapped(Widget child) => BlocProvider(create: (_) => MainBloc(webService: WebService()), child: child);
  void _showSuccessSnackbar(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.green));
  void _showErrorSnackbar(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.red));
  void _showSnackbar(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
}

class _BannerItem {
  final String image, text;
  _BannerItem({required this.image, required this.text});
}
