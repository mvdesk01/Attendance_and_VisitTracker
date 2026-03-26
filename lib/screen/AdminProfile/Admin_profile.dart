import 'dart:convert';
import 'dart:io';

import 'package:attendance_system_ios/bloc/main_bloc.dart';
import 'package:attendance_system_ios/bloc/main_event.dart';
import 'package:attendance_system_ios/bloc/main_state.dart';
import 'package:attendance_system_ios/util/custome_dialogforDeleteUser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../model/Profile/UpdateUserinfo.dart';
import '../../service/log_file_manager.dart';
import '../../util/MyColor.dart';
import '../../model/UsersList/GetAllusersListResponse.dart';

class AdminUserProfile extends StatefulWidget {
  Message datum;

  AdminUserProfile(
      {
        Key? key,
        required this.datum,
      })
      : super(key: key);
  @override
  State<AdminUserProfile> createState() => _AdminUserProfile();
}

class _AdminUserProfile extends State<AdminUserProfile> {

  final TextEditingController nameController = TextEditingController();
  final TextEditingController cardIdController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController dateOfJoiningController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController remoteaddressController = TextEditingController();
  final TextEditingController DeviceIdController = TextEditingController();

  String? profileImage;
  final ImagePicker _picker = ImagePicker();
  late MainBloc mainBloc;
  late bool _isLoading = false;
  String? Auth_Token = "";
  final storage = FlutterSecureStorage();
  String? officeapprovedflag = "O";
  String? approvedflag = "Y";
  String? nondistancecheck = 'N';
  bool _showOfficeAddressButton = false;
  late bool isEmailEditable;
  late bool isMobileEditable;
  late bool _showUpdateButton = false;
  bool _showChangeAddressButton = false;
  bool _isChecked = false;


  @override
  void initState() {
    super.initState();

    mainBloc = BlocProvider.of(context);
    profileImage = "";
    isEmailEditable = false; // Initially not editable
    isMobileEditable = false;// Default profile picture
    getData();

  }
  Future<void> getData() async {
    Auth_Token = await storage.read(key: 'Auth_Token');
    print("Auth_Token-->$Auth_Token");
    mainBloc.add(GetUserInfoEvents(Staffcode: widget.datum.staffCode!, token: Auth_Token!));

  }
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child:
      Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text("Profile"),
          backgroundColor: MyColors.lightBlue,
          centerTitle: true,
          titleTextStyle: GoogleFonts.roboto(
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
          ).copyWith(color: Colors.white),
          actions: [

            Padding(
              padding: const EdgeInsets.all(5.0),
              child:
              GestureDetector(
                onTap: (){
                  //Delete Profile/User
                  print("on click delete_Profile");

                  showDialog(
                      context: context,
                      builder: (BuildContext context) =>
                          _buildPopupDialogforLogout(
                              context));
                },
                child: Image.asset(
                  "assets/icons/delete_Profile.png",
                  width: 35,
                  height: 35,

                ),
              ),
            )
          ],
        ),

        body: LoadingOverlay(
            isLoading: _isLoading,
            opacity: 0.5,
            color: Colors.white,
            progressIndicator: CircularProgressIndicator(
              backgroundColor: Color(0xFFCE4A6F),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
            ),
            child: BlocListener<MainBloc, MainState>(
              listener: (context, state) async
              {
                if (state is GetUserinfoLoadingState) {
                  setState(() {
                    _isLoading = true;
                  });
                }
                if (state is GetUserinfoLoadedState) {
                  final user = state.profileuserinfo.message;

                  setState(() {
                    _isLoading = false;

                    // Populate the text fields
                    nameController.text = user?.displayName ?? '';
                    cardIdController.text = user?.staffCode ?? '';
                    emailController.text = user?.emailId ?? '';
                    mobileController.text = user?.mobileNo ?? '';
                    dateOfJoiningController.text = user?.createdOn != null
                        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(user!.createdOn!))
                        : '';
                    DeviceIdController.text = user?.uuid ?? '';
                    addressController.text = user?.currAddress ?? '';
                    // if(user?.addressapproveFlag == 'P'){
                    //  _changeaddress();
                    // }
                    if (user?.addressapproveFlag == 'P') {
                      _showChangeAddressButton = true;
                      _showOfficeAddressButton = false; // Hide Office Address Button
                    } else if (user?.addressapproveFlag == 'PO') {
                      _showChangeAddressButton = false;
                      _showOfficeAddressButton = true; // Show Office Address Button
                    }

                    if(user?.atsCheckflag== 'Y'){
                      setState(() {
                        _isChecked=true;
                      });
                    }

                    // _showChangeAddressButton = user?.addressapproveFlag == 'P';
                    // _showChangeAddressButton = user?.addressapproveFlag == 'PO';
                    remoteaddressController.text = user?.newRemoteLocation ?? '';
                    // Handle profile picture
                    if (user?.profilePic != null && user!.profilePic!.isNotEmpty) {
                      profileImage = user.profilePic; // Base64 string
                    } else {
                      profileImage = null;
                    }
                  });
                }
                else if (state is GetUserinfoErrorState) {
                  setState(() {
                    _isLoading = false;
                  });
                  Fluttertoast.showToast(
                    msg: "  Failed To Fetch Details...!   ",
                    toastLength: Toast.LENGTH_SHORT,
                    timeInSecForIosWeb: 1,
                  );
                }

                if (state is DeleteStaffEntryLoadingState) {
                  print("DeleteStaffEntryLoadingState called...");

                  setState(() {
                    _isLoading = true;
                  });
                }
                else if (state is DeleteStaffEntryLoadedState) {
                  print("DeleteStaffEntryLoadedState called...");

                  setState(() {
                    _isLoading = false;
                  });
                  Fluttertoast.showToast(
                    msg:  " "+state.cancelGatepassResponse.message!+" ...!",
                    toastLength: Toast.LENGTH_SHORT,
                    timeInSecForIosWeb: 1,
                  );
                  if(state.cancelGatepassResponse.message=="User Deleted Successfully...")
                  {
                    CustomDialog().popUp(context,
                        "Well done! User Deleted Successfully...!!");
                  }
                }
                else if (state is DeleteStaffEntryErrorState) {
                  print("DeleteStaffEntryErrorState called...");

                  setState(() {
                    _isLoading = false;
                  });
                }
                if(state is acceptrequestLoadingState){
                  setState(() {
                    _isLoading=true;
                  });
                }
                else if(state is acceptrequestLoadedState){
                  setState(() {
                    _isLoading = false;
                  });
                  if(state.cancelGatepassResponse.message == "AddressApproveFlag Updated Successfully..."){
                    Fluttertoast.showToast(
                      msg: "  Request Accepted   ",
                      toastLength: Toast.LENGTH_SHORT,
                      timeInSecForIosWeb: 1,
                    );
                  }

                }
                else if(state is acceptrequestErrorState){
                  setState(() {
                    _isLoading=false;
                  });
                  Fluttertoast.showToast(
                    msg: "  Failed To Accept Request...!   ",
                    toastLength: Toast.LENGTH_SHORT,
                    timeInSecForIosWeb: 1,
                  );
                }
                if(state is nondistancecheckLoadingState){
                  setState(() {
                    _isLoading=true;
                  });
                }
                else if(state is nondistancecheckLoadedState){
                  setState(() {
                    _isLoading = false;
                  });
                  Fluttertoast.showToast(
                    msg: "  Request Accepted   ",
                    toastLength: Toast.LENGTH_SHORT,
                    timeInSecForIosWeb: 1,
                  );
                }
                else if(state is nondistancecheckErrorState){
                  setState(() {
                    _isLoading=false;
                  });
                  Fluttertoast.showToast(
                    msg: "  Failed To Set Request...!   ",
                    toastLength: Toast.LENGTH_SHORT,
                    timeInSecForIosWeb: 1,
                  );
                }
                if(state is UpdateUserinfoLoadingState){
                  setState(() {
                    _isLoading=true;
                  });
                }
                else if(state is UpdateUserinfoLoadedState){
                  setState(() {
                    _isLoading = false;
                  });
                  if(state.updateuserinfo.message == "EmailId is Already Present.."){
                    Fluttertoast.showToast(msg: "EmailId already present");
                    return;
                  }else if(state.updateuserinfo.message == "MobileNo is Already Present.."){
                    Fluttertoast.showToast(msg: "Mobile Number already present");
                    return;
                  }
                  else if(state.updateuserinfo.message == "Profile Updated Successfully..."){
                    Fluttertoast.showToast(msg: "Details Updated succesfully!!");
                  }

                }
                else if(state is UpdateUserinfoErrorState){
                  setState(() {
                    _isLoading= false;
                  });
                  Fluttertoast.showToast(msg: "error in updating");
                }
                if(state is updateUserAtsFlagLoadingState){
                  _isLoading=  true;
                }
                else if(state is updateUserAtsFlagLoadedState){
                  setState(() {
                    _isLoading=false;
                  });
                  Fluttertoast.showToast(msg: "User Attendance flag changed");
                }
                else if(state is updateUserAtsFlagErrorState){
                  setState(() {
                    _isLoading=false;
                  });
                  Fluttertoast.showToast(msg: "User Attendance flag changedd");

                }
              },
              child:
              SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      GestureDetector(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 70,
                              backgroundImage: profileImage != null
                                  ? MemoryImage(base64Decode(profileImage!))
                                  : AssetImage(" ") as ImageProvider,
                              child: profileImage == null
                                  ? const Icon(Icons.person, size: 50, color: Colors.white)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.black, width: 1),
                          ),
                        ),
                        style: TextStyle(color: Colors.black),
                        enabled: false, // Make uneditable
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: cardIdController,
                        decoration: InputDecoration(
                          labelText: 'Card ID',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.blue, width: 1),
                          ),
                        ),
                        style: TextStyle(color: Colors.black),
                        enabled: false, // Make uneditable
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: dateOfJoiningController,
                        decoration: InputDecoration(
                          labelText: 'Date of Joining',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.blue, width: 1),
                          ),
                        ),
                        style: TextStyle(color: Colors.black),
                        enabled: false, // Make uneditable
                      ),

                      const SizedBox(height: 10),
                      _buildEditableProfileField(
                        emailController,
                        'Email',
                        isEmailEditable,
                            () {
                          setState(() {
                            isEmailEditable = !isEmailEditable; // Toggle email editable state
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildEditableProfileField(
                        mobileController,
                        'Mobile Number',
                        isMobileEditable,
                            () {
                          setState(() {
                            isMobileEditable = !isMobileEditable; // Toggle mobile editable state
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity, // Makes the TextField span the entire screen width
                        child: TextField(
                          controller: addressController,
                          decoration: InputDecoration(
                            labelText: 'Current Address',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.blue, width: 1),
                            ),
                          ),
                          style: TextStyle(color: Colors.black), // Set text color to black
                          enabled: false, // Make uneditable
                          maxLines: null, // Allows the text to wrap and expand vertically
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity, // Makes the TextField span the entire screen width
                        child: TextField(
                          controller: remoteaddressController,
                          decoration: InputDecoration(
                            labelText: 'Remote Address',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.blue, width: 1),
                            ),
                          ),
                          style: TextStyle(color: Colors.black), // Set text color to black
                          enabled: false, // Make uneditable
                          maxLines: null, // Allows the text to wrap and expand vertically
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start, // Aligns to the left
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Checkbox(
                            value: _isChecked,
                            onChanged: (bool? value) {
                              setState(() {
                                _isChecked = value!;
                              });

                              // Send ATSFlag depending on the state
                              _handleCheckboxChecked(_isChecked);
                            },
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity(horizontal: -4.0, vertical: -4.0),
                          ),
                          const Text("Timelog Attendance"),
                        ],
                      ),

                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          //Expanded(child: child)
                          Visibility(
                            visible: _showChangeAddressButton,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: ElevatedButton(
                                  onPressed: _changeaddress,
                                  child: Text('Change Address'),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Visibility(
                            visible: _showUpdateButton,
                            child: ElevatedButton(
                              onPressed: () async {
                                setState(() {
                                  _isLoading = true;
                                });

                                try {
                                  //final updatedFields = getAllFields();

                                  final updateProfileResponse = ProfileUpdateRequest(
                                    staffCode: cardIdController.text,
                                    profilePic: profileImage.toString(),
                                    email: emailController.text,
                                    mobileNo: mobileController.text,
                                    // profileImage: updatedFields["profilePic"], // Handle Base64 or URL
                                  );
                                  print(profileImage.toString());
                                  mainBloc.add(UpdateProfileDetailsEvents(
                                    updateuserinfo: updateProfileResponse ,
                                    token: Auth_Token!,
                                  ));
                                } catch (e) {
                                  LogFileManager.writeLog('Error in catch admin profile: $e');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to update profile: ${e.toString()}')),
                                  );
                                } finally {
                                  setState(() {
                                    _isLoading = false;
                                  });
                                }
                              },
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text('Update'),
                            ),
                          ),
                          Visibility(
                            visible: _showOfficeAddressButton,
                            child: ElevatedButton(
                              onPressed: _changetoofficeaddress, // Replace with actual function
                              child: Text('Office Address'),
                            ),
                          ),
                        ],
                      )
                    ],
                  )
              ),
            )
        ),
      ),
    );
  }

  Widget _buildEditableProfileField(
      TextEditingController controller,
      String label,
      bool isEditable,
      Function toggleEditable) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: label == 'Mobile Number' ? TextInputType.number : TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(color: Colors.black),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.black, width: 1),
              ),
            ),
            enabled: isEditable,
            maxLength: label == 'Mobile Number' ? 10 : null,
            style: const TextStyle(color: Colors.black),
            onChanged: (value) {
              setState(() {
                _showUpdateButton = true;  // Show Update button when edited
              });
            },
          ),
        ),
        IconButton(
          icon: Icon(isEditable ? Icons.check : Icons.edit, color: Colors.black),
          onPressed: () {
            if (label == 'Mobile Number' && _validatePhoneNumber(controller.text) != null) {
              Fluttertoast.showToast(msg: "Enter a valid 10-digit mobile number");
              return;
            }
            if (label == 'Email' && _validateEmail(controller.text) != null) {
              Fluttertoast.showToast(msg: "Enter a valid email address");
              return;
            }
            toggleEditable();
          },
        ),
      ],
    );
  }

  String? _validatePhoneNumber(String value) {
    if (value.isEmpty) {
      return "Phone number is required";
    } else if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
      return "Enter a valid 10-digit phone number";
    }
    return null;
  }

  String? _validateEmail(String value) {
    if (value.isEmpty) {
      return "Email is required";
    } else if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{3,}$').hasMatch(value)) {
      return "Enter a valid email address";
    }
    return null;
  }

  Widget _buildPopupDialogforLogout(BuildContext context) {
    return new AlertDialog(
      // title: const Text('Popup example'),
      content: new Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            "Delete",
            style: TextStyle(
                fontSize: 20,
                color: MyColors.appDefaultColorCode,
                fontWeight: FontWeight.bold),
          ),
          SizedBox(
            height: 20,
          ),
          Text(
            "Are you sure you want to Remove This Staff?",
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
      actions: <Widget>[
        new TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          // textColor: Theme.of(context).primaryColor,
          child: const Text(
            'CANCEL',
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
        new TextButton(
          onPressed: () {
            Navigator.pop(context);
            //here call Api
            mainBloc.add(DeleteStaffEntryEvents(staffCode: widget.datum.staffCode!, token: Auth_Token!));
          },
          // textColor: Theme.of(context).primaryColor,
          child: const Text(
            'CONFIRM',
            style: TextStyle(
              fontSize: 14.0,
              color: MyColors.orangeColorCode,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  _changeaddress() {
    setState(() {
      _isLoading = true;
    });
    //here call Api
    mainBloc.add(AcceptlocationRequest(staffcode: widget.datum.staffCode!, approvedflag: approvedflag!, token: Auth_Token!));
    print(approvedflag);
    Fluttertoast.showToast(
      msg: "Remote location request approved successfully!",
      toastLength: Toast.LENGTH_SHORT,
    );
    Navigator.pop(context);
    setState(() {
      _isLoading = false;
    });
    //mainBloc.add(DeleteStaffEntryEvents(staffCode: widget.datum.staffCode!, token: Auth_Token!));
    //AcceptlocationRequest
  }

  _changetoofficeaddress() {
    Navigator.pop(context);
    //here call Api
    mainBloc.add(AcceptlocationRequest(staffcode: widget.datum.staffCode!, approvedflag: officeapprovedflag!, token: Auth_Token!));
    print(officeapprovedflag);
    //mainBloc.add(DeleteStaffEntryEvents(staffCode: widget.datum.staffCode!, token: Auth_Token!));
    //AcceptlocationRequest
  }

  _handleCheckboxChecked(bool ischecked){
    final flag = ischecked ? "Y" : "N";

    mainBloc.add(UpdateUserFlagATS(
      UserId: widget.datum.staffCode!,
      AtsFlag: flag,
    ));

  }
}




/*
  Widget _buildEditableProfileField(TextEditingController controller, String label, bool isEditable, Function toggleEditable) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: label == 'Mobile Number' ? TextInputType.number : TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(color: Colors.black),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.black, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.black, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.black, width: 2),
              ),
              errorText: label == 'Mobile Number'
                  ? _validatePhoneNumber(controller.text)
                  : label == 'Email'
                  ? _validateEmail(controller.text)
                  : null, // Error messages
            ),
            enabled: isEditable,
            maxLength: label == 'Mobile Number' ? 10 : null, // Restrict phone number to 10 digits
            style: const TextStyle(color: Colors.black),
            onChanged: (value) {
              // Validate input on change
              if (label == 'Mobile Number') {
                _validatePhoneNumber(value);
              } else if (label == 'Email') {
                _validateEmail(value);
              }
            },
          ),
        ),
        IconButton(
          icon: Icon(isEditable ? Icons.check : Icons.edit, color: Colors.black),
          onPressed: () {
            if (label == 'Mobile Number' && _validatePhoneNumber(controller.text) != null) {
              Fluttertoast.showToast(msg: "Enter a valid 10-digit mobile number");
              return;
            }
            if (label == 'Email' && _validateEmail(controller.text) != null) {
              Fluttertoast.showToast(msg: "Enter a valid email address");
              return;
            }
            toggleEditable();
          },
        ),
      ],
    );
  }
*/