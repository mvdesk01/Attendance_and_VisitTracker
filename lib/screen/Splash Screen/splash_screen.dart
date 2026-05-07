import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../bloc/main_bloc.dart';
import '../../bloc/main_event.dart';
import '../../bloc/main_state.dart';
import '../../service/WebService.dart';
import '../../service/appupdate_service.dart';
import '../../service/log_file_manager.dart';
import '../../service/internet_service.dart';
import '../../util/MyColor.dart';
import '../Login/login_screen.dart';
import '../Home/home.dart';
import '../admin_side/home_admin/admin_home.dart';
import 'location_disclosure_screen.dart';

class SplashScreen extends StatefulWidget {
  final String? initialPayload;
  const SplashScreen({super.key, this.initialPayload});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  late MainBloc _mainBloc;
  
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Interval(0.0, 0.6, curve: Curves.easeOutBack)),
    );

    _controller.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // optional small delay for smoother UI
      await Future.delayed(const Duration(milliseconds: 300));

      await AppUpdateService.checkAndUpdate(context);

      // now safe to continue
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    await Future.wait([
      _handlePermissions(),
      _clearStorageOnFirstLaunch(),
    ]);

    // Ensure splash is visible for at least 2 seconds for the animation to play
    await Future.delayed(const Duration(milliseconds: 1200));
    
    bool hasInternet = await InternetService().hasInternetAccess();
    if (!hasInternet) {
      _showNoInternetDialog();
      return; 
    }

    if (widget.initialPayload != null) {
      _navigateToNotificationRoute();
    } else {
      _checkRememberMe();
    }
  }

  Future<void> _handlePermissions() async {
    await Permission.notification.request();
  }

  Future<void> _clearStorageOnFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      bool isFirstLaunch = prefs.getBool('is_first_app_launch') ?? true;
      if (isFirstLaunch) {
        await storage.deleteAll();
        await prefs.setBool('is_first_app_launch', false);
      }
    } catch (e) {
      LogFileManager.writeLog("Storage Clear Error: $e");
    }
  }

  Future<void> _checkRememberMe() async {
    if (mounted) {
      await checkLocationDisclosure();
    }
    try {
      String? user = await storage.read(key: 'username');
      String? pass = await storage.read(key: 'password');

      if (user != null && pass != null) {
        _mainBloc.add(LoginEvents(username: user, password: pass));
      } else {
        _goToLogin();
      }
    } catch (e) {
      await storage.deleteAll();
      _goToLogin();
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

  void _goToLogin() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => BlocProvider(
          create: (context) => MainBloc(webService: WebService()),
          child: const LoginScreen(),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  void _navigateToNotificationRoute() {
    Navigator.of(context).pushReplacementNamed(
      '/track_visit_location',
      arguments: widget.initialPayload,
    );
  }

  void _showNoInternetDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("No Connection"),
        content: const Text("Please check your internet settings to continue."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _initializeApp();
            },
            child: const Text("Retry"),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _mainBloc = context.read<MainBloc>();
    return Scaffold(
      body: BlocListener<MainBloc, MainState>(
        listener: (context, state) {
          if (state is LoginErrorState) {
            _goToLogin();
          }
          if (state is LoginLoadedState) {
            _handleLoginSuccess(state);
          }
        },
        child: _buildBody(),
      ),
    );
  }

  void _handleLoginSuccess(LoginLoadedState state) async {
    final token = state.loginResponse?.token?.result?.token;
    if (token != null) {
      await storage.write(key: 'Auth_Token', value: token);
      final user = await storage.read(key: 'username');

      Widget target = (user == "mzdl002") ? const AdminHomeScreen() : const HomeScreen();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => BlocProvider(
            create: (context) => MainBloc(webService: WebService()),
            child: target,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    } else {
      _goToLogin();
    }
  }

  Widget _buildBody() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            MyColors.lightBlue,
            MyColors.lightBlue,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 3),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
              );
            },
            child: Image.asset(
              "assets/icons/new_app_icon.png",
              width: 140,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.fingerprint,
                size: 140,
                color: Colors.white70,
              ),
            ),
          ),
          const SizedBox(height: 20),
          FadeTransition(
            opacity: _fadeAnimation,
            child: const Text(
              "Attendance System",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2.0,
                shadows: [
                  Shadow(
                    blurRadius: 10.0,
                    color: Colors.black26,
                    offset: Offset(2.0, 2.0),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(flex: 3),
          FadeTransition(
            opacity: _fadeAnimation,
            child: const Padding(
              padding: EdgeInsets.only(bottom: 30),
              child: Text(
                "@ Copy 2025 M-Tech Innovations Ltd",
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
