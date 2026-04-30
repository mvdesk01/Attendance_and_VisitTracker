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
import 'package:attendance_system_ios/screen/MinutesOfTheMeetingForm.dart';
import 'package:attendance_system_ios/screen/Profile/profile.dart';
import 'package:attendance_system_ios/screen/Remote%20Location/remote_location.dart';
import 'package:attendance_system_ios/screen/Settings/Timer.dart';
import 'package:attendance_system_ios/screen/Transaction/COff%20Debit/CoffDebitScreen.dart';
import 'package:attendance_system_ios/screen/Transaction/COff%20Debit/DebitCoffScreen.dart';
import 'package:attendance_system_ios/screen/Transaction/CoffCreditScreen.dart';
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

import '../../model/in_out_details.dart';
import '../../service/background_service.dart';
import '../../service/internet_service.dart';
import '../AdminProfile/Databasepunchout.dart';
import '../AdminProfile/Databsepunchin.dart';
import '../Expense/ExpenseScreen.dart';
import '../Tour/TourmainScreen.dart';
import '../Visit/Start Stop Visit/start_stop_visit.dart';
import '../Visit/visit_outside/visit_outside.dart';

class HomeScreen extends StatefulWidget {
  final String? initialPayload;
  const HomeScreen({super.key, this.initialPayload});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String todayDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
  bool isLoadingStatus = false;
  String? _currentLat;
  String? _currentLon;
  String? _currentAddress;
  bool isButtonDisabledIn = false;
  bool isButtonDisabledOut = false;

  String? lastInTime;
  String? lastOutTime;
  LocalAuthentication auth = LocalAuthentication();

  bool lastPunchIn = true;
  bool lastPunchOut = true;
  bool _isOverlayLoading = false;
  late MainBloc mainBloc;
  List<Map<String, dynamic>> multiLatLongList = [];
  final storage = const FlutterSecureStorage();

  String? staffCode = "";
  String? Auth_Token = "";
  String? staffName = "";
  String? remotelocation = "";
  String? distancecheckglag = "";
  String? remotelat = "";
  String? remotelong = "";
  String? addressflag = "";
  String REMOTELOCATION = "";
  String REMOTELAT = "";
  String REMOTELONG = "";
  String ADDRESSFLAG = "";
  String DISTANCEFLAG = "";
  String? atsflag = "";
  String? plantcode = "";

  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;
  Timer? _bannerTimer;
  bool isTablet = false;

  final List<_BannerItem> attendanceBanners = [
    _BannerItem(
      image: "assets/banners/attendance_banner1.png",
      text: "Punch-In/Out with Location Verification",
    ),
    _BannerItem(
      image: "assets/banners/attendance_banner2.png",
      text: "Track Visits & Field Work in Real-Time",
    ),
    _BannerItem(
      image: "assets/banners/attendance_banner3.png",
      text: "Accurate Work Hours & Attendance Reports",
    ),
  ];

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    startBannerAutoScroll();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.initialPayload != null) {
        Navigator.of(context).pushReplacementNamed(
          '/track_visit_location',
          arguments: widget.initialPayload,
        );
      }
      InternetService().startListening(MyApp.navigatorKey.currentState!.overlay!.context);
    });
    initialize();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> initialize() async {
    await _checkauthorisation();
    await getData();
    await _checkAndRequestLocationPermission();
    await _updateButtonInitialState();
  }

  Future<void> _checkauthorisation() async {
    staffCode = await storage.read(key: 'Staff_Code');
    Auth_Token = await storage.read(key: 'Auth_Token');
    staffName = await storage.read(key: 'Staff_Name');
    if (staffCode != null && Auth_Token != null) {
      mainBloc.add(GetStaffDetailsEvents(StaffCode: staffCode!, token: Auth_Token!));
    }
  }

  Future<void> getData() async {
    staffCode = await storage.read(key: 'Staff_Code');
    Auth_Token = await storage.read(key: 'Auth_Token');
    staffName = await storage.read(key: 'Staff_Name');
    if (staffCode != null && Auth_Token != null) {
      mainBloc.add(GetUserInfoEvents(Staffcode: staffCode!, token: Auth_Token!));
      mainBloc.add(GetMultiRemoteLocation(Auth_Token!, staffCode!));
    }
  }

  Future<void> _checkAndRequestLocationPermission() async {
    await handleLocationPermission();
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

  Future<void> _updateButtonInitialState() async {
    setState(() => isLoadingStatus = true);
    try {
      String formattedDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
      final response = await http.post(
        Uri.parse('http://114.143.140.28:8020/api/InOut/InOutDetails'),
        headers: {"Content-Type": "application/json", 'Authorization': 'Bearer $Auth_Token'},
        body: jsonEncode({"staffCode": staffCode, "fromDate": formattedDate, "toDate": formattedDate}),
      ).timeout(const Duration(seconds: 15));

      final Map<String, dynamic> decoded = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        List<dynamic> data = decoded['data'] ?? [];
        List<InOutDetail> details = data.map((item) => InOutDetail.fromJson(item)).toList();

        if (details.isNotEmpty) {
          String lastTime = details[0].transactionTime!.substring(11, 19);
          if (details[0].inOut == "IN") {
            setState(() {
              isButtonDisabledIn = true;
              isButtonDisabledOut = false;
              lastPunchIn = false;
              lastPunchOut = true;
              lastInTime = lastTime;
              if (details.length > 1) lastOutTime = details[1].transactionTime!.substring(11, 19);
            });
          } else {
            setState(() {
              isButtonDisabledIn = false;
              isButtonDisabledOut = true;
              lastPunchIn = true;
              lastPunchOut = false;
              lastOutTime = lastTime;
              if (details.length > 1) lastInTime = details[1].transactionTime!.substring(11, 19);
            });
          }
        }
      } else if (response.statusCode == 400 && decoded['message'] == "No Records Found.") {
        setState(() {
          isButtonDisabledIn = false;
          isButtonDisabledOut = true;
          lastInTime = "-";
          lastOutTime = "-";
        });
      }
    } catch (e) {
      print("Error fetching initial state: $e");
    } finally {
      setState(() => isLoadingStatus = false);
    }
  }

  void startBannerAutoScroll() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        _currentPage = (_currentPage + 1) % attendanceBanners.length;
        _pageController.animateToPage(_currentPage, duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  void onLogout() async {
    if (VisitState.isVisitRunning.value) {
      bool? result = await showStopVisitDialogBox(context);
      if (result != true) return;
    }
    await storage.deleteAll();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => BlocProvider(create: (context) => MainBloc(webService: WebService()), child: const LoginScreen())),
      (route) => false,
    );
  }

  Future<bool?> showStopVisitDialogBox(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Stop Visit Tracking"),
        content: const Text("Are you sure you want to stop tracking the visit?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () { stopVisit(); Navigator.of(context).pop(true); }, child: const Text("Ok")),
        ],
      ),
    );
  }

  Future<void> stopVisit() async {
    try {
      await storage.delete(key: 'SelectedVisit');
      VisitState.isVisitRunning.value = false;
      BackgroundService().stopService();
      await FlutterLocalNotificationsPlugin().cancel(foregroundServiceNotificationId);
      if (Platform.isIOS) await NativeLocationBridge.stopNativeTracking();
    } catch (e) {
      LogFileManager.writeLog("stop visit error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    mainBloc = BlocProvider.of<MainBloc>(context);
    isTablet = MediaQuery.of(context).size.width >= 600;
    return Scaffold(
      // backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      bottomNavigationBar: _buildBottomNav(),
      body: _selectedIndex == 0 ? _buildHomeContent() : const AttendanceReport(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: MyColors.lightBlue,
      iconTheme: const IconThemeData(color: Colors.white),
      title: Text("Attendance", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white)),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded),
          onPressed: () => Fluttertoast.showToast(msg: "No new notifications"),
        ),
      ],
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
    return Container(
      decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      child: BottomNavigationBar(
        elevation: 0,
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        selectedItemColor: MyColors.lightBlue,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.description_outlined), label: 'Reports'),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return LoadingOverlay(
      isLoading: _isOverlayLoading,
      opacity: 0.3,
      progressIndicator: const CircularProgressIndicator(color: MyColors.lightBlue),
      child: BlocListener<MainBloc, MainState>(
        listener: (context, state) {
          if (state is GetStaffDetailsLoadingState || state is GetUserinfoLoadingState || state is GetMultiRemoteLocationLoadingState) {
            setState(() => _isOverlayLoading = true);
          } else if (state is GetStaffDetailsLoadedState) {
            setState(() => _isOverlayLoading = false);
          } else if (state is GetUserinfoLoadedState) {
            final user = state.profileuserinfo.message;
            setState(() {
              _isOverlayLoading = false;
              remotelocation = user!.newRemoteLocation;
              distancecheckglag = user.distanceCheckFlag;
              remotelat = user.remoteLatitude;
              remotelong = user.remoteLongitude;
              addressflag = user.addressapproveFlag;
              atsflag = user.atsCheckflag;
              plantcode = user.plantCode;
            });
            REMOTELOCATION = remotelocation ?? "";
            REMOTELAT = remotelat ?? "";
            REMOTELONG = remotelong ?? "";
            DISTANCEFLAG = distancecheckglag ?? "";
            ADDRESSFLAG = addressflag ?? "";
          }else if(state is GetMultiRemoteLocationLoadedState){
            multiLatLongList = state.response;
           setState(() {
              _isOverlayLoading = false;
           });
          }
          else if (state is GetUserinfoErrorState || state is GetStaffDetailsErrorState || state is GetMultiRemoteLocationErrorState) {
            setState(() => _isOverlayLoading = false);
          }
        },
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildBannerSection(),
              if (addressflag == 'Y') _buildAttendanceSection(),
              _buildVisitSection(),
              _buildOtherFeaturesSection(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Hello,", style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey)),
                Text(staffName ?? "", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Profile())),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: MyColors.lightBlue, width: 2)),
              child: const CircleAvatar(radius: 22, backgroundColor: Colors.white, child: Icon(Icons.person, color: MyColors.lightBlue)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerSection() {
    return Column(
      children: [
        SizedBox(
          height: isTablet ? 300 : 190,
          child: PageView.builder(
            controller: _pageController,
            itemCount: attendanceBanners.length,
            onPageChanged: (index) {
              _currentPage = index;
            },
            itemBuilder: (context, index) {
              final banner = attendanceBanners[index];

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 5,
                child: Stack(
                  children: [

                    /// Banner Image
                    Image.asset(
                      banner.image,
                      height: isTablet ? 300 : 190,
                      width: double.infinity,
                      fit: BoxFit.fill,
                    ),
                    /// Dark overlay
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.20),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(attendanceBanners.length, (index) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: _currentPage == index ? 12 : 6,
            height: 6,
            decoration: BoxDecoration(color: _currentPage == index ? MyColors.lightBlue : Colors.grey[300], borderRadius: BorderRadius.circular(3)),
          )),
        ),
      ],
    );
  }

  Widget _buildAttendanceSection() {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 10,),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Daily Attendance", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(todayDate, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
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
              setState(() => _isOverlayLoading = true);
              isPunchIn ? await checkBiometrics() : await checkbiometricspunchout();
              setState(() => _isOverlayLoading = false);
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

  Widget _buildVisitSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Visit Management", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildFeatureCard(Icons.add_location_alt_outlined, "Plan Visit", Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VisitOutside())))),
              const SizedBox(width: 12),
              Expanded(child: _buildFeatureCard(Icons.play_circle_outline_rounded, "Start/Stop", Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VisitStartStopScreen(visit: null))))),
              const SizedBox(width: 12),
              Expanded(child: _buildFeatureCard(Icons.history_toggle_off_rounded, "History", Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => BlocProvider(create: (_) => MainBloc(webService: WebService()), child: const VisitHistoryScreen()))))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 24)),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherFeaturesSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Quick Actions", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildQuickActionTile(Icons.backpack_outlined, "Leave Management", "Apply or check leave status", Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => BlocProvider(create: (_) => MainBloc(webService: WebService()), child: const PendingLeave())))),
          _buildQuickActionTile(Icons.book_outlined, "Gate Pass", "Apply for temporary exit", Colors.indigo, () => Navigator.push(context, MaterialPageRoute(builder: (_) => BlocProvider(create: (_) => MainBloc(webService: WebService()), child: const GatePass())))),
          _buildQuickActionTile(Icons.monetization_on_outlined, "Expense Claims", "Manage your work expenses", Colors.green, () => Navigator.push(context, MaterialPageRoute(builder: (_) => BlocProvider(create: (_) => MainBloc(webService: WebService()), child: const Expensemanagmentscreen())))),
        ],
      ),
    );
  }

  Widget _buildQuickActionTile(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color)),
        title: Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      ),
    );
  }

  // --- Core Attendance Logic (Maintained exactly as provided) ---

  Future<void> punchIn() async {
    bool hasPermission = await handleLocationPermission();
    if (!hasPermission) return;

    if(DISTANCEFLAG == 'Y'){
        try {
          await LocationHandler.checkIfInZone();
          _currentLat = LocationHandler.currentLat.toString();
          _currentLon = LocationHandler.currentLon.toString();
          _currentAddress = LocationHandler.currentAddress;
          String currentDate = DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now()).substring(0, 19);
          String currentTime = DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now()).substring(11, 19);
          String currentDateTime = DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now()).substring(0, 19);
          if (await getInEntryFromDataBase(currentDate, currentTime, staffCode!)) {
            await storeInEntry(currentDate, currentDateTime, staffCode!, "001", _currentAddress!, _currentLat!, _currentLon!, plantcode?.toString() ?? "01");
            setState(() { isButtonDisabledIn = true; isButtonDisabledOut = false; _updateButtonInitialState(); });
            // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Punch-in Successful!'), backgroundColor: Colors.green));
            showPunchSnackbar(isPunchIn: true, success: true);
          }
        } catch (e) {
          // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Punch-in failed!')));
          showPunchSnackbar(isPunchIn: true, success: false);
        } finally { setState(() => _isOverlayLoading = false); }
    } else {
      if(ADDRESSFLAG == 'Y'){
        LocationHandler.changeToRemoteLocation();
        LocationHandler.remoteZoneLat = double.parse(REMOTELAT);
        LocationHandler.remoteZoneLon = double.parse(REMOTELONG);
        LocationHandler.multiLatLong = multiLatLongList;
        bool ifInZone = await LocationHandler.checkIfInZone();
        if(ifInZone) {
          try {
            _currentLat = LocationHandler.currentLat.toString();
            _currentLon = LocationHandler.currentLon.toString();
            _currentAddress = LocationHandler.currentAddress;
            String currentDate = DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now()).substring(0, 19);
            String currentTime = DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now()).substring(11, 19);
            String currentDateTime = DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now()).substring(0, 19);
            if (await getInEntryFromDataBase(currentDate, currentTime, staffCode!)) {
              await storeInEntry(currentDate, currentDateTime, staffCode!, "001", _currentAddress!, _currentLat!, _currentLon!, plantcode?.toString() ?? "01");
              setState(() { isButtonDisabledIn = true; isButtonDisabledOut = false; _updateButtonInitialState(); });
              // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Punch-in Successful!'), backgroundColor: Colors.green));
              showPunchSnackbar(isPunchIn: true, success: true);
            }
          } catch (e) {
            showPunchSnackbar(isPunchIn: true, success: false);
            // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Punch-in failed!')));
          } finally { setState(() => _isOverlayLoading = false); }
        } else {
          _currentLat = LocationHandler.currentLat.toString();
          _currentLon = LocationHandler.currentLon.toString();
          _currentAddress = LocationHandler.currentAddress;
          String currentDate = DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now()).substring(0, 19);
          String currentDateTime = DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now()).substring(0, 19);
          await storeNotInZoneEntry(currentDate, currentDateTime, staffCode!, "002", _currentAddress!, _currentLat!, _currentLon!, plantcode?.toString() ?? "01");
          Fluttertoast.showToast(msg: "Not in zone!!");
        }
      }
    }
  }

  Future<void> punchOut() async {
    bool hasPermission = await handleLocationPermission();
    if (!hasPermission) return;

    if(DISTANCEFLAG =='Y'){
        try {
          await LocationHandler.checkIfInZone();
          _currentLat = LocationHandler.currentLat.toString();
          _currentLon = LocationHandler.currentLon.toString();
          _currentAddress = LocationHandler.currentAddress;
          String currentDate = DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now()).substring(0, 19);
          String currentTime = DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now()).substring(11, 19);
          String currentDateTime = DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now()).substring(0, 19);
          if (await getOutEntryFromDataBase(currentDate, currentTime, staffCode!)) {
            await storeOutEntry(currentDate, currentDateTime, staffCode!, "000", _currentAddress!, _currentLat!, _currentLon!, plantcode?.toString() ?? "01");
            setState(() { isButtonDisabledIn = false; isButtonDisabledOut = true; _updateButtonInitialState(); });
            // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Punch-out Successful!'), backgroundColor: Colors.green));
            showPunchSnackbar(isPunchIn: false, success: true);
          }
        } catch (e) {
          showPunchSnackbar(isPunchIn: false, success: false);
          // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Punch-out failed!')));
        } finally { setState(() => _isOverlayLoading = false); }
    } else {
      if(ADDRESSFLAG == 'Y'){
        LocationHandler.changeToRemoteLocation();
        LocationHandler.remoteZoneLat = double.parse(REMOTELAT);
        LocationHandler.remoteZoneLon = double.parse(REMOTELONG);
        LocationHandler.multiLatLong = multiLatLongList;
        bool ifInZone = await LocationHandler.checkIfInZone();
        if(ifInZone) {
          try {
            _currentLat = LocationHandler.currentLat.toString();
            _currentLon = LocationHandler.currentLon.toString();
            _currentAddress = LocationHandler.currentAddress;
            String currentDate = DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now()).substring(0, 19);
            String currentTime = DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now()).substring(11, 19);
            String currentDateTime = DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now()).substring(0, 19);
            if (await getOutEntryFromDataBase(currentDate, currentTime, staffCode!)) {
              await storeOutEntry(currentDate, currentDateTime, staffCode!, "000", _currentAddress!, _currentLat!, _currentLon!, plantcode?.toString() ?? "01");
              setState(() { isButtonDisabledOut = true; isButtonDisabledIn = false; _updateButtonInitialState(); });
              // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Punch-out Successful!'), backgroundColor: Colors.green));
              showPunchSnackbar(isPunchIn: false, success: true);
            }
          } catch (e) {
            showPunchSnackbar(isPunchIn: false, success: false);
            // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Punch-out failed!')));
          } finally { setState(() => _isOverlayLoading = false); }
        } else {
          _currentLat = LocationHandler.currentLat.toString();
          _currentLon = LocationHandler.currentLon.toString();
          _currentAddress = LocationHandler.currentAddress;
          String currentDate = DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now()).substring(0, 19);
          String currentDateTime = DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now()).substring(0, 19);
          await storeNotInZoneEntry(currentDate, currentDateTime, staffCode!, "002", _currentAddress!, _currentLat!, _currentLon!, plantcode?.toString() ?? "01");
          Fluttertoast.showToast(msg: "Not in zone!!");
        }
      }
    }
  }

  Future<bool> getInEntryFromDataBase(String TransactionDate, String TransactionTime, String StaffCode) async {
    try {
      final response = await http.post(
        Uri.parse("http://114.143.140.28:8020/api/InOut/InOutLastFlag"),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $Auth_Token'},
        body: jsonEncode({'TransactionDate': TransactionDate, 'StaffCode': StaffCode}),
      );
      final res = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) return res['data'] == "000";
      if (response.statusCode == 400 && res['message'] == "No Record Found.") return true;
      return false;
    } catch(e) { return false; }
  }

  Future<bool> getOutEntryFromDataBase(String TransactionDate, String TransactionTime, String StaffCode) async {
    try {
      final response = await http.post(
        Uri.parse("http://114.143.140.28:8020/api/InOut/InOutLastFlag"),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $Auth_Token'},
        body: jsonEncode({'TransactionDate': TransactionDate, 'StaffCode': StaffCode}),
      );
      final res = json.decode(response.body);
      return (response.statusCode == 200 || response.statusCode == 201) && res['data'] == "001";
    } catch(e) { return false; }
  }

  Future<String?> storeInEntry(String TransactionDate, String TransactionTime, String StaffCode, String FlagValue, String Address, String Latitude, String Longitude, String plantcode) async {
    try {
      final response = await http.post(
        Uri.parse("http://114.143.140.28:8020/api/InOut/InOutSaveData"),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $Auth_Token'},
        body: jsonEncode({
          'TransactionDate': TransactionDate, 'TransactionTime': TransactionTime, 'StaffCode': StaffCode,
          'flagValue': FlagValue, 'address': Address, 'latitude': Latitude, 'longitude': Longitude, "plantCode": plantcode
        }),
      );
      return response.body;
    } catch(e) { return null; }
  }

  Future<String?> storeOutEntry(String TransactionDate, String TransactionTime, String StaffCode, String FlagValue, String Address, String Latitude, String Longitude, String plantcode) async {
    try {
      final response = await http.post(
        Uri.parse("http://114.143.140.28:8020/api/InOut/InOutSaveData"),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $Auth_Token'},
        body: jsonEncode({
          'TransactionDate': TransactionDate, 'TransactionTime': TransactionTime, 'StaffCode': StaffCode,
          'flagValue': FlagValue, 'address': Address, 'latitude': Latitude, 'longitude': Longitude, "plantCode": plantcode
        }),
      );
      return response.body;
    } catch(e) { return null; }
  }

  Future<String?> storeNotInZoneEntry(String TransactionDate, String TransactionTime, String StaffCode, String FlagValue, String Address, String Latitude, String Longitude, String plantcode) async {
    try {
      final response = await http.post(
        Uri.parse("http://114.143.140.28:8020/api/InOut/InOutSaveData"),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $Auth_Token'},
        body: jsonEncode({
          'TransactionDate': TransactionDate, 'TransactionTime': TransactionTime, 'StaffCode': StaffCode,
          'flagValue': FlagValue, 'address': Address, 'latitude': Latitude, 'longitude': Longitude, "plantCode": plantcode
        }),
      );
      return response.body;
    } catch(e) { return null; }
  }

  Future<void> checkBiometrics() async {
    try {
      bool canCheck = await auth.canCheckBiometrics;
      if (canCheck) await authenticate();
      else await punchIn();
    } catch (e) { await punchIn(); }
  }

  Future<void> authenticate() async {
    try {
      bool authResult = await auth.authenticate(localizedReason: 'Please authenticate to proceed');
      if (authResult) await punchIn();
    } catch (e) { await punchIn(); }
  }

  Future<void> checkbiometricspunchout() async {
    try {
      bool canCheck = await auth.canCheckBiometrics;
      if (canCheck) await authenticatepunchout();
      else await punchOut();
    } catch (e) { await punchOut(); }
  }

  Future<void> authenticatepunchout() async {
    try {
      bool authResult = await auth.authenticate(localizedReason: 'Please authenticate to proceed');
      if (authResult) await punchOut();
    } catch (e) { await punchOut(); }
  }

  void showPunchSnackbar({
    required bool isPunchIn,
    required bool success,
  }) {
    final now = DateFormat('hh:mm a').format(DateTime.now());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: success
            ? (isPunchIn ? Colors.green : Colors.green)
            : Colors.orange,
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Icon(
              success
                  ? (isPunchIn ? Icons.login : Icons.logout)
                  : Icons.error_outline,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                success
                    ? (isPunchIn
                    ? "Punch In Successful • $now"
                    : "Punch Out Successful • $now")
                    : "Punch action failed",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerItem {
  final String image;
  final String text;
  _BannerItem({required this.image, required this.text});
}
