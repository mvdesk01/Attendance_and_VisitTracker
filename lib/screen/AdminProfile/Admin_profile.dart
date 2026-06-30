import 'dart:convert';
import 'package:attendance_system_ios/bloc/main_bloc.dart';
import 'package:attendance_system_ios/bloc/main_event.dart';
import 'package:attendance_system_ios/bloc/main_state.dart';
import 'package:attendance_system_ios/util/custome_dialogforDeleteUser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:loading_overlay/loading_overlay.dart';
import '../../model/Profile/UpdateUserinfo.dart';
import '../../service/WebService.dart';
import '../../util/MyColor.dart';
import '../../model/UsersList/GetAllusersListResponse.dart';

class AdminUserProfile extends StatefulWidget {
  final Message datum;

  const AdminUserProfile({Key? key, required this.datum}) : super(key: key);

  @override
  State<AdminUserProfile> createState() => _AdminUserProfileState();
}

class _AdminUserProfileState extends State<AdminUserProfile> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController cardIdController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController dateOfJoiningController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController remoteaddressController = TextEditingController();
  final TextEditingController deviceIdController = TextEditingController();

  String? profileImage;
  late MainBloc mainBloc;
  bool _isLoading = false;
  String? authToken = "";
  String? staffCode = "";
  final storage = const FlutterSecureStorage();

  String? officeApprovedFlag = "O";
  String? addressApprovedFlag;
  bool _showOfficeAddressButton = false;
  bool isEmailEditable = false;
  bool isMobileEditable = false;
  bool _showUpdateButton = false;
  bool _showChangeAddressButton = false;
  bool _isAtsChecked = false;
  String? distanceCheckFlag;
  List<Map<String, dynamic>> multipleRemoteLocations = [ ];

  @override
  void initState() {
    super.initState();
    mainBloc = context.read<MainBloc>();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    authToken = await storage.read(key: 'Auth_Token');
    staffCode = widget.datum.staffCode!;
    if (staffCode != null && authToken != null) {
      mainBloc.add(GetUserInfoEvents(Staffcode: staffCode!, token: authToken!));
      _getMultiRemoteLocation();
    }
  }

  void _getMultiRemoteLocation () {
    mainBloc.add(GetMultiRemoteLocation(authToken!, staffCode!));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text("User Profile", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 18)),
        backgroundColor: MyColors.appDefaultColorCode,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _showDeleteConfirmation(context),
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 26),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        opacity: 0.3,
        color: Colors.black,
        progressIndicator: const CircularProgressIndicator(color: Colors.white),
        child: BlocListener<MainBloc, MainState>(
          listener: _handleBlocStates,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildProfileHeader(),
                const SizedBox(height: 32),
                _buildInfoSection(),
                const SizedBox(height: 24),
                _buildActionButtons(),
                const SizedBox(height: 40),
                if (multipleRemoteLocations.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildSectionTitle("Project Remote Locations"),
                  const SizedBox(height: 10),
                  _buildRemoteLocationList(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleBlocStates(BuildContext context, MainState state) {
    setState(() {
      _isLoading = state is GetUserinfoLoadingState ||
          state is DeleteStaffEntryLoadingState ||
          state is acceptrequestLoadingState ||
          state is nondistancecheckLoadingState ||
          state is UpdateUserinfoLoadingState ||
          state is updateUserAtsFlagLoadingState;
    });

    if (state is GetUserinfoLoadedState) {
      final user = state.profileuserinfo.message;
      setState(() {
        nameController.text = user?.displayName ?? '';
        cardIdController.text = user?.staffCode ?? '';
        emailController.text = user?.emailId ?? '';
        mobileController.text = user?.mobileNo ?? '';
        if (user?.createdOn != null) {
          try {
            dateOfJoiningController.text = DateFormat('dd/MM/yyyy').format(DateTime.parse(user!.createdOn!));
          } catch (_) {
            dateOfJoiningController.text = user?.createdOn ?? '';
          }
        }
        deviceIdController.text = user?.uuid ?? '';
        addressController.text = user?.currAddress ?? '';
        remoteaddressController.text = user?.newRemoteLocation ?? '';

        _isAtsChecked = user?.atsCheckflag == 'Y';
        distanceCheckFlag = user?.distanceCheckFlag;

        if (user?.addressapproveFlag == 'P') {
          addressApprovedFlag = 'Y';
          _showChangeAddressButton = true;
        } else {
          _showChangeAddressButton = false;
        }

        profileImage = (user?.profilePic?.isNotEmpty ?? false) ? user!.profilePic : null;
      });
    }

    if (state is DeleteStaffEntryLoadedState) {
      Fluttertoast.showToast(msg: state.cancelGatepassResponse.message ?? "User deleted");
      if (state.cancelGatepassResponse.message == "User Deleted Successfully...") {
        CustomDialog().popUp(context, "User Deleted Successfully!");
        Navigator.pop(context);
      }
    }

    if (state is acceptrequestLoadedState) {
      Fluttertoast.showToast(msg: "Location Request Accepted");
      _fetchInitialData();
    }

    if (state is nondistancecheckLoadedState) {
      setState(() {
        distanceCheckFlag = distanceCheckFlag == 'Y' ? 'N' : 'Y';
      });
      Fluttertoast.showToast(msg: distanceCheckFlag == 'Y' ? "Anywhere attendance enabled" : "Distance check enabled");
    }

    if (state is UpdateUserinfoLoadedState) {
      Fluttertoast.showToast(msg: state.updateuserinfo.message ?? "Profile updated");
      if (state.updateuserinfo.message == "Profile Updated Successfully...") {
        setState(() => _showUpdateButton = false);
      }
    }

    if( state is GetMultiRemoteLocationLoadingState){
      setState(() {
        _isLoading = true;
      });
    }
    if(state is GetMultiRemoteLocationLoadedState) {
      setState(() {
        _isLoading = false;
        multipleRemoteLocations = List<Map<String, dynamic>>.from(state.response);
      });
    }
    if(state is GetMultiRemoteLocationErrorState) {
      setState(() {
        _isLoading = false;
      });
      String error = state.msg;
      Fluttertoast.showToast(msg: error);
    }

    if (state is UpdateMultiRemoteLocationLoadingState){
      setState(() {
        _isLoading = true;
      });
    }
    if(state is UpdateMultiRemoteLocationLoadedState) {
      _getMultiRemoteLocation();
      setState(() {
        _isLoading = false;
      });
      Fluttertoast.showToast(msg: "Remote Location Updated");
    }
    if(state is UpdateMultiRemoteLocationErrorState) {
      setState(() {
        _isLoading = false;
      });
      String error = state.msg;
      Fluttertoast.showToast(msg: error);
    }

    if (state is GetUserinfoErrorState || state is DeleteStaffEntryErrorState || state is acceptrequestErrorState || state is UpdateUserinfoErrorState) {
      Fluttertoast.showToast(msg: "Operation failed. Please try again.");

    }
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: MyColors.appDefaultColorCode.withOpacity(0.2), width: 4),
            ),
            child: CircleAvatar(
              radius: 65,
              backgroundColor: Colors.grey[100],
              backgroundImage: profileImage != null ? MemoryImage(base64Decode(profileImage!)) : null,
              child: profileImage == null ? const Icon(Icons.person, size: 60, color: Colors.grey) : null,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: MyColors.appDefaultColorCode, shape: BoxShape.circle),
            child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 20),
          )
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Basic Information"),
        const SizedBox(height: 16),
        _buildReadOnlyField("Full Name", nameController, Icons.person_outline_rounded),
        _buildReadOnlyField("Staff ID", cardIdController, Icons.badge_outlined),
        // _buildReadOnlyField("Joining Date", dateOfJoiningController, Icons.calendar_today_rounded),
        _buildEditableField("Email Address", emailController, isEmailEditable, Icons.email_outlined, () {
          setState(() => isEmailEditable = !isEmailEditable);
        }),
        _buildEditableField("Mobile Number", mobileController, isMobileEditable, Icons.phone_android_rounded, () {
          setState(() => isMobileEditable = !isMobileEditable);
        }),
        _buildReadOnlyField("Current Address", addressController, Icons.location_on_outlined, maxLines: 2),
        if (remoteaddressController.text.isNotEmpty)
          _buildReadOnlyField("Remote Address", remoteaddressController, Icons.home_work_outlined, maxLines: 2),

        const SizedBox(height: 20),
        _buildSectionTitle("Settings & Permissions"),
        const SizedBox(height: 12),
        _buildAtsToggle(),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title.toUpperCase(), style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 1.1)),
    );
  }

  Widget _buildReadOnlyField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        maxLines: maxLines,
        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: MyColors.appDefaultColorCode, size: 20),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[100]!)),
        ),
      ),
    );
  }

  Widget _buildEditableField(
      String label,
      TextEditingController controller,
      bool isEditable,
      IconData icon,
      VoidCallback onToggle,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: true,
        keyboardType: label.contains("Mobile")
            ? TextInputType.number
            : TextInputType.emailAddress,
        maxLength: label.contains("Mobile") ? 10 : null,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        onChanged: (_) {
          setState(() {
            _showUpdateButton = true;
          });
        },
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon,
              color: MyColors.appDefaultColorCode, size: 20),

          suffixIcon: IconButton(
            icon: Icon(
              isEditable ? Icons.check_circle : Icons.edit,
              color: isEditable ? Colors.green : Colors.grey,
            ),
            onPressed: () {

              if (isEditable) {

                if (label.contains("Mobile") &&
                    _validatePhoneNumber(controller.text) != null) {
                  Fluttertoast.showToast(
                      msg: "Enter valid 10 digit mobile number");
                  return;
                }

                if (label.contains("Email") &&
                    _validateEmail(controller.text) != null) {
                  Fluttertoast.showToast(
                      msg: "Enter valid email address");
                  return;
                }
              }

              /// FIX
              onToggle();
            },
          ),

          filled: true,
          fillColor: isEditable ? Colors.white : Colors.grey[50],

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isEditable
                  ? MyColors.appDefaultColorCode
                  : Colors.grey[100]!,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAtsToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: SwitchListTile(
        title: Text("Timelog Attendance", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: Text("Allow automated time tracking", style: GoogleFonts.poppins(fontSize: 11)),
        value: _isAtsChecked,
        activeColor: MyColors.appDefaultColorCode,
        onChanged: (val) {
          setState(() => _isAtsChecked = val);
          mainBloc.add(UpdateUserFlagATS(UserId: widget.datum.staffCode!, AtsFlag: val ? "Y" : "N"));
        },
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_showChangeAddressButton)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildPrimaryButton("APPROVE REMOTE ADDRESS", Colors.orange[700]!, _handleAddressApproval),
          ),

        _buildPrimaryButton(
          distanceCheckFlag == 'Y' ? "DISABLE ANYWHERE ATTENDANCE" : "ALLOW ATTENDANCE FROM ANYWHERE",
          distanceCheckFlag == 'Y' ? Colors.red[600]! : Colors.green[600]!,
          _toggleDistanceCheck,
        ),

        if (_showUpdateButton)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _buildPrimaryButton("UPDATE PROFILE DETAILS", MyColors.appDefaultColorCode, _updateProfile),
          ),
      ],
    );
  }

  Widget _buildPrimaryButton(String text, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Text(text, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
      ),
    );
  }

  Widget _buildRemoteLocationList() {
    return Column(
      children: multipleRemoteLocations.map((loc) {
        final flag = (loc['flag'] ?? "P").toString().toUpperCase();
        final srNo = loc['srNo'];
        final locationName = loc['locationName'];
        final latitude = loc['latitude'];
        final longitude = loc['longitude'];
        final radius = loc['radius'];
        final staffCode = loc['staffCode'];

        String statusText = "PENDING";
        Color statusColor = Colors.orange;

        if (flag == "Y") {
          statusText = "APPROVED";
          statusColor = Colors.green;
        } else if (flag == "N") {
          statusText = "DISABLED";
          statusColor = Colors.red;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            color: Colors.grey[50],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, color: MyColors.appDefaultColorCode),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc['locationName'] ?? "Project Location",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        statusText,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              _buildLocationActionButton(flag, srNo, locationName, latitude, longitude, radius, staffCode)
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLocationActionButton(String flag, int srNo, String locationName, String latitude, String longitude, String radius, String staffCode) {
    if (flag == "P") {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          minimumSize: const Size(80, 36),
        ),
        onPressed: () {
          _updateRemoteLocation(srNo, "Y", locationName, latitude, longitude, radius, staffCode);
        },
        child: Text(
          "APPROVE",
          style: GoogleFonts.poppins(fontSize: 11),
        ),
      );
    }

    if (flag == "Y") {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          minimumSize: const Size(80, 36),
        ),
        onPressed: () {
          _updateRemoteLocation(srNo, "N", locationName, latitude, longitude, radius, staffCode);
        },
        child: Text(
          "DISABLE",
          style: GoogleFonts.poppins(fontSize: 11),
        ),
      );
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        minimumSize: const Size(80, 36),
      ),
      onPressed: () {
        _updateRemoteLocation(srNo, "Y", locationName, latitude, longitude, radius, staffCode);
      },
      child: Text(
        "ENABLE",
        style: GoogleFonts.poppins(fontSize: 11),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Remove Staff", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to delete this staff member? This action cannot be undone.", style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("CANCEL", style: GoogleFonts.poppins(color: Colors.grey))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              mainBloc.add(DeleteStaffEntryEvents(staffCode: widget.datum.staffCode!, token: authToken!));
            },
            child: Text("DELETE", style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _handleAddressApproval() {
    mainBloc.add(AcceptlocationRequest(staffcode: widget.datum.staffCode!, approvedflag: addressApprovedFlag!, token: authToken!));
  }

  void _toggleDistanceCheck() {
    mainBloc.add(NonDistancecheckRequest(
      approvedflag: distanceCheckFlag == 'Y' ? 'N' : 'Y',
      staffcode: widget.datum.staffCode!,
      token: authToken!,
    ));
  }

  void _updateProfile() {
    if( !_validateUserProfile() ) return;

    final request = ProfileUpdateRequest(
      staffCode: cardIdController.text,
      profilePic: profileImage ?? "",
      email: emailController.text,
      mobileNo: mobileController.text,
    );
    mainBloc.add(UpdateProfileDetailsEvents(updateuserinfo: request, token: authToken!));
  }

  bool _validateUserProfile() {
      if (_validatePhoneNumber(mobileController.text) != null) {
        Fluttertoast.showToast(
            msg: "Enter valid 10 digit mobile number");
        return false;
      }

      if (_validateEmail(emailController.text) != null) {
        Fluttertoast.showToast(
            msg: "Enter valid email address");
        return false;
      }

      return true;
  }

  void _updateRemoteLocation(int srNo, String flag, String locationName, String latitude, String longitude, String radius, String staffCode) {
    mainBloc.add(
      UpdateMultiRemoteLocationEvent(
        srNo,
        staffCode,
        latitude,
        longitude,
        locationName,
        flag,
        radius,
        authToken!,
      ),
    );
  }

  String? _validatePhoneNumber(String value) => RegExp(r'^[0-9]{10}$').hasMatch(value) ? null : "";
  String? _validateEmail(String value) => RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{3,}$').hasMatch(value) ? null : "";

  @override
  void dispose() {
    nameController.dispose();
    cardIdController.dispose();
    emailController.dispose();
    mobileController.dispose();
    dateOfJoiningController.dispose();
    addressController.dispose();
    remoteaddressController.dispose();
    deviceIdController.dispose();
    super.dispose();
  }
}
















// import 'dart:convert';
//
// import 'package:attendance_system_ios/bloc/main_bloc.dart';
// import 'package:attendance_system_ios/bloc/main_event.dart';
// import 'package:attendance_system_ios/bloc/main_state.dart';
// import 'package:attendance_system_ios/util/custome_dialogforDeleteUser.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:intl/intl.dart';
// import 'package:loading_overlay/loading_overlay.dart';
//
// import '../../model/Profile/UpdateUserinfo.dart';
// import '../../model/UsersList/GetAllusersListResponse.dart';
// import '../../service/log_file_manager.dart';
// import '../../util/MyColor.dart';
//
// /// distanceCheckFlag = Y (allow mark from anywhere), N (not allowed by admin), by default null (not allowed)
// /// addressApprovedFlag = Y ( allow mark attendance from admin), P ( requested form user and pending from admin approve), N (not allowed by admin), by default null ( no action form user)
// class AdminUserProfile extends StatefulWidget {
//   Message datum;
//
//   AdminUserProfile({
//     Key? key,
//     required this.datum,
//   }) : super(key: key);
//
//   @override
//   State<AdminUserProfile> createState() => _AdminUserProfile();
// }
//
// class _AdminUserProfile extends State<AdminUserProfile> {
//   final TextEditingController nameController = TextEditingController();
//   final TextEditingController cardIdController = TextEditingController();
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController mobileController = TextEditingController();
//   final TextEditingController dateOfJoiningController = TextEditingController();
//   final TextEditingController addressController = TextEditingController();
//   final TextEditingController remoteaddressController = TextEditingController();
//   final TextEditingController DeviceIdController = TextEditingController();
//
//   String? profileImage;
//   final ImagePicker _picker = ImagePicker();
//   late MainBloc mainBloc;
//   late bool _isLoading = false;
//   String? Auth_Token = "";
//   final storage = FlutterSecureStorage();
//   String? officeapprovedflag = "O";
//   String? addressApprovedFlag;
//   String? nondistancecheck = 'N';
//   bool _showOfficeAddressButton = false;
//   late bool isEmailEditable;
//   late bool isMobileEditable;
//   late bool _showUpdateButton = false;
//   bool _showChangeAddressButton = false;
//   bool _isChecked = false;
//
//   /// check or allow user to mark location form anywhere
//   String? distanceCheckFlag;
//
//   @override
//   void initState() {
//     super.initState();
//
//     mainBloc = BlocProvider.of(context);
//     profileImage = "";
//     isEmailEditable = false; // Initially not editable
//     isMobileEditable = false; // Default profile picture
//     getData();
//   }
//
//   Future<void> getData() async {
//     Auth_Token = await storage.read(key: 'Auth_Token');
//     print("Auth_Token-->$Auth_Token");
//     mainBloc.add(GetUserInfoEvents(
//         Staffcode: widget.datum.staffCode!, token: Auth_Token!));
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return DefaultTabController(
//       length: 4,
//       child: Scaffold(
//         appBar: AppBar(
//           leading: IconButton(
//             icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
//             onPressed: () => Navigator.of(context).pop(),
//           ),
//           title: const Text("Profile"),
//           backgroundColor: MyColors.darkBlue,
//           centerTitle: true,
//           titleTextStyle: GoogleFonts.roboto(
//             fontWeight: FontWeight.bold,
//             fontSize: 18.0,
//           ).copyWith(color: Colors.white),
//           actions: [
//             Padding(
//               padding: const EdgeInsets.all(5.0),
//               child: GestureDetector(
//                 onTap: () {
//                   //Delete Profile/User
//                   print("on click delete_Profile");
//
//                   showDialog(
//                       context: context,
//                       builder: (BuildContext context) =>
//                           _buildPopupDialogforRemoveStaffcode(context));
//                 },
//                 child: Image.asset(
//                   "assets/icons/delete_Profile.png",
//                   width: 35,
//                   height: 35,
//                 ),
//               ),
//             )
//           ],
//         ),
//         body: LoadingOverlay(
//             isLoading: _isLoading,
//             opacity: 0.5,
//             color: Colors.white,
//             progressIndicator: CircularProgressIndicator(
//               backgroundColor: Color(0xFFCE4A6F),
//               valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
//             ),
//             child: BlocListener<MainBloc, MainState>(
//               listener: (context, state) async {
//                 if (state is GetUserinfoLoadingState) {
//                   setState(() {
//                     _isLoading = true;
//                   });
//                 }
//                 if (state is GetUserinfoLoadedState) {
//                   final user = state.profileuserinfo.message;
//
//                   setState(() {
//                     _isLoading = false;
//
//                     // Populate the text fields
//                     nameController.text = user?.displayName ?? '';
//                     cardIdController.text = user?.staffCode ?? '';
//                     emailController.text = user?.emailId ?? '';
//                     //mobileController.text = user?.mobileNo ?? '';
//                     if (user?.mobileNo == null ||
//                         user!.mobileNo!.trim().isEmpty ||
//                         user.mobileNo == "null") {
//                       mobileController.text = "N/A";
//                       print("N/A");
//                     } else {
//                       print(user.mobileNo);
//                       mobileController.text = user.mobileNo!;
//                     }
//                     dateOfJoiningController.text = user?.createdOn != null
//                         ? DateFormat('dd/MM/yyyy')
//                             .format(DateTime.parse(user!.createdOn!))
//                         : '';
//                     DeviceIdController.text = user?.uuid ?? '';
//                     addressController.text = user?.currAddress ?? '';
//                     // if(user?.addressapproveFlag == 'P'){
//                     //  _changeaddress();
//                     // }
//                     if (user?.addressapproveFlag == 'P') {
//                       addressApprovedFlag = 'Y';
//                       _showChangeAddressButton = true;
//                       _showOfficeAddressButton =
//                           false; // Hide Office Address Button
//                     }
//                     /*else if (user?.addressapproveFlag == 'PO') {
//                       _showChangeAddressButton = false;
//                       _showOfficeAddressButton = true; // Show Office Address Button
//                     }*/
//
//                     if (user?.atsCheckflag == 'Y') {
//                       setState(() {
//                         _isChecked = true;
//                       });
//                     }
//
//                     // _showChangeAddressButton = user?.addressapproveFlag == 'P';
//                     // _showChangeAddressButton = user?.addressapproveFlag == 'PO';
//                     //remoteaddressController.text = user?.newRemoteLocation ?? '';
//                     if (user?.newRemoteLocation == null ||
//                         user!.newRemoteLocation!.trim().isEmpty ||
//                         user.newRemoteLocation == "null") {
//                       remoteaddressController.text = "N/A";
//                       print("N/A");
//                     } else {
//                       print(user.newRemoteLocation);
//                       remoteaddressController.text = user.newRemoteLocation!;
//                     }
//                     // Handle profile picture
//                     if (user?.profilePic != null &&
//                         user!.profilePic!.isNotEmpty) {
//                       profileImage = user.profilePic; // Base64 string
//                     } else {
//                       profileImage = null;
//                     }
//                     distanceCheckFlag = user!.distanceCheckFlag;
//                   });
//                 } else if (state is GetUserinfoErrorState) {
//                   setState(() {
//                     _isLoading = false;
//                   });
//                   Fluttertoast.showToast(
//                     msg: "  Failed To Fetch Details...!   ",
//                     toastLength: Toast.LENGTH_SHORT,
//                     timeInSecForIosWeb: 1,
//                   );
//                 }
//
//                 if (state is DeleteStaffEntryLoadingState) {
//                   print("DeleteStaffEntryLoadingState called...");
//
//                   setState(() {
//                     _isLoading = true;
//                   });
//                 } else if (state is DeleteStaffEntryLoadedState) {
//                   print("DeleteStaffEntryLoadedState called...");
//
//                   setState(() {
//                     _isLoading = false;
//                   });
//                   Fluttertoast.showToast(
//                     msg: " " + state.cancelGatepassResponse.message! + " ...!",
//                     toastLength: Toast.LENGTH_SHORT,
//                     timeInSecForIosWeb: 1,
//                   );
//                   if (state.cancelGatepassResponse.message ==
//                       "User Deleted Successfully...") {
//                     CustomDialog().popUp(
//                         context, "Well done! User Deleted Successfully...!!");
//                   }
//                 } else if (state is DeleteStaffEntryErrorState) {
//                   print("DeleteStaffEntryErrorState called...");
//
//                   setState(() {
//                     _isLoading = false;
//                   });
//                 }
//
//                 if (state is acceptrequestLoadingState) {
//                   setState(() {
//                     _isLoading = true;
//                   });
//                 } else if (state is acceptrequestLoadedState) {
//                   setState(() {
//                     _isLoading = false;
//                   });
//                   if (state.cancelGatepassResponse.message ==
//                       "AddressApproveFlag Updated Successfully...") {
//                     Fluttertoast.showToast(
//                       msg: "  Request Accepted   ",
//                       toastLength: Toast.LENGTH_SHORT,
//                       timeInSecForIosWeb: 1,
//                     );
//                   }
//                 } else if (state is acceptrequestErrorState) {
//                   setState(() {
//                     _isLoading = false;
//                   });
//                   Fluttertoast.showToast(
//                     msg: "  Failed To Accept Request...!   ",
//                     toastLength: Toast.LENGTH_SHORT,
//                     timeInSecForIosWeb: 1,
//                   );
//                 }
//
//                 if (state is nondistancecheckLoadingState) {
//                   setState(() {
//                     _isLoading = true;
//                   });
//                 } else if (state is nondistancecheckLoadedState) {
//                   setState(() {
//                     _isLoading = false;
//
//                     if (distanceCheckFlag == 'Y') {
//                       distanceCheckFlag = 'N';
//                     } else {
//                       distanceCheckFlag = 'Y';
//                     }
//                   });
//
//                   Fluttertoast.showToast(
//                     msg: distanceCheckFlag == 'Y'
//                         ? "User can mark attendance from anywhere"
//                         : "Distance check enabled",
//                     toastLength: Toast.LENGTH_SHORT,
//                   );
//                 } else if (state is nondistancecheckErrorState) {
//                   setState(() {
//                     _isLoading = false;
//                   });
//                   Fluttertoast.showToast(
//                     msg: "  Failed To Set Request...!   ",
//                     toastLength: Toast.LENGTH_SHORT,
//                     timeInSecForIosWeb: 1,
//                   );
//                 }
//
//                 if (state is UpdateUserinfoLoadingState) {
//                   setState(() {
//                     _isLoading = true;
//                   });
//                 } else if (state is UpdateUserinfoLoadedState) {
//                   setState(() {
//                     _isLoading = false;
//                   });
//                   if (state.updateuserinfo.message ==
//                       "EmailId is Already Present..") {
//                     Fluttertoast.showToast(msg: "EmailId already present");
//                     return;
//                   } else if (state.updateuserinfo.message ==
//                       "MobileNo is Already Present..") {
//                     Fluttertoast.showToast(
//                         msg: "Mobile Number already present");
//                     return;
//                   } else if (state.updateuserinfo.message ==
//                       "Profile Updated Successfully...") {
//                     Fluttertoast.showToast(
//                         msg: "Details Updated succesfully!!");
//                   }
//                 } else if (state is UpdateUserinfoErrorState) {
//                   setState(() {
//                     _isLoading = false;
//                   });
//                   Fluttertoast.showToast(msg: "error in updating");
//                 }
//
//                 if (state is updateUserAtsFlagLoadingState) {
//                   _isLoading = true;
//                 } else if (state is updateUserAtsFlagLoadedState) {
//                   setState(() {
//                     _isLoading = false;
//                   });
//                   Fluttertoast.showToast(msg: "User Attendance flag changed");
//                 } else if (state is updateUserAtsFlagErrorState) {
//                   setState(() {
//                     _isLoading = false;
//                   });
//                   Fluttertoast.showToast(msg: "User Attendance flag changedd");
//                 }
//               },
//               child: SingleChildScrollView(
//                   child: Column(
//                 children: <Widget>[
//                   GestureDetector(
//                     child: Stack(
//                       clipBehavior: Clip.none,
//                       children: [
//                         CircleAvatar(
//                           radius: 70,
//                           backgroundImage: profileImage != null
//                               ? MemoryImage(base64Decode(profileImage!))
//                               : AssetImage(" ") as ImageProvider,
//                           child: profileImage == null
//                               ? const Icon(Icons.person,
//                                   size: 50, color: Colors.white)
//                               : null,
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   TextField(
//                     controller: nameController,
//                     decoration: InputDecoration(
//                       labelText: 'Name',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10),
//                         borderSide: BorderSide(color: Colors.black, width: 1),
//                       ),
//                     ),
//                     style: TextStyle(color: Colors.black),
//                     enabled: false, // Make uneditable
//                   ),
//                   const SizedBox(height: 10),
//                   TextField(
//                     controller: cardIdController,
//                     decoration: InputDecoration(
//                       labelText: 'Card ID',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10),
//                         borderSide: BorderSide(color: Colors.blue, width: 1),
//                       ),
//                     ),
//                     style: TextStyle(color: Colors.black),
//                     enabled: false, // Make uneditable
//                   ),
//                   const SizedBox(height: 10),
//                   TextField(
//                     controller: dateOfJoiningController,
//                     decoration: InputDecoration(
//                       labelText: 'Date of Joining',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10),
//                         borderSide: BorderSide(color: Colors.blue, width: 1),
//                       ),
//                     ),
//                     style: TextStyle(color: Colors.black),
//                     enabled: false, // Make uneditable
//                   ),
//                   const SizedBox(height: 10),
//                   _buildEditableProfileField(
//                     emailController,
//                     'Email',
//                     isEmailEditable,
//                     () {
//                       setState(() {
//                         isEmailEditable =
//                             !isEmailEditable; // Toggle email editable state
//                       });
//                     },
//                   ),
//                   const SizedBox(height: 10),
//                   _buildEditableProfileField(
//                     mobileController,
//                     'Mobile Number',
//                     isMobileEditable,
//                     () {
//                       setState(() {
//                         isMobileEditable =
//                             !isMobileEditable; // Toggle mobile editable state
//                       });
//                     },
//                   ),
//                   const SizedBox(height: 10),
//                   SizedBox(
//                     width: double.infinity,
//                     // Makes the TextField span the entire screen width
//                     child: TextField(
//                       controller: addressController,
//                       decoration: InputDecoration(
//                         labelText: 'Current Address',
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(10),
//                           borderSide: BorderSide(color: Colors.blue, width: 1),
//                         ),
//                       ),
//                       style: TextStyle(color: Colors.black),
//                       // Set text color to black
//                       enabled: false,
//                       // Make uneditable
//                       maxLines:
//                           null, // Allows the text to wrap and expand vertically
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   SizedBox(
//                     width: double.infinity,
//                     // Makes the TextField span the entire screen width
//                     child: TextField(
//                       controller: remoteaddressController,
//                       decoration: InputDecoration(
//                         labelText: 'Remote Address',
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(10),
//                           borderSide: BorderSide(color: Colors.blue, width: 1),
//                         ),
//                       ),
//                       style: TextStyle(color: Colors.black),
//                       // Set text color to black
//                       enabled: false,
//                       // Make uneditable
//                       maxLines:
//                           null, // Allows the text to wrap and expand vertically
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.start,
//                     // Aligns to the left
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       Checkbox(
//                         value: _isChecked,
//                         onChanged: (bool? value) {
//                           setState(() {
//                             _isChecked = value!;
//                           });
//
//                           // Send ATSFlag depending on the state
//                           _handleCheckboxChecked(_isChecked);
//                         },
//                         materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                         visualDensity:
//                             VisualDensity(horizontal: -4.0, vertical: -4.0),
//                       ),
//                       const Text("Timelog Attendance"),
//                     ],
//                   ),
//                   const SizedBox(height: 10),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       ElevatedButton(
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: distanceCheckFlag == 'Y'
//                               ? Colors.red
//                               : Colors.green,
//                         ),
//                         onPressed: () {
//                           _toggleDistanceCheck();
//                         },
//                         child: Text(
//                           distanceCheckFlag == 'Y'
//                               ? "Disable Anywhere Attendance"
//                               : "Allow Attendance From Anywhere",
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 10),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       //Expanded(child: child)
//                       Visibility(
//                         visible: _showChangeAddressButton,
//                         child: Align(
//                           alignment: Alignment.bottomCenter,
//                           child: Padding(
//                             padding: const EdgeInsets.all(16.0),
//                             child: ElevatedButton(
//                               onPressed: _changeaddress,
//                               child: Text('Remote/Office Address Requested'),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 5),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Visibility(
//                         visible: _showUpdateButton,
//                         child: ElevatedButton(
//                           onPressed: () async {
//                             setState(() {
//                               _isLoading = true;
//                             });
//
//                             try {
//                               //final updatedFields = getAllFields();
//
//                               final updateProfileResponse =
//                                   ProfileUpdateRequest(
//                                 staffCode: cardIdController.text,
//                                 profilePic: profileImage.toString(),
//                                 email: emailController.text,
//                                 mobileNo: mobileController.text,
//                                 // profileImage: updatedFields["profilePic"], // Handle Base64 or URL
//                               );
//                               print(profileImage.toString());
//                               mainBloc.add(UpdateProfileDetailsEvents(
//                                 updateuserinfo: updateProfileResponse,
//                                 token: Auth_Token!,
//                               ));
//                             } catch (e) {
//                               LogFileManager.writeLog(
//                                   'Error in catch admin profile: $e');
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 SnackBar(
//                                     content: Text(
//                                         'Failed to update profile: ${e.toString()}')),
//                               );
//                             } finally {
//                               setState(() {
//                                 _isLoading = false;
//                               });
//                             }
//                           },
//                           child: _isLoading
//                               ? const CircularProgressIndicator(
//                                   color: Colors.white)
//                               : const Text('Update'),
//                         ),
//                       ),
//                       Visibility(
//                         visible: _showOfficeAddressButton,
//                         child: ElevatedButton(
//                           onPressed: _changetoofficeaddress,
//                           // Replace with actual function
//                           child: Text('Office Address'),
//                         ),
//                       ),
//                     ],
//                   )
//                 ],
//               )),
//             )),
//       ),
//     );
//   }
//
//   Widget _buildEditableProfileField(TextEditingController controller,
//       String label, bool isEditable, Function toggleEditable) {
//     return Row(
//       children: [
//         Expanded(
//           child: TextField(
//             controller: controller,
//             keyboardType: label == 'Mobile Number'
//                 ? TextInputType.number
//                 : TextInputType.emailAddress,
//             decoration: InputDecoration(
//               labelText: label,
//               labelStyle: const TextStyle(color: Colors.black),
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(10),
//                 borderSide: const BorderSide(color: Colors.black, width: 1),
//               ),
//             ),
//             enabled: isEditable,
//             maxLength: label == 'Mobile Number' ? 10 : null,
//             style: const TextStyle(color: Colors.black),
//             onChanged: (value) {
//               setState(() {
//                 _showUpdateButton = true; // Show Update button when edited
//               });
//             },
//           ),
//         ),
//         IconButton(
//           icon:
//               Icon(isEditable ? Icons.check : Icons.edit, color: Colors.black),
//           onPressed: () {
//             if (label == 'Mobile Number' &&
//                 _validatePhoneNumber(controller.text) != null) {
//               Fluttertoast.showToast(
//                   msg: "Enter a valid 10-digit mobile number");
//               return;
//             }
//             if (label == 'Email' && _validateEmail(controller.text) != null) {
//               Fluttertoast.showToast(msg: "Enter a valid email address");
//               return;
//             }
//             toggleEditable();
//           },
//         ),
//       ],
//     );
//   }
//
//   String? _validatePhoneNumber(String value) {
//     if (value.isEmpty) {
//       return "Phone number is required";
//     } else if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
//       return "Enter a valid 10-digit phone number";
//     }
//     return null;
//   }
//
//   String? _validateEmail(String value) {
//     if (value.isEmpty) {
//       return "Email is required";
//     } else if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{3,}$')
//         .hasMatch(value)) {
//       return "Enter a valid email address";
//     }
//     return null;
//   }
//
//   Widget _buildPopupDialogforRemoveStaffcode(BuildContext context) {
//     return new AlertDialog(
//       // title: const Text('Popup example'),
//       content: new Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: <Widget>[
//           Text(
//             "Delete",
//             style: TextStyle(
//                 fontSize: 20,
//                 color: MyColors.appDefaultColorCode,
//                 fontWeight: FontWeight.bold),
//           ),
//           SizedBox(
//             height: 20,
//           ),
//           Text(
//             "Are you sure you want to Remove This Staff?",
//             style: TextStyle(fontSize: 18),
//           ),
//         ],
//       ),
//       actions: <Widget>[
//         new TextButton(
//           onPressed: () {
//             Navigator.of(context).pop();
//           },
//           // textColor: Theme.of(context).primaryColor,
//           child: const Text(
//             'CANCEL',
//             style: TextStyle(
//               fontSize: 14.0,
//               fontWeight: FontWeight.normal,
//             ),
//           ),
//         ),
//         new TextButton(
//           onPressed: () {
//             Navigator.pop(context);
//             //here call Api
//             mainBloc.add(DeleteStaffEntryEvents(
//                 staffCode: widget.datum.staffCode!, token: Auth_Token!));
//           },
//           // textColor: Theme.of(context).primaryColor,
//           child: const Text(
//             'CONFIRM',
//             style: TextStyle(
//               fontSize: 14.0,
//               color: MyColors.orangeColorCode,
//               fontWeight: FontWeight.normal,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   _changeaddress() {
//     setState(() {
//       _isLoading = true;
//     });
//     //here call Api
//     mainBloc.add(AcceptlocationRequest(
//         staffcode: widget.datum.staffCode!,
//         approvedflag: addressApprovedFlag!,
//         token: Auth_Token!));
//     print(addressApprovedFlag);
//     Fluttertoast.showToast(
//       msg: "Remote location request approved successfully!",
//       toastLength: Toast.LENGTH_SHORT,
//     );
//     Navigator.pop(context);
//     setState(() {
//       _isLoading = false;
//     });
//     //mainBloc.add(DeleteStaffEntryEvents(staffCode: widget.datum.staffCode!, token: Auth_Token!));
//     //AcceptlocationRequest
//   }
//
//   _changetoofficeaddress() {
//     Navigator.pop(context);
//     //here call Api
//     mainBloc.add(AcceptlocationRequest(
//         staffcode: widget.datum.staffCode!,
//         approvedflag: officeapprovedflag!,
//         token: Auth_Token!));
//     print(officeapprovedflag);
//     //mainBloc.add(DeleteStaffEntryEvents(staffCode: widget.datum.staffCode!, token: Auth_Token!));
//     //AcceptlocationRequest
//   }
//
//   _handleCheckboxChecked(bool ischecked) {
//     final flag = ischecked ? "Y" : "N";
//
//     mainBloc.add(UpdateUserFlagATS(
//       UserId: widget.datum.staffCode!,
//       AtsFlag: flag,
//     ));
//   }
//
//   void _toggleDistanceCheck() {
//     String newFlag;
//
//     if (distanceCheckFlag == 'Y') {
//       newFlag = 'N';
//     } else {
//       newFlag = 'Y';
//     }
//
//     mainBloc.add(
//       NonDistancecheckRequest(
//         approvedflag: newFlag,
//         staffcode: widget.datum.staffCode!,
//         token: Auth_Token!,
//       ),
//     );
//   }
// }
