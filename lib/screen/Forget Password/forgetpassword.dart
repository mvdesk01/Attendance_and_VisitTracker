import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:attendance_system_ios/screen/Login/login_screen.dart';
import 'package:attendance_system_ios/util/MyColor.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';

import '../../bloc/main_bloc.dart';
import '../../service/WebService.dart';
import '../../service/log_file_manager.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({Key? key}) : super(key: key);

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final String username = "mtechattendence@gmail.com";
  final String password = "hjle ldkz vymh xgmg"; // App-specific password
  String? generatedOtp;
  String? Oldpassword;
  DateTime? otpTimestamp; // Store OTP generation time

  final TextEditingController _staffCodeController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();


  bool isLoading = false;

  bool isResendOtp = false;
  String? email;
  String? _phone;
  String? staffCode;
  String? emailid;
  String? _maskedPhone;
  String? _maskedEmail;
  String? _verificationId;
  bool _isOTPSent = false;
  bool _isOTPVerified = false;

  int _resendAttempts = 0; // Counter for resend attempts
  bool _isResendDisabled = false; // To control resend button state
  int _resendCooldown = 30; // Cooldown in seconds
  Timer? _timer; // Timer instance for cooldown

  final ButtonStyle raisedButtonStyle = ElevatedButton.styleFrom(
    foregroundColor: Colors.white,
    backgroundColor: Colors.blue,
    minimumSize: const Size(92, 40),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
  );

  Future<void> _getUserInfoByStaffCode() async {
    staffCode = _staffCodeController.text.trim();
    if (staffCode!.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter your staff code.");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://114.143.140.28:8091/Users/GetUserInfoByStaffCode?staffCode=$staffCode'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['message']['emailId'] != null) {
          email = data['message']['emailId'];
          setState(() {
            _phone = email;
            _maskedEmail = _maskEmail(email!);
          });
          Fluttertoast.showToast(msg: "emailID fetched successfully.");
          setState(() {
            isLoading = false;
          });
          sendOtpEmail();
        } else {
          Fluttertoast.showToast(msg: "Staff code not found.");
        }
      } else {
        setState(() {
          isLoading = false;
        });
        Fluttertoast.showToast(msg: "Failed to fetch user info. Try again.");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: "Error fetching user details: $e");
    }
  }

  String _maskPhone(String emaill) {
    return emaill.substring(0, 2) + "*" * (emaill.length - 4) + emaill.substring(emaill.length - 2);
  }

  String _maskEmail(String email) {
    int atIndex = email.indexOf('@');
    if (atIndex > 2) {
      return email.substring(0, 2) + "*" * (atIndex - 2) + email.substring(atIndex);
    }
    return email; // If email is too short, return it as is.
  }

  void sendOtpEmail() async {

    setState(() {
      isLoading = true;
    });


    // Generate OTP
    generatedOtp = generateOtp();
    otpTimestamp = DateTime.now(); // Store the OTP generation time
    print('Generated OTP: $generatedOtp at $otpTimestamp');

    // Configure the SMTP server
    final smtpServer = gmail(username, password);

    // Create the email message
    final message = Message()
      ..from = Address(username, 'M-Tech Attendance System(kd)')
      ..recipients.add(email) // Add recipient email
      ..subject = 'Reset Password OTP'
      ..text = '''
Dear User,

Thank you for using the M-Tech Attendance System.

Your One-Time Password (OTP) to reset password is : $generatedOtp

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
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent successfully to your registered mail!')),
      );
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Email not sent: $e');
      LogFileManager.writeLog('Email not sent: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send OTP: $e')),
      );
    }
  }
  String generateOtp() {
    final random = Random();
    return List.generate(6, (index) => random.nextInt(10)).join();
  }
  //940071

  Future<void> _verifyOtp() async {
    String enteredOtp = _otpController.text.trim();

    if ( enteredOtp.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter the OTP.");
      return;
    }
    if (otpTimestamp == null || DateTime.now().difference(otpTimestamp!).inMinutes > 5) {
      Fluttertoast.showToast(msg: "OTP has expired. Please request a new one.");
      setState(() {
        generatedOtp = null;
        otpTimestamp = null; // Clear timestamp// Keep OTP null so a new one can be sent
        isResendOtp = true;  // Allow resend
      });
      return;
    }

    // Check if OTP has expired
    // if (otpTimestamp == null || DateTime.now().difference(otpTimestamp!).inMinutes > 1) {
    //   Fluttertoast.showToast(msg: "OTP has expired. Please request a new one.");
    //   setState(() {
    //     _isOTPSent = false;
    //     generatedOtp = null; // Clear OTP
    //
    //     isResendOtp = true; // Show resend button
    //   });
    //   return;
    // }
    if (enteredOtp == generatedOtp) {
      setState(() {
        _isOTPVerified = true;
        isResendOtp = false;
      });
      Fluttertoast.showToast(msg: "OTP verified successfully.");
    } else {
      Fluttertoast.showToast(msg: "Invalid OTP. Please try again.");
    }

  }

  Future<void> _resetPassword() async {
    String newPassword = _newPasswordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      Fluttertoast.showToast(msg: "Please fill out both password fields.");
      return;
    }
    if (_newPasswordController.text.trim().length < 8 ||
        !RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$')
            .hasMatch(_newPasswordController.text.trim())) {
      Fluttertoast.showToast(msg: 'Password must be at least 8 characters long, contain a special character, a letter, and a number.');
      return ;
    }

    if (newPassword != confirmPassword) {
      Fluttertoast.showToast(msg: "Passwords do not match.");
      return;
    }
   await _oldewpassword();
    if(Oldpassword== confirmPassword){
      Fluttertoast.showToast(msg: "New Password cannot be same as old one");
    }
    await _forgetPassword(newPassword);
  }

  Future<void> _oldewpassword() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://114.143.140.28:8091/Users/GetUserInfoByStaffCode?staffCode=$staffCode'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['message'] != null && data['message']['password'] != null) {
          Oldpassword = data['message']['password'];
          print("Fetched Old Password: $Oldpassword");
        } else {
          Fluttertoast.showToast(msg: "Failed to fetch old password.");
          Oldpassword = null;
        }
      } else {
        Fluttertoast.showToast(msg: "Error fetching old password.");
        Oldpassword = null;
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Exception: $e");
      Oldpassword = null;
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }


  Future<void> _forgetPassword(String password) async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://114.143.140.28:8091/Users/ForgotPassword?StaffCode=$staffCode&Password=$password'),
      );

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200) {
        Map<String, dynamic> result = json.decode(response.body);
        print("Success: ${result['message']}");
        Fluttertoast.showToast(msg: "Password Updated Successfully.");

        // Navigate to login screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider(
              create: (context) => MainBloc(webService: WebService()),
              child: const LoginScreen(),
            ),
          ),
        );
      } else {
        // ✅ Handle error message safely
        Map<String, dynamic> result = json.decode(response.body);
        String errorMessage = result['message'] ?? "Failed to update password.";
        print("Error: $errorMessage");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error on forget password: $e");
    }
  }


  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

/*  Widget _buildResendOtpButton() {
    return Column(
      children: [
        ElevatedButton(
          style: raisedButtonStyle.copyWith(
            backgroundColor: MaterialStateProperty.all(
              _isResendDisabled ? Colors.grey : Colors.blue,
            ),
          ),
          onPressed: sendOtpEmail,
          child: const Text('Resend OTP'),
        ),
        if (_isResendDisabled)
          Text(
            "Enable in $_resendCooldown sec",
            style: const TextStyle(fontSize: 14, color: Colors.red),
          ),
        Text(
          "Attempts: $_resendAttempts/3",
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }*/

  Widget _buildResendOtpButton() {
    return Visibility(
      visible: isResendOtp, // Show only when OTP expires
      child: Column(
        children: [
          ElevatedButton(
            style: raisedButtonStyle.copyWith(
              backgroundColor: MaterialStateProperty.all(
                _isResendDisabled ? Colors.grey : Colors.blue,
              ),
            ),
            onPressed: _isResendDisabled ? null : () {
              sendOtpEmail();
              setState(() {
                isResendOtp = false; // Hide after resending
              });
            },
            child: const Text('Resend OTP'),
          ),
          if (_isResendDisabled)
            Text(
              "Enable in $_resendCooldown sec",
              style: const TextStyle(fontSize: 14, color: Colors.red),
            ),
          Text(
            "Attempts: $_resendAttempts/3",
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 100, bottom: 20), // <-- Add top padding here
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      const Center(
                        child: Text(
                          'Forget Password',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                Image.asset("assets/icons/graphic-design.png",
                  width: 100,
                  height: 110,
                ),

                const SizedBox(height: 30,),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 42),
                  child: TextFormField(
                    controller: _staffCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Enter Staff Code',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(height: 10,),
                ElevatedButton(
                  style: raisedButtonStyle,
                  onPressed: _getUserInfoByStaffCode,
                  child: const Text('Confirm'),
                ),

                if (_maskedEmail != null) Text("Email id:"+email!, style: const TextStyle(fontSize: 16)),
                if (_isOTPSent && !_isOTPVerified)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 16),
                    child: Column(
                      children: [
                        // TextField(controller: _otpController, decoration: InputDecoration(labelText: "Enter OTP")),
                        TextFormField(
                          controller: _otpController,
                          decoration: const InputDecoration(
                            labelText: "Enter OTP",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        ElevatedButton(onPressed: _verifyOtp, child: Text("Verify OTP")),
                        _buildResendOtpButton(), // Resend OTP button appears only when needed
                      ],
                    )
                  ),
                if (_isOTPVerified)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 16),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _newPasswordController,
                          decoration: const InputDecoration(hintText: 'Enter New Password'),
                        ),
                        TextFormField(
                          controller: _confirmPasswordController,
                          decoration: const InputDecoration(hintText: 'Confirm New Password'),
                        ),
                        ElevatedButton(
                          style: raisedButtonStyle,
                          onPressed: _resetPassword,
                          child: const Text('Reset Password'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          if(isLoading)
            Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: MyColors.lightBlue,
                  ),
                )
            )

        ],
      ),

    );
  }

}
///old
// Future<void> _sendOtp() async {
//   if (_phone == null) {
//     Fluttertoast.showToast(msg: "Please fetch your emailID first.");
//     return;
//   }
//
//   if (_resendAttempts >= 3) {
//     Fluttertoast.showToast(msg: "Resend limit reached. Try again later.");
//     return;
//   }
//
//   setState(() {
//     _isResendDisabled = true;
//     _resendAttempts++;
//     _resendCooldown = 30; // Reset cooldown
//   });
//
//   try {
//     await FirebaseAuth.instance.verifyPhoneNumber(
//       phoneNumber: "+91$_phone",
//       timeout: const Duration(seconds: 60),
//       verificationCompleted: (PhoneAuthCredential credential) async {
//         await FirebaseAuth.instance.signInWithCredential(credential);
//         setState(() {
//           _isOTPVerified = true;
//         });
//         Fluttertoast.showToast(msg: "Phone number verified automatically.");
//       },
//       verificationFailed: (FirebaseAuthException e) {
//         Fluttertoast.showToast(msg: "Verification failed: ${e.message}");
//       },
//       codeSent: (String verificationId, int? resendToken) {
//         setState(() {
//           _verificationId = verificationId;
//           _isOTPSent = true;
//         });
//         Fluttertoast.showToast(msg: "OTP sent to your phone.");
//       },
//       codeAutoRetrievalTimeout: (String verificationId) {
//         _verificationId = verificationId;
//       },
//     );
//   } catch (e) {
//     Fluttertoast.showToast(msg: "Error sending OTP: $e");
//   }
//
//   // Start the cooldown timer
//   _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//     setState(() {
//       if (_resendCooldown > 0) {
//         _resendCooldown--;
//       } else {
//         _isResendDisabled = false;
//         timer.cancel();
//       }
//     });
//   });
// }
///
// Future<void> _forgetPassword(String password) async {
//
//   setState(() {
//     isLoading = true;
//   });
//
//   /*String hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());
//
//   // Log the hashed password for debugging (optional)
//   print("Hashed password: $hashedPassword");
//
//   var headers = {
//     "Content-Type": "application/json",
//     "Authorization": "Basic $hashedPassword"
//   };
//
//   var requestBody = jsonEncode({
//     "StaffCode": "cd03059",
//     "Password": hashedPassword,
//   });*/
//
//   try {
//     final response = await http.post(
//       // Uri.parse('http://114.143.140.28:8091/Users/ForgotPassword'),
//       Uri.parse('http://114.143.140.28:8091/Users/ForgotPassword?StaffCode=$staffCode&Password=$password'),
//       // headers: {"Content-Type": "application/json"},
//       // body: json.encode({
//       //   'StaffCode': 'cd03059',
//       //   'Password': "Manish@1"
//       // })
//     );
//
//     setState(() {
//       isLoading = false;
//     });
//
//     if (response.statusCode == 200) {
//       // Handle successful response
//       Map<String, dynamic> result = json.decode(response.body);
//       print("Success: ${result['message']}");
//       Fluttertoast.showToast(msg: "Password Updated Successfully.");
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (_) => BlocProvider(
//             create: (context) => MainBloc(webService: WebService()),
//             child: const LoginScreen(),
//           ),
//         ),
//       );
//     } else {
//       // Handle error response
//       Map<String, dynamic> result = json.decode(response.body);
//       print("Error: ${result['message']}");
//       print("Error: ${result['error']}");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(result['message'] ?? "Failed to forget password. Try again")),
//       );
//     }
//   } catch (e) {
//     setState(() {
//       isLoading = false;
//     });
//     print("Error on forget password: $e");
//   }
// }