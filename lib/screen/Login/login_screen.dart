import 'package:attendance_system_ios/bloc/main_bloc.dart';
import 'package:attendance_system_ios/bloc/main_event.dart';
import 'package:attendance_system_ios/bloc/main_state.dart';
import 'package:attendance_system_ios/screen/AdminHomeScreen/AdminHome.dart';
import 'package:attendance_system_ios/screen/Home/home.dart';
import 'package:attendance_system_ios/screen/Register/register_screen.dart';
import 'package:attendance_system_ios/service/WebService.dart';
import 'package:attendance_system_ios/service/log_file_manager.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:local_auth/local_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart';
import '../../util/MyColor.dart';
import '../Forget Password/forgetpassword.dart';
import '../password retrieval/password_retrieval.dart';
import 'UpdateDeviceID.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  var checkedValue;
  var isLoading;
  bool _switchValue = true;
  bool passwordVisibility = true;

  late bool _isLoading = false;
  late MainBloc _mainBloc;
  final storage = FlutterSecureStorage();
  TextEditingController _CardIdtextController = TextEditingController();
  TextEditingController _PasswordtextController = TextEditingController();
  String? mdeviceId = "";

  bool isAdminLogin = false;
  LocalAuthentication auth = LocalAuthentication();

  @override
  void activate() {}

  final ButtonStyle raisedButtonStyle = ElevatedButton.styleFrom(
    foregroundColor: Colors.white, backgroundColor: MyColors.lightBlue,
    minimumSize: const Size(92, 40),
    // padding: EdgeInsets.symmetric(horizontal: 0),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
  );

  @override
  void initState() {
    super.initState();
    print(isloggedIn);

    ///changes
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   InternetService().startListening(MyApp.navigatorKey.currentState!.overlay!.context);
    // });
  }

  void dispose() {
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
      PermissionStatus newStatus =
          await Permission.manageExternalStorage.request();

      if (newStatus.isGranted) {
        print("File access permission granted after request.");
      } else if (newStatus.isDenied) {
        print("File access permission denied.");
      } else if (newStatus.isPermanentlyDenied) {
        print(
            "File access permission permanently denied. Please enable it from settings.");
        // Optionally, open the app settings for the user
        await openAppSettings();
      }
    }
  }

  Future<String?> _getId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    print(androidInfo.id);
    return androidInfo.id; // This should return ANDROID_ID

    // var deviceInfo = DeviceInfoPlugin();
    // if (Platform.isIOS) { // import 'dart:io'
    //   var iosDeviceInfo = await deviceInfo.iosInfo;
    //   return iosDeviceInfo.identifierForVendor; // unique ID on iOS
    // } else if(Platform.isAndroid) {
    //   var androidDeviceInfo = await deviceInfo.androidInfo;
    //   print("androidDeviceInfo "+androidDeviceInfo.toString());
    //   print("AndroidId... "+AndroidId().getId().toString());
    //
    //   return AndroidId().getId(); // unique ID on Android
    // }
  }

  @override
  Widget build(BuildContext context) {
    _mainBloc = BlocProvider.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: _loginscreen(),
    );
  }

  _loginscreen() {
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
              if (state.loginResponse?.message != null) {
                print("Login successfull!!!");
                // Fluttertoast.showToast(
                //   msg: "   Login Successfully...!   ",
                //   toastLength: Toast.LENGTH_SHORT,
                //   timeInSecForIosWeb: 1,
                // );

                // Store Auth Token and other details
                await storage.write(
                    key: 'Auth_Token',
                    value: state.loginResponse!.token!.result!.token);
                await storage.write(
                    key: 'Staff_Code',
                    value: state.loginResponse!.message!.staffCode);
                await storage.write(
                    key: 'Staff_Name',
                    value: state.loginResponse!.message!.displayName);

                SharedPreferences prefs = await SharedPreferences.getInstance();

                // Save values to shared preferences
                await prefs.setString('Auth_TokenVal',
                    state.loginResponse!.token!.result!.token.toString());
                String? Auth_TokenVall = prefs.getString("Auth_TokenVal");

                print(isloggedIn);
                print("HEREEEEEEEEEEEEEEEEEEEEEEEEEE " + Auth_TokenVall!);
                if (isAdminLogin) {
                  // Admin login does not require device ID check
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider(
                        create: (context) {
                          return MainBloc(webService: WebService());
                        },
                        child: AdminHomeScreen(),
                      ),
                    ),
                  );
                } else {
                  await checkBiometrics();
                }
                // else {
                //   // For user login, verify device ID
                //   String? responseDeviceId =state.loginResponse!.message!.uuid;
                //   print("Database response Device Id: ${state.loginResponse!.message!.uuid}");
                //   print("Current device Id: ${AndroidId().getId()}");// Device ID from response
                //   String? deviceId= await   _getId();
                //   print("deviceIdddd: ${deviceId}");// Device ID from response
                //   await checkBiometrics();
                //    if (responseDeviceId == deviceId) {
                //     Fluttertoast.showToast(
                //       msg: "   Login Successfully...!   ",
                //       toastLength: Toast.LENGTH_SHORT,
                //       timeInSecForIosWeb: 1,
                //     );
                //     // Navigate to User Home Screen
                //     Navigator.pushReplacement(
                //       context,
                //       MaterialPageRoute(
                //         builder: (_) => BlocProvider(
                //           create: (context) {
                //             return MainBloc(webService: WebService());
                //           },
                //           child: HomeScreen(),
                //         ),
                //       ),
                //     );
                //   await checkBiometrics();
                //   }
                //    else if(false) {
                //     Fluttertoast.showToast(
                //       msg: 'Please Login from Registered Device',
                //       toastLength: Toast.LENGTH_SHORT,
                //       timeInSecForIosWeb: 2,
                //     );
                //   }
                // }
              } else {
                // uncomment if login gives the issue in second time login
                storage.delete(key: 'username');
                storage.delete(key: 'password');
              }
            } else if (state is LoginErrorState) {
              print("login error state message");
              // if(state.msg ==)
              setState(() {
                _isLoading = false;
              });
            }
          },
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                      // mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 100),
                        Column(
                          children: [
                            Image.asset(
                              "assets/icons/graphic-design.png",
                              width: 100,
                              height: 110,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "Attendance System",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 6),
                            const Text(
                              "Sign in to continue",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          "Login",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        SizedBox(height: 5),
                        const SizedBox(height: 30),

                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 12),
                          child: TextFormField(
                            controller: _CardIdtextController,
                            decoration: InputDecoration(
                              labelText: 'Staff Code',
                              prefixIcon: const Icon(Icons.badge_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 12),
                          child: TextFormField(
                            controller: _PasswordtextController,
                            obscureText: passwordVisibility,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  passwordVisibility
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    passwordVisibility = !passwordVisibility;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Row(
                            children: [
                              Transform.scale(
                                scale: 0.9,
                                child: CupertinoSwitch(
                                  value: _switchValue,
                                  activeColor: MyColors.lightBlue,
                                  onChanged: (value) {
                                    setState(() {
                                      _switchValue = value;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "Remember me",
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 20),
                          child: SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: MyColors.lightBlue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: _validation,
                              child: const Text(
                                'LOGIN',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ),

                        Padding(padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                      const PasswordRetrieval()),
                                );
                              },
                              child: const Text("Password\nRetrieval"),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const ForgotPassword()),
                                );
                              },
                              child: const Text(
                                  " Forgot Password?\n(only for operators) "),
                            ),
                            // const SizedBox(width: 10),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const RegisterScreen()),
                                );
                              },
                              child: const Text("Register"),
                            ),
                          ],
                        ),
                        ),

                        const SizedBox(height: 20,),
                        Center(
                          child:
                            TextButton(onPressed: (){
                              Navigator.push(context, MaterialPageRoute(builder: (context)=> const Updatedeviceid()));
                              //Navigator.push(context, MaterialPageRoute(builder: (context)=> Updatedeviceidnew()));
                            },
                                child: const Text('Switched To New Device?Register New Device Here!'))

                        )

                      ])),
            ],
          )),
    );
  }

  void doLogin(String username, String passwordd) {
    String userName = username;
    String password = passwordd;

    // Hash the password (you should hash the password for security reasons)
    // final String passwordHashed = BCrypt.hashpw(password, BCrypt.gensalt());
    _mainBloc.add(LoginEvents(username: userName, password: password));
  }

  void _validation() {
    if (_CardIdtextController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "  Please Enter Your CardId...!   ",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
    } else if (_PasswordtextController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "  Please Enter Password...!   ",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
    } else {
      checkLoggingUser();
    }
  }

  void checkLoggingUser() {
    String cardId = _CardIdtextController.text;
    String password = _PasswordtextController.text;

    // Check if the user is admin (you can adapt this logic as necessary)
    if (cardId == "mzdl002" && password == "Admin@123\$" ||
        cardId == "kdzl002" && password == "KdAdmin@1234\$") {
      isAdminLogin = true;
      doLogin(cardId, password);
    } else {
      isAdminLogin = false;
      doLogin(cardId, password);
    }

    // If "Remember Me" is selected, save the login credentials
    if (_switchValue) {
      storage.write(key: 'username', value: cardId);
      storage.write(key: 'password', value: password);
    } else {
      storage.delete(key: 'username');
      storage.delete(key: 'password');
    }
  }

  Future<void> checkDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();

    await checkBiometrics();
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
        Fluttertoast.showToast(
          msg: "  No biometrics available on this device...!   ",
          toastLength: Toast.LENGTH_SHORT,
          timeInSecForIosWeb: 1,
        );

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
        Fluttertoast.showToast(
          msg: "  Authentication successful",
          toastLength: Toast.LENGTH_LONG,
          timeInSecForIosWeb: 1,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider(
              create: (context) => MainBloc(webService: WebService()),
              child: HomeScreen(),
            ),
          ),
        );
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
            Fluttertoast.showToast(
              msg: "Biometric authentication is not available on this device.",
              toastLength: Toast.LENGTH_LONG,
              timeInSecForIosWeb: 1,
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider(
                  create: (context) => MainBloc(webService: WebService()),
                  child: HomeScreen(),
                ),
              ),
            );

            break;
          case 'NotEnrolled':
            LogFileManager.writeLog(
                "No biometrics enrolled. Please enroll your fingerprint or Face ID in device settings.");
            print(
                "No biometrics enrolled. Please enroll your fingerprint or Face ID in device settings.");
            Fluttertoast.showToast(
              msg:
                  "No biometrics enrolled. Please enroll your fingerprint or Face ID in device settings.",
              toastLength: Toast.LENGTH_LONG,
              timeInSecForIosWeb: 1,
            );
            break;
          case 'LockedOut':
            print(
                "Biometric authentication is temporarily locked. Please try again later.");
            LogFileManager.writeLog(
                "Biometric authentication is temporarily locked. Please try again later.");
            Fluttertoast.showToast(
              msg:
                  "Biometric authentication is temporarily locked. Please try again later.",
              toastLength: Toast.LENGTH_LONG,
              timeInSecForIosWeb: 1,
            );
            break;
          case 'Failed':
            print("Authentication failed. Please try again.");
            LogFileManager.writeLog("Authentication failed. Please try again.");
            Fluttertoast.showToast(
              msg: "Authentication failed. Please try again.",
              toastLength: Toast.LENGTH_LONG,
              timeInSecForIosWeb: 1,
            );
            break;
          case 'UserCancel':
            print("Authentication was canceled by the user.");
            LogFileManager.writeLog("Authentication was canceled by the user.");
            Fluttertoast.showToast(
              msg: "Authentication was canceled by the user.",
              toastLength: Toast.LENGTH_LONG,
              timeInSecForIosWeb: 1,
            );
            break;
          case 'PasscodeNotSet':
            print("A passcode must be set to use biometric authentication.");
            LogFileManager.writeLog(
                "A passcode must be set to use biometric authentication.");
            Fluttertoast.showToast(
              msg: "A passcode must be set to use biometric authentication.",
              toastLength: Toast.LENGTH_LONG,
              timeInSecForIosWeb: 1,
            );
            break;
          default:
            print("An unexpected error occurred: ${e.message}");
            LogFileManager.writeLog(
                "An unexpected error occurred: ${e.message}");
            Fluttertoast.showToast(
              msg: "An unexpected error occurred: ${e.message}",
              toastLength: Toast.LENGTH_LONG,
              timeInSecForIosWeb: 1,
            );
        }
      }
    }
  }
}
