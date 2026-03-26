

import 'dart:io';
import 'dart:math';

import 'package:attendance_system_ios/bloc/main_event.dart';
import 'package:attendance_system_ios/bloc/main_state.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../bloc/main_bloc.dart';
import '../../util/MyColor.dart';

class Updatedeviceid extends StatefulWidget {
  const Updatedeviceid({super.key});

  @override
  State<Updatedeviceid> createState() => UpdatedeviceidState();
}

class UpdatedeviceidState extends State<Updatedeviceid>{
  final FocusNode _captchaFocusNode = FocusNode();
  late bool isLoading=false;
  late MainBloc _mainBloc;
  final storage = FlutterSecureStorage();
  TextEditingController _NewDeiceIdtextCintroller = TextEditingController();
  TextEditingController _StaffCodetextController = TextEditingController();
  TextEditingController _captchaInputController = TextEditingController();
  static const MethodChannel _channel = MethodChannel('com.example/device_id');
  String? _deviceId;
  String _generatedCaptcha = '';
  bool _showCaptcha = false;
  static const String lastUpdateKey = "last_device_update";



  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getDeviceId();
    generateCaptcha();
  }

  @override
  Widget build(BuildContext context) {
    _mainBloc = BlocProvider.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: true,

      body: _updatescreen(),
    );
  }
  _updatescreen() {
    return LoadingOverlay(
      isLoading: isLoading,
      opacity: 0.5,
      color: Colors.white,
      progressIndicator: CircularProgressIndicator(
        backgroundColor: Color(0xFFCE4A6F),
        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
      ),
      child: BlocListener<MainBloc,MainState>(listener: (context,state) async{
        if(state is updateUUIDLoadingState){
          isLoading=true;
        }
        else if(state is updateUUIDLoadedState){
          isLoading=false;
          if(state.apiresponsee.message=="UUID updated successfully."){
            Fluttertoast.showToast(msg: 'Id Updated Successfully');
            _captchaInputController.clear();

            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setInt(lastUpdateKey, DateTime.now().millisecondsSinceEpoch);

            setState(() {
              _showCaptcha=false;
            });
            return;
          }
          else if(state.apiresponsee.status == false && state.apiresponsee.message == "No changes were made."){
            Fluttertoast.showToast(msg: 'No changes were made');
            _captchaInputController.clear();
            setState(() {
              _showCaptcha=false;
            });
              return;
          }
          else if(state.apiresponsee.status == false){
            Fluttertoast.showToast(msg: 'Id Not Updated');
          }
        }

      },
        child:
        CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 80),
                    const Text(
                      'Register New Device',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Image.asset(
                      "assets/icons/mtechlogo2.png",
                      width: 220,
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Switched to a new device?\nClick SUBMIT to register your new device and continue using the app.',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _NewDeiceIdtextCintroller,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'New Device ID',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone_android),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _StaffCodetextController,
                      decoration: const InputDecoration(
                        labelText: 'Enter Staff Code',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: raisedButtonStyle,
                        onPressed: _validation,
                        child: const Text(
                          'SUBMIT',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    if (_showCaptcha) ...[
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'CAPTCHA:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            color: Colors.grey[300],
                            child: Text(
                              _generatedCaptcha,
                              style: const TextStyle(
                                fontSize: 18,
                                letterSpacing: 2,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: generateCaptcha,
                            tooltip: 'Refresh CAPTCHA',
                          )
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _captchaInputController,
                        decoration: const InputDecoration(
                          labelText: 'Enter CAPTCHA',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.verified_user),
                        ),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.verified),
                          onPressed: onVerifyAndSubmit,
                          label: const Text(
                            "Verify & Confirm",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        )

      ),
    );

  }
  void onVerifyAndSubmit() {
    if (_captchaInputController.text == _generatedCaptcha) {
      submitnewdeviceid();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("CAPTCHA does not match. Try again.")),
      );
      generateCaptcha();
      _captchaInputController.clear();
    }
  }
  final ButtonStyle raisedButtonStyle = ElevatedButton.styleFrom(
    foregroundColor: Colors.white, backgroundColor: MyColors.lightBlue,
    minimumSize: const Size(92, 40),
    // padding: EdgeInsets.symmetric(horizontal: 0),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
  );
  _validation() {
    if(_NewDeiceIdtextCintroller.text.isEmpty){
      Fluttertoast.showToast(
        msg: "  No Device ID Found   ",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
    }
    else if(_StaffCodetextController.text.isEmpty){
      Fluttertoast.showToast(
        msg: "  Please Enter StaffCode First!  ",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
    }
    else if(_StaffCodetextController.text.length != 7){
      Fluttertoast.showToast(
        msg: "  Please Enter Correct StaffCode !  ",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
    }
    else{
      onSubmitPressed();
     // validatecaptch();
      //submitnewdeviceid();
    }

  }
  Future<bool> canChangeDeviceID() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? lastUpdateMillis = prefs.getInt(lastUpdateKey);
    if (lastUpdateMillis == null) return true;

    DateTime lastUpdate = DateTime.fromMillisecondsSinceEpoch(lastUpdateMillis);
    final now = DateTime.now();
    return now.difference(lastUpdate).inDays >= 7;
  }
/*  void onSubmitPressed() async {
    bool canChange = await canChangeDeviceID();
    if (!canChange) {
      // Prevent showing captcha again
      setState(() {
        _showCaptcha = false;
      });
      Fluttertoast.showToast(msg: "Device ID can be changed only after 7 days.");
      return;
    }

    // If captcha already visible, don’t show dialog again
    if (_showCaptcha) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Confirm Change"),
        content: Text("Once Device ID is changed, it can only be changed after 7 days."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),

          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close the dialog

              bool canChangeAgain = await canChangeDeviceID();
              if (!canChangeAgain) {
                // Show snackbar instead of captcha
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Device ID can be changed only after 7 days.")),
                );
                return;
              }

              setState(() {
                _showCaptcha = true;
                generateCaptcha();
                FocusScope.of(context).requestFocus(_captchaFocusNode);
              });
            },
            child: Text("OK"),
          ),

        ],
      ),
    );
  }*/
///gemini
/*  void onSubmitPressed() async {
    bool canChange = await canChangeDeviceID();
    if (!canChange) {
      setState(() {
        _showCaptcha = false; // Ensure captcha is hidden
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Device ID can be changed only after 7 days.")),
      );
      return;
    }

    // If we reach here, it means canChange is true, so we can proceed with showing the dialog/captcha.
    // However, if the captcha is already shown (e.g., user dismissed the dialog but didn't enter captcha),
    // we don't want to show the dialog again.
    if (_showCaptcha) {
      // If captcha is already visible, focus on the input field
      FocusScope.of(context).requestFocus(_captchaFocusNode);
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Confirm Change"),
        content: Text("Once Device ID is changed, it can only be changed after 7 days."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
              setState(() {
                _showCaptcha = false; // Hide captcha if dialog is cancelled
              });
            },
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close the dialog

              // Re-check just before showing captcha, although it should be true here
              bool canChangeAgain = await canChangeDeviceID();
              if (canChangeAgain) {
                setState(() {
                  _showCaptcha = true;
                  generateCaptcha();
                  FocusScope.of(context).requestFocus(_captchaFocusNode);
                });
              } else {
                // This case should ideally not be hit if the initial check is correct
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Device ID can be changed only after 7 days.")),
                );
                setState(() {
                  _showCaptcha = false;
                });
              }
            },
            child: Text("OK"),
          ),
        ],
      ),
    );
  }*/
  void onSubmitPressed() async {
    bool canChange = await canChangeDeviceID();
    if (!canChange) {
      setState(() {
        _showCaptcha = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Device ID can be changed only after 7 days.")),
      );
      return;
    }

    // If we get here, it means we can change the device ID
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Confirm Change"),
        content: Text("Once Device ID is changed, it can only be changed after 7 days."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _showCaptcha = true;
                generateCaptcha();
                FocusScope.of(context).requestFocus(_captchaFocusNode);
              });
            },
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  void submitnewdeviceid(){
    String staffcode=_StaffCodetextController.text;
    String id = _deviceId!;
    _mainBloc.add(UpdateUUID(UserId: staffcode, UUID: id));
  }

  Future<String?> _getDeviceId() async {
    String? deviceId;
    try {
      if (Platform.isAndroid) {
        final String? result = await _channel.invokeMethod('getAndroidId');
        deviceId = result;
        return deviceId;
      } else if (Platform.isIOS) {
        DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor;
        return deviceId;
      }
    } on PlatformException catch (e) {
      deviceId = 'Failed to get Device ID: ${e.message}';
    } finally {
      setState(() {
        _deviceId = deviceId;
        String replacedText = _deviceId!.replaceAll(RegExp(r'[^.]'), '*');
        _NewDeiceIdtextCintroller.text = replacedText;
      });
      print('Device ID: $_deviceId');
    }

  }
  void generateCaptcha() {
    const chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    Random rand = Random();
    setState(() {
      _generatedCaptcha = List.generate(6, (index) => chars[rand.nextInt(chars.length)]).join();
    });
  }
}



