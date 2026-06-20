import 'dart:convert';
import 'dart:io';

import 'package:android_id/android_id.dart';
import 'package:attendance_system_ios/bloc/main_bloc.dart';
import 'package:attendance_system_ios/bloc/main_event.dart';
import 'package:attendance_system_ios/bloc/main_state.dart';
import 'package:attendance_system_ios/screen/Forget%20Password/forget_password.dart';
import 'package:attendance_system_ios/screen/Home/home.dart';
import 'package:attendance_system_ios/screen/Register/register_screen.dart';
import 'package:attendance_system_ios/service/WebService.dart';
import 'package:attendance_system_ios/service/log_file_manager.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:local_auth/local_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
import '../../util/MyColor.dart';
import '../../service/internet_service.dart';
import '../AdminHomeScreen/AdminHome.dart';
import '../Forget Password/forgetpassword.dart';
import 'UpdateDeviceID.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _switchValue = true;
  bool passwordVisibility = true;
  bool _isLoading = false;
  late MainBloc _mainBloc;
  final storage = const FlutterSecureStorage();
  final TextEditingController _CardIdtextController = TextEditingController();
  final TextEditingController _PasswordtextController = TextEditingController();

  bool isAdminLogin = false;
  LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
  }

  Future<String?> _getId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    return androidInfo.id;
  }

  @override
  Widget build(BuildContext context) {
    _mainBloc = BlocProvider.of(context);
    return Scaffold(
      body: _loginscreen(),
    );
  }

  _loginscreen() {
    return LoadingOverlay(
      isLoading: _isLoading,
      opacity: 0.3,
      color: Colors.black,
      progressIndicator: const CircularProgressIndicator(color: Colors.lightBlue),
      child: BlocListener<MainBloc, MainState>(
        listener: (context, state) async {
          if (state is LoginLoadingState) {
            setState(() => _isLoading = true);
          } else if (state is LoginLoadedState) {
            setState(() => _isLoading = false);
            if (state.loginResponse?.message != null) {
              await storage.write(key: 'Auth_Token', value: state.loginResponse!.token!.result!.token);
              await storage.write(key: 'Staff_Code', value: state.loginResponse!.message!.staffCode);
              await storage.write(key: 'Staff_Name', value: state.loginResponse!.message!.displayName);
              await storage.write(key: 'Plant_Code', value: state.loginResponse!.message!.plantCode);

              if (isAdminLogin) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (context) => MainBloc(webService: WebService()),
                      child: const AdminHomeScreen(),
                    ),
                  ),
                );
              } else {
                await checkBiometrics();
              }
            } else {
              await storage.delete(key: 'username');
              await storage.delete(key: 'password');
            }
          } else if (state is LoginErrorState) {
            setState(() => _isLoading = false);
          }
        },
        child: Stack(
          children: [
            // Background Gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    MyColors.lightBlue,
                    MyColors.linearGradient2ColorCode,
                  ],
                ),
              ),
            ),

            Column(
              children: [
                const SizedBox(height: 80),
                // Header Branding
                Hero(
                  tag: 'app_icon',
                  child: Container(
                    height: 90,
                    width: 90,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      "assets/icons/new_app_icon.png",
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.fingerprint, size: 50, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Attendance System",
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.1,
                  ),
                ),
                Text(
                  "Smart Attendance, Better Management",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),

                // Login Form Card
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 20,
                          offset: Offset(0, -5),
                        )
                      ],
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(32, 48, 32, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Welcome Back",
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Please sign in to your account",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 40),

                          _buildTextField(
                            controller: _CardIdtextController,
                            hint: "Staff Code",
                            icon: Icons.badge_outlined,
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _PasswordtextController,
                            hint: "Password",
                            icon: Icons.lock_outline,
                            isPassword: true,
                            obscureText: passwordVisibility,
                            onSuffixPressed: () => setState(() => passwordVisibility = !passwordVisibility),
                          ),

                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: Checkbox(
                                      value: _switchValue,
                                      activeColor: MyColors.appDefaultColorCode,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                      onChanged: (v) => setState(() => _switchValue = v!),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Remember me",
                                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPassword())),
                                child: Text(
                                  "Forgot Password?",
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: MyColors.appDefaultColorCode,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: MyColors.lightBlue,
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shadowColor: MyColors.appDefaultColorCode.withOpacity(0.4),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: _validation,
                              child: Text(
                                "LOGIN",
                                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account?",
                                style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final staffCode = await Navigator.push<String>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const RegisterScreen(),
                                    ),
                                  );

                                  if (staffCode != null && staffCode.isNotEmpty) {
                                    _CardIdtextController.text = staffCode;

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Registration successful. Your Staff Code is $staffCode',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: Text(
                                  "Register Now",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: MyColors.appDefaultColorCode,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
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
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onSuffixPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: MyColors.appDefaultColorCode, size: 20),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, size: 20),
            onPressed: onSuffixPressed,
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  void doLogin(String username, String passwordd) {
    _mainBloc.add(LoginEvents(username: username, password: passwordd));
  }

  void _validation() {
    if (_CardIdtextController.text.isEmpty) {
      Fluttertoast.showToast(msg: "Please Enter Staff Code");
    } else if (_PasswordtextController.text.isEmpty) {
      Fluttertoast.showToast(msg: "Please Enter Password");
    } else {
      checkLoggingUser();
    }
  }

  void checkLoggingUser() {
    String cardId = _CardIdtextController.text;
    String password = _PasswordtextController.text;

    if ((cardId == "mzdl002" && password == "Admin@123\$") || (cardId == "kdzl002" && password == "KdAdmin@1234\$")) {
      isAdminLogin = true;
    } else {
      isAdminLogin = false;
    }

    if (_switchValue) {
      storage.write(key: 'username', value: cardId);
      storage.write(key: 'password', value: password);
    } else {
      storage.delete(key: 'username');
      storage.delete(key: 'password');
    }
    doLogin(cardId, password);
  }

  Future<void> checkBiometrics() async {
    try {
      bool canCheckBiometrics = await auth.canCheckBiometrics;
      if (canCheckBiometrics) {
        await authenticate();
      } else {
        await authenticate();
      }
    } catch (e) {
      print("Error checking biometrics: $e");
    }
  }

  Future<void> authenticate() async {
    try {
      bool isAuthenticated = await auth.authenticate(
        localizedReason: 'Please authenticate to proceed',
      );

      if (isAuthenticated) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider(
              create: (context) => MainBloc(webService: WebService()),
              child: const HomeScreen(),
            ),
          ),
        );
      }
    } catch (e) {
      if (e is PlatformException) {
        if (e.code == 'NotAvailable') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (context) => MainBloc(webService: WebService()),
                child: const HomeScreen(),
              ),
            ),
          );
        }
      }
    }
  }
}
