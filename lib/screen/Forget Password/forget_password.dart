// import 'dart:async';
// import 'dart:convert';
//
// import 'package:attendance_system_ios/screen/Login/login_screen.dart';
// import 'package:attendance_system_ios/util/MyColor.dart';
// import 'package:bcrypt/bcrypt.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:http/http.dart' as http;
//
// import '../../bloc/main_bloc.dart';
// import '../../service/WebService.dart';
//
// class ForgetPassword extends StatefulWidget {
//   const ForgetPassword({Key? key}) : super(key: key);
//
//   @override
//   State<ForgetPassword> createState() => _ForgetPasswordState();
// }
//
// class _ForgetPasswordState extends State<ForgetPassword> {
//   final TextEditingController _staffCodeController = TextEditingController();
//   final TextEditingController _otpController = TextEditingController();
//   final TextEditingController _newPasswordController = TextEditingController();
//   final TextEditingController _confirmPasswordController = TextEditingController();
//
//   bool isLoading = false;
//
//   bool isResendOtp = false;
//   String? _phone;
//   String? staffCode;
//   String? _maskedPhone;
//   String? _verificationId;
//   bool _isOTPSent = false;
//   bool _isOTPVerified = false;
//
//   int _resendAttempts = 0; // Counter for resend attempts
//   bool _isResendDisabled = false; // To control resend button state
//   int _resendCooldown = 30; // Cooldown in seconds
//   Timer? _timer; // Timer instance for cooldown
//
//   final ButtonStyle raisedButtonStyle = ElevatedButton.styleFrom(
//     foregroundColor: Colors.white,
//     backgroundColor: Colors.blue,
//     minimumSize: const Size(92, 40),
//     shape: const RoundedRectangleBorder(
//       borderRadius: BorderRadius.all(Radius.circular(8)),
//     ),
//   );
//
//   Future<void> _getUserInfoByStaffCode() async {
//     staffCode = _staffCodeController.text.trim();
//     if (staffCode!.isEmpty) {
//       Fluttertoast.showToast(msg: "Please enter your staff code.");
//       return;
//     }
//
//     setState(() {
//       isLoading = true;
//     });
//
//     try {
//       final response = await http.get(
//         Uri.parse('http://114.143.140.28:8091/Users/GetUserInfoByStaffCode?staffCode=$staffCode'),
//         headers: {'Content-Type': 'application/json'},
//       );
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (data['message']['mobileNo'] != null) {
//           String phone = data['message']['mobileNo'];
//           setState(() {
//             _phone = phone;
//             _maskedPhone = _maskPhone(phone);
//           });
//           Fluttertoast.showToast(msg: "Phone fetched successfully.");
//           setState(() {
//             isLoading = false;
//           });
//           _sendOtp();
//         } else {
//           Fluttertoast.showToast(msg: "Staff code not found.");
//         }
//       } else {
//         setState(() {
//           isLoading = false;
//         });
//         Fluttertoast.showToast(msg: "Failed to fetch user info. Try again.");
//       }
//     } catch (e) {
//       setState(() {
//         isLoading = false;
//       });
//       Fluttertoast.showToast(msg: "Error fetching user details: $e");
//     }
//   }
//
//   String _maskPhone(String phone) {
//     return phone.substring(0, 2) + "*" * (phone.length - 4) + phone.substring(phone.length - 2);
//   }
//
//   Future<void> _sendOtp() async {
//     if (_phone == null) {
//       Fluttertoast.showToast(msg: "Please fetch your phone number first.");
//       return;
//     }
//
//     if (_resendAttempts >= 3) {
//       Fluttertoast.showToast(msg: "Resend limit reached. Try again later.");
//       return;
//     }
//
//     setState(() {
//       _isResendDisabled = true;
//       _resendAttempts++;
//       _resendCooldown = 30; // Reset cooldown
//     });
//
//     try {
//       await FirebaseAuth.instance.verifyPhoneNumber(
//         phoneNumber: "+91$_phone",
//         timeout: const Duration(seconds: 60),
//         verificationCompleted: (PhoneAuthCredential credential) async {
//           await FirebaseAuth.instance.signInWithCredential(credential);
//           setState(() {
//             _isOTPVerified = true;
//           });
//           Fluttertoast.showToast(msg: "Phone number verified automatically.");
//         },
//         verificationFailed: (FirebaseAuthException e) {
//           Fluttertoast.showToast(msg: "Verification failed: ${e.message}");
//         },
//         codeSent: (String verificationId, int? resendToken) {
//           setState(() {
//             _verificationId = verificationId;
//             _isOTPSent = true;
//           });
//           Fluttertoast.showToast(msg: "OTP sent to your phone.");
//         },
//         codeAutoRetrievalTimeout: (String verificationId) {
//           _verificationId = verificationId;
//         },
//       );
//     } catch (e) {
//       Fluttertoast.showToast(msg: "Error sending OTP: $e");
//     }
//
//     // Start the cooldown timer
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       setState(() {
//         if (_resendCooldown > 0) {
//           _resendCooldown--;
//         } else {
//           _isResendDisabled = false;
//           timer.cancel();
//         }
//       });
//     });
//   }
//
//   Future<void> _verifyOtp() async {
//     String enteredOtp = _otpController.text.trim();
//
//     if (_verificationId == null || enteredOtp.isEmpty) {
//       Fluttertoast.showToast(msg: "Please enter the OTP.");
//       return;
//     }
//
//     try {
//       PhoneAuthCredential credential = PhoneAuthProvider.credential(
//         verificationId: _verificationId!,
//         smsCode: enteredOtp,
//       );
//
//       await FirebaseAuth.instance.signInWithCredential(credential);
//       setState(() {
//         _isOTPVerified = true;
//       });
//       Fluttertoast.showToast(msg: "OTP verified successfully.");
//     } catch (e) {
//       Fluttertoast.showToast(msg: "Invalid OTP. Please try again.");
//     }
//   }
//
//   Future<void> _resetPassword() async {
//     String newPassword = _newPasswordController.text.trim();
//     String confirmPassword = _confirmPasswordController.text.trim();
//
//     if (newPassword.isEmpty || confirmPassword.isEmpty) {
//       Fluttertoast.showToast(msg: "Please fill out both password fields.");
//       return;
//     }
//
//     if (newPassword != confirmPassword) {
//       Fluttertoast.showToast(msg: "Passwords do not match.");
//       return;
//     }
//     _forgetPassword(newPassword);
//   }
//
//   Future<void> _forgetPassword(String password) async {
//
//     setState(() {
//       isLoading = true;
//     });
//
//     /*String hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());
//
//     // Log the hashed password for debugging (optional)
//     print("Hashed password: $hashedPassword");
//
//     var headers = {
//       "Content-Type": "application/json",
//       "Authorization": "Basic $hashedPassword"
//     };
//
//     var requestBody = jsonEncode({
//       "StaffCode": "cd03059",
//       "Password": hashedPassword,
//     });*/
//
//     try {
//       final response = await http.post(
//         // Uri.parse('http://114.143.140.28:8091/Users/ForgotPassword'),
//         Uri.parse('http://114.143.140.28:8091/Users/ForgotPassword?StaffCode=$staffCode&Password=$password'),
//         // headers: {"Content-Type": "application/json"},
//         // body: json.encode({
//         //   'StaffCode': 'cd03059',
//         //   'Password': "Manish@1"
//         // })
//       );
//
//       setState(() {
//         isLoading = false;
//       });
//
//       if (response.statusCode == 200) {
//         // Handle successful response
//         Map<String, dynamic> result = json.decode(response.body);
//         print("Success: ${result['message']}");
//         Fluttertoast.showToast(msg: "Password Updated Successfully.");
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (_) => BlocProvider(
//               create: (context) => MainBloc(webService: WebService()),
//               child: const LoginScreen(),
//             ),
//           ),
//         );
//       } else {
//         // Handle error response
//         Map<String, dynamic> result = json.decode(response.body);
//         print("Error: ${result['message']}");
//         print("Error: ${result['error']}");
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(result['message'] ?? "Failed to forget password. Try again")),
//         );
//       }
//     } catch (e) {
//       setState(() {
//         isLoading = false;
//       });
//       print("Error on forget password: $e");
//     }
//   }
//
//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }
//
//   Widget _buildResendOtpButton() {
//     return Column(
//       children: [
//         ElevatedButton(
//           style: raisedButtonStyle.copyWith(
//             backgroundColor: MaterialStateProperty.all(
//               _isResendDisabled ? Colors.grey : Colors.blue,
//             ),
//           ),
//           onPressed: _sendOtp,
//           child: const Text('Resend OTP'),
//         ),
//         if (_isResendDisabled)
//           Text(
//             "Enable in $_resendCooldown sec",
//             style: const TextStyle(fontSize: 14, color: Colors.red),
//           ),
//         Text(
//           "Attempts: $_resendAttempts/3",
//           style: const TextStyle(fontSize: 14, color: Colors.grey),
//         ),
//       ],
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       resizeToAvoidBottomInset: true,
//       appBar: AppBar(
//         title: const Text("Forget Password"),
//         backgroundColor: Colors.blue,
//       ),
//       body: Stack(
//         children: [
//           SingleChildScrollView(
//             child: Column(
//               children: [
//                 const SizedBox(height: 40),
//                 const Text("Forget Password", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
//                 const SizedBox(height: 20),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 42),
//                   child: TextFormField(
//                     controller: _staffCodeController,
//                     decoration: const InputDecoration(hintText: 'Enter User Id'),
//                   ),
//                 ),
//                 ElevatedButton(
//                   style: raisedButtonStyle,
//                   onPressed: _getUserInfoByStaffCode,
//                   child: const Text('Confirm'),
//                 ),
//                 if (_maskedPhone != null) Text("Phone No.: $_maskedPhone", style: const TextStyle(fontSize: 16)),
//                 if (_isOTPSent && !_isOTPVerified)
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 16),
//                     child: Column(
//                       children: [
//                         TextFormField(
//                           controller: _otpController,
//                           decoration: const InputDecoration(hintText: 'Enter OTP'),
//                         ),
//                         ElevatedButton(
//                           style: raisedButtonStyle,
//                           onPressed: _verifyOtp,
//                           child: const Text('Verify OTP'),
//                         ),
//                         _buildResendOtpButton(),
//                       ],
//                     ),
//                   ),
//                 if (_isOTPVerified)
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 16),
//                     child: Column(
//                       children: [
//                         TextFormField(
//                           controller: _newPasswordController,
//                           decoration: const InputDecoration(hintText: 'Enter New Password'),
//                         ),
//                         TextFormField(
//                           controller: _confirmPasswordController,
//                           decoration: const InputDecoration(hintText: 'Confirm New Password'),
//                         ),
//                         ElevatedButton(
//                           style: raisedButtonStyle,
//                           onPressed: _resetPassword,
//                           child: const Text('Reset Password'),
//                         ),
//                       ],
//                     ),
//                   ),
//               ],
//             ),
//           ),
//
//           if(isLoading)
//             Container(
//                 color: Colors.black.withOpacity(0.5),
//                 child: const Center(
//                   child: CircularProgressIndicator(
//                     color: MyColors.lightBlue,
//                   ),
//                 )
//             )
//
//         ],
//       ),
//
//     );
//   }
// }
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
// /*import 'dart:convert';
//
// import 'package:attendance_system_ios/screen/Login/login_screen.dart';
// import 'package:bcrypt/bcrypt.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:http/http.dart' as http;
//
// class ForgetPassword extends StatefulWidget {
//   const ForgetPassword({Key? key}) : super(key: key);
//
//   @override
//   State<ForgetPassword> createState() => _ForgetPasswordState();
// }
//
// class _ForgetPasswordState extends State<ForgetPassword> {
//   final TextEditingController _staffCodeController = TextEditingController();
//   final TextEditingController _otpController = TextEditingController();
//   final TextEditingController _newPasswordController = TextEditingController();
//   final TextEditingController _confirmPasswordController = TextEditingController();
//
//   bool isResendOtp = false;
//   String? _phone;
//   String? staffCode;
//   String? _maskedPhone;
//   String? _verificationId; // Firebase Verification ID
//   bool _isOTPSent = false;
//   bool _isOTPVerified = false;
//
//   final ButtonStyle raisedButtonStyle = ElevatedButton.styleFrom(
//     foregroundColor: Colors.white,
//     backgroundColor: Colors.blue,
//     minimumSize: const Size(92, 40),
//     shape: const RoundedRectangleBorder(
//       borderRadius: BorderRadius.all(Radius.circular(8)),
//     ),
//   );
//
//   Future<void> _getUserInfoByStaffCode() async {
//     staffCode = _staffCodeController.text.trim();
//     if (staffCode!.isEmpty) {
//       Fluttertoast.showToast(msg: "Please enter your staff code.");
//       return;
//     }
//
//     try {
//       // API call to fetch user info
//       final response = await http.get(
//         Uri.parse('http://114.143.140.28:8091/Users/GetUserInfoByStaffCode?staffCode=$staffCode'),
//         headers: {'Content-Type': 'application/json'},
//       );
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (data['message']['mobileNo'] != null) {
//           String phone = data['message']['mobileNo'];
//           setState(() {
//             _phone = phone;
//             _maskedPhone = _maskPhone(phone);
//           });
//           Fluttertoast.showToast(msg: "Email fetched successfully.");
//           _sendOtp();
//         } else {
//           Fluttertoast.showToast(msg: "Staff code not found.");
//         }
//       } else {
//         Fluttertoast.showToast(msg: "Failed to fetch user info. Try again.");
//       }
//     } catch (e) {
//       Fluttertoast.showToast(msg: "Error fetching user details: $e");
//     }
//   }
//
//   String _maskPhone(String phone) {
//     final markedphone = phone.substring(0, 1) + "*"*(phone.length - 4) + phone.substring(7, 10);
//     //Logic for email marked
// *//*    final parts = phone.split('@');
//     if (parts.length == 2) {
//       final username = parts[0];
//       final maskedUsername = username.length > 2
//           ? username.substring(0, 2) + '*' * (username.length - 2)
//           : '*' * username.length;
//       return "$maskedUsername@${parts[1]}";
//     }*//*
//     return markedphone;
//   }
//
//   Future<void> _sendOtp() async {
//     // String phoneNumber = "+91${_phoneController.text.trim()}";
//     String phoneNumber = "+91$_phone";
//
//
//     if (phoneNumber.isEmpty) {
//       Fluttertoast.showToast(msg: "Please enter your phone number.");
//       return;
//     }
//
//     try {
//       await FirebaseAuth.instance.verifyPhoneNumber(
//         phoneNumber: phoneNumber,
//         timeout: const Duration(seconds: 60),
//         verificationCompleted: (PhoneAuthCredential credential) async {
//           // Automatically verifies and signs in
//           await FirebaseAuth.instance.signInWithCredential(credential);
//           setState(() {
//             _isOTPVerified = true;
//           });
//           Fluttertoast.showToast(msg: "Phone number verified automatically.");
//         },
//         verificationFailed: (FirebaseAuthException e) {
//           Fluttertoast.showToast(msg: "Verification failed: ${e.message}");
//         },
//         codeSent: (String verificationId, int? resendToken) {
//           setState(() {
//             _verificationId = verificationId;
//             _isOTPSent = true;
//           });
//           Fluttertoast.showToast(msg: "OTP sent to $phoneNumber.");
//         },
//         codeAutoRetrievalTimeout: (String verificationId) {
//           _verificationId = verificationId;
//         },
//       );
//     } catch (e) {
//       Fluttertoast.showToast(msg: "Error sending OTP: $e");
//     }
//   }
//
//   Future<void> _verifyOtp() async {
//     String enteredOtp = _otpController.text.trim();
//
//     if (_verificationId == null || enteredOtp.isEmpty) {
//       Fluttertoast.showToast(msg: "Please enter the OTP.");
//       return;
//     }
//
//     try {
//       PhoneAuthCredential credential = PhoneAuthProvider.credential(
//         verificationId: _verificationId!,
//         smsCode: enteredOtp,
//       );
//
//       await FirebaseAuth.instance.signInWithCredential(credential);
//       setState(() {
//         _isOTPVerified = true;
//       });
//       Fluttertoast.showToast(msg: "OTP verified successfully.");
//     } catch (e) {
//       Fluttertoast.showToast(msg: "Invalid OTP. Please try again.");
//     }
//   }
//
//   Future<void> _resetPassword() async {
//     String newPassword = _newPasswordController.text.trim();
//     String confirmPassword = _confirmPasswordController.text.trim();
//
//     if (newPassword.isEmpty || confirmPassword.isEmpty) {
//       Fluttertoast.showToast(msg: "Please fill out both password fields.");
//       return;
//     }
//
//     if (newPassword != confirmPassword) {
//       Fluttertoast.showToast(msg: "Passwords do not match.");
//       return;
//     }
//     _forgetPassword(newPassword);
//   }
//
//   Future<void> _forgetPassword(String password) async {
//
//     String hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());
//
//     // Log the hashed password for debugging (optional)
//     print("Hashed password: $hashedPassword");
//
//     var headers = {
//       "Content-Type": "application/json",
//       "Authorization": "Basic $hashedPassword"
//     };
//
//     var requestBody = jsonEncode({
//       "staffCode": staffCode,
//       "password": hashedPassword
//     });
//
//     final response = await http.post(
//       Uri.parse('http://114.143.140.28:8091/Users/ForgotPassword'),
//       headers: headers,
//       body:  requestBody
//     );
//
//     if(response.statusCode == 200){
//       String result = json.decode(response.body);
//       Fluttertoast.showToast(msg: "Password reset successfully.");
//       Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Failed to forget password. Try again")),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Forget Password"),
//         backgroundColor: Colors.blue,
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const SizedBox(height: 40),
//             const Text(
//               "Forget Password",
//               style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
//             ),
//             const SizedBox(height: 20),
//
//             // Phone Number Input
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 42),
//               child: TextFormField(
//                 controller: _staffCodeController,
//                 decoration: const InputDecoration(
//                   border: UnderlineInputBorder(),
//                   hintText: 'Enter User Id',
//                 ),
//               ),
//             ),
//             ElevatedButton(
//               style: raisedButtonStyle,
//               onPressed: _getUserInfoByStaffCode,
//               child: const Text('Confirm'),
//             ),
//
//             if (_maskedPhone != null) ...[
//               Text(
//                 "Phone No.: $_maskedPhone",
//                 style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
//               ),
//             ],
//
//             if (_isOTPSent && !_isOTPVerified) ...[
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 16),
//                 child: TextFormField(
//                   controller: _otpController,
//                   decoration: const InputDecoration(
//                     border: UnderlineInputBorder(),
//                     hintText: 'Enter OTP',
//                   ),
//                 ),
//               ),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   ElevatedButton(
//                     style: raisedButtonStyle,
//                     onPressed: _verifyOtp,
//                     child: const Text('Verify OTP'),
//                   ),
//                   const SizedBox(width: 20,),
//                   ElevatedButton(
//                     style: raisedButtonStyle,
//                     onPressed: _verifyOtp,
//                     child: const Text('Resend OTP'),
//                   ),
//                 ],
//               ),
//               // Padding(padding: EdgeInsets.symmetric(horizontal: 30)),
//               // if(true)
//               // const SizedBox(width: 120,
//               // child: Text("Enable in 30 sec")),
//
//               Container(
//                 width: 150,
//                 child: const Padding(padding: EdgeInsets.symmetric(horizontal: 120, ),
//                   child: Text("Enable in 30 sec"),
//                 ),
//               ),
//
//
//             ],
//
//             if (_isOTPVerified) ...[
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 16),
//                 child: TextFormField(
//                   controller: _newPasswordController,
//                   decoration: const InputDecoration(
//                     border: UnderlineInputBorder(),
//                     hintText: 'Enter New Password',
//                   ),
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 16),
//                 child: TextFormField(
//                   controller: _confirmPasswordController,
//                   decoration: const InputDecoration(
//                     border: UnderlineInputBorder(),
//                     hintText: 'Confirm New Password',
//                   ),
//                 ),
//               ),
//               ElevatedButton(
//                 style: raisedButtonStyle,
//                 onPressed: _resetPassword,
//                 child: const Text('Reset Password'),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }*/
//
//
//
//
//
//
//
//
//
//
// /*
// import 'dart:convert';
// import 'package:attendance_system_ios/screen/Login/login_screen.dart';
// import 'package:attendance_system_ios/util/MyColor.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:http/http.dart' as http;
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:fluttertoast/fluttertoast.dart';
//
// class ForgetPassword extends StatefulWidget {
//   const ForgetPassword({super.key});
//
//   @override
//   State<ForgetPassword> createState() => _ForgetPasswordState();
// }
//
// class _ForgetPasswordState extends State<ForgetPassword> {
//   final TextEditingController _staffCodeController = TextEditingController();
//   final TextEditingController _otpController = TextEditingController();
//   final TextEditingController _newPasswordController = TextEditingController();
//   final TextEditingController _confirmPasswordController = TextEditingController();
//
//   String? _email; // Full email fetched from the API
//   String? _maskedEmail; // Partially masked email for display
//   String? _verificationCode; // Holds the OTP sent to the email
//   bool _isOTPSent = false;
//   bool _isOTPVerified = false;
//   bool _isResendDisabled = false; // To disable Resend OTP temporarily
//
//   final ButtonStyle raisedButtonStyle = ElevatedButton.styleFrom(
//     foregroundColor: Colors.white,
//     backgroundColor: MyColors.lightBlue,
//     minimumSize: const Size(92, 40),
//     shape: const RoundedRectangleBorder(
//       borderRadius: BorderRadius.all(Radius.circular(8)),
//     ),
//   );
//
//   Future<void> _getUserInfoByStaffCode() async {
//     String staffCode = _staffCodeController.text.trim();
//     if (staffCode.isEmpty) {
//       Fluttertoast.showToast(msg: "Please enter your staff code.");
//       return;
//     }
//
//     try {
//       // API call to fetch user info
//       final response = await http.get(
//         Uri.parse('http://114.143.140.28:8091/Users/GetUserInfoByStaffCode?staffCode=$staffCode'),
//         headers: {'Content-Type': 'application/json'},
//       );
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (data['message']['emailId'] != null) {
//           String email = data['message']['emailId'];
//           setState(() {
//             _email = email;
//             _maskedEmail = _maskEmail(email);
//           });
//           Fluttertoast.showToast(msg: "Email fetched successfully.");
//           _sendOtp();
//         } else {
//           Fluttertoast.showToast(msg: "Staff code not found.");
//         }
//       } else {
//         Fluttertoast.showToast(msg: "Failed to fetch user info. Try again.");
//       }
//     } catch (e) {
//       Fluttertoast.showToast(msg: "Error fetching user details: $e");
//     }
//   }
//
//   String _maskEmail(String email) {
//     final parts = email.split('@');
//     if (parts.length == 2) {
//       final username = parts[0];
//       final maskedUsername = username.length > 2
//           ? username.substring(0, 2) + '*' * (username.length - 2)
//           : '*' * username.length;
//       return "$maskedUsername@${parts[1]}";
//     }
//     return email;
//   }
//
//   Future<void> _sendOtp() async {
//     if (_email == null) {
//       Fluttertoast.showToast(msg: "Please fetch the email using your staff code first.");
//       return;
//     }
//
//     try {
//       // Sends a password reset email (acts as OTP email)
//       await FirebaseAuth.instance.sendPasswordResetEmail(email: _email!);
//       Fluttertoast.showToast(
//           msg: "OTP email sent. Please check your inbox.");
//     } on FirebaseAuthException catch (e) {
//       String errorMessage;
//
//       if (e.code == 'user-not-found') {
//         errorMessage = "No user found with this email.";
//       } else if (e.code == 'invalid-email') {
//         errorMessage = "The email address is invalid.";
//       } else {
//         errorMessage = "An error occurred: ${e.message}";
//       }
//
//       Fluttertoast.showToast(msg: errorMessage);
//     } catch (e) {
//       Fluttertoast.showToast(msg: "An unexpected error occurred: $e");
//     }
//
//    try {
//       // Generate OTP
//       String generatedOtp = (100000 + (999999 - 100000) * (DateTime.now().millisecond / 1000)).toInt().toString();
//       setState(() {
//         _verificationCode = generatedOtp;
//         _isOTPSent = true;
//         _isResendDisabled = true;
//       });
//
//       // Simulating OTP sending via Firebase (you can replace this with actual email OTP logic)
//       await FirebaseAuth.instance.verifyPasswordResetCode(_email!);
//       Fluttertoast.showToast(msg: "OTP sent to $_maskedEmail.");
//
//       // Enable resend after 30 seconds
//       Future.delayed(const Duration(seconds: 30), () {
//         setState(() {
//           _isResendDisabled = false;
//         });
//       });
//     } catch (e) {
//       Fluttertoast.showToast(msg: "Error sending OTP: $e");
//       print("Error sending OTP: $e");
//     }
//
//   }
//
//   Future<void> _verifyOtp() async {
//     String enteredOtp = _otpController.text.trim();
//
//     if (_verificationCode == null || enteredOtp.isEmpty) {
//       Fluttertoast.showToast(msg: "Please enter the OTP.");
//       return;
//     }
//
//     if (enteredOtp == _verificationCode) {
//       setState(() {
//         _isOTPVerified = true;
//       });
//       Fluttertoast.showToast(msg: "OTP verified successfully.");
//     } else {
//       Fluttertoast.showToast(msg: "Invalid OTP. Please try again.");
//     }
//   }
//
//   Future<void> _resetPassword() async {
//     String newPassword = _newPasswordController.text.trim();
//     String confirmPassword = _confirmPasswordController.text.trim();
//
//     if (newPassword.isEmpty || confirmPassword.isEmpty) {
//       Fluttertoast.showToast(msg: "Please fill out both password fields.");
//       return;
//     }
//
//     if (newPassword != confirmPassword) {
//       Fluttertoast.showToast(msg: "Passwords do not match.");
//       return;
//     }
//
//     try {
//       final response = await http.post(
//         Uri.parse('http://114.143.140.28:8091/Users/ForgotPassword'),
//         body: json.encode({"email": _email, "newPassword": newPassword}),
//         headers: {"Content-Type": "application/json"},
//       );
//
//       if (response.statusCode == 200) {
//         Fluttertoast.showToast(msg: "Password reset successfully. Please log in.");
//         Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
//       } else {
//         Fluttertoast.showToast(msg: "Failed to reset password. Try again.");
//       }
//     } catch (e) {
//       Fluttertoast.showToast(msg: "Error resetting password: $e");
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
//           onPressed: () => Navigator.of(context).pop(),
//         ),
//         title: const Text("Forget Password"),
//         backgroundColor: MyColors.lightBlue,
//         titleTextStyle: GoogleFonts.roboto(
//           fontWeight: FontWeight.bold,
//           fontSize: 18.0,
//         ).copyWith(color: Colors.white),
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const SizedBox(height: 40),
//             const Text("Forget Password", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, fontFamily: 'Dubai', color: Colors.black)),
//             const SizedBox(height: 20),
//
//             // Staff Code Input
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 42),
//               child: TextFormField(
//                 controller: _staffCodeController,
//                 decoration: const InputDecoration(
//                   border: UnderlineInputBorder(),
//                   hintText: 'Enter Staff Code',
//                 ),
//               ),
//             ),
//             ElevatedButton(
//               style: raisedButtonStyle,
//               onPressed: _getUserInfoByStaffCode,
//               child: const Text('Fetch Email'),
//             ),
//
//             if (_maskedEmail != null) ...[
//               Text(
//                 "Email: $_maskedEmail",
//                 style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
//               ),
//             ],
//
//             if (_isOTPSent && !_isOTPVerified) ...[
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 16),
//                 child: TextFormField(
//                   controller: _otpController,
//                   decoration: const InputDecoration(
//                     border: UnderlineInputBorder(),
//                     hintText: 'Enter OTP',
//                   ),
//                 ),
//               ),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   ElevatedButton(
//                     style: raisedButtonStyle,
//                     onPressed: _verifyOtp,
//                     child: const Text('Verify OTP'),
//                   ),
//                   ElevatedButton(
//                     style: raisedButtonStyle.copyWith(
//                       backgroundColor: MaterialStateProperty.all(
//                         _isResendDisabled ? Colors.grey : MyColors.lightBlue,
//                       ),
//                     ),
//                     onPressed: _isResendDisabled ? null : _sendOtp,
//                     child: const Text('Resend OTP'),
//                   ),
//                 ],
//               ),
//             ],
//
//             if (_isOTPVerified) ...[
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 16),
//                 child: TextFormField(
//                   controller: _newPasswordController,
//                   decoration: const InputDecoration(
//                     border: UnderlineInputBorder(),
//                     hintText: 'Enter New Password',
//                   ),
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 16),
//                 child: TextFormField(
//                   controller: _confirmPasswordController,
//                   decoration: const InputDecoration(
//                     border: UnderlineInputBorder(),
//                     hintText: 'Confirm New Password',
//                   ),
//                 ),
//               ),
//               ElevatedButton(
//                 style: raisedButtonStyle,
//                 onPressed: _resetPassword,
//                 child: const Text('Reset Password'),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }
// */
//
//
//
//
//
//
//
//
//
//
//
// /*
// import 'package:attendance_system_ios/screen/Login/login_screen.dart';
// import 'package:attendance_system_ios/util/MyColor.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
//
// class ForgetPassword extends StatefulWidget {
//   const ForgetPassword({super.key});
//
//   @override
//   State<ForgetPassword> createState() => _ForgetPasswordState();
// }
//
// class _ForgetPasswordState extends State<ForgetPassword> {
//
//   final ButtonStyle raisedButtonStyle = ElevatedButton.styleFrom(
//     foregroundColor: Colors.white, backgroundColor: MyColors.lightBlue,
//     minimumSize: const Size(92, 40),
//     // padding: EdgeInsets.symmetric(horizontal: 0),
//     shape: const RoundedRectangleBorder(
//       borderRadius: BorderRadius.all(Radius.circular(8)),
//     ),
//   );
//
//   Future<void> _sendOtp() async {
//
//   }
//
//   Future<void> _verifyOtp() async {
//
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
//           onPressed: () => Navigator.of(context).pop(),
//         ),
//
//         title: const Text("Forget Password"),
//         backgroundColor: MyColors.lightBlue,
//         // centerTitle: true,
//         titleTextStyle: GoogleFonts.roboto(
//         fontWeight: FontWeight.bold,
//         fontSize: 18.0,
//       ).copyWith(
//         color: Colors.white,
//       )
//       ),
//
//
//
//       body: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const SizedBox(height: 40,),
//
//             const Text("Forget Password", style: TextStyle(
//               fontWeight: FontWeight.bold,
//               fontSize: 22,
//               fontFamily: 'Dubai',
//               color: Colors.black,
//             ),),
//
//             const SizedBox(height: 70,),
//
//             const Padding(padding: EdgeInsets.symmetric(horizontal: 42),
//             child: Row(
//               children: [
//             Text("Registered Mobile No.",
//               style: TextStyle(
//               fontSize: 16,
//               fontFamily: 'Dubai',
//               fontWeight: FontWeight.bold,
//             ),),
//                 Text("*", style: TextStyle(
//                   color: Colors.red,
//                 ),)
//               ]
//             ),
//             ),
//
//
//             Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 42),
//                 child: TextFormField(
//                   decoration: const InputDecoration(
//                     border: UnderlineInputBorder(),
//                     hintText: 'Enter Mobile No.',
//                   ),
//                 )
//             ),
//
//
//             Padding(padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 16),
//             child:  Row(
//               children: [
//                 Flexible(
//                     child: TextFormField(
//                       decoration: const InputDecoration(
//                         border: UnderlineInputBorder(),
//                         hintText: 'Enter OTP',
//                       ),
//                     )
//                 ),
//                 Flexible(
//                     child: ElevatedButton(
//                       style: raisedButtonStyle,
//                       onPressed: () { },
//                       child: const Text('Get OTP'),
//                     )
//                 )
//               ],
//             ),
//             ),
//
//
//             Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 16),
//                 child: TextFormField(
//                   decoration: const InputDecoration(
//                     border: UnderlineInputBorder(),
//                     hintText: 'Enter your card ID',
//                   ),
//                 )
//             ),
//
//             Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 16),
//                 child: TextFormField(
//                   decoration: const InputDecoration(
//                     border: UnderlineInputBorder(),
//                     hintText: 'Enter New Password',
//                   ),
//                 )
//             ),
//
//             Padding(padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 10),
//                 child: ElevatedButton(
//                   style: raisedButtonStyle,
//                   onPressed: () {
//                     Navigator.push(context,
//                         MaterialPageRoute(builder: (context) => const LoginScreen()));
//                   },
//                   child: const Text('  Forget  '),
//                 )
//             ),
//
//           ],
//         )
//       ),
//     );
//   }
// }
// */
