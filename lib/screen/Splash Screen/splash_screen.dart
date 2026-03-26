import 'dart:async';
import 'dart:io';

import 'package:attendance_system_ios/bloc/main_bloc.dart';
import 'package:attendance_system_ios/bloc/main_event.dart';
import 'package:attendance_system_ios/bloc/main_state.dart';
import 'package:attendance_system_ios/screen/AdminHomeScreen/AdminHome.dart';
import 'package:attendance_system_ios/screen/Home/home.dart';
import 'package:attendance_system_ios/service/WebService.dart';
import 'package:attendance_system_ios/service/log_file_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart';
import '../../util/MyColor.dart';
import '../Login/login_screen.dart';
import '../../service/internet_service.dart';

class SplashScreen extends StatefulWidget {
  final String? initialPayload;
  const SplashScreen({super.key, this.initialPayload});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  // final FlutterSecureStorage storage = const FlutterSecureStorage(aOptions: AndroidOptions(
  //   encryptedSharedPreferences: true,
  // ));
  bool _switchValue = false;
  MainBloc? _mainBloc;

  bool _isLoading = false;
  bool isAdminLogin = false;

  @override
  void initState() {
    super.initState();
    // _mainBloc=BlocProvider.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await requestPermissions(); // Ensure all permissions are handled first
      await clearKeychainValues();
      await checkInternetAndProceed();
      if (widget.initialPayload != null) {
        Navigator.of(context).pushReplacementNamed(
          '/track_visit_location',
          arguments: widget.initialPayload,
        );
      } else {
        navigateToLoginScreen();
      }
    });

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  Future<void> requestPermissions() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
    await filePermission(context);
  }

  Future<void> filePermission(BuildContext context) async {
    if (Platform.isAndroid) {
      while (true) {
        if (!context.mounted) return; // safety check before loop

        PermissionStatus status = await Permission.manageExternalStorage.status;

        if (status.isGranted) {
          print("✅ Storage permission granted.");
          break; // Exit loop when granted
        }

        PermissionStatus newStatus = await Permission.manageExternalStorage.request();

        if (newStatus.isGranted) {
          print("✅ Storage permission granted.");
          break;
        } else if (newStatus.isPermanentlyDenied) {
          print("❌ Permission permanently denied. Opening settings...");
          await showPermissionDialog(
              context,
              "Storage Permission Required",
              "This app needs storage access to work properly. Please enable it in settings."
          );
          await openAppSettings();
        } else {
          await showPermissionDialog(
              context,
              "Storage Permission Required",
              "We need access to your storage to save and read files. Without this, the app cannot function."
          );
        }
      }
    } else {
      print("ℹ️ Storage permission not required on iOS.");
    }
  }

  Future<void> showPermissionDialog(BuildContext context, String title, String message) async {
    return showDialog(
      context: context,
      barrierDismissible: false, // User must tap button
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }


  Future<void> checkInternetAndProceed() async {
    try {
      bool hasInternet = await InternetService().hasInternetAccess();
      if (!hasInternet) {
        print("else: no internet");
        showNoInternetDialog();
      }
      else {
        return;
      }
    } catch (e) {
      debugPrint("Error checking internet: $e");
      InternetService().startListening(context); // Ensure the dialog shows
    }
  }

  void showNoInternetDialog() {
    BuildContext dialogContext; // To store the dialog's context

    // Show the dialog
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext dContext) {
        dialogContext = dContext; // Assign the dialog context
        // Start a timer to dismiss after 1 minute
        Timer(const Duration(days: 60), () {
          if (Navigator.of(dialogContext).canPop()) {
            Navigator.pop(dialogContext); // Auto-close after 60 seconds
          }
        });

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.blue, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off, size: 50, color: Colors.white),
                const SizedBox(height: 16),
                const Text(
                  "No Internet Connection",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Please try reconnecting to continue using the app.Heading to login screen!!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    bool hasInternet = await InternetService().hasInternetAccess();
                    if (hasInternet) {
                      if (Navigator.of(dialogContext).canPop()) {
                        Navigator.pop(dialogContext); // Close dialog
                      }
                      checkInternetAndProceed(); // Proceed if internet is back
                    }
                  },
                  child: const Text("retry"),
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
        print("First launch detected. Clearing secure storage...");
        await storage.deleteAll();
        await prefs.setBool('is_first_app_launch', false);
        print("Secure storage cleared and first launch flag updated.");
      } else {
        print("Not first launch. Skipping secure storage clearance.");
      }
    } catch (e) {
      print("Error clearing secure storage: $e");
      LogFileManager.writeLog("Error clearing secure storage: $e");
    }
  }


  @override
  void dispose(){
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
   // InternetService().stopListening();
   //  InternetService().stopListening();
    super.dispose();
  }

  Future<void> filepermission() async {
    // Check the file access permission status
    PermissionStatus status = await Permission.manageExternalStorage.status;

    if (status.isGranted) {
      // If permission is already granted, log the information
      print("File access permission already granted.");
    } else {
      // If permission is not granted, request the permission
      PermissionStatus newStatus = await Permission.manageExternalStorage.request();

      if (newStatus.isGranted) {
        print("File access permission granted after request.");
      } else if (newStatus.isDenied) {
        print("File access permission denied.");
      } else if (newStatus.isPermanentlyDenied) {
        print("File access permission permanently denied. Please enable it from settings.");
        // Optionally, open the app settings for the user
        await openAppSettings();
      }
    }
  }

  navigateToLoginScreen() async {
    _checkRememberMe();
  }

  @override
  Widget build(BuildContext context) {
    _mainBloc = context.read<MainBloc>();
    return Scaffold(
        body: _splashscreen()
    );
  }

  Future<void> _checkRememberMe() async {
    // final prefs = await SharedPreferences.getInstance();
    // String storedUsername = prefs.getString('username') ?? 'Null';
    // String storedPassword = prefs.getString('password') ?? 'Null';
    // String storedUsername = await storage.read(key: 'username')?? 'Null';
    // String storedPassword = await storage.read(key: 'password')?? 'Null';
    String storedUsername='Null';
    String storedPassword='Null';
    try {
      storedUsername = await storage.read(key: 'username') ?? 'Null';
      storedPassword = await storage.read(key: 'password') ?? 'Null';
    } catch (e) {
      if (e is PlatformException && e.message?.contains('BAD_DECRYPT') == true) {
        // Handle the error: Clear the corrupted data
        await storage.deleteAll();
        print('Secure storage reset due to decryption error.');
      } else {
        await storage.deleteAll();
        print('Unexpected error: $e');
      }
    }

    print(storedUsername);
    print(storedPassword);

    if (storedUsername != 'Null' && storedPassword != 'Null') {
      if(!isloggedIn){
        // String storedUsername = await storage.read(key: 'username') ?? 'Null';

        // if (storedUsername.isNotEmpty && storedUsername != 'Null') {
         isloggedIn=false;
         if (storedUsername == "mzdl002" && storedPassword == "Admin@123\$") {
           Navigator.pushReplacementNamed(context, "/AdminHome");
         }// Proceed to home
        else{
           Navigator.pushReplacementNamed(context, "/Home");
         }
        // } else {
        //   Navigator.pushReplacementNamed(context, "/Login"); // Go to login
        // }
      }
      _switchValue = true;

      if (storedUsername == "mzdl002" && storedPassword == "Admin@123\$") {
        isAdminLogin = true;
        doLogin(storedUsername, storedPassword);
      } else {
        isAdminLogin = false;
        doLogin(storedUsername, storedPassword);
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 4000));

      if (!mounted) return; // Check if the widget is still mounted before navigation

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );

      if (!mounted) return; // Check again before performing another navigation

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => MainBloc(webService: WebService()),
            child: LoginScreen(),
          ),
        ),
      );
    }
  }

  void doLogin(String username,String passwordd) {
    String userName = username;
    final password = passwordd;

    // Hash the password (you should hash the password for security reasons)
    // final String passwordHashed = BCrypt.hashpw(password, BCrypt.gensalt());
    _mainBloc!.add(LoginEvents(username: userName, password: password));
  }

  _splashscreen() {
   // Access Bloc safely inside build()
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
            if (state is LoginLoadingState) {
              setState(() {
                _isLoading = true;
              });
            } else if (state is LoginLoadedState) {
              setState(() {
                _isLoading = false;
              });

              if (state.loginResponse!.message != null) {
                /*   Fluttertoast.showToast(
                msg: "   Login Successfully...!   ",
                toastLength: Toast.LENGTH_SHORT,
                timeInSecForIosWeb: 1,
              );
*/
                await storage.write(key: 'Auth_Token', value: state.loginResponse!.token!.result!.token);
                // await storage.write(key: 'Staff_Code', value: state.loginResponse!.message!.staffCode);
                // await storage.write(key: 'Staff_Name', value: state.loginResponse!.message!.displayName);
                // SharedPreferences prefs = await SharedPreferences.getInstance();
                //
                // // Save values to shared preferences
                // await prefs.setString('Auth_TokenVal', state.loginResponse!.token!.result!.token.toString());
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
            } else if (state is LoginErrorState) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          child:
          Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        "assets/icons/graphic-design.png",
                        width: 100,
                        height: 105,
                      ),
                      const Text("Attendance System",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 28,color: MyColors.black, fontWeight: FontWeight.bold),
                      ),
                    ]
                ),
                Container(
                  alignment: Alignment.bottomCenter,
                  margin: const EdgeInsets.only(right: 37,left: 37,bottom: 35),
                  child:   const Text("@ Copy 2025 M-Tech Innovations Ltd Pune Attendance System",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14,color: MyColors.black),
                  ),
                )
              ]
          )
      ),
    );
  }

}

// class AppIntegrityChecker {
//   static const platform = MethodChannel('com.flutter_attendance/play_integrity_check');
//
//   Future<bool> checkAppIntegrity() async {
//     try {
//       final bool result = await platform.invokeMethod('checkAppIntegrity');
//       return result;
//     } on PlatformException catch (e) {
//       print("Failed to check app integrity: ${e.message}");
//       return false;
//     }
//   }
// }

// class _PlayIntegrity {
//   static const MethodChannel _channel = MethodChannel('com.flutter_attendance/play_integrity_check');
//
//   static Future<String?> getIntegrityToken() async {
//     try {
//       final String? token = await _channel.invokeMethod('getIntegrityToken');
//       return token;
//     } catch (e) {
//       print('Failed to get integrity token: $e');
//       return null;
//     }
//   }
// }
// Check if the user has previously logged in and chose "Remember Me"
//   Future<void> _checkRememberMe() async {
//     final prefs = await SharedPreferences.getInstance();
//     // String storedUsername = await storage.read(key: 'username') ?? 'Null';
//     // String storedPassword = await storage.read(key: 'password') ?? 'Null';
//     String storedUsername = prefs.getString('username') ?? 'Null';
//     String storedPassword = prefs.getString('password') ?? 'Null';
//     print(storedUsername);
//     print(storedPassword);
//
//     if (storedUsername != 'Null' && storedPassword != 'Null') {
//       // Auto-login user
//       /*   _CardIdtextController.text = storedUsername;
//       _PasswordtextController.text = storedPassword;*/
//       _switchValue = true;
//
//       if (storedUsername == "mzdl002" && storedPassword == "Admin@123\$") {
//         isAdminLogin = true;
//         doLogin(storedUsername,storedPassword);
//       } else {
//         isAdminLogin = false;
//         doLogin(storedUsername,storedPassword);
//       }
//       // doLogin(storedUsername,storedPassword);
//     } else {
//       await Future.delayed(const Duration(milliseconds: 4000), () {});
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (context) => const LoginScreen()),
//       );
//
//       Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//               builder: (_) => BlocProvider(
//                   create: (context) {
//                     return MainBloc(
//                         webService: WebService());
//                   },
//                   child: LoginScreen())));
//
//     }
//   }
///

// void showNoInternetDialog() {
//   Timer? timer; // Declare a timer
//
//   // Start a timer to close the dialog after 1 minute (60 seconds)
//   timer = Timer(const Duration(seconds: 60), () {
//     if (Navigator.canPop(context)) {
//       Navigator.pop(context); // Dismiss dialog if still open
//       Navigator.pushReplacementNamed(context, "/Login"); // Redirect to login
//     }
//   });
//
//   showDialog(
//     barrierDismissible: false,
//     context: context,
//     builder: (dialogContext) => Dialog(
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Container(
//         decoration: BoxDecoration(
//           gradient: const LinearGradient(
//             colors: [Colors.white],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//           borderRadius: BorderRadius.circular(20),
//         ),
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Icon(Icons.wifi_off, size: 50, color: Colors.black),
//             const SizedBox(height: 16),
//             const Text(
//               "No Internet Connection Found",
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
//             ),
//             const SizedBox(height: 8),
//             const Text(
//               "Heading you to login screen. Kindly switch on the internet to proceed.",
//               textAlign: TextAlign.center,
//               style: TextStyle(fontSize: 16, color: Colors.black),
//             ),
//             const SizedBox(height: 16),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blue.shade700,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//               ),
//               onPressed: () async {
//                 bool hasInternet = await InternetService().hasInternetAccess();
//                 if (hasInternet) {
//                   timer?.cancel(); // Cancel the timer if internet is back
//                   if (Navigator.canPop(dialogContext)) {
//                     Navigator.pop(dialogContext); // Close dialog
//                   }
//                   checkInternetAndProceed(); // Proceed further
//                 }
//               },
//               child: const Text("Retry"),
//             ),
//           ],
//         ),
//       ),
//     ),
//   ).then((_) {
//     // Cancel timer if dialog is manually closed
//     timer?.cancel();
//   });
// }