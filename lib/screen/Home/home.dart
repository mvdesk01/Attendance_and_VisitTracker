import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:attendance_system_ios/bloc/main_bloc.dart';
import 'package:attendance_system_ios/bloc/main_event.dart';
import 'package:attendance_system_ios/bloc/main_state.dart';
import 'package:attendance_system_ios/main.dart';
import 'package:attendance_system_ios/screen/AdminHomeScreen/AdminHome.dart';
import 'package:attendance_system_ios/screen/Gate%20Pass/gate_pass.dart';
import 'package:attendance_system_ios/screen/Home/report.dart';
import 'package:attendance_system_ios/screen/Leave/leave.dart';
import 'package:attendance_system_ios/screen/Login/login_screen.dart';
import 'package:attendance_system_ios/screen/Profile/profile.dart';
import 'package:attendance_system_ios/screen/Remote%20Location/remote_location.dart';
import 'package:attendance_system_ios/screen/Transaction/COff%20Debit/CoffDebitScreen.dart';
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
import 'package:package_info_plus/package_info_plus.dart';

import '../../model/in_out_details.dart';
// import '../CancellationRequest/CancellationRequestScreen.dart';
import '../../service/background_service.dart';
import '../../service/internet_service.dart';
import '../AdminProfile/Databasepunchout.dart';
import '../AdminProfile/Databsepunchin.dart';
import '../Expense/ExpenseScreen.dart';
import '../Settings/Timer.dart';
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
  String todayDate =
  DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now()).substring(0, 10);
  String currentTime = DateFormat('dd-MM-yyyy HH:mm:ss')
      .format(DateTime.now())
      .substring(10, 19);

  static bool isLoading = false;
  String? _currentLat;
  String? _currentLon;
  Position? _currentPosition;
  String? _currentAddress;

  // String formattedDate = DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now());
  // String currentDate = formattedDate.substring(0,10);
  bool isButtonDisabledIn = false;
  bool isButtonDisabledOut = false;

  late String lastInOutTime;
  late String lastInOutTime1;
  String? lastInTime;
  String? lastOutTime;
  LocalAuthentication auth = LocalAuthentication();

  static bool lastPunchIn = true;
  static bool lastPunchOut = true;
  late bool _isLoading = false;
  late MainBloc mainBloc;
  List<Map<String, dynamic>> multiLatLongList = [];
  final storage = FlutterSecureStorage();

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
  String STAFFCODE = "";
  String? atsflag = "";
  String? plantcode = "";

  PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentPage = 0;
  Timer? _bannerTimer;

  bool isTablet = false;

  String appVersion = "";

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

  @override

  ///change3
  void initState() {
    // TODO: implement initState
    super.initState();
    startBannerAutoScroll();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.initialPayload != null) {
        Navigator.of(context).pushReplacementNamed(
          '/track_visit_location',
          arguments: widget.initialPayload,
        );
      }
    });

    ///changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      InternetService()
          .startListening(MyApp.navigatorKey.currentState!.overlay!.context);
    });
    initialize();
    _loadVersion();

    ///change2
    // Future.delayed(const Duration(seconds: 1), () {
    //   if (mounted) {
    //     InternetService().startListening(context);
    //   }
    // });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    appVersion = info.version;
  }

  Future<void> initialize() async {
    await _checkauthorisation();
    await getData();
    await _checkAndRequestLocationPermission();
    await _updateButtonInitialState();
  }

  Future<void> _checkauthorisation() async {
    staffCode = await storage.read(key: 'Staff_Code');

    print("staffCode-->$staffCode");
    Auth_Token = await storage.read(key: 'Auth_Token');

    print("Auth_Token-->${Auth_Token}");
    staffName = await storage.read(key: 'Staff_Name');

    mainBloc
        .add(GetStaffDetailsEvents(StaffCode: staffCode!, token: Auth_Token!));
    //mainBloc.add(GetStaffDetailsEvents(StaffCode: staffCode, token: Auth_Token));
  }

  Future<void> getData() async {
    staffCode = await storage.read(key: 'Staff_Code');

    print("staffCode-->$staffCode");
    Auth_Token = await storage.read(key: 'Auth_Token');

    print("Auth_Token-->" + Auth_Token!);
    staffName = await storage.read(key: 'Staff_Name');

    mainBloc.add(GetUserInfoEvents(Staffcode: staffCode!, token: Auth_Token!));
    mainBloc.add(GetMultiRemoteLocation(Auth_Token!, staffCode!));
    //mainBloc.add(GetStaffDetailsEvents(StaffCode: staffCode, token: Auth_Token));
  }

  Future<void> _checkAndRequestLocationPermission() async {
    // while (true) {
    bool hasPermission = await handleLocationPermission();
    if (!hasPermission) {
      _showSnackbar(
          "Location permission is required! Please allow from settings.");
    }
    // }
    return;
  }

  Future<bool> handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // _showSnackbar("Location services are disabled. Please enable them.");
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // _showSnackbar("Location permission denied! Please allow to proceed.");
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // _showSnackbar("Location permission is permanently denied! Allow manually.");
      return false;
    }

    return true;
  }

  Future<void> _updateButtonInitialState() async {
    // print("inout statuscode inside update");
    final hasPermission = await handleLocationPermission();
    if (!hasPermission) {
      Fluttertoast.showToast(
        msg:
        "Allow location permission from settings to use Punch-In Punch-Out feature!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        fontSize: 14.0,
      );
    }

    setState(() {
      isLoading = true;
    });
    try {
      print("inout statuscode try");

      // Format the date to 'dd/MM/yyyy' format as required by the API
      String formattedFromDate =
      DateFormat('dd/MM/yyyy').format(DateTime.now());
      String formattedToDate = DateFormat('dd/MM/yyyy').format(DateTime.now());

      final response = await http
          .post(
        Uri.parse('http://114.143.140.28:8091/api/InOut/InOutDetails'),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $Auth_Token'
        },
        body: jsonEncode({
          "staffCode": staffCode,
          "fromDate": formattedFromDate,
          "toDate": formattedToDate,
        }),
      )
          .timeout(const Duration(seconds: 15));

      print("home inout details statuscode: ${response.statusCode}");
      print("home inout details body: ${response.body}");
      final Map<String, dynamic> decoded = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        List<dynamic> data = decoded['data'] ?? [];

        List<InOutDetail> details =
        data.map((item) => InOutDetail.fromJson(item)).toList();

        setState(() {
          isLoading = false;
        });

        /// In-Out Button UI update Logic using booleans
        if (details.isNotEmpty) {
          lastInOutTime = details[0].transactionTime!.substring(11, 19);
          if (details.length > 1) {
            lastInOutTime1 = details[1].transactionTime!.substring(11, 19);
          }

          if (details[0].inOut == "IN") {
            setState(() {
              isButtonDisabledIn = true;
              isButtonDisabledOut = false;

              lastPunchIn = false;
              lastPunchOut = true;

              lastInTime = lastInOutTime;
              if (details.length > 1) {
                lastOutTime = lastInOutTime1;
              }
            });
          } else if (details[0].inOut == "OUT") {
            setState(() {
              isButtonDisabledIn = false;
              isButtonDisabledOut = true;

              lastPunchIn = true;
              lastPunchOut = false;

              lastOutTime = lastInOutTime;
              if (details.length > 1) {
                lastInTime = lastInOutTime1;
              }
            });
          }
        }
      } else if (response.statusCode == 400) {
        setState(() {
          isLoading = false;
        });
        if (decoded['message'] == "No Records Found.") {
          setState(() {
            isButtonDisabledIn = false;
            isButtonDisabledOut = true;

            lastInTime = "-";
            lastOutTime = "-";

            showGradientSnackBar(context);
          });
        }
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showMaterialBanner(
          MaterialBanner(
            content: const Text('Error loading page!! Try again'),
            actions: [
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                  _reloadPage();
                },
                child: const Text('TRY AGAIN'),
              ),
            ],
            backgroundColor: Colors.red.shade700,
          ),
        );

        setState(() {
          isButtonDisabledIn = true;
          isButtonDisabledOut = true;
        });
      }
    } on TimeoutException catch (_) {
      setState(() {
        isLoading = false;
        isButtonDisabledIn = true;
        isButtonDisabledOut = true;
      });

      _showRetryBanner();
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error while fetching initial data from api $e");

      ScaffoldMessenger.of(context).showMaterialBanner(
        MaterialBanner(
          content: const Text('Error loading page!! Try again'),
          actions: [
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                _reloadPage();
              },
              child: const Text('TRY AGAIN'),
            ),
          ],
          backgroundColor: Colors.red.shade700,
        ),
      );

      setState(() {
        isButtonDisabledIn = true;
        isButtonDisabledOut = true;
      });
    }
  }

  Future<Position> getCurrentLocaiton() async {
    Position? lastKnownPosition = await Geolocator.getLastKnownPosition();
    if (lastKnownPosition != null) {
      _currentPosition = lastKnownPosition;
      print(
          "start location lat long : ${_currentPosition!.latitude}, ${_currentPosition!.longitude}");
      return _currentPosition!;
    } else {
      _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium);
      print(
          "start location lat long : ${_currentPosition!.latitude}, ${_currentPosition!.longitude}");
      return _currentPosition!;
    }
  }

  void showGradientSnackBar(BuildContext context) {
    // if (!context.mounted) return; // ✅ prevents crash if widget is disposed

    final snackBar = SnackBar(
      content: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.lightBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius:
          BorderRadius.circular(8), // ✅ rounded gradient background
        ),
        padding: EdgeInsets.all(16),
        child: Text(
          'Welcome to Mtech! Start Your Day',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      action: SnackBarAction(
        label: 'OK',
        textColor: Colors.lightGreenAccent,
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
      backgroundColor: Colors.transparent,
      // Use transparent background
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );

    // ScaffoldMessenger.of(context).showSnackBar(snackBar);
    // ✅ Always hide previous snackbar before showing new one
    /*  ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);*/
  }

  void _showRetryBanner() {
    ScaffoldMessenger.of(context)
      ..hideCurrentMaterialBanner()
      ..showMaterialBanner(
        MaterialBanner(
          content: const Text(
            'Unable to connect to server. Please try again.',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                _reloadPage();
              },
              child: const Text(
                'RETRY',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
          backgroundColor: Colors.red.shade700,
        ),
      );
  }

  final ButtonStyle raisedButtonStyle = ElevatedButton.styleFrom(
    foregroundColor: Colors.white, backgroundColor: MyColors.darkBlue,
    minimumSize: const Size(32, 35),
    // padding: EdgeInsets.symmetric(horizontal: 0),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
  );

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void startBannerAutoScroll() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        if (_currentPage < attendanceBanners.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }

        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    mainBloc = BlocProvider.of(context);
    isTablet = MediaQuery.of(context).size.width >= 600;
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GestureDetector(
                onTap: () {
                  Fluttertoast.showToast(
                    msg: "No Notification Found",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                  );
                },
                child: const Icon(Icons.notifications),
              )),
        ],
        iconTheme: const IconThemeData(
          color: Colors.white,
          size: 28,
        ),
        title: const Text("Attendance(kd)"),
        backgroundColor: MyColors.lightBlue,
        centerTitle: true,
        titleTextStyle: GoogleFonts.roboto(
          fontWeight: FontWeight.bold,
          fontSize: 20.0,
        ).copyWith(
          color: Colors.white,
        ),
      ),

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
                color: MyColors.lightBlue,
                child: Column(children: [
                  const Padding(padding: EdgeInsets.symmetric(vertical: 8)),
                  const Text(
                    "Attendance(kd)",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold),
                  ),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 3)),
                  GestureDetector(
                    onTap: () async {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider(
                            create: (context) =>
                                MainBloc(webService: WebService()),
                            child: Profile(),
                          ),
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 52,
                          backgroundImage:
                          AssetImage("assets/icons/profile.png"),
                        ),
                        Text(
                          "${staffName!}",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          " ${staffCode!}",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ])),

            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Home'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (context) => MainBloc(webService: WebService()),
                      child: HomeScreen(),
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.backpack_outlined),
              title: const Text('Leave'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (context) => MainBloc(webService: WebService()),
                      child: PendingLeave(),
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.book_outlined),
              title: const Text('Gate Pass'),
              onTap: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => BlocProvider(
                            create: (context) {
                              return MainBloc(webService: WebService());
                            },
                            child: GatePass())));
                //    Navigator.push(context, MaterialPageRoute(builder: (context) => const GatePass()));
              },
            ),
            // ListTile(
            //   leading: const Icon(Icons.book_outlined),
            //   title: const Text('COff Credit'),
            //   onTap: () {
            //     Navigator.pushReplacement(
            //         context,
            //         MaterialPageRoute(
            //             builder: (_) => BlocProvider(
            //                 create: (context) {
            //                   return MainBloc(webService: WebService());
            //                 },
            //                 child: Coffcreditscreen())));
            //     //    Navigator.push(context, MaterialPageRoute(builder: (context) => const GatePass()));
            //   },
            // ),
            ListTile(
              leading: const Icon(Icons.book_outlined),
              title: const Text('COff Debit'),
              onTap: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => BlocProvider(
                            create: (context) {
                              return MainBloc(webService: WebService());
                            },
                            child: CoffDebitscreen())));
                //    Navigator.push(context, MaterialPageRoute(builder: (context) => const GatePass()));
              },
            ),
            // ListTile(
            //   leading: const Icon(Icons.book_outlined),
            //   title: const Text('Cancellation Request'),
            //   onTap: (){
            //     Navigator.pushReplacement(
            //         context,
            //         MaterialPageRoute(
            //             builder: (_) => BlocProvider(
            //                 create: (context) {
            //                   return MainBloc(
            //                       webService: WebService());
            //                 },
            //                 child: CancellationRequestScreen())));
            //     //    Navigator.push(context, MaterialPageRoute(builder: (context) => const GatePass()));
            //   },
            // ),
            ListTile(
              leading: const Icon(Icons.money_off_outlined),
              title: const Text('Expense Management'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (context) => MainBloc(webService: WebService()),
                      child: Expensemanagmentscreen(),
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.tour_outlined),
              title: const Text('Tour Details'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (context) => MainBloc(webService: WebService()),
                      child: TourPendingScreen(),
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_city_outlined),
              title: const Text('Change to Remote Location'),
              onTap: () {
                // Navigator.push(context, MaterialPageRoute(builder: (context) => const RemoteLocation()));
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (context) => MainBloc(webService: WebService()),
                      child: RemoteLocation(),
                    ),
                  ),
                );
              },
            ),
            const Divider(
              color: Colors.black45,
            ),
            ListTile(
              leading: const Icon(Icons.add_location_alt_outlined),
              title: const Text('Visit Outside'),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => VisitOutside()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: const Text('Start/Stop Visit'),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => VisitStartStopScreen(
                          visit: null,
                        )));
                //  mainBloc.add(GetMinutesOfMeetingFormNoEvents(UserId: "cd03080",SrNo: "844",token: Auth_Token!));
              },
            ),
            /* ListTile(
              leading: const Icon(Icons.location_searching_outlined),
              title: const Text('Track Visit Location'),
              onTap: (){
                Navigator.push(context, MaterialPageRoute(builder: (context) =>  */ /*TrackVisitLocation()*/ /*TrackVisitScreen()));
              },
            ),*/
            ListTile(
              leading: const Icon(Icons.location_history_outlined),
              title: const Text('Visit History'),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => BlocProvider(
                            create: (context) {
                              return MainBloc(webService: WebService());
                            },
                            child: VisitHistoryScreen())));
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (context) => MainBloc(webService: WebService()),
                      child: SettingsPage(),
                    ),
                  ),
                );
              },
            ),
            // ListTile(
            //   leading: const Icon(Icons.admin_panel_settings),
            //   title: const Text('Admin'),
            //   onTap: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder: (_) => BlocProvider(
            //           create: (context) => MainBloc(webService: WebService()),
            //           child: AdminHomeScreen(),
            //         ),
            //       ),
            //     );
            //   },
            // ),
            ListTile(
              leading: const Icon(
                Icons.logout_sharp,
                color: MyColors.darkBlue,
              ),
              title: const Text(
                'Logout',
                style: TextStyle(color: MyColors.darkBlue),
              ),
              onTap: () {
                print("Logout Clicked...");
                showDialog(
                    context: context,
                    builder: (BuildContext context) =>
                        _buildPopupDialogforLogout(context));
              },
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  Divider(color: Colors.grey[300], thickness: 0.8),
                  Text(
                    "App Version $appVersion",
                    style: TextStyle(
                      fontSize: 14,
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


      //Bottom Navigation bar
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books_sharp),
            label: 'Report',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: MyColors.lightBlue,
        onTap: _onItemTapped,
      ),
      // backgroundColor: Theme.of(context).primaryColor,

      // Implement Screens of Bottom Navigation bar Home and Report
      body: _homescreen(),
    );
  }

  Widget _buildPopupDialogforLogout(BuildContext context) {
    return new AlertDialog(
      // title: const Text('Popup example'),
      content: new Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            "Logout",
            style: TextStyle(
                fontSize: 20,
                color: MyColors.appDefaultColorCode,
                fontWeight: FontWeight.bold),
          ),
          SizedBox(
            height: 20,
          ),
          Text(
            "Are you sure you want to Logout Attendance App?",
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
      actions: <Widget>[
        new TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          // textColor: Theme.of(context).primaryColor,
          child: const Text(
            'CANCEL',
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
        new TextButton(
          onPressed: () {
            onLogout();
          },
          // textColor: Theme.of(context).primaryColor,
          child: const Text(
            'CONFIRM',
            style: TextStyle(
              fontSize: 14.0,
              color: MyColors.orangeColorCode,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  _homescreen() {
    return LoadingOverlay(
      isLoading: _isLoading,
      opacity: 0.5,
      color: Colors.white,
      progressIndicator: CircularProgressIndicator(
        backgroundColor: Color(0xFFCE4A6F),
        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
      ),
      child: BlocListener<MainBloc, MainState>(
        listener: (context, state) async {
          if (state is GetStaffDetailsLoadingState) {
            setState(() {
              _isLoading = true;
            });
          } else if (state is GetStaffDetailsLoadedState) {
            setState(() {
              _isLoading = false;
            });

            // if(state.staffDetailsResponse?.message?.errorMessage == "StaffCode is Not Valid.."){
            //     scaffoldMessengerKey.currentState!.showSnackBar(
            //       SnackBar(content: Text("Session Expire. Kindly Login Again"),
            //         action: SnackBarAction(
            //             label: 'Login Again',
            //             onPressed: (){
            //           onLogout();
            //         }),
            //         duration: Duration(days: 2),
            //       ),
            //     );
            // }
          } else if (state is GetStaffDetailsErrorState) {
            setState(() {
              _isLoading = false;
            });
            Fluttertoast.showToast(
              msg: "   Failed To Connect Server...!   ",
              toastLength: Toast.LENGTH_SHORT,
              timeInSecForIosWeb: 1,
            );
          }

          if (state is GetUserinfoLoadingState) {
            setState(() {
              _isLoading = true;
            });
          }
          if (state is GetUserinfoLoadedState) {
            final user = state.profileuserinfo.message;

            setState(() {
              _isLoading = false;
              remotelocation = user!.newRemoteLocation;
              distancecheckglag = user.distanceCheckFlag;
              remotelat = user.remoteLatitude;
              remotelong = user.remoteLongitude;
              addressflag = user.addressapproveFlag;
              atsflag = user.atsCheckflag;
              plantcode = user.plantCode;
            });

            REMOTELOCATION = remotelocation.toString();
            REMOTELAT = remotelat.toString();
            REMOTELONG = remotelong.toString();
            DISTANCEFLAG = distancecheckglag.toString();
            ADDRESSFLAG = addressflag.toString();

            print("hellooo" + REMOTELOCATION);
            print("plantcodee" + plantcode.toString());
          } else if (state is GetUserinfoErrorState) {
            setState(() {
              _isLoading = false;
            });

            Fluttertoast.showToast(
              msg: state.msg,
              toastLength: Toast.LENGTH_SHORT,
            );

            if (state.msg == "User Not Found...") {
              scaffoldMessengerKey.currentState?.showSnackBar(
                SnackBar(
                  content: const Text('Restore Session. Kindly Login Again!!'),
                  action: SnackBarAction(
                    label: 'Login Again',
                    onPressed: onLogout,
                  ),
                  duration: const Duration(days: 1),
                ),
              );
            }
          } else if (state is GetMultiRemoteLocationLoadingState) {
            setState(() {
              isLoading = true;
            });
          } else if (state is GetMultiRemoteLocationLoadedState) {
            if(state.response != null) {
              multiLatLongList = state.response;
            }
            setState(() {
              isLoading = false;
            });
          } else if (state is GetMultiRemoteLocationErrorState) {
            setState(() {
              isLoading = false;
            });
            Fluttertoast.showToast(
              msg: state.msg,
              toastLength: Toast.LENGTH_SHORT,
            );
          }
        },
        child: <Widget>[
          //Home Screen
          SingleChildScrollView(
            child: Stack(
              children: [
                if (isLoading)
                  Container(
                    color: Colors.black54, // Add a semi-transparent background
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white), // Customize the color
                      ),
                    ),
                  ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  staffName!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Staff Code: $staffCode",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => const Profile()));
                            },
                            child: CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.blue.shade100,
                              child: const Icon(
                                Icons.person_outline,
                                color: Colors.blue,
                                size: 26,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    ///old
/*
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      // mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16, width: 0,),
                            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
                              child:  Text(staffName!, style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'Dubai',
                                color: Colors.black87,
                              ),),
                            ),
                            Row(
                              children: [
                                const SizedBox(width: 18,),
                                const Padding(padding: EdgeInsets.zero,
                                  child: Text("Staff Code: ", style: TextStyle(fontSize: 14, fontFamily: 'Dubai', color: Colors.black54),),
                                ),
                                Padding(padding: EdgeInsets.zero,
                                  child: Text(staffCode!, style: TextStyle(fontSize: 14, fontFamily: 'Dubai', color: Colors.black87),),
                                ),
                              ],
                            ),

                          ],
                        ),

                        // const SizedBox(width: 100,),
                        Padding(padding: const EdgeInsets.symmetric(horizontal: 10),),
                        Flexible(
                          child:  Image.asset("assets/icons/mtechlogo2.png",
                            // width: double.nan,
                            height: 70,
                          ),
                        ),
                        // ),

                      ],
                    ),
*/

                    SizedBox(
                      height: isTablet ? 300 : 210,
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
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            elevation: 5,
                            child: Stack(
                              children: [
                                /// Banner Image
                                Image.asset(
                                  banner.image,
                                  height: isTablet ? 300 : 220,
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

                    const SizedBox(
                      height: 10,
                    ),

                    /// Mark your attendance
                    if (addressflag == 'Y') markYourAttendance(),

                    const SizedBox(
                      height: 10,
                    ),

                    /// visit management
                    visitManagementUI(),

                    /// Other
                    Card.outlined(
                      color: Colors.blue[50],
                      // elevation: 5,
                      margin: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 15, vertical: 8),
                            child: Text(
                              "Other ",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87 /*fontFamily:'Dubai'*/),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => BlocProvider(
                                          create: (context) {
                                            return MainBloc(
                                                webService: WebService());
                                          },
                                          child: const PendingLeave())));
                            },
                            child: Card.filled(
                              color: Colors.white,
                              elevation: 2,
                              margin: const EdgeInsets.all(14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.blueAccent
                                              .withOpacity(0.1),
                                          borderRadius:
                                          BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.backpack_outlined,
                                          size: 28,
                                          color: Colors.blueAccent,
                                        )),
                                    const SizedBox(
                                      width: 16,
                                    ),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Leave",
                                            style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.black87,
                                                fontWeight: FontWeight.w600),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Check status and apply for leave',
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.black54),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios_rounded,
                                        color: MyColors.lighterBlue),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => BlocProvider(
                                          create: (context) {
                                            return MainBloc(
                                                webService: WebService());
                                          },
                                          child: const GatePass())));
                            },
                            child: Card.filled(
                              color: Colors.white,
                              elevation: 2,
                              margin: const EdgeInsets.all(14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.blueAccent
                                              .withOpacity(0.1),
                                          borderRadius:
                                          BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.book_outlined,
                                          size: 28,
                                          color: Colors.blueAccent,
                                        )),
                                    const SizedBox(
                                      width: 16,
                                    ),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Gate Pass",
                                            style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.black87,
                                                fontWeight: FontWeight.w600),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Check status and apply for gate pass',
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.black54),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios_rounded,
                                        color: MyColors.lighterBlue),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          /// Report Screen..   Report Screen..   Report Screen..
          const Center(child: AttendanceReport())
        ][_selectedIndex],
      ),
    );
  }

  Widget markYourAttendance() {
    return Card.outlined(
      color: Colors.blue[50],
      margin: const EdgeInsets.all(15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: Text(
              "Mark Your Attendance",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      Dialog errorDialog = Dialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0)),
                        //this right here
                        child: Container(
                          height: 230.0,
                          width: 230.0,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              const Padding(
                                padding: EdgeInsets.all(5.0),
                                child: Text(
                                  'Marking Your Attendance',
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(0.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      "assets/icons/In01.png",
                                      // height: 240,
                                      width: 80,
                                    ),
                                    const Text(
                                      "Punch IN",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17),
                                    ),
                                  ],
                                ),
                              ),
                              const Padding(
                                  padding: EdgeInsets.only(top: 10.0)),
                              ElevatedButton(
                                style: raisedButtonStyle,
                                onPressed: isButtonDisabledIn
                                    ? null
                                    : () async {
                                  Navigator.of(context).pop();
                                  setState(() {
                                    isLoading =
                                    true; // Show progress indicator
                                  });
                                  await checkBiometrics();
                                  //await punchIn();
                                  setState(() {
                                    isLoading =
                                    false; // Show progress indicator
                                  });
                                },
                                child: const Text("OK"),
                                /* isLoading
                                          ? CircularProgressIndicator()
                                          : Text("OK"),*/
                              ),
                              /*  if (isLoading)
                                           Container(
                                             color: Colors.black54, // Add a semi-transparent background
                                             child: Center(
                                               child: CircularProgressIndicator(
                                                 valueColor: AlwaysStoppedAnimation<Color>(Colors.white), // Customize the color
                                               ),
                                             ),
                                           ),*/
                              /*   TextButton(onPressed: () {
                                  Navigator.of(context).pop();
                                  },
                                  child: const Text('OK', style: TextStyle(color: MyColors.darkBlue, fontSize: 16.0),),),*/
                            ],
                          ),
                        ),
                      );
                      showDialog(
                          context: context,
                          builder: (BuildContext context) => errorDialog);
                    }, //onTap
                    child: Container(
                      width: 130,
                      height: 144,
                      child: Card.filled(
                        color: Colors.white,
                        clipBehavior: Clip.antiAliasWithSaveLayer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        elevation: 8,
                        margin: const EdgeInsets.all(10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Image.asset(
                              "assets/icons/In01.png",
                              // height: 240,
                              width: 80,
                            ),
                            const Text(
                              "IN",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 17),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Text(
                          "Last IN: ",
                          style: TextStyle(
                              color: Colors.blueGrey,
                              fontSize: 14,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "${lastInTime ?? '-'}",
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: lastPunchIn
                                  ? Colors.blueGrey
                                  : Colors.greenAccent[400]),
                        )
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 25),
              Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      Dialog errorDialog = Dialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0)),
                        //this right here
                        child: Container(
                          height: 230.0,
                          width: 230.0,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              const Padding(
                                padding: EdgeInsets.all(5.0),
                                child: Text(
                                  'Marking Your Attendance',
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(0.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      "assets/icons/out01.png",
                                      // height: 240,
                                      width: 80,
                                    ),
                                    const Text(
                                      "Punch OUT",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17),
                                    ),
                                  ],
                                ),
                              ),
                              const Padding(
                                  padding: EdgeInsets.only(top: 10.0)),
                              ElevatedButton(
                                style: raisedButtonStyle,
                                onPressed: isButtonDisabledOut
                                    ? null
                                    : () async {
                                  Navigator.of(context).pop();
                                  setState(() {
                                    isLoading =
                                    true; // Show progress indicator
                                  });
                                  await checkbiometricspunchout();
                                  //await punchOut();
                                  setState(() {
                                    isLoading =
                                    false; // Show progress indicator
                                  });
                                },
                                child: const Text("OK"),
                              ),
                              /*   TextButton(onPressed: () {
                                  Navigator.of(context).pop();
                                  },
                                  child: const Text('OK', style: TextStyle(color: MyColors.darkBlue, fontSize: 16.0),),),*/
                            ],
                          ),
                        ),
                      );
                      showDialog(
                          context: context,
                          builder: (BuildContext context) => errorDialog);
                    },
                    child: Container(
                      width: 130,
                      height: 144,
                      child: Card.filled(
                        color: Colors.white,
                        clipBehavior: Clip.antiAliasWithSaveLayer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        elevation: 8,
                        margin: const EdgeInsets.all(10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Image.asset(
                              "assets/icons/out01.png",
                              // height: 240,
                              width: 80,
                            ),
                            const Text(
                              "OUT",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 17),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          Text(
                            "Last OUT: ",
                            style: TextStyle(
                                color: Colors.blueGrey,
                                fontSize: 14,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "${lastOutTime ?? '-'}",
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: lastPunchOut
                                    ? Colors.blueGrey
                                    : Colors.greenAccent[400]),
                          )
                        ],
                      )),
                ],
              ),
            ],
          ),
          Expanded(
            flex: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              // mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Check attendance report here  ",
                  style: TextStyle(
                      color: MyColors.fontBlue,
                      fontFamily: 'Dubai',
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
                Padding(
                  padding: EdgeInsets.all(0.1),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: MyColors.fontBlue),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AttendanceReport()));
                    },
                    child: const Text(
                      "Report",
                      style: TextStyle(fontSize: 13, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 5))
        ],
      ),
    );
  }

  Widget visitManagementUI() {
    return Card.outlined(
      color: Colors.blue[50],
      // elevation: 5,
      margin: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: Text(
              "Visit Management",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const VisitOutside()));
            },
            child: Card.filled(
              color: Colors.white,
              elevation: 2,
              margin: const EdgeInsets.all(14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.add_location_alt_outlined,
                          size: 28,
                          color: Colors.blueAccent,
                        )),
                    // const SizedBox(width: 8,),

                    const SizedBox(
                      width: 16,
                    ),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Visit Outside",
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Schedule your visit',
                            style:
                            TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),

                    // const Spacer(),
                    // const Padding(padding: EdgeInsets.symmetric(horizontal: 10),
                    /*child:*/
                    Icon(Icons.arrow_forward_ios_rounded,
                        color: MyColors.lighterBlue),
                    // ),
                  ],
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => VisitStartStopScreen(visit: null)));
            },
            child: Card.filled(
              color: Colors.white,
              elevation: 2,
              margin: const EdgeInsets.all(14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.location_on_outlined,
                          size: 28,
                          color: Colors.blueAccent,
                        )),
                    // const SizedBox(width: 8,),

                    const SizedBox(
                      width: 16,
                    ),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Start-Stop Visit",
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Start and Stop your active visit',
                            style:
                            TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),

                    // const Spacer(),
                    // const Padding(padding: EdgeInsets.symmetric(horizontal: 10),
                    /*child:*/
                    Icon(Icons.arrow_forward_ios_rounded,
                        color: MyColors.lighterBlue),
                    // ),
                  ],
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => BlocProvider(
                          create: (context) {
                            return MainBloc(webService: WebService());
                          },
                          child: const VisitHistoryScreen())));
            },
            child: Card.filled(
              color: Colors.white,
              elevation: 2,
              margin: const EdgeInsets.all(14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.location_history_outlined,
                          size: 28,
                          color: Colors.blueAccent,
                        )),
                    const SizedBox(
                      width: 16,
                    ),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Visit History",
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Track your visit history location',
                            style:
                            TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: MyColors.lighterBlue),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _reloadPage() {
    _updateButtonInitialState();
    // setState(() {
    //   isLoading = true;
    // });
    //
    // // Simulate a network request or page reload with a delay
    // Future.delayed(Duration(seconds: 2), () {
    //   setState(() {
    //     isLoading = false;
    //   });
    //   _updateButtonInitialState();
    // });
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }

  Future<void> punchIn() async {
    bool hasPermission = await handleLocationPermission();

    if (!hasPermission) {
      _showSnackbar(
          "Location permission required for Punch In!.Please allow from settings");
      return;
    }

    if (DISTANCEFLAG == 'Y') {
      try {
        await LocationHandler.checkIfInZone();
        _currentLat = LocationHandler.currentLat.toString();
        _currentLon = LocationHandler.currentLon.toString();
        _currentAddress = LocationHandler.currentAddress;
        LogFileManager.writeLog("punch in N y else" +
            _currentLat! +
            _currentLon! +
            _currentAddress!);

        String currentDate = DateFormat('dd-MM-yyyy HH:mm:ss')
            .format(DateTime.now())
            .substring(0, 19);
        String currentTime = DateFormat('dd-MM-yyyy HH:mm:ss')
            .format(DateTime.now())
            .substring(11, 19);
        String currentDateTime = DateFormat('dd-MM-yyyy HH:mm:ss')
            .format(DateTime.now())
            .substring(0, 19);
        // await retorepunchdata();
        if (await getInEntryFromDataBase(
            currentDate, currentTime, staffCode!)) {
          String? result = await storeInEntry(
              currentDate,
              currentDateTime,
              staffCode!,
              "001",
              _currentAddress!,
              _currentLat!,
              _currentLon!,
              plantcode?.toString() ?? "01");

          print("result $result");

          // After successful operation, show a SnackBar
          setState(() {
            isButtonDisabledIn = true;
            isButtonDisabledOut = false;
            _updateButtonInitialState();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: const Text('Punch-in Successful!'),
                action: SnackBarAction(
                    label: 'OK',
                    onPressed: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    }),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3)),
          );
          LogFileManager.writeLog("punch in flag Y try if: $result");
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: const Text('Already Marked!! or First Punch Out!!'),
                action: SnackBarAction(
                    label: 'X',
                    onPressed: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    }),
                backgroundColor: Colors.redAccent,
                duration: const Duration(seconds: 3)),
          );
          LogFileManager.writeLog("punch in flag Y try else ");
        }
      } catch (e) {
        print("Error: $e");

        // If there is an error, show a SnackBar with the error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Punch-in failed! Please try again.'),
              duration: const Duration(seconds: 3)),
        );
        print(_currentLat);
        print(_currentLon);
        print(_currentAddress);
        print(staffCode);
        print("actual location flag N catch $e");
        LogFileManager.writeLog("actual location flag N catch $e");
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      if (ADDRESSFLAG == 'Y') {
        LocationHandler.changeToRemoteLocation();
        LocationHandler.remoteZoneLat = double.parse(REMOTELAT);
        LocationHandler.remoteZoneLon = double.parse(REMOTELONG);
        LocationHandler.multiLatLong = multiLatLongList;
        // _currentAddress = REMOTELOCATION.toString();
        bool ifInZone = await LocationHandler.checkIfInZone();
        print(ifInZone);
        if (ifInZone) {
          // Simulate API calls
          try {
            _currentLat = LocationHandler.currentLat.toString();
            _currentLon = LocationHandler.currentLon.toString();
            _currentAddress = LocationHandler.currentAddress;
            LogFileManager.writeLog(
                "punch in Y" + _currentLat! + _currentLon! + _currentAddress!);

            String currentDate = DateFormat('dd-MM-yyyy HH:mm:ss')
                .format(DateTime.now())
                .substring(0, 19);
            String currentTime = DateFormat('dd-MM-yyyy HH:mm:ss')
                .format(DateTime.now())
                .substring(11, 19);
            String currentDateTime = DateFormat('dd-MM-yyyy HH:mm:ss')
                .format(DateTime.now())
                .substring(0, 19);
//if (await getOutEntryFromDataBase(currentDate, currentTime, staffCode!))
//             await retorepunchdata();
            if (await getInEntryFromDataBase(
                currentDate, currentTime, staffCode!)) {
              String? result = await storeInEntry(
                  currentDate,
                  currentDateTime,
                  staffCode!,
                  "001",
                  _currentAddress!,
                  _currentLat!,
                  _currentLon!,
                  plantcode?.toString() ?? "01");
              print(currentDate);
              print(currentTime);
              print(currentDateTime);
              print(_currentAddress);
              // After successful operation, show a SnackBar
              setState(() {
                isButtonDisabledIn = true;
                isButtonDisabledOut = false;
                _updateButtonInitialState();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: const Text('Punch-in Successful!'),
                    action: SnackBarAction(
                        label: 'OK',
                        onPressed: () {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        }),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 3)),
              );
              LogFileManager.writeLog("punch-in marked: $result");
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                    const Text('Already Marked!! or First Punch Out!!'),
                    action: SnackBarAction(
                        label: 'X',
                        onPressed: () {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        }),
                    backgroundColor: Colors.redAccent,
                    duration: const Duration(seconds: 3)),
              );
            }
            LogFileManager.writeLog("punch in flag N else if else");
          } catch (e) {
            print("Error: $e");

            // If there is an error, show a SnackBar with the error message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Punch-in failed! Please try again.'),
                  duration: const Duration(seconds: 3)),
            );
            LogFileManager.writeLog("punch in flag N else catch Error: $e");
          } finally {
            setState(() {
              isLoading = false;
            });
          }
        } else {
          _currentLat = LocationHandler.currentLat.toString();
          _currentLon = LocationHandler.currentLon.toString();
          _currentAddress = LocationHandler.currentAddress;
          String currentDate = DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now()).substring(0, 19);
          String currentDateTime = DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now()).substring(0, 19);

          String? result = await storeNotInZoneEntry(
              currentDate,
              currentDateTime,
              staffCode!,
              "002",
              _currentAddress!,
              _currentLat!,
              _currentLon!,
              plantcode?.toString() ?? "01");

          Fluttertoast.showToast(
              msg: "Not in zone!!",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 1,
              // textColor: Colors.white,
              fontSize: 12.0);
          LogFileManager.writeLog("Not-in-zone entry marked: $result");
          print("Not in zone");
        }
      } else {
        Fluttertoast.showToast(
            msg: "Admin approval to mark attendance is pending!!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            // textColor: Colors.white,
            fontSize: 12.0);
        print("Admin approval to mark attendance is pending!!");
        LogFileManager.writeLog(
            "Admin approval to mark attendance is pending!!");
      }
    }
  }

  Future<void> punchOut() async {
    bool hasPermission = await handleLocationPermission();
    if (!hasPermission) {
      _showSnackbar(
          "Location permission required for Punch In!.Please allow from settings");
      return;
    }

    if (DISTANCEFLAG == 'Y') {
      try {
        await LocationHandler.checkIfInZone();
        _currentLat = LocationHandler.currentLat.toString() ?? '';
        _currentLon = LocationHandler.currentLon.toString();
        _currentAddress = LocationHandler.currentAddress;
        LogFileManager.writeLog("punch out N y else" +
            _currentLat! +
            _currentLon! +
            _currentAddress!);

        String currentDate = DateFormat('dd-MM-yyyy HH:mm:ss')
            .format(DateTime.now())
            .substring(0, 19);
        String currentTime = DateFormat('dd-MM-yyyy HH:mm:ss')
            .format(DateTime.now())
            .substring(11, 19);
        String currentDateTime = DateFormat('dd-MM-yyyy HH:mm:ss')
            .format(DateTime.now())
            .substring(0, 19);
        // await retorepunchoutdata();

        if (await getOutEntryFromDataBase(
            currentDate, currentTime, staffCode!)) {
          String? result = await storeOutEntry(
              currentDate,
              currentDateTime,
              staffCode!,
              "000",
              _currentAddress!,
              _currentLat!,
              _currentLon!,
              plantcode?.toString() ?? "01");

          print("result $result");

          // After successful operation, show a SnackBar
          setState(() {
            isButtonDisabledIn = true;
            isButtonDisabledOut = false;
            _updateButtonInitialState();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: const Text('Punch-out Successful!'),
                action: SnackBarAction(
                    label: 'OK',
                    onPressed: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    }),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3)),
          );
          LogFileManager.writeLog("punch out acual location try: $result");
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: const Text('Already Marked!! or First Punch Out!!'),
                action: SnackBarAction(
                    label: 'X',
                    onPressed: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    }),
                backgroundColor: Colors.redAccent,
                duration: const Duration(seconds: 3)),
          );
          LogFileManager.writeLog("punch out actual location try else");
        }
      } catch (e) {
        print("Error: $e");

        // If there is an error, show a SnackBar with the error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Punch-out failed! Please try again.'),
              duration: const Duration(seconds: 3)),
        );
        LogFileManager.writeLog("punch out actual location catch: $e");
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      if (ADDRESSFLAG == 'Y') {
        LocationHandler.changeToRemoteLocation();
        LocationHandler.remoteZoneLat = double.parse(REMOTELAT);
        LocationHandler.remoteZoneLon = double.parse(REMOTELONG);
        LocationHandler.multiLatLong = multiLatLongList;
        // _currentAddress = REMOTELOCATION.toString();
        bool ifInZone = await LocationHandler.checkIfInZone();
        if (ifInZone) {
          try {
            _currentLat = LocationHandler.currentLat.toString();
            _currentLon = LocationHandler.currentLon.toString();
            _currentAddress = LocationHandler.currentAddress;
            LogFileManager.writeLog("punch out else y" +
                _currentLat! +
                _currentLon! +
                _currentAddress!);

            String currentDate = DateFormat('dd-MM-yyyy HH:mm:ss')
                .format(DateTime.now())
                .toString()
                .substring(0, 19);
            String currentTime = DateFormat('dd-MM-yyyy HH:mm:ss')
                .format(DateTime.now())
                .toString()
                .substring(11, 19);
            String currentDateTime = DateFormat('dd-MM-yyyy HH:mm:ss')
                .format(DateTime.now())
                .toString()
                .substring(0, 19);
            // await retorepunchoutdata();

            if (await getOutEntryFromDataBase(
                currentDate, currentTime, staffCode!)) {
              String? result = await storeOutEntry(
                  currentDate,
                  currentDateTime,
                  staffCode!,
                  "000",
                  _currentAddress!,
                  _currentLat!,
                  _currentLon!,
                  plantcode?.toString() ?? "01");

              setState(() {
                isButtonDisabledOut = true;
                isButtonDisabledIn = false;
                _updateButtonInitialState();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Punch-out Successful!'),
                  action: SnackBarAction(
                      label: 'OK',
                      onPressed: () {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      }),
                  backgroundColor: Colors.green,
                ),
              );
              LogFileManager.writeLog(
                  "punch out remote location flagN else  try: $result");
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: const Text('Already Marked!! or First Punch In!!'),
                    action: SnackBarAction(
                        label: 'X',
                        onPressed: () {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        }),
                    backgroundColor: Colors.redAccent,
                    duration: const Duration(seconds: 3)),
              );
              LogFileManager.writeLog(
                  "punch out remote location fllag N else else");
            }
          } catch (e) {
            print("Error: $e");

            // If there is an error, show a SnackBar with the error message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Punch-out failed! Please try again.'),
                  duration: const Duration(seconds: 3)),
            );
            LogFileManager.writeLog(
                "punch out remote location flagN else  catch: $e");
          } finally {
            setState(() {
              isLoading = false;
            });
          }
        } else {
          _currentLat = LocationHandler.currentLat.toString();
          _currentLon = LocationHandler.currentLon.toString();
          _currentAddress = LocationHandler.currentAddress;
          String currentDate = DateFormat('dd-MM-yyyy HH:mm:ss')
              .format(DateTime.now())
              .substring(0, 19);
          String currentDateTime = DateFormat('dd-MM-yyyy HH:mm:ss')
              .format(DateTime.now())
              .substring(0, 19);
          String? result = await storeNotInZoneEntry(
              currentDate,
              currentDateTime,
              staffCode!,
              "002",
              _currentAddress!,
              _currentLat!,
              _currentLon!,
              plantcode?.toString() ?? "01");
          Fluttertoast.showToast(
              msg: "Not in zone!!",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 1,
              // textColor: Colors.white,
              fontSize: 12.0);
          print("Not in zone");
          LogFileManager.writeLog("NotInZone Entry is marked: $result");
        }
      } else {
        Fluttertoast.showToast(
            msg: "Admin approval to mark attendance is pending!!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            // textColor: Colors.white,
            fontSize: 12.0);
        print("Admin approval to mark attendance is pending!!");
        LogFileManager.writeLog(
            "Admin approval to mark attendance is pending!!");
      }
    }
  }

  Future<bool> getInEntryFromDataBase(
      String TransactionDate, String TransactionTime, String StaffCode) async {
    try {
      final response = await http.post(
        Uri.parse("http://114.143.140.28:8091/api/InOut/InOutLastFlag"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $Auth_Token',
        },
        body: jsonEncode(<String, String>{
          'TransactionDate': TransactionDate,
          'StaffCode': StaffCode,
          // 'TransactionTime': TransactionTime,
        }),
      );
      print("response getInEntryFromDataBase ${response.body}");
      final Map<String, dynamic> res = json.decode(response.body);
      print("res getInEntryFromDataBase $res");
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (res['data'] == "000") {
          // LogFileManager.writeLog("get in entry $res");
          return true;
        } else {
          LogFileManager.writeLog("Last punch entry already present $response");
          return false;
        }
      } else if (response.statusCode == 400) {
        if (res['message'] == "No Record Found.") {
          // LogFileManager.writeLog("get in entry $res");
          return true;
        }
        print(
            'Api failed last Punch-in entry ${response.statusCode}, ${response.body}');
        return false;
      } else {
        LogFileManager.writeLog(
            "Failed to fetch last Punch-in entry ${response.statusCode}, ${response.body}");
        return false;
      }
    } catch (e) {
      LogFileManager.writeLog("Error in getInEntryFrom Database: $e");
      print("Error in getInEntryFrom Database: $e");
      return false;
    }
  }

  Future<bool> getOutEntryFromDataBase(
      String TransactionDate, String TransactionTime, String StaffCode) async {
    final response = await http.post(
      Uri.parse("http://114.143.140.28:8091/api/InOut/InOutLastFlag"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $Auth_Token',
      },
      body: jsonEncode(<String, String>{
        'TransactionDate': TransactionDate,
        'StaffCode': StaffCode,
        // 'TransactionTime': TransactionTime,
      }),
    );
    print("response getOutEntryFromDataBase ${response.body}");
    final Map<String, dynamic> res = json.decode(response.body);
    print("res getOutEntryFromDataBase $res");
    if (response.statusCode == 201 || response.statusCode == 200) {
      if (res['data'] == "001") {
        // LogFileManager.writeLog("get in entry $res");
        return true;
      } else {
        LogFileManager.writeLog("Last punch entry already present $response");
        return false;
      }
    } else {
      LogFileManager.writeLog("getOutEntryFromDataBase exception $res");
      return false;
    }
  }

  Future<String?> storeInEntry(
      String TransactionDate,
      String TransactionTime,
      String StaffCode,
      String FlagValue,
      String Address,
      String Latitude,
      String Longitude,
      String plantcode) async {
    try {
      print("plantcode" + plantcode);
      final response = await http.post(
        Uri.parse("http://114.143.140.28:8091/api/InOut/InOutSaveData"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $Auth_Token',
        },
        body: jsonEncode(<String, String>{
          'TransactionDate': TransactionDate,
          'TransactionTime': TransactionTime,
          'StaffCode': StaffCode,
          'flagValue': FlagValue,
          'address': Address,
          'latitude': Latitude,
          'longitude': Longitude,
          "plantCode": plantcode
        }),
      );
      print("punch-in response body" + response.body);
      print("punch-in response status code" + response.statusCode.toString());

      if (response.statusCode == 201 || response.statusCode == 200) {
        LogFileManager.writeLog("storeinentry $response");
        if (atsflag == 'Y') {
          try {
            final response = await http.post(
              Uri.parse(
                  "https://m-techinnovations.co.in/PersonTrackingAPI/API/SaveDetailsTLS"),
              headers: <String, String>{
                'Content-Type': 'application/json; charset=UTF-8',
              },
              body: jsonEncode(<String, String>{
                'TransactionDate': TransactionDate,
                'TransactionTime': TransactionTime,
                'StaffCode': StaffCode,
                'FlagValue': FlagValue,
                'Address': Address,
                'Latitude': Latitude,
                'Longitude': Longitude
              }),
            );
            print(response.body);
            if (response.statusCode == 201) {
              LogFileManager.writeLog("storeinentry $response");
              return json.decode(response.body).toString();
            } else {
              LogFileManager.writeLog("storeinentry else");
              // sqlitePunchIN(TransactionDate,TransactionTime,StaffCode,FlagValue,Address,Latitude,Longitude);
              return json.decode(response.body).toString();
              //throw Exception('Failed to store entry');
            }
          } catch (e) {
            //sqlitePunchIN(TransactionDate,TransactionTime,StaffCode,FlagValue,Address,Latitude,Longitude);
            LogFileManager.writeLog('Error in Store InEntry: $e');
          }
        }
        return json.decode(response.body).toString();
      } else {
        LogFileManager.writeLog("storeinentry else");
        // sqlitePunchIN(TransactionDate,TransactionTime,StaffCode,FlagValue,Address,Latitude,Longitude);
        return json.decode(response.body).toString();
        //throw Exception('Failed to store entry');
      }
    } catch (e) {
      // sqlitePunchIN(TransactionDate,TransactionTime,StaffCode,FlagValue,Address,Latitude,Longitude);
      LogFileManager.writeLog('Error in Store Punch-In Entry: $e');
    }
  }

  Future<String?> storeOutEntry(
      String TransactionDate,
      String TransactionTime,
      String StaffCode,
      String FlagValue,
      String Address,
      String Latitude,
      String Longitude,
      String plantcode) async {
    try {
      print("plantcodeout" + plantcode);
      final response = await http.post(
        Uri.parse("http://114.143.140.28:8091/api/InOut/InOutSaveData"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $Auth_Token',
        },
        body: jsonEncode(<String, String>{
          'TransactionDate': TransactionDate,
          'TransactionTime': TransactionTime,
          'StaffCode': StaffCode,
          'flagValue': FlagValue,
          'address': Address,
          'latitude': Latitude,
          'longitude': Longitude,
          "plantCode": plantcode
        }),
      );
      print("punch-out response body" + response.body);
      print("punch-out response status code" + response.statusCode.toString());
      if (response.statusCode == 201 || response.statusCode == 200) {
        LogFileManager.writeLog("storeoutentry $response");
        if (atsflag == 'Y') {
          try {
            final response = await http.post(
              Uri.parse(
                  "https://m-techinnovations.co.in/PersonTrackingAPI/API/SaveDetailsTLS"),
              headers: <String, String>{
                'Content-Type': 'application/json; charset=UTF-8',
              },
              body: jsonEncode(<String, String>{
                'TransactionDate': TransactionDate,
                'TransactionTime': TransactionTime,
                'StaffCode': StaffCode,
                'FlagValue': FlagValue,
                'Address': Address,
                'Latitude': Latitude,
                'Longitude': Longitude
              }),
            );
            print(response.body);
            if (response.statusCode == 201) {
              LogFileManager.writeLog("storeinentry $response");
              return json.decode(response.body).toString();
            } else {
              LogFileManager.writeLog("storeinentry else");
              sqlitePunchIN(TransactionDate, TransactionTime, StaffCode,
                  FlagValue, Address, Latitude, Longitude);
              return json.decode(response.body).toString();
              //throw Exception('Failed to store entry');
            }
          } catch (e) {
            //sqlitePunchIN(TransactionDate,TransactionTime,StaffCode,FlagValue,Address,Latitude,Longitude);
            LogFileManager.writeLog('Error in Store InEntry: $e');
          }
        }
        return json.decode(response.body).toString();
      } else {
        LogFileManager.writeLog("storeoutentry else");
        // sqlitePunchOUT(TransactionDate,TransactionTime,StaffCode,"000",Address,Latitude,Longitude);
        throw Exception('Failed to store entry');
      }
    } catch (e) {
      LogFileManager.writeLog("Error in Store Punch-Out Entry: $e");
      // sqlitePunchOUT(TransactionDate,TransactionTime,StaffCode,"000",Address,Latitude,Longitude);
      print("Error in Store Punch-Out Entry: $e");
    }
  }

  Future<String?> storeNotInZoneEntry(
      String TransactionDate,
      String TransactionTime,
      String StaffCode,
      String FlagValue,
      String Address,
      String Latitude,
      String Longitude,
      String plantcode) async {
    try {
      final response = await http.post(
        Uri.parse("http://114.143.140.28:8091/api/InOut/InOutSaveData"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $Auth_Token',
        },
        body: jsonEncode(<String, String>{
          'TransactionDate': TransactionDate,
          'TransactionTime': TransactionTime,
          'StaffCode': StaffCode,
          'flagValue': FlagValue,
          'address': Address,
          'latitude': Latitude,
          'longitude': Longitude,
          "plantCode": plantcode
        }),
      );
      print("storeNotInZoneEntry response body" + response.body);
      print("storeNotInZoneEntry response status code" +
          response.statusCode.toString());
      if (response.statusCode == 201 || response.statusCode == 200) {
        LogFileManager.writeLog("storeNotInZoneEntry $response");
        return json.decode(response.body).toString();
      } else {
        LogFileManager.writeLog(
            "storeNotInZoneEntry is not stored, unexpected error");
        // sqlitePunchOUT(TransactionDate,TransactionTime,StaffCode,"000",Address,Latitude,Longitude);
        throw Exception('Failed to store entry');
      }
    } catch (e) {
      LogFileManager.writeLog("Error in Store storeNotInZoneEntry Entry: $e");
      // sqlitePunchOUT(TransactionDate,TransactionTime,StaffCode,"000",Address,Latitude,Longitude);
      print("Error in Store storeNotInZoneEntry Entry: $e");
    }
  }

  /// ------------------------------ other functions -------------------------------------

  Future<void> stopVisit() async {
    // await service.stopSelf();
    // await locationStream?.cancel();
    // locationStream = null;

    try {
      await storage.delete(key: 'SelectedVisit');
      // ✅ Update global state only
      VisitState.isVisitRunning.value = false;

      BackgroundService backgroundService = BackgroundService();
      backgroundService.stopService();
      // ❗️ Manually cancel the notification (especially for iOS)
      await FlutterLocalNotificationsPlugin()
          .cancel(foregroundServiceNotificationId);
      if (Platform.isIOS) {
        await NativeLocationBridge
            .stopNativeTracking(); // 👈 Native ios stop tracking
      }
    } catch (e) {
      print("stop visit at Logout $e");
      LogFileManager.writeLog("stop visit at Logout $e");
    }
  }

  Future<bool> showStopVisitDialogBox(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Stop Visit Tracking"),
          content:
          const Text("Are you sure you want to stop tracking the visit?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // ❌ Cancel
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                stopVisit();
                Navigator.of(context).pop(true); // ✅ OK
              },
              child: const Text("Ok"),
            ),
          ],
        );
      },
    );
    return result ?? false; // Return false if dismissed
  }

  void onLogout() async {
    if (VisitState.isVisitRunning.value) {
      bool result = await showStopVisitDialogBox(context);
      if (!result) {
        return;
      }
    }

    // Clear the secure storage
    await clearAllSecureStorage();

    // , navigate the user to the login screen or any other screen
    Navigator.pop(context);

    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => BlocProvider(
              create: (context) {
                return MainBloc(webService: WebService());
              },
              child: LoginScreen()),
        ),
            (Route<dynamic> route) => false);
  }

  // Function to clear specific keys
  Future<void> clearSecureStorage() async {
    await storage.delete(key: 'Auth_Token'); // Delete auth token
    await storage.delete(key: 'Staff_Code'); // Delete staff code
    await storage.delete(key: 'Staff_Name'); // Delete staff name
    await storage.delete(
        key: 'username'); // Delete username (if used for remember me)
    await storage.delete(
        key: 'password'); // Delete password (if used for remember me)
  }

// Or to clear all stored data
  Future<void> clearAllSecureStorage() async {
    await storage.deleteAll(); // Clear all stored data
  }

  Future<void> retorepunchdata() async {
    final dbHelper = DatabaseHelper();
    List<Map<String, dynamic>> offlineEntries =
    await dbHelper.getOfflinePunchEntries();

    for (var entry in offlineEntries) {
      try {
        final response = await http.post(
          Uri.parse(
              "https://m-techinnovations.co.in/PersonTrackingAPI/API/SaveDetails"),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode({
            'TransactionDate': entry['transaction_date'],
            'TransactionTime': entry['transaction_time'],
            'StaffCode': entry['staff_code'],
            'FlagValue': entry['flag_value'],
            'Address': entry['address'],
            'Latitude': entry['latitude'],
            'Longitude': entry['longitude'],
          }),
        );

        if (response.statusCode == 201) {
          await dbHelper.deletePunchEntry(entry['id']);
          print("Restored and deleted offline punch entry");

          // Only update UI if this was the most recent operation
          final lastEntry =
          await dbHelper.getLastPunchEntry(entry['staff_code']);
          if (lastEntry != null && lastEntry['id'] == entry['id']) {
            setState(() {
              if (entry['flag_value'] == "001") {
                isButtonDisabledIn = true;
                isButtonDisabledOut = false;
              } else {
                isButtonDisabledIn = false;
                isButtonDisabledOut = true;
              }
            });
          }
        }
      } catch (e) {
        print("Error restoring punch data:$e");
      }
    }
  }

  Future<void> retorepunchoutdata() async {
    final dbHelper = DatabaseHelperPunchout();
    List<Map<String, dynamic>> offlineEntries =
    await dbHelper.getOfflinePunchoutEntries();

    for (var entry in offlineEntries) {
      try {
        final response = await http.post(
          Uri.parse(
              "https://m-techinnovations.co.in/PersonTrackingAPI/API/SaveDetails"),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode({
            'TransactionDate': entry['transaction_date'],
            'TransactionTime': entry['transaction_time'],
            'StaffCode': entry['staff_code'],
            'FlagValue': entry['flag_value'],
            'Address': entry['address'],
            'Latitude': entry['latitude'],
            'Longitude': entry['longitude'],
          }),
        );

        if (response.statusCode == 201) {
          await dbHelper.deletePunchoutEntry(entry['id']);
          print("Restored and deleted offline punch entry");

          // Only update UI if this was the most recent operation
          final lastEntry =
          await dbHelper.getLastPunchoutEntry(entry['staff_code']);
          if (lastEntry != null && lastEntry['id'] == entry['id']) {
            setState(() {
              if (entry['flag_value'] == "001") {
                isButtonDisabledIn = true;
                isButtonDisabledOut = false;
              } else {
                isButtonDisabledIn = false;
                isButtonDisabledOut = true;
              }
            });
          }
        }
      } catch (e) {
        print("Error restoring punch data:$e");
      }
    }
  }

  Future<void> sqlitePunchIN(
      String transactionDate,
      String transactionTime,
      String staffCode,
      String flagvalue,
      String address,
      String latitude,
      String longitude,
      ) async {
    final dbHelper = DatabaseHelper();

    // Check if entry already exists
    bool exists = await dbHelper.checkDuplicateEntry(
        staffCode, transactionDate, flagvalue);
    if (exists) {
      LogFileManager.writeLog(
          "Duplicate offline entry skipped for $staffCode on $transactionDate with flag $flagvalue");
      return;
    }

    Map<String, dynamic> row = {
      'transaction_date': transactionDate,
      'transaction_time': transactionTime,
      'staff_code': staffCode,
      'flag_value': flagvalue,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };

    await dbHelper.insertPunchEntry(row);
    LogFileManager.writeLog("Offline punch entry saved: $row");

    setState(() {
      isButtonDisabledIn = true;
      isButtonDisabledOut = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Punch in saved offline!'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> sqlitePunchOUT(
      String transactionDate,
      String transactionTime,
      String staffCode,
      String s,
      String address,
      String latitude,
      String longitude) async {
    final dbHelper = DatabaseHelperPunchout();

    // Check if entry already exists
    bool exists =
    await dbHelper.checkDuplicatePunchOut(staffCode, transactionDate, s);
    if (exists) {
      LogFileManager.writeLog(
          "Duplicate offline entry skipped for $staffCode on $transactionDate with flag $s");
      return;
    }

    Map<String, dynamic> row = {
      'transaction_date': transactionDate,
      'transaction_time': transactionTime,
      'staff_code': staffCode,
      'flag_value': s,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };

    await dbHelper.insertPunchoutEntry(row);
    LogFileManager.writeLog("Offline punch entry saved: $row");

    setState(() {
      isButtonDisabledIn = false;
      isButtonDisabledOut = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Punch out saved offline!'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> checkBiometrics() async {
    try {
      bool canCheckBiometrics = await auth.canCheckBiometrics;
      if (canCheckBiometrics) {
        List<BiometricType> availableBiometrics =
        await auth.getAvailableBiometrics();
        print("Available biometrics: $availableBiometrics");
        LogFileManager.writeLog("Available biometrics: $availableBiometrics");
        //LogFileManager.saveData("Available biometrics: $availableBiometrics","hereeeee");
        await authenticate();
      } else {
        // Fluttertoast.showToast(
        //   msg: "  No biometrics available on this device...!   ",
        //   toastLength: Toast.LENGTH_SHORT,
        //   timeInSecForIosWeb: 1,
        // );

        LogFileManager.writeLog("No biometrics available on this device");
        //LogFileManager.saveData("Available biometrics: ");

        print("No biometrics available on this device");

        await authenticate();
      }
    } catch (e) {
      LogFileManager.writeLog('Error checking biometrics: $e');
      print("Error checking biometrics: $e");
    }
  }

  Future<void> authenticate() async {
    try {
      bool isAuthenticated = await auth.authenticate(
        localizedReason: 'Please authenticate to proceed',
        /*     useErrorDialogs: true,  // Show error dialogs automatically*/
        //stickyAuth: true,       // Keep the authentication prompt on screen
      );

      if (isAuthenticated) {
        print("Authentication successful!");
        // Fluttertoast.showToast(
        //   msg: "  Authentication successful",
        //   toastLength: Toast.LENGTH_LONG,
        //   timeInSecForIosWeb: 1,
        // );
        await punchIn();
      } else {
        // Fluttertoast.showToast(
        //   msg: "Authentication failed. Please try again!",
        //   toastLength: Toast.LENGTH_LONG,
        //   timeInSecForIosWeb: 1,
        // );
        print("Authentication failed.");
      }
    } catch (e) {
      if (e is PlatformException) {
        print("Authentication e.code----" + e.code);
        LogFileManager.writeLog("Authentication e.code----" + e.code);
        switch (e.code) {
          case 'NotAvailable':
            LogFileManager.writeLog(
                "Biometric authentication is not available on this device.");
            print("Biometric authentication is not available on this device.");
            // Fluttertoast.showToast(
            //   msg: "Biometric authentication is not available on this device.",
            //   toastLength: Toast.LENGTH_LONG,
            //   timeInSecForIosWeb: 1,
            // );
            await punchIn();

            break;
          case 'NotEnrolled':
            LogFileManager.writeLog(
                "No biometrics enrolled. Please enroll your fingerprint or Face ID in device settings.");
            print(
                "No biometrics enrolled. Please enroll your fingerprint or Face ID in device settings.");
            // Fluttertoast.showToast(
            //   msg: "No biometrics enrolled. Please enroll your fingerprint or Face ID in device settings.",
            //   toastLength: Toast.LENGTH_LONG,
            //   timeInSecForIosWeb: 1,
            // );
            break;
          case 'LockedOut':
            print(
                "Biometric authentication is temporarily locked. Please try again later.");
            LogFileManager.writeLog(
                "Biometric authentication is temporarily locked. Please try again later.");
            // Fluttertoast.showToast(
            //   msg: "Biometric authentication is temporarily locked. Please try again later.",
            //   toastLength: Toast.LENGTH_LONG,
            //   timeInSecForIosWeb: 1,
            // );
            break;
          case 'Failed':
            print("Authentication failed. Please try again.");
            LogFileManager.writeLog("Authentication failed. Please try again.");
            // Fluttertoast.showToast(
            //   msg: "Authentication failed. Please try again.",
            //   toastLength: Toast.LENGTH_LONG,
            //   timeInSecForIosWeb: 1,
            // );
            break;
          case 'UserCancel':
            print("Authentication was canceled by the user.");
            LogFileManager.writeLog("Authentication was canceled by the user.");
            // Fluttertoast.showToast(
            //   msg: "Authentication was canceled by the user.",
            //   toastLength: Toast.LENGTH_LONG,
            //   timeInSecForIosWeb: 1,
            // );
            break;
          case 'PasscodeNotSet':
            print("A passcode must be set to use biometric authentication.");
            LogFileManager.writeLog(
                "A passcode must be set to use biometric authentication.");
            // Fluttertoast.showToast(
            //   msg: "A passcode must be set to use biometric authentication.",
            //   toastLength: Toast.LENGTH_LONG,
            //   timeInSecForIosWeb: 1,
            // );
            break;
          default:
            print("An unexpected error occurred: ${e.message}");
            LogFileManager.writeLog(
                "An unexpected error occurred: ${e.message}");
        // Fluttertoast.showToast(
        //   msg: "An unexpected error occurred: ${e.message}",
        //   toastLength: Toast.LENGTH_LONG,
        //   timeInSecForIosWeb: 1,
        // );
        }
      }
    }
  }

  Future<void> checkbiometricspunchout() async {
    try {
      bool canCheckBiometrics = await auth.canCheckBiometrics;
      if (canCheckBiometrics) {
        List<BiometricType> availableBiometrics =
        await auth.getAvailableBiometrics();
        print("Available biometrics: $availableBiometrics");
        LogFileManager.writeLog("Available biometrics: $availableBiometrics");
        //LogFileManager.saveData("Available biometrics: $availableBiometrics","hereeeee");
        await authenticatepunchout();
      } else {
        // Fluttertoast.showToast(
        //   msg: "  No biometrics available on this device...!   ",
        //   toastLength: Toast.LENGTH_SHORT,
        //   timeInSecForIosWeb: 1,
        // );

        LogFileManager.writeLog("No biometrics available on this device");
        //LogFileManager.saveData("Available biometrics: ");

        print("No biometrics available on this device");

        await authenticatepunchout();
      }
    } catch (e) {
      LogFileManager.writeLog('Error checking biometrics: $e');
      print("Error checking biometrics: $e");
    }
  }

  Future<void> authenticatepunchout() async {
    try {
      bool isAuthenticated = await auth.authenticate(
        localizedReason: 'Please authenticate to proceed',
        /*     useErrorDialogs: true,  // Show error dialogs automatically*/
        //stickyAuth: true,       // Keep the authentication prompt on screen
      );

      if (isAuthenticated) {
        print("Biometric Authentication successful!");
        // Fluttertoast.showToast(
        //   msg: "Biometric Authentication Successful",
        //   toastLength: Toast.LENGTH_LONG,
        //   timeInSecForIosWeb: 1,
        // );
        await punchOut();
      } else {
        Fluttertoast.showToast(
          msg: "Authentication failed. Please try again!",
          toastLength: Toast.LENGTH_LONG,
          timeInSecForIosWeb: 1,
        );
        print("Authentication failed.");
      }
    } catch (e) {
      if (e is PlatformException) {
        print("Authentication e.code----" + e.code);
        LogFileManager.writeLog("Authentication e.code----" + e.code);
        switch (e.code) {
          case 'NotAvailable':
            LogFileManager.writeLog(
                "Biometric authentication is not available on this device.");
            print("Biometric authentication is not available on this device.");
            // Fluttertoast.showToast(
            //   msg: "Biometric authentication is not available on this device.",
            //   toastLength: Toast.LENGTH_LONG,
            //   timeInSecForIosWeb: 1,
            // );
            await punchOut();

            break;
          case 'NotEnrolled':
            LogFileManager.writeLog(
                "No biometrics enrolled. Please enroll your fingerprint or Face ID in device settings.");
            print(
                "No biometrics enrolled. Please enroll your fingerprint or Face ID in device settings.");
            // Fluttertoast.showToast(
            //   msg: "No biometrics enrolled. Please enroll your fingerprint or Face ID in device settings.",
            //   toastLength: Toast.LENGTH_LONG,
            //   timeInSecForIosWeb: 1,
            // );
            break;
          case 'LockedOut':
            print(
                "Biometric authentication is temporarily locked. Please try again later.");
            LogFileManager.writeLog(
                "Biometric authentication is temporarily locked. Please try again later.");
            // Fluttertoast.showToast(
            //   msg: "Biometric authentication is temporarily locked. Please try again later.",
            //   toastLength: Toast.LENGTH_LONG,
            //   timeInSecForIosWeb: 1,
            // );
            break;
          case 'Failed':
            print("Authentication failed. Please try again.");
            LogFileManager.writeLog("Authentication failed. Please try again.");
            // Fluttertoast.showToast(
            //   msg: "Authentication failed. Please try again.",
            //   toastLength: Toast.LENGTH_LONG,
            //   timeInSecForIosWeb: 1,
            // );
            break;
          case 'UserCancel':
            print("Authentication was canceled by the user.");
            LogFileManager.writeLog("Authentication was canceled by the user.");
            // Fluttertoast.showToast(
            //   msg: "Authentication was canceled by the user.",
            //   toastLength: Toast.LENGTH_LONG,
            //   timeInSecForIosWeb: 1,
            // );
            break;
          case 'PasscodeNotSet':
            print("A passcode must be set to use biometric authentication.");
            LogFileManager.writeLog(
                "A passcode must be set to use biometric authentication.");
            // Fluttertoast.showToast(
            //   msg: "A passcode must be set to use biometric authentication.",
            //   toastLength: Toast.LENGTH_LONG,
            //   timeInSecForIosWeb: 1,
            // );
            break;
          default:
            print("An unexpected error occurred: ${e.message}");
            LogFileManager.writeLog(
                "An unexpected error occurred: ${e.message}");
        // Fluttertoast.showToast(
        //   msg: "An unexpected error occurred: ${e.message}",
        //   toastLength: Toast.LENGTH_LONG,
        //   timeInSecForIosWeb: 1,
        // );
        }
      }
    }
  }
}

class _BannerItem {
  final String image;
  final String text;

  _BannerItem({required this.image, required this.text});
}

/// old punch in-out code
/*
Future<void> punchIn() async {
  bool hasPermission = await handleLocationPermission();

  if (!hasPermission) {
    _showSnackbar("Location permission required for Punch In!.Please allow from settings");
    return;
  }

  if(DISTANCEFLAG == 'Y'){
    print("errorrr0N");
    if(ADDRESSFLAG == 'Y') {
      print("errorrr0NY");

      LocationHandler.changeToRemoteLocation();

      LocationHandler.remoteZoneLat = double.parse(REMOTELAT);
      LocationHandler.remoteZoneLon = double.parse(REMOTELONG);
      try {
        _currentLat = LocationHandler.currentLat.toString();
        _currentLon = LocationHandler.currentLon.toString();
        _currentAddress = LocationHandler.currentAddress;
        LogFileManager.writeLog("punch in N Y"+_currentLat! + _currentLon! + _currentAddress!);

        print(_currentLat);
        print(_currentLon);
        print(_currentAddress);

        String currentDate = DateFormat('dd-MM-yyyy HH:mm:ss').format(
            DateTime.now()).substring(0, 10);
        String currentTime = DateFormat('dd-MM-yyyy HH:mm:ss').format(
            DateTime.now()).substring(11, 19);
        String currentDateTime = DateFormat('dd-MM-yyyy HH:mm:ss').format(
            DateTime.now()).substring(0, 19);
        print(currentDate);
        print(currentTime);
        print(currentDateTime);
        print(_currentAddress);
        await retorepunchdata();
        if (await getInEntryFromDataBase(currentDate, currentTime, staffCode!)) {
          String? result = await storeInEntry(
              currentDate,
              currentDateTime,
              staffCode!,
              "001",
              _currentAddress!,
              _currentLat!,
              _currentLon!,
              plantcode?.toString() ?? "01"
          );

          print("result $result");
          // After successful operation, show a SnackBar
          setState(() {
            isButtonDisabledIn = true;
            isButtonDisabledOut = false;
            _updateButtonInitialState();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: const Text('Punch-in Successful!'),
                action: SnackBarAction(label: 'OK', onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                }),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3)
            ),
          );
          LogFileManager.writeLog("punch in try flag y result if $result");
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: const Text('Already Marked!! or First Punch Out!!'),
                action: SnackBarAction(label: 'X', onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                }),
                backgroundColor: Colors.redAccent,
                duration: const Duration(seconds: 3)
            ),
          );
          LogFileManager.writeLog("punch in try flag Y else result ");
        }
      } catch (e) {
        print("Error: $e");

        // If there is an error, show a SnackBar with the error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Punch-in failed! Please try again.'),
              duration: const Duration(seconds: 3)
          ),
        );
        LogFileManager.writeLog("punch in catch flag N catch Error: $e");
      } finally{
        setState(() {
          isLoading=false;
        });
      }
    }
    else{
      try {
        await LocationHandler.checkIfInZone();
        _currentLat = LocationHandler.currentLat.toString();
        _currentLon = LocationHandler.currentLon.toString();
        _currentAddress = LocationHandler.currentAddress;
        LogFileManager.writeLog("punch in N y else"+_currentLat! + _currentLon! + _currentAddress!);

        String currentDate = DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now()).substring(0, 10);
        String currentTime = DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now()).substring(11, 19);
        String currentDateTime = DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now()).substring(0, 19);
        await retorepunchdata();
        if (await getInEntryFromDataBase(currentDate, currentTime, staffCode!)) {
          String? result = await storeInEntry(currentDate, currentDateTime, staffCode!, "001", _currentAddress!, _currentLat!, _currentLon!,
              plantcode?.toString() ?? "01"

          );

          print("result $result");

          // After successful operation, show a SnackBar
          setState(() {
            isButtonDisabledIn = true;
            isButtonDisabledOut = false;
            _updateButtonInitialState();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: const Text('Punch-in Successful!'),
                action: SnackBarAction(label: 'OK', onPressed: (){ScaffoldMessenger.of(context).hideCurrentSnackBar();}),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3)
            ),
          );
          LogFileManager.writeLog("punch in flag Y try if: $result");
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: const Text('Already Marked!! or First Punch Out!!'),
                action: SnackBarAction(label: 'X', onPressed: (){ScaffoldMessenger.of(context).hideCurrentSnackBar();}),
                backgroundColor: Colors.redAccent,
                duration: const Duration(seconds: 3)
            ),
          );
          LogFileManager.writeLog("punch in flag Y try else ");
        }
      } catch (e) {
        print("Error: $e");

        // If there is an error, show a SnackBar with the error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Punch-in failed! Please try again.'),
              duration: const Duration(seconds: 3)
          ),
        );
        print(_currentLat);
        print(_currentLon);
        print(_currentAddress);
        print(staffCode);
        print("actual location flag N catch $e");
        LogFileManager.writeLog("actual location flag N catch $e");
      } finally{
        setState(() {
          isLoading = false;
        });
      }
    }
  }
  else{
    print("errorrr0001");
    if(ADDRESSFLAG == 'Y'){
      print("errorrr0002");

      LocationHandler.changeToRemoteLocation();
      LocationHandler.remoteZoneLat = double.parse(REMOTELAT);
      LocationHandler.remoteZoneLon = double.parse(REMOTELONG);
      // _currentAddress = REMOTELOCATION.toString();
      bool ifInZone = await LocationHandler.checkIfInZone();
      print(ifInZone);
      if(ifInZone) {
        // Simulate API calls
        try {
          _currentLat = LocationHandler.currentLat.toString();
          _currentLon = LocationHandler.currentLon.toString();
          _currentAddress = LocationHandler.currentAddress;
          LogFileManager.writeLog("punch in Y"+_currentLat! + _currentLon! + _currentAddress!);

          String currentDate = DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now()).substring(0, 10);
          String currentTime = DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now()).substring(11, 19);
          String currentDateTime = DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now()).substring(0, 19);
//if (await getOutEntryFromDataBase(currentDate, currentTime, staffCode!))
          await retorepunchdata();
          if (await getInEntryFromDataBase(currentDate, currentTime, staffCode!)) {
            String? result = await storeInEntry(currentDate, currentDateTime, staffCode!, "001", _currentAddress!, _currentLat!, _currentLon!,plantcode?.toString() ?? "01"
            );
            print(currentDate);
            print(currentTime);
            print(currentDateTime);
            print(_currentAddress);
            // After successful operation, show a SnackBar
            setState(() {
              isButtonDisabledIn = true;
              isButtonDisabledOut = false;
              _updateButtonInitialState();
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: const Text('Punch-in Successful!'),
                  action: SnackBarAction(label: 'OK', onPressed: (){ScaffoldMessenger.of(context).hideCurrentSnackBar();}),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3)
              ),
            );
            LogFileManager.writeLog("punch in flag N else if try: $result");
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: const Text('Already Marked!! or First Punch Out!!'),
                  action: SnackBarAction(label: 'X', onPressed: (){ScaffoldMessenger.of(context).hideCurrentSnackBar();}),
                  backgroundColor: Colors.redAccent,
                  duration: const Duration(seconds: 3)
              ),
            );
          }
          LogFileManager.writeLog("punch in flag N else if else");
        } catch (e) {
          print("Error: $e");

          // If there is an error, show a SnackBar with the error message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Punch-in failed! Please try again.'),
                duration: const Duration(seconds: 3)
            ),
          );
          LogFileManager.writeLog("punch in flag N else catch Error: $e");
        } finally{
          setState(() {
            isLoading = false;
          });
        }
      } else{
        Fluttertoast.showToast(
            msg: "Not in zone!!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            // textColor: Colors.white,
            fontSize: 12.0
        );
        LogFileManager.writeLog("punch in flag y not in zone");
        print("Not in zone");
      }
    }
    else{
      bool ifInZone = await LocationHandler.checkIfInZone();
      if(ifInZone) {
        try {
          _currentLat = LocationHandler.currentLat.toString();
          _currentLon = LocationHandler.currentLon.toString();
          _currentAddress = LocationHandler.currentAddress;
          print(_currentLat);
          print(_currentLon);
          print(_currentAddress);
          LogFileManager.writeLog("punch in else y  else"+_currentLat! + _currentLon! + _currentAddress!);

          String currentDate = DateFormat('dd-MM-yyyy HH:mm:ss').format(
              DateTime.now()).substring(0, 10);
          String currentTime = DateFormat('dd-MM-yyyy HH:mm:ss').format(
              DateTime.now()).substring(11, 19);
          String currentDateTime = DateFormat('dd-MM-yyyy HH:mm:ss').format(
              DateTime.now()).substring(0, 19);
          await retorepunchdata();
          if (await getInEntryFromDataBase(
              currentDate, currentTime, staffCode!)) {
            String? result = await storeInEntry(
                currentDate,
                currentDateTime,
                staffCode!,
                "001",
                _currentAddress!,
                _currentLat!,
                _currentLon!,
                plantcode?.toString() ?? "01"

            );

            print("result $result");

            // After successful operation, show a SnackBar
            setState(() {
              isButtonDisabledIn = true;
              isButtonDisabledOut = false;
              _updateButtonInitialState();
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: const Text('Punch-in Successful!'),
                  action: SnackBarAction(label: 'OK', onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  }),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3)
              ),
            );
            LogFileManager.writeLog("punch in flag N else actual location: $result");
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: const Text(
                      'Already Marked!! or First Punch Out!!'),
                  action: SnackBarAction(label: 'X', onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  }),
                  backgroundColor: Colors.redAccent,
                  duration: const Duration(seconds: 3)
              ),
            );
          }
        } catch (e) {
          print("Error: $e");

          // If there is an error, show a SnackBar with the error message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Punch-in failed! Please try again.'),
                duration: const Duration(seconds: 3)
            ),
          );
          LogFileManager.writeLog("punch in flag N else actual location catch: $e");

        } finally{
          setState(() {
            isLoading = false;
          });
        }
      } else {
        Fluttertoast.showToast(
            msg: "Not in zone!!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            // textColor: Colors.white,
            fontSize: 12.0
        );
        LogFileManager.writeLog("punch in flag P not in zone");
        print("Not in zone");
      }
    }
  }

}

Future<void> punchOut() async {
  bool hasPermission = await handleLocationPermission();
  if (!hasPermission) {
    _showSnackbar("Location permission required for Punch In!.Please allow from settings");
    return;
  }

  if(DISTANCEFLAG =='Y'){
    if(ADDRESSFLAG == 'Y') {
      LocationHandler.changeToRemoteLocation();

      LocationHandler.remoteZoneLat = double.parse(REMOTELAT);
      LocationHandler.remoteZoneLon = double.parse(REMOTELONG);
      // _currentAddress = REMOTELOCATION.toString();
      // bool ifInZone = await LocationHandler.checkIfInZone();
      // if (ifInZone) {
      try {
        _currentLat = LocationHandler.currentLat.toString();
        _currentLon = LocationHandler.currentLon.toString();
        _currentAddress = LocationHandler.currentAddress;
        LogFileManager.writeLog("punch out N Y"+_currentLat! + _currentLon! + _currentAddress!);

        String currentDate = DateFormat('dd-MM-yyyy HH:mm:ss').format(
            DateTime.now()).substring(0, 10);
        String currentTime = DateFormat('dd-MM-yyyy HH:mm:ss').format(
            DateTime.now()).substring(11, 19);
        String currentDateTime = DateFormat('dd-MM-yyyy HH:mm:ss').format(
            DateTime.now()).substring(0, 19);
        await retorepunchoutdata();
        if (await getOutEntryFromDataBase(currentDate, currentTime, staffCode!)) {
          String? result = await storeOutEntry(
              currentDate,
              currentDateTime,
              staffCode!,
              "000",
              _currentAddress!,
              _currentLat!,
              _currentLon!,
              plantcode?.toString() ?? "01"
          );

          print("result $result");

          // After successful operation, show a SnackBar
          setState(() {
            isButtonDisabledIn = true;
            isButtonDisabledOut = false;
            _updateButtonInitialState();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: const Text('Punch-out Successful!'),
                action: SnackBarAction(label: 'OK', onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                }),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3)
            ),
          );
          LogFileManager.writeLog("punch out remote location try: $result");
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: const Text('Already Marked!! or First Punch Out!!'),
                action: SnackBarAction(label: 'X', onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                }),
                backgroundColor: Colors.redAccent,
                duration: const Duration(seconds: 3)
            ),
          );
        }
      } catch (e) {
        print("Error: $e");

        // If there is an error, show a SnackBar with the error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Punch-out failed! Please try again.'),
              duration: const Duration(seconds: 3)
          ),
        );
        LogFileManager.writeLog("punch out remote location catch: $e");
      } finally{
        setState(() {
          isLoading = false;
        });
      }
    }
    else{
      try {
        await LocationHandler.checkIfInZone();
        _currentLat = LocationHandler.currentLat.toString()??'';
        _currentLon = LocationHandler.currentLon.toString();
        _currentAddress = LocationHandler.currentAddress;
        LogFileManager.writeLog("punch out N y else"+_currentLat! + _currentLon! + _currentAddress!);

        String currentDate = DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now()).substring(0, 10);
        String currentTime = DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now()).substring(11, 19);
        String currentDateTime = DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now()).substring(0, 19);
        await retorepunchoutdata();

        if (await getOutEntryFromDataBase(currentDate, currentTime, staffCode!)) {
          String? result = await storeOutEntry(currentDate, currentDateTime, staffCode!, "000", _currentAddress!, _currentLat!, _currentLon!,plantcode?.toString() ?? "01"
          );

          print("result $result");

          // After successful operation, show a SnackBar
          setState(() {
            isButtonDisabledIn = true;
            isButtonDisabledOut = false;
            _updateButtonInitialState();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: const Text('Punch-out Successful!'),
                action: SnackBarAction(label: 'OK', onPressed: (){ScaffoldMessenger.of(context).hideCurrentSnackBar();}),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3)
            ),
          );
          LogFileManager.writeLog("punch out acual location try: $result");
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: const Text('Already Marked!! or First Punch Out!!'),
                action: SnackBarAction(label: 'X', onPressed: (){ScaffoldMessenger.of(context).hideCurrentSnackBar();}),
                backgroundColor: Colors.redAccent,
                duration: const Duration(seconds: 3)
            ),
          );
          LogFileManager.writeLog("punch out actual location try else");
        }

      } catch (e) {
        print("Error: $e");

        // If there is an error, show a SnackBar with the error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Punch-out failed! Please try again.'),
              duration: const Duration(seconds: 3)
          ),
        );
        LogFileManager.writeLog("punch out actual location catch: $e");
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
  else{
    print("errorrr001");

    if(ADDRESSFLAG == 'Y'){

      print("errorrr002");

      LocationHandler.changeToRemoteLocation();

      // String? remoLoc= REMOTELOCATION.toString();
      // String? remoLat= REMOTELAT.toString();
      // String? remoLong= REMOTELONG.toString();
      // print("error"+ remoLoc + remoLong + remoLat);

      // setState(() async {
      //
      // });
*/
/**/ /*

      LocationHandler.remoteZoneLat = double.parse(REMOTELAT);
      LocationHandler.remoteZoneLon = double.parse(REMOTELONG);
      // _currentAddress = REMOTELOCATION.toString();
      bool ifInZone = await LocationHandler.checkIfInZone();
      if(ifInZone) {
        // Simulate API calls
        try {
          _currentLat = LocationHandler.currentLat.toString();
          _currentLon = LocationHandler.currentLon.toString();
          _currentAddress = LocationHandler.currentAddress;
          LogFileManager.writeLog("punch out else y"+_currentLat! + _currentLon! + _currentAddress!);

          String currentDate = DateFormat('dd-MM-yyyy HH:mm:ss').format(
              DateTime.now()).toString().substring(0, 10);
          String currentTime = DateFormat('dd-MM-yyyy HH:mm:ss').format(
              DateTime.now()).toString().substring(11, 19);
          String currentDateTime = DateFormat('dd-MM-yyyy HH:mm:ss').format(
              DateTime.now()).toString().substring(0, 19);
          await retorepunchoutdata();

          if (await getOutEntryFromDataBase(
              currentDate, currentTime, staffCode!)) {
            String? result = await storeOutEntry(
                currentDate,
                currentDateTime,
                staffCode!,
                "000",
                _currentAddress!,
                _currentLat!,
                _currentLon!,
                plantcode?.toString() ?? "01"
            );

            setState(() {
              isButtonDisabledOut = true;
              isButtonDisabledIn = false;
              _updateButtonInitialState();
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Punch-out Successful!'),
                action: SnackBarAction(label: 'OK', onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                }),
                backgroundColor: Colors.green,
              ),
            );
            LogFileManager.writeLog("punch out remote location flagN else  try: $result");
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: const Text('Already Marked!! or First Punch In!!'),
                  action: SnackBarAction(label: 'X', onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  }),
                  backgroundColor: Colors.redAccent,
                  duration: const Duration(seconds: 3)
              ),
            );
            LogFileManager.writeLog("punch out remote location fllag N else else");
          }
        } catch (e) {
          print("Error: $e");

          // If there is an error, show a SnackBar with the error message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Punch-out failed! Please try again.'),
                duration: const Duration(seconds: 3)
            ),
          );
          LogFileManager.writeLog("punch out remote location flagN else  catch: $e");
        } finally{
          setState(() {
            isLoading = false;
          });
        }
      } else{
        Fluttertoast.showToast(
            msg: "Not in zone!!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            // textColor: Colors.white,
            fontSize: 12.0
        );
        print("Not in zone");
        LogFileManager.writeLog("punch out remote location flagN not in zone");
      }
    }
    else{
      bool ifInZone = await LocationHandler.checkIfInZone();
      if(ifInZone) {
        try {
          _currentLat = LocationHandler.currentLat.toString();
          _currentLon = LocationHandler.currentLon.toString();
          _currentAddress = LocationHandler.currentAddress;
          LogFileManager.writeLog("punch out else y else"+_currentLat! + _currentLon! + _currentAddress!);

          String currentDate = DateFormat('dd-MM-yyyy HH:mm:ss').format(
              DateTime.now()).substring(0, 10);
          String currentTime = DateFormat('dd-MM-yyyy HH:mm:ss').format(
              DateTime.now()).substring(11, 19);
          String currentDateTime = DateFormat('dd-MM-yyyy HH:mm:ss').format(
              DateTime.now()).substring(0, 19);
          await retorepunchoutdata();

          if (await getOutEntryFromDataBase(
              currentDate, currentTime, staffCode!)) {
            String? result = await storeOutEntry(
                currentDate,
                currentDateTime,
                staffCode!,
                "000",
                _currentAddress!,
                _currentLat!,
                _currentLon!,
                plantcode?.toString() ?? "01"
            );

            print("result $result");

            // After successful operation, show a SnackBar
            setState(() {
              isButtonDisabledIn = true;
              isButtonDisabledOut = false;
              _updateButtonInitialState();
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: const Text('Punch-out Successful!'),
                  action: SnackBarAction(label: 'OK', onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  }),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3)
              ),
            );
            LogFileManager.writeLog("punch out actual location flagN else  catch: $result");

          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: const Text(
                      'Already Marked!! or First Punch Out!!'),
                  action: SnackBarAction(label: 'X', onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  }),
                  backgroundColor: Colors.redAccent,
                  duration: const Duration(seconds: 3)
              ),
            );
            LogFileManager.writeLog("punch out remote location flagN else  else");

          }
        } catch (e) {
          print("Error: $e");
          print(_currentLat);
          print(_currentLon);
          print(_currentAddress);
          // If there is an error, show a SnackBar with the error message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Punch-out failed! Please try again.'),
                duration: const Duration(seconds: 3)
            ),
          );
          LogFileManager.writeLog("punch out actual location flagN else  catch: $e");

        } finally{
          setState(() {
            isLoading = false;
          });
        }
      }
      else{
        Fluttertoast.showToast(
            msg: "Not in zone!!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            // textColor: Colors.white,
            fontSize: 12.0
        );
        print("Not in zone");
        LogFileManager.writeLog("punch out actaual location flagN else not in zone");

      }
    }
  }
}*/
