import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:android_id/android_id.dart';
import 'package:attendance_system_ios/screen/Login/login_screen.dart';
import 'package:attendance_system_ios/service/log_file_manager.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
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
  final String password = "hjle ldkz vymh xgmg";
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
  final storage = const FlutterSecureStorage();
  String? externalPlantCode;

  @override
  void initState() {
    super.initState();
    fetchExternalPlantCode();
  }

  Future<String?> _getId() async {
    var deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      var iosDeviceInfo = await deviceInfo.iosInfo;
      return iosDeviceInfo.identifierForVendor;
    } else if (Platform.isAndroid) {
      return const AndroidId().getId();
    }
    return null;
  }

  Future<bool> checkUserByStaffCodeMobileNoAndEmail() async {
    String staffCode = _cardIdController.text.trim();
    String emailID = _emailController.text.trim();
    String mobileNo = _phoneController.text
        .trim()
        .isEmpty ? '' : _phoneController.text.trim();
    try {
      final response = await http.get(
        Uri.parse(
            'http://114.143.140.28:8020/Users/CheckUserByStaffCodeMobileNoAndEmail?StaffCode=$staffCode&EmailId=$emailID&MobileNo=$mobileNo'),
      );
      if (response.statusCode == 200) {
        final result = response.body;
        if (result.toString() == '{"message":"No Record Found.."}') {
          return true;
        } else if (result.toString() == '{"message":"MobileNo is Already Present..."}') {
          return true;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result.toString()))
          );
        }
      }
    } catch (e) {
      LogFileManager.writeLog(
          'Error in checkUserByStaffCodeMobileNoAndEmail: $e');
    }
    return false;
  }

  String generateOtp() {
    final random = Random();
    return List.generate(6, (index) => random.nextInt(10)).join();
  }

  void sendOtpEmail() async {
    String? validationMsg = _validateInputFieldsWithToasts();
    if (!_formKey.currentState!.validate() || validationMsg != null) {
      if (validationMsg != null) Fluttertoast.showToast(msg: validationMsg);
      return;
    }
    setState(() => _isLoading = true);

    if (!await checkUserByStaffCodeMobileNoAndEmail()) {
      setState(() => _isLoading = false);
      return;
    }

    generatedOtp = generateOtp();
    final smtpServer = gmail(username, password);
    final message = Message()
      ..from = Address(username, 'M-Tech Attendance System')
      ..recipients.add(_emailController.text.trim())
      ..subject = 'Your OTP Code [M-Tech Attendance System]'
      ..text = 'Your One-Time Password (OTP) is: $generatedOtp\n\nValid for 5 minutes.';

    try {
      await send(message, smtpServer);
      setState(() {
        _isOTPSent = true;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent successfully!')),
      );
    } on SocketException {
      setState(() {
        _isLoading = false;
      });
      Fluttertoast.showToast(msg: "No Internet Connection");
      print('Email not sent: SocketException');
      LogFileManager.writeLog('Email not sent: SocketException');
    } catch (e) {
      setState(() => _isLoading = false);
      LogFileManager.writeLog('Email not sent: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send OTP: $e')),
      );
    }
  }

  void verifyOtp() {
    if (_otpController.text.trim() == generatedOtp) {
      Fluttertoast.showToast(msg: 'OTP Verified Successfully!');
      _registerUser();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP. Please try again.')),
      );
    }
  }

  String? _validateInputFields(String value, String fieldName) {
    if (value.isEmpty && fieldName != 'Mobile Number')
      return '$fieldName cannot be empty';
    if (fieldName == 'Card ID' && value.length != 7)
      return 'Card ID must be 7 digits';
    if (fieldName == 'Email' &&
        !RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$').hasMatch(
            value)) {
      return 'Enter a valid email address.';
    }
    if (fieldName == 'Password') {
      if (value.length < 8 || !RegExp(
          r'^(?=.*[a-zA-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$')
          .hasMatch(value)) {
        return 'Weak password';
      }
    }
    return null;
  }

  String? _validateInputFieldsWithToasts() {
    // if (_cardIdController.text.trim().length != 7) return 'Card ID must be 7 digits';
    if (_nameController.text
        .trim()
        .isEmpty) return 'Name is required';
    if (_emailController.text
        .trim()
        .isEmpty) return 'Email is required';
    if (_passwordController.text
        .trim()
        .length < 8) return 'Password too short';
    return null;
  }

  Future<void> fetchExternalPlantCode() async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://114.143.140.28:8020/Users/GetAllPlantCodes',
        ),
        headers: {
          'accept': '*/*',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['status'] == true) {
          final List data = jsonResponse['data'];

          final externalPlant = data.firstWhere(
                (item) =>
            (item['dispName'] ?? '')
                .toString()
                .toUpperCase() ==
                'EXTERNAL',
            orElse: () => null,
          );

          if (externalPlant != null) {
            externalPlantCode = externalPlant['uniquePlantCode']?.toString();
            print('External Plant Code : $externalPlantCode',);
          }
        }
      }
    } catch (e) {
      print('Error fetching plant code : $e');
      LogFileManager.writeLog('Error fetching plant code : $e',);
    }
  }

  Future<void> _registerUser() async {
    setState(() => _isLoading = true);
    try {
      String? deviceID = await _getId();
      final visitDate = DateFormat('yyyy-MM-ddTHH:mm:ss').format(DateTime.now());

      var body = jsonEncode({
        "staffCode": "string",
        "displayName": _nameController.text.trim(),
        "emailID": _emailController.text.trim(),
        "password": _passwordController.text.trim(),
        "mobileNo": _phoneController.text.trim().isEmpty ? 'null' : _phoneController.text.trim(),
        "createdOn": visitDate,
        "createdBy": "system",
        "latitude": "0.0",
        "longitude": "0.0",
        "currAddress": "N/A",
        "uuid": deviceID ?? "unknown",
        "userType": "s",
        "plantCode": externalPlantCode,
        "uniqueNumber": ""
      });

      final response = await http.post(
        Uri.parse("http://114.143.140.28:8020/Users/RegisterUser"),
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        final result = json.decode(response.body);

        String message = result['message'] ?? '';

        String staffCode = '';

        RegExp regExp = RegExp(r'StaffCode\s*:\s*(\S+)');
        Match? match = regExp.firstMatch(message);

        if (match != null) {
          staffCode = match.group(1) ?? '';
          await sendStaffCodeEmail(
            _emailController.text.trim(),
            _nameController.text.trim(),
            staffCode,
          );
        }

        print("Generated StaffCode: $staffCode");
        print("Registration Success Response: $result");
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text("Successfully registered!")),
        // );
        Navigator.pop(context, staffCode);
      } else {
        final err = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${err['message']}")));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      LogFileManager.writeLog("Registration failed: $e");
    }
  }

  Future<void> sendStaffCodeEmail(
      String email,
      String name,
      String staffCode,
      ) async {
    try {
      final smtpServer = gmail(username, password);

      final message = Message()
        ..from = Address(username, 'M-Tech Attendance System')
        ..recipients.add(email)
        ..subject = 'Registration Successful'
        ..text = '''
Dear $name,

Your registration has been completed successfully.

Your Login Staff Code:

$staffCode

Please use this Staff Code along with your password to login.

Regards,
M-Tech Attendance System
''';

      await send(message, smtpServer);
    } catch (e) {
      print("Failed to send staff code email: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
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

          // Content
          Column(
            children: [
              const SizedBox(height: 60),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Text(
                        "Registration",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Spacer to balance back button
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Form Card
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
                      ]
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(30, 40, 30, 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Hero(
                              tag: 'app_icon',
                              child: Container(
                                height: 80,
                                width: 80,
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: MyColors.lightBlue.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Image.asset(
                                  'assets/icons/new_app_icon.png',
                                  errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.person_add_rounded, size: 40, color: MyColors.appDefaultColorCode),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),

                          _buildSectionTitle("Personal Details"),
                          const SizedBox(height: 15),
                          _buildModernField(
                            controller: _nameController,
                            hint: "Full Name",
                            icon: Icons.person_outline_rounded,
                            validator: (v) => _validateInputFields(v!, 'Name'),
                          ),
                          const SizedBox(height: 15),
                          _buildModernField(
                            controller: _emailController,
                            hint: "Email Address",
                            icon: Icons.alternate_email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => _validateInputFields(v!, 'Email'),
                          ),
                          const SizedBox(height: 15),
                          _buildModernField(
                            controller: _phoneController,
                            hint: "Mobile Number (Optional)",
                            icon: Icons.phone_iphone_rounded,
                            maxLength: 10,
                            keyboardType: TextInputType.phone,
                          ),

                          // const SizedBox(height: 25),
                          // _buildSectionTitle("Account Security"),
                          // const SizedBox(height: 15),
                          // _buildModernField(
                          //   controller: _cardIdController,
                          //   hint: "7-digit Staff ID",
                          //   icon: Icons.badge_outlined,
                          //   maxLength: 7,
                          //   keyboardType: TextInputType.number,
                          //   validator: (v) => _validateInputFields(v!, 'Card ID'),
                          // ),
                          const SizedBox(height: 15),
                          _buildModernField(
                            controller: _passwordController,
                            hint: "Password",
                            icon: Icons.lock_outline_rounded,
                            obscureText: passwordVisibility,
                            suffix: IconButton(
                              icon: Icon(passwordVisibility ? Icons.visibility_off : Icons.visibility, size: 20, color: MyColors.appDefaultColorCode),
                              onPressed: () => setState(() => passwordVisibility = !passwordVisibility),
                            ),
                            validator: (v) => _validateInputFields(v!, 'Password'),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(left: 12, top: 8),
                            child: Text(
                              "* Include Uppercase, Number & Special Character",
                              style: TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Action Buttons
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            child: !_isOTPSent
                                ? _buildPrimaryButton(
                              "Verify Identity via OTP",
                              onPressed: _isLoading ? null : sendOtpEmail,
                              color: MyColors.lightBlue,
                            )
                                : Column(
                              children: [
                                _buildModernField(
                                  controller: _otpController,
                                  hint: "6-digit OTP Code",
                                  icon: Icons.verified_user_outlined,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                ),
                                const SizedBox(height: 20),
                                _buildPrimaryButton(
                                  "Complete Registration",
                                  onPressed: verifyOtp,
                                  color: Colors.green.shade700,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade600,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildModernField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffix,
    int? maxLength,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        maxLength: maxLength,
        keyboardType: keyboardType,
        validator: validator,
        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: MyColors.appDefaultColorCode, size: 20),
          suffixIcon: suffix,
          counterText: "",
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(String text, {VoidCallback? onPressed, required Color color}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: color.withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
