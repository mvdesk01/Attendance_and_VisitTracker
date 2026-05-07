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
import '../../../model/Profile/UpdateUserinfo.dart';
import '../../../service/WebService.dart';
import '../../../util/MyColor.dart';
import '../../../model/UsersList/GetAllusersListResponse.dart';

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
        _buildReadOnlyField("Joining Date", dateOfJoiningController, Icons.calendar_today_rounded),
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

  Widget _buildEditableField(String label, TextEditingController controller, bool isEditable, IconData icon, VoidCallback onToggle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: isEditable,
        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
        onChanged: (_) => setState(() => _showUpdateButton = true),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: MyColors.appDefaultColorCode, size: 20),
          suffixIcon: IconButton(
            icon: Icon(isEditable ? Icons.check_circle_outline : Icons.edit_outlined, color: isEditable ? Colors.green : Colors.grey),
            onPressed: () {
              if (isEditable) {
                if (label.contains("Email") && _validateEmail(controller.text) != null) {
                  Fluttertoast.showToast(msg: "Invalid email");
                  return;
                }
                if (label.contains("Mobile") && _validatePhoneNumber(controller.text) != null) {
                  Fluttertoast.showToast(msg: "Invalid mobile number");
                  return;
                }
              }
              onToggle();
            },
          ),
          filled: true,
          fillColor: isEditable ? Colors.white : Colors.grey[50],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isEditable ? MyColors.appDefaultColorCode : Colors.grey[200]!)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isEditable ? MyColors.appDefaultColorCode : Colors.grey[100]!)),
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
    final request = ProfileUpdateRequest(
      staffCode: cardIdController.text,
      profilePic: profileImage ?? "",
      email: emailController.text,
      mobileNo: mobileController.text,
    );
    mainBloc.add(UpdateProfileDetailsEvents(updateuserinfo: request, token: authToken!));
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
