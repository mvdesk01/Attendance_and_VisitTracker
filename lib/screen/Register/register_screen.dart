import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:android_id/android_id.dart';
import 'package:attendance_system_ios/screen/Login/login_screen.dart';
import 'package:attendance_system_ios/service/log_file_manager.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:encrypt/encrypt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:uuid/uuid.dart';
import '../../bloc/main_bloc.dart';
import '../../service/WebService.dart';
import '../../util/MyColor.dart';
import 'package:http/http.dart' as http;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  final String username = "mtechattendence@gmail.com";
  final String password = "hjle ldkz vymh xgmg"; // App-specific password
  String? generatedOtp;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _cardIdController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _isOTPSent = false;
  bool _isLoading = false;
  bool passwordVisibility = true;
  int _resendCount = 0;
  DateTime? _otpSentTime;
  String? _verificationId;
  String? _selectedValue;
  String? deviceId;
  final storage = FlutterSecureStorage();

  final ButtonStyle raisedButtonStyle = ElevatedButton.styleFrom(
    foregroundColor: Colors.white,
    backgroundColor: MyColors.lightBlue,
    minimumSize: const Size(92, 40),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
  );


  @override
  void initState() {
    super.initState();
    //_initializeDeviceId();
    // _getId();
  }
  Future<String?> _getId() async {
    var deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) { // import 'dart:io'
      var iosDeviceInfo = await deviceInfo.iosInfo;
      return iosDeviceInfo.identifierForVendor; // unique ID on iOS
    } else if(Platform.isAndroid) {
      var androidDeviceInfo = await deviceInfo.androidInfo;
      print("androidDeviceInfo "+androidDeviceInfo.toString());
      print("AndroidId... "+AndroidId().getId().toString());

      return AndroidId().getId();
     // unique ID on Android
    }
  }

  // Future<void> _initializeDeviceId() async {
  //   String? savedDeviceId = await storage.read(key: "device_id");
  //   if (savedDeviceId == null) {
  //     String newDeviceId = const Uuid().v4();
  //     await storage.write(key: "device_id", value: newDeviceId);
  //     setState(() {
  //       deviceId = newDeviceId;
  //     });
  //   } else {
  //     setState(() {
  //       deviceId = savedDeviceId;
  //     });
  //   }
  // }

  Future<bool> checkUserByStaffCodeMobileNoAndEmail() async {
    String staffCode = _cardIdController.text.trim();
    String emailID = _emailController.text.trim();
    String mobileNo = _phoneController.text.trim().isEmpty ? '0000000000' : _phoneController.text.trim();
    try{
      final response = await http.get(
        Uri.parse('http://114.143.140.28:8020/Users/CheckUserByStaffCodeMobileNoAndEmail?StaffCode=$staffCode&EmailId=$emailID&MobileNo=$mobileNo'),
        // headers: {'Content-Type': 'application/json'}
      );
      if(response.statusCode == 200){
        final result = response.body;
        print("check user by email, mobile no. and staff code: ${result.toString()}");
        if(result.toString() == '{"message":"No Record Found.."}'){
          return true;
        }
        else if(result.toString() == '{"message":"MobileNo is Already Present..."}' && mobileNo == '0000000000'){
          return true;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result.toString()))
          );
        }
      }
    } catch(e){
      print('Error in checkUserByStaffCodeMobileNoAndEmail: $e');
      LogFileManager.writeLog('Error in checkUserByStaffCodeMobileNoAndEmail: $e');
    }

    return false;
  }

  // Function to generate a 6-digit OTP
  String generateOtp() {
    final random = Random();
    return List.generate(6, (index) => random.nextInt(10)).join();
  }

  // Function to send email with OTP
  void sendOtpEmail() async {
    String? result = _validateInputFieldsWithToasts();
    if (!_formKey.currentState!.validate() || result != null) {
      Fluttertoast.showToast(msg: result!);
      return; // Stop if there are validation errors
    }
    setState(() {
      _isLoading = true;
    });

    if(!await checkUserByStaffCodeMobileNoAndEmail()){
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Generate OTP
    generatedOtp = generateOtp();
    print('Generated OTP: $generatedOtp');

    // Configure the SMTP server
    final smtpServer = gmail(username, password);

    // Create the email message
    final message = Message()
      ..from = Address(username, 'M-Tech Attendance System')
      ..recipients.add(_emailController.text.trim()) // Add recipient email
      ..subject = 'Your OTP Code [M-Tech Attendance System]'
      ..text = '''
Dear User,

Thank you for using the M-Tech Attendance System.

Your One-Time Password (OTP) is: $generatedOtp

This OTP is valid for the next 5 minutes. Please use it promptly to complete your verification.

If you did not request this OTP, please ignore this email.

Best regards,  
M-Tech Attendance System Support Team
    ''';

    try {
      // Send the email
      final sendReport = await send(message, smtpServer);
      print('Email sent: ${sendReport.toString()}');
      LogFileManager.writeLog('Email sent: ${sendReport.toString()}');
      setState(() {
        _isOTPSent = true;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent successfully!')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Email not sent: $e');
      LogFileManager.writeLog('Email not sent: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send OTP: $e')),
      );
    }
  }

  // Function to verify the OTP
  void verifyOtp() {
    if (_otpController.text.trim() == generatedOtp) {
   /*   ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP Verified Successfully!')),
      );*/
      Fluttertoast.showToast(msg: 'OTP Verified Successfully!');

      // Perform further actions (e.g., navigate to another screen)
      _registerUser();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP. Please try again.')),
      );
    }
  }


  String? _validateInputFields(String value, String fieldName) {
    switch (fieldName) {
      case 'Card ID':
        if (value.isEmpty) {
          return 'Card ID cannot be empty';
        }
        break;
      case 'Name':
        if (value.isEmpty) return 'Name cannot be empty';
        break;
      case 'Email':
        if (!RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$').hasMatch(value)) {
          return 'Enter a valid email address.';
        }
        break;
      case 'Password':
        if (value.length < 8 ||
            !RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$')
                .hasMatch(value)) {
             return 'Password must be at least 8 characters long, contain a special character, a letter, and a number.';
             }
        break;
      case 'Mobile Number':
        if (value.isNotEmpty && !RegExp(r'^\d{10}$').hasMatch(value)) {
          return 'Mobile Number should be 10 digits.';
        }
        break;
    }
    return null;
  }

  String? _validateInputFieldsWithToasts() {
    if (_cardIdController.text.trim().isEmpty) {
      return 'Card ID cannot be empty';
    }
    if (_cardIdController.text.trim().length != 7) {
      return 'Card ID must be 7 digit';
    }
    if (_nameController.text.trim().isEmpty) {
      return 'Name cannot be empty';
    }
    if (_emailController.text.trim().isEmpty) {
      return 'Email cannot be empty';
    }
    if (!RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$').hasMatch(_emailController.text.trim())) {
      return 'Enter a valid email address.';
    }
    if (_passwordController.text.trim().isEmpty) {
      return 'Password cannot be empty';
    }
    if (_passwordController.text.trim().length < 8 ||
        !RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$')
            .hasMatch(_passwordController.text.trim())) {
      return 'Password must be at least 8 characters long, contain a special character, a letter, and a number.';
    }
    // if (_phoneController.text.trim().isEmpty) {
    //   return 'Mobile number cannot be empty';
    // }
    // if (!RegExp(r'^\d{10}$').hasMatch(_phoneController.text.trim())) {
    //   return 'Mobile Number should be 10 digits.';
    // }
    return null;
  }

  Future<void> _registerUser() async {
    setState(() {
      _isLoading = true;
    });
    try {
      String staffCode = _cardIdController.text.trim();
      String displayName = _nameController.text.trim();
      String emailID = _emailController.text.trim();
      String password = _passwordController.text.trim();
      String mobileNo = _phoneController.text.trim().isEmpty? 'null' : _phoneController.text.trim();
      String? deviceID = await _getId();

      // Get the current date in the required format
      final DateFormat dateFormat = DateFormat('yyyy-MM-ddTHH:mm:ss');
      final String visitDate = dateFormat.format(DateTime.now());

      // Encrypt the password using AES encryption
      // String encryptedPassword = encryptPassword(password);

      // Log the encrypted password for debugging (optional)
      // print("Encrypted password: $encryptedPassword");

      var headers = {
        // 'accept: */*'
        "Content-Type": "application/json",
        // "Authorization": "Basic $encryptedPassword"
      };

      var requestBody = jsonEncode({
        "staffCode": staffCode,
        "displayName": displayName,
        "emailID": emailID,
        "password": password,
        "mobileNo": mobileNo,
        "createdOn": visitDate,
        "createdBy": "string",
        "latitude": "string",
        "longitude": "string",
        "currAddress": "M tech Innovations,Phase-1, Hinjewadi,Pune",
        "uuid":deviceID ?? "unknown_device", // Pass the device ID or fallback
        "userType": "s",
        "plantCode": /*_selectedValue*/ "01",
        "uniqueNumber": "string"
      });

      // Make the API call
      final response = await http.post(
        Uri.parse("http://114.143.140.28:8020/Users/RegisterUser"),
        headers: headers,
        body: requestBody,
      );

      setState(() {
        _isLoading = false; // Hide loading spinner
      });

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print("Registration Success Response: $result");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Successfully registered!")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider(
              create: (context) => MainBloc(webService: WebService()),
              child: LoginScreen(),
            ),
          ),
        );
      } else {
        final errorResult = json.decode(response.body);
        print("Registration Error Response: $errorResult");
        LogFileManager.writeLog("Registration Error Response: $errorResult");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${errorResult['message']}")),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false; // Hide loading spinner
      });
      print("Registration failed: $e");
      LogFileManager.writeLog("Registration failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registration failed: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          // Back Button (Left)
                          IconButton(
                            icon: Icon(Icons.arrow_back, size: 28),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),

                          // Center Title (using Expanded)
                          Expanded(
                            child: Center(
                              child: Text(
                                'REGISTER',
                                style: TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),

                          // Placeholder for symmetry (invisible icon)
                          Opacity(
                            opacity: 0,
                            child: Icon(Icons.arrow_back, size: 28),
                          ),
                        ],
                      ),
                      SizedBox(height: 50),
                      Container(
                        width: 100,
                        height: 110,
                        child: Image.asset('assets/icons/graphic-design.png'),
                      ),
                      SizedBox(height: 50),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            TextFormField(
                              maxLength: 7,
                              controller: _cardIdController,
                              decoration: InputDecoration(
                                labelText: '7-digit Unique ID',
                                helperText: 'Use this ID to log in after registration',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                return _validateInputFields(value!, 'Card ID');
                              },
                            ),
                            SizedBox(height: 15),
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Name',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                return _validateInputFields(value!, 'Name');
                              },
                            ),
                            SizedBox(height: 15),
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                return _validateInputFields(value!, 'Email');
                              },
                            ),
                            SizedBox(height: 15),
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                border: OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: Icon(passwordVisibility
                                      ? Icons.visibility
                                      : Icons.visibility_off),
                                  onPressed: () {
                                    setState(() {
                                      passwordVisibility = !passwordVisibility;
                                    });
                                  },
                                ),
                              ),
                              obscureText: passwordVisibility,
                              validator: (value) {
                                return _validateInputFields(value!, 'Password');
                              },
                            ),
                            Text("*Password must be 8 digit long and should contain atleast one:"
                                "1. Uppercase"
                                "2. lowercase"
                                "3.number and special characters", style: TextStyle(color: Colors.red,fontSize: 10), ),
                            SizedBox(height: 15),
                            TextFormField(
                              keyboardType: TextInputType.phone,
                              controller: _phoneController,
                              decoration: InputDecoration(
                                labelText: 'Mobile Number(optional)',
                                border: OutlineInputBorder(),
                                counterText: "10",
                              ),
                              maxLength: 10,
                              validator: (value) {
                                return _validateInputFields(value!, 'Mobile Number');
                              },
                            ),
                            /*SizedBox(height: 15),
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: "Select PlantCode",
                                border: OutlineInputBorder()
                              ),
                                value: _selectedValue,
                                items: [
                                  DropdownMenuItem(
                                    value: null,
                                    child: Text("Please Select"),
                                  ),DropdownMenuItem(
                                    value: "01",
                                    child: Text("01"),
                                  ),
                                  DropdownMenuItem(
                                    value: "02",
                                    child: Text("02"),
                                  ),

                                ], onChanged: (String? newValue){
                                setState(() {
                                  _selectedValue = newValue;
                                });
                            },
                              validator: (value){
                                if(value == null || value == "Please Select"){
                                  return 'Please select plant code';
                                }
                                return null;
                              },
                            ),*/
                            SizedBox(height: 15),
                            ElevatedButton(
                              style: raisedButtonStyle,
                              onPressed: _isLoading ? null : sendOtpEmail,
                              child: const Text('Send OTP'),
                            ),
                            SizedBox(height: 15),
                            Visibility(
                              visible: _isOTPSent,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _otpController,
                                    decoration: InputDecoration(
                                      labelText: 'OTP',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  SizedBox(height: 15),
                                  ElevatedButton(
                                    style: raisedButtonStyle,
                                    onPressed: verifyOtp,
                                    child: Text('Verify OTP'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5), // Semi-transparent background
              child: const Center(
                child: CircularProgressIndicator(
                  color: MyColors.lightBlue,
                ),
              ),
            ),
        ],
      ),
    );
  }

}



/// password encryption crypto
/*
  void check() {
     String password="Admin@123\$";
    final bytes = utf8.encode(password); // Convert string to bytes

    final passwordd= sha256.convert(bytes); // Perform SHA-256 hashing

    String  encryptedPasswordd=passwordd.toString();
    print("encryptedPasswordd: $encryptedPasswordd");
  }
*/
/// password encryption AES
/*String encryptPassword(String password) {
  // Replace these with the actual values provided by your API provider
  final key = encrypt.Key.fromUtf8('abcdefghijklmno9'); // Must be 32 chars
  final iv = encrypt.IV.fromUtf8('abcdefghijklmnop'); // Must be 16 chars

  final encrypter = Encrypter(AES(key, mode: AESMode.cbc, padding: 'PKCS7'));

  final encrypted = encrypter.encrypt(password, iv: iv);

  // Return Base64-encoded encrypted string
  return encrypted.base64.toString();
}*/


/// Firebase -> send otp, verify otp
//  // Future<void> _sendOTP() async {
//   //   String? result = _validateInputFieldsWithToasts();
//   //   if (!_formKey.currentState!.validate() || result != null) {
//   //     Fluttertoast.showToast(msg: result!);
//   //     return; // Stop if there are validation errors
//   //   }
//   //
//   //   if (_resendCount >= 3) {
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       const SnackBar(content: Text("Max resend attempts reached. Try again later.")),
//   //     );
//   //     return;
//   //   }
//   //
//   //   String phone = "+91${_phoneController.text.trim()}";
//   //
//   //   setState(() {
//   //     _isLoading = true;
//   //   });
//   //
//   //   await _auth.verifyPhoneNumber(
//   //     phoneNumber: phone,
//   //     verificationCompleted: (PhoneAuthCredential credential) async {
//   //       await _auth.signInWithCredential(credential);
//   //       _registerUser();
//   //     },
//   //     verificationFailed: (FirebaseAuthException e) {
//   //       setState(() {
//   //         _isLoading = false;
//   //       });
//   //       ScaffoldMessenger.of(context).showSnackBar(
//   //         SnackBar(content: Text("Failed to send OTP: ${e.message}")),
//   //       );
//   //     },
//   //     codeSent: (String verificationId, int? resendToken) {
//   //       setState(() {
//   //         _isOTPSent = true;
//   //         _verificationId = verificationId;
//   //         _isLoading = false;
//   //         _otpSentTime = DateTime.now();
//   //         _resendCount++;
//   //       });
//   //     },
//   //     codeAutoRetrievalTimeout: (String verificationId) {
//   //       setState(() {
//   //       _verificationId = verificationId;
//   //       _isOTPSent = true;
//   //       });
//   //     },
//   //   );
//   // }
//
//  /* Future<void> _verifyOTP() async {
//     final String smsCode = _otpController.text.trim();
//
//     if (_verificationId != null) {
//       // Check if OTP has expired (10 minutes from _otpSentTime)
//       if (_otpSentTime != null && DateTime.now().difference(_otpSentTime!).inMinutes > 10) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("OTP expired. Please request a new one.")),
//         );
//         setState(() {
//           _isOTPSent = false;
//           _otpController.clear();
//         });
//         return;
//       }
//
//       try {
//         // Verify OTP within 10 minutes
//         PhoneAuthCredential credential = PhoneAuthProvider.credential(
//           verificationId: _verificationId!,
//           smsCode: smsCode,
//         );
//
//         // Attempt signing in with the OTP credential
//         await _auth.signInWithCredential(credential);
//         _registerUser();
//       } on FirebaseAuthException catch (e) {
//         // Check for specific error codes and handle appropriately
//         if (e.code == 'invalid-verification-code') {
//           // Allow retries within 10 minutes, treating "Invalid OTP" as incorrect entry
//           if (_otpSentTime != null && DateTime.now().difference(_otpSentTime!).inMinutes <= 10) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text("Incorrect OTP. Please try again.")),
//             );
//           } else {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text("OTP expired. Please request a new one.")),
//             );
//             setState(() {
//               _isOTPSent = false;
//               _otpController.clear();
//             });
//           }
//         } else {
//           // Handle other exceptions
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text("An error occurred: ${e.message}")),
//           );
//         }
//       }
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("No OTP request found. Please request a new OTP.")),
//       );
//     }
//   }*/


/*Future<void> _registerUser() async {
    setState(() {
      _isLoading = true; // Show loading spinner
    });

    try {
      String staffCode = _cardIdController.text.trim();
      String displayName = _nameController.text.trim();
      String emailID = _emailController.text.trim();
      String password = _passwordController.text.trim();
      String mobileNo = _phoneController.text.trim();
      String? deviceId= await _getId();
      // Get current date and format it
      final DateFormat dateFormat = DateFormat('yyyy-MM-ddTHH:mm:ss');
      final String visitDate = dateFormat.format(DateTime.now());

      // Hash the password using bcrypt
     // String hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());
     // print("Hashed password: $hashedPassword");
      final bytes = utf8.encode(password); // Convert string to bytes

      final passwordd= sha256.convert(bytes); // Perform SHA-256 hashing

    String  encryptedPasswordd=passwordd.toString();

      // Prepare the request headers and body
      var headers = {
        "Content-Type": "application/json",
     //   "Authorization": "Basic $hashedPassword"
      };

      var requestBody = jsonEncode({
        "staffCode": staffCode,
        "displayName": displayName,
        "emailID": emailID,
        "password": encryptedPasswordd,
        "mobileNo": mobileNo,
        "createdOn": visitDate,
        "createdBy": "string",
        "latitude": "string",
        "longitude": "string",
        "currAddress": "string",
        "uuid":deviceId ?? "unknown_device", // Pass the device ID or fallback
        "userType": "s",
        "uniqueNumber": "string"
      });

      // Make the API call
      final response = await http.post(
        Uri.parse("http://114.143.140.28:8020/Users/RegisterUser"),
        headers: headers,
        body: requestBody,
      );

      setState(() {
        _isLoading = false; // Hide loading spinner
      });

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print("Registration Success Response: $result");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Successfully registered!")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider(
              create: (context) => MainBloc(webService: WebService()),
              child: LoginScreen(),
            ),
          ),
        );
      } else {
        final errorResult = json.decode(response.body);
        print("Registration Error Response: $errorResult");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${errorResult['message']}")),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false; // Hide loading spinner
      });
      print("Registration failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registration failed: ${e.toString()}")),
      );
    }
  }*/