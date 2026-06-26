import 'dart:async';

import 'package:attendance_system_ios/bloc/main_bloc.dart';
import 'package:attendance_system_ios/bloc/main_event.dart';
import 'package:attendance_system_ios/bloc/main_state.dart';
import 'package:attendance_system_ios/screen/AdminHomeScreen/AdminHome.dart';
import 'package:attendance_system_ios/screen/Home/home.dart';
import 'package:attendance_system_ios/screen/Splash%20Screen/permission_disclosure_screen.dart';
import 'package:attendance_system_ios/service/WebService.dart';
import 'package:attendance_system_ios/service/log_file_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../service/appupdate_service.dart';
import '../../service/internet_service.dart';
import '../../util/MyColor.dart';
import '../Login/login_screen.dart';

class SplashScreen extends StatefulWidget {
  final String? initialPayload;

  const SplashScreen({super.key, this.initialPayload});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  MainBloc? _mainBloc;
  bool _isLoading = false;
  bool isAdminLogin = false;

  @override
  void initState() {
    super.initState();
    // _initializeApp();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   AppUpdateService.checkAndUpdate(context);
    // });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // optional small delay for smoother UI
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      await AppUpdateService.checkAndUpdate(context);

      if (!mounted) return;

      await _initializeApp();
    });

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  Future<void> _initializeApp() async {
    await requestPermissions();
    await clearKeychainValues();

    bool hasInternet = await InternetService().hasInternetAccess();
    if (!hasInternet) {
      if (mounted) showNoInternetDialog();
      return;
    }

    if (mounted) {
      await checkLocationDisclosure();
    }

    if (!mounted) return;

    if (widget.initialPayload != null) {
      Navigator.of(context).pushReplacementNamed(
        '/track_visit_location',
        arguments: widget.initialPayload,
      );
    } else {
      _checkRememberMe();
    }
  }

  Future<void> checkLocationDisclosure() async {
    final prefs = await SharedPreferences.getInstance();
    bool accepted = prefs.getBool("location_disclosure_accepted") ?? false;

    if (!accepted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LocationDisclosureScreen(
            onAgree: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool("location_disclosure_accepted", true);
              Navigator.pop(context);
            },
          ),
        ),
      );
    }
  }

  Future<void> requestPermissions() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  void showNoInternetDialog() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext dContext) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded,
                    size: 64, color: MyColors.redColorCode),
                const SizedBox(height: 16),
                const Text(
                  "No Internet Connection",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Please check your internet connection and try again.",
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 16, color: MyColors.text5ColorCode),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MyColors.appDefaultColorCode,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      bool hasInternet =
                          await InternetService().hasInternetAccess();
                      if (hasInternet) {
                        Navigator.pop(dContext);
                        _initializeApp();
                      }
                    },
                    child: const Text("Retry",
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> clearKeychainValues() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      bool isFirstLaunch = prefs.getBool('is_first_app_launch') ?? true;
      if (isFirstLaunch) {
        await storage.deleteAll();
        await prefs.setBool('is_first_app_launch', false);
      }
    } catch (e) {
      LogFileManager.writeLog("Error clearing secure storage: $e");
    }
  }

  Future<void> _checkRememberMe() async {
    String storedUsername = 'Null';
    String storedPassword = 'Null';
    try {
      storedUsername = await storage.read(key: 'username') ?? 'Null';
      storedPassword = await storage.read(key: 'password') ?? 'Null';
    } catch (e) {
      await storage.deleteAll();
    }

    if (storedUsername != 'Null' && storedPassword != 'Null') {
      isAdminLogin =
          (storedUsername == "mzdl002" && storedPassword == "Admin@123\$");
      _mainBloc?.add(
          LoginEvents(username: storedUsername, password: storedPassword));
    } else {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => MainBloc(webService: WebService()),
            child: const LoginScreen(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    _mainBloc = context.read<MainBloc>();
    return Scaffold(
      body: LoadingOverlay(
        isLoading: _isLoading,
        opacity: 0.5,
        color: Colors.white,
        progressIndicator: const CircularProgressIndicator(
          color: MyColors.appDefaultColorCode,
        ),
        child: BlocListener<MainBloc, MainState>(
          listener: (context, state) {
            if (state is LoginLoadingState) {
              setState(() => _isLoading = true);
            } else if (state is LoginLoadedState) {
              setState(() => _isLoading = false);
              if (state.loginResponse?.token?.result?.token != null) {
                storage.write(
                    key: 'Auth_Token',
                    value: state.loginResponse!.token!.result!.token);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (context) => MainBloc(webService: WebService()),
                      child: isAdminLogin
                          ? const AdminHomeScreen()
                          : const HomeScreen(),
                    ),
                  ),
                );
              }
            } else if (state is LoginErrorState) {
              setState(() => _isLoading = false);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (context) => MainBloc(webService: WebService()),
                    child: const LoginScreen(),
                  ),
                ),
              );
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, MyColors.lightblueColorCode],
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Hero(
                    tag: 'app_logo',
                    child: Image.asset(
                      "assets/icons/graphic-design.png",
                      width: 120,
                      height: 120,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Attendance System",
                    style: TextStyle(
                      fontSize: 32,
                      color: MyColors.appDefaultColorCode,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Smart Field Tracking Solutions",
                    style: TextStyle(
                      fontSize: 16,
                      color: MyColors.text5ColorCode,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    const CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          MyColors.appDefaultColorCode),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "@ 2025 M-Tech Innovations Ltd Pune\nAttendance System",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: MyColors.text3greyColorCode,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
