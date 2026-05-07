import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart'; // Import permission_handler
import '../../../bloc/main_bloc.dart';
import '../../../bloc/main_event.dart';
import '../../../bloc/main_state.dart';
import '../../../model/Profile/UpdateUserinfo.dart';
import '../../../service/log_file_manager.dart';
import '../../../util/MyColor.dart';

class ProfileforAdmin extends StatefulWidget {
  const ProfileforAdmin({super.key});
  @override
  State<ProfileforAdmin> createState() => _ProfileforAdminState();
}

class _ProfileforAdminState extends State<ProfileforAdmin> {

  String? staffCode = "";
  String? Auth_Token = "";
  late bool _isLoading = false;
  late MainBloc mainBloc;
  final storage = FlutterSecureStorage();
  late bool isEmailEditable;
  late bool isMobileEditable;
  String base64Image="";
  late bool _showUpdateButton = false;

  void initState() {
    super.initState();
    profileImage = ""; // Default profile picture
    mainBloc = BlocProvider.of(context);
    isEmailEditable = false; // Initially not editable
    isMobileEditable = false;
    getData();
  }
  Map<String, String?> getAllFields() {
    return {
      "displayName": nameController.text.trim(),
      "emailId": emailController.text.trim(),
      "mobileNo": mobileController.text.trim(),
      "currAddress": addressController.text.trim(),
      "profilePic": profileImage,
    };
  }

  Future<void> getData() async {
    staffCode = await storage.read(key: 'Staff_Code');
    print("staffCode-->" + staffCode!);
    Auth_Token = await storage.read(key: 'Auth_Token');
    print("Auth_Token-->" + Auth_Token!);
    mainBloc.add(GetUserInfoEvents(Staffcode: staffCode!, token: Auth_Token!));
  }

  Map<String, String?> originalData = {};

  Map<String, String?> getUpdatedFields() {
    Map<String, String?> updatedData = {};

    if (nameController.text.trim() != originalData["displayName"]) {
      updatedData["displayName"] = nameController.text.trim();
    }
    if (emailController.text.trim() != originalData["emailId"]) {
      updatedData["emailId"] = emailController.text.trim();
    }
    if (mobileController.text.trim() != originalData["mobileNo"]) {
      updatedData["mobileNo"] = mobileController.text.trim();
    }
    if (addressController.text.trim() != originalData["currAddress"]) {
      updatedData["currAddress"] = addressController.text.trim();
    }
    if (profileImage != originalData["profilePic"]) {
      updatedData["profilePic"] = profileImage;
    }

    // Return only updated fields
    return updatedData;
  }

  bool _showChangeAddressButton = false;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController cardIdController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController dateOfJoiningController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController remoteaddressController = TextEditingController();
  String? profileImage;
  final ImagePicker _picker = ImagePicker();

  void setJoiningDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final formattedDate = DateFormat('dd/MM/yyyy').format(date);
      dateOfJoiningController.text = formattedDate; // Update the controller
    } catch (e) {
      LogFileManager.writeLog('Error in Store InEntry: $e');
      print("Error parsing date: $e");
      dateOfJoiningController.text = "Invalid date"; // Fallback text
    }
  }

  Future<void> _requestGalleryPermission() async {
    if (await Permission.photos.isGranted || await Permission.storage.isGranted) {
      _showCameraOptions();
    } else {
      final status = await Permission.photos.request();
      if (status.isGranted) {
        _showCameraOptions();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Permission to access gallery is denied. Please enable it in settings.'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () {
                openAppSettings();
              },
            ),
          ),
        );
      }
    }
  }
/*
  Future<void> _showCameraOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete Profile Picture'),
              onTap: () {
                setState(() {
                  profileImage = null;
                });
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Upload Profile Picture'),
              onTap: () async {
                Navigator.of(context).pop(); // Close the modal first
                final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  setState(() {
                    profileImage = image.path; // Store the image path
                  });
                  base64Image = await _convertImageToBase64(image.path);
                  print("Base64 Image String: $base64Image");
                }
              },
            ),
          ],
        );
      },
    );
  }*/

  Future<void> _showCameraOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // ListTile(
            //   leading: const Icon(Icons.delete),
            //   title: const Text('Delete Profile Picture'),
            //   onTap: () {
            //     setState(() {
            //       profileImage = null;
            //     });
            //     Navigator.of(context).pop();
            //   },
            // ),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Upload Profile Picture'),
              onTap: () async {
                Navigator.of(context).pop(); // Close the modal first
                final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

                if (image != null) {
                  File compressedFile = await _compressImage(File(image.path)); // Compress Image
                  String base64String = await _convertImageToBase64(compressedFile); // Convert to Base64

                  setState(() {
                    profileImage = base64String;
                    _showUpdateButton = true; // Store Base64 string
                  });

                  print("📸 Compressed Base64 Image (first 100 chars): ${base64String.substring(0, 100)}...");
                }
              },
            ),
          ],
        );
      },
    );
  }

  /* Future<String> _convertImageToBase64(String imagePath) async {
    File imageFile = File(imagePath);
    List<int> imageBytes = await imageFile.readAsBytes();
    String base64Image = base64Encode(imageBytes);
    return base64Image;
  }
*/


  // Future<File> _compressImage(File file) async {
  //   final directory = await getTemporaryDirectory();
  //   final compressedFilePath = '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
  //
  //   // Compress and save the image
  //   final compressedImage = await FlutterImageCompress.compressAndGetFile(
  //     file.absolute.path,
  //     compressedFilePath,
  //     quality: 50, // Adjust quality as needed
  //     minWidth: 300, // Reduce image size
  //     minHeight: 300,
  //   );
  //
  //   return compressedImage ?? file; // Return compressed file
  // }
  Future<File> _compressImage(File file) async {
    final directory = await getTemporaryDirectory();
    final compressedFilePath = '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      compressedFilePath,
      quality: 50,
      minWidth: 300,
      minHeight: 300,
    );

    if (result is File) {
      return File(result!.path);
    } else {
      return file; // fallback
    }
  }

  Future<String> _convertImageToBase64(File file) async {
    List<int> imageBytes = await file.readAsBytes();
    return base64Encode(imageBytes); // Convert to Base64
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      ),
      body: BlocListener<MainBloc, MainState>(
        listener: (context, state) {
          if (state is GetUserinfoLoadingState) {
            setState(() {
              _isLoading = true;
            });
          }
          else if (state is GetUserinfoLoadedState) {
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
              addressController.text = user?.currAddress ?? '';
              remoteaddressController.text = user?.newRemoteLocation ?? '';
              _showChangeAddressButton = user?.addressapproveFlag == 'Y';

              // Store original data
              originalData = {
                "displayName": user?.displayName,
                "staffCode": user?.staffCode,
                "emailId": user?.emailId,
                "mobileNo": user?.mobileNo,
                "createdOn": user?.createdOn,
                "currAddress": user?.currAddress,
                "profilePic": user?.profilePic
              };

              // Handle profile picture
              if (user?.profilePic != null && user!.profilePic!.isNotEmpty) {
                profileImage = _cleanBase64(user.profilePic!); // Remove any invalid characters
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
              msg: "   Failed To Connect Server...!   ",
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
        },
        child: SingleChildScrollView(
          child:  Column(
            children: <Widget>[
              GestureDetector(
                onTap: _showCameraOptions, // Call the refactored method
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    /*      CircleAvatar(
                      radius: 70,
                      backgroundImage: profileImage != null
                          ? MemoryImage(base64Decode(profileImage!))
                          : AssetImage(" ") as ImageProvider,
                      child: profileImage == null
                          ? const Icon(Icons.person, size: 50, color: Colors.white)
                          : null,
                    ),*/
                    CircleAvatar(
                      radius: 70,
                      backgroundImage: profileImage != null
                          ? MemoryImage(base64Decode(_cleanBase64(profileImage!))) // Decode Base64
                          : const AssetImage("assets/icons/profileicon.png"), // Default image
                      child: profileImage == null
                          ? const Icon(Icons.person, size: 50, color: Colors.white)
                          : null,
                    ),
                    // CircleAvatar(
                    //   radius: 70,
                    //   backgroundImage: profileImage != null
                    //       ? (profileImage!.startsWith('http') // If it's a URL
                    //       ? NetworkImage(profileImage!)
                    //       : (profileImage!.startsWith('data:image') // If it's Base64
                    //       ? MemoryImage(base64Decode(profileImage!.split(',')[1]))
                    //       : FileImage(File(profileImage!))) as ImageProvider)
                    //       : const AssetImage('assets/icons/profileicon.png'),
                    //   child: profileImage == null
                    //       ? const Icon(Icons.person, size: 50, color: Colors.white)
                    //       : null,
                    // ),
                    Positioned(
                      bottom: 10,
                      right: 0,
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: Colors.white,
                        child: GestureDetector(
                          onTap: _showCameraOptions, // Update to call this method
                          child: Image.asset(
                            "assets/icons/camera.png",
                            width: 20,
                            height: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildProfileField(nameController, 'Name'),
              const SizedBox(height: 10),
              _buildProfileField(cardIdController, 'Card ID'),
              const SizedBox(height: 10),
              _buildProfileField(emailController, 'Email Id'),
              /*_buildEditableProfileField(
                emailController,
                'Email',
                isEmailEditable,
                    () {
                  setState(() {
                    isEmailEditable = !isEmailEditable; // Toggle email editable state
                  });
                },
              ),*/
              const SizedBox(height: 10),
              _buildProfileField(mobileController, 'Mobile Number'),
              /*   _buildEditableProfileField(
                mobileController,
                'Mobile Number',
                isMobileEditable,
                    () {
                  setState(() {
                    isMobileEditable = !isMobileEditable; // Toggle mobile editable state
                  });
                },
              ),*/
              const SizedBox(height: 10),
              _buildProfileField(dateOfJoiningController, 'Date of Joining'),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.all(10.0), // Adjust the value as needed
                child: SizedBox(
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
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: SizedBox(
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
              ),
              Visibility(
                  visible: _showUpdateButton,
                  child: ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        _isLoading = true;
                      });

                      try {
                        final updatedFields = getAllFields();

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
                        LogFileManager.writeLog('Error in catch profile: $e');
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
                  )
              ),

            ],
          ),
        ),
      ),
    );
  }
  String _cleanBase64(String base64String) {
    if (base64String.contains(",")) {
      return base64String.split(",").last.trim(); // Remove 'data:image/...;base64,' prefix
    }
    return base64String.trim();
  }

  Widget _buildProfileField(TextEditingController controller, String label) {

    return Padding(padding: EdgeInsets.all(12),
      child: TextField(
        controller: controller,
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
        ),
        enabled: false, // Non-editable by default
        style: const TextStyle(color: Colors.black), // Text color
      ),
    );

  }

/*  Widget _buildEditableProfileField(TextEditingController controller, String label, bool isEditable, Function toggleEditable) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
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
            ),
            enabled: isEditable, // Reflects the editable state
            style: const TextStyle(color: Colors.black), // Text color
          ),
        ),
        IconButton(
          icon: Icon(isEditable ? Icons.check : Icons.edit, color: Colors.black),
          onPressed: () {
            toggleEditable(); // Toggles the editable state
          },
        ),
      ],
    );
  }*/

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

}



