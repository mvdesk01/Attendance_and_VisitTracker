import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

import '../../bloc/main_bloc.dart';
import '../../bloc/main_event.dart';
import '../../bloc/main_state.dart';
import '../../model/Profile/UpdateUserinfo.dart';
import '../../service/WebService.dart';
import '../../screen/Home/home.dart';
import '../../service/log_file_manager.dart';
import '../../util/MyColor.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> with SingleTickerProviderStateMixin {

  final storage = const FlutterSecureStorage();
  final ImagePicker _picker = ImagePicker();

  late AnimationController _pageController;
  late Animation<double> _fadeAnimation;

  late MainBloc mainBloc;

  bool loading = true;
  bool showUpdate = false;

  String? profileImage;

  late bool _isLoading = false;

  final nameController = TextEditingController();
  final staffController = TextEditingController();
  final emailController = TextEditingController();
  final mobileController = TextEditingController();
  final joinController = TextEditingController();
  final addressController = TextEditingController();
  final remoteController = TextEditingController();

  @override
  void initState() {
    super.initState();

    mainBloc = BlocProvider.of<MainBloc>(context);

    _pageController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

    _fadeAnimation =
        CurvedAnimation(parent: _pageController, curve: Curves.easeOut);

    loadProfile();
  }

  Future<void> loadProfile() async {

    final staff = await storage.read(key: "Staff_Code");
    final token = await storage.read(key: "Auth_Token");

    mainBloc.add(GetUserInfoEvents(Staffcode: staff!, token: token!));
  }

  String cleanBase64(String base64String) {
    if (base64String.contains(",")) {
      return base64String.split(",").last;
    }
    return base64String;
  }

  // Future<void> pickImage() async {
  //
  //   final XFile? image =
  //   await _picker.pickImage(source: ImageSource.gallery);
  //
  //   if (image == null) return;
  //
  //   final cropped = await ImageCropper().cropImage(
  //     sourcePath: image.path,
  //     aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
  //   );
  //
  //   if (cropped == null) return;
  //
  //   final bytes = await File(cropped.path).readAsBytes();
  //
  //   setState(() {
  //     profileImage = base64Encode(bytes);
  //     showUpdate = true;
  //   });
  // }

  Future<void> pickImage() async {
    try {
      final XFile? image =
      await _picker.pickImage(source: ImageSource.gallery);

      if (image == null) return;

      CroppedFile? cropped;

      try {
        cropped = await ImageCropper().cropImage(
          sourcePath: image.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        );
      } catch (e) {
        print("Cropper error: $e");
      }

      final filePath = cropped?.path ?? image.path;

      final bytes = await File(filePath).readAsBytes();

      setState(() {
        profileImage = base64Encode(bytes);
        showUpdate = true;
      });
    } catch (e) {
      print("Image pick error: $e");
    }
  }

  Widget shimmerLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        children: List.generate(
          6,
              (index) => Container(
            margin: const EdgeInsets.all(16),
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget glassCard(String title, TextEditingController controller) {

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: MyColors.lightBlue.withOpacity(.3)),
            ),
            child: TextField(
              controller: controller,
              enabled: false,
              maxLines: null,
              decoration: InputDecoration(
                labelText: title,
                labelStyle: TextStyle(color: MyColors.lightBlue),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget header() {
    return Stack(
      clipBehavior: Clip.none,
      children: [

        /// Gradient Header Background
        Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                MyColors.lightBlue,
                MyColors.lightBlue.withOpacity(.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        /// Back Button
        Positioned(
          left: 10,
          top: 5,
          child: SafeArea(
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),

        /// Centered Title
        SafeArea(
          child: Container(
            height: 80,
            alignment: Alignment.center,
            child: const Text(
              "Profile",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),

        /// Avatar (Centered)
        Positioned(
          bottom: -60,
          left: 0,
          right: 0,
          child: Center(
            child: Hero(
              tag: "profile_avatar",
              child: GestureDetector(
                onTap: pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [

                    /// Avatar with shadow
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 15,
                            color: Colors.black.withOpacity(.25),
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 65,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundImage: profileImage != null
                              ? MemoryImage(
                              base64Decode(cleanBase64(profileImage!)))
                              : const AssetImage(
                            "assets/icons/profileicon.png",
                          ) as ImageProvider,
                        ),
                      ),
                    ),

                    /// Camera Icon
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 6,
                            color: Colors.black.withOpacity(.2),
                          )
                        ],
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: 18,
                        color: MyColors.lightBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  @override
  Widget build(BuildContext context) {

    return BlocListener<MainBloc, MainState>(
      listener: (context, state) {

        if (state is GetUserinfoLoadedState) {

          final user = state.profileuserinfo.message;

          nameController.text = user?.displayName ?? "";
          staffController.text = user?.staffCode ?? "";
          emailController.text = user?.emailId ?? "";
          mobileController.text = user?.mobileNo ?? "";
          addressController.text = user?.currAddress ?? "";
          remoteController.text = user?.newRemoteLocation ?? "";

          if (user?.createdOn != null) {
            joinController.text = DateFormat('dd/MM/yyyy')
                .format(DateTime.parse(user!.createdOn!));
          }

          if (user?.profilePic != null) {
            profileImage = cleanBase64(user!.profilePic!);
          }

          setState(() {
            loading = false;
          });

          _pageController.forward();
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
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => BlocProvider(
                        create: (context) {
                          return MainBloc(
                              webService: WebService());
                        },
                        child: HomeScreen())));
          }

        }
        else if(state is UpdateUserinfoErrorState){
          setState(() {
            _isLoading= false;
          });
          Fluttertoast.showToast(msg: "error in updating");
        }

      },

      child: Scaffold(

        body: loading
            ? shimmerLoader()
            : FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [

              header(),

              const SizedBox(height: 90),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [

                      glassCard("Name", nameController),
                      glassCard("Staff Code", staffController),
                      glassCard("Email", emailController),
                      glassCard("Mobile", mobileController),
                      glassCard("Joining Date", joinController),
                      glassCard("Current Address", addressController),
                      glassCard("Remote Address", remoteController),

                      const SizedBox(height: 25),

                      if (showUpdate)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MyColors.lightBlue,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                            onPressed: () async {
                              final token = await storage.read(key: "Auth_Token");
                              setState(() {
                                _isLoading = true;
                              });

                              try {
                                //final updatedFields = getAllFields();

                                final updateProfileResponse = ProfileUpdateRequest(
                                  staffCode: staffController.text,
                                  profilePic: profileImage.toString(),
                                  email: emailController.text,
                                  mobileNo: mobileController.text,
                                  // profileImage: updatedFields["profilePic"], // Handle Base64 or URL
                                );
                                print(profileImage.toString());
                                mainBloc.add(UpdateProfileDetailsEvents(
                                  updateuserinfo: updateProfileResponse ,
                                  token: token!,
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
                          child: const Text(
                            "Update Profile",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {

    nameController.dispose();
    staffController.dispose();
    emailController.dispose();
    mobileController.dispose();
    joinController.dispose();
    addressController.dispose();
    remoteController.dispose();
    _pageController.dispose();

    super.dispose();
  }
}

/*class _ProfileState extends State<Profile> with SingleTickerProviderStateMixin {
  final storage = const FlutterSecureStorage();
  final ImagePicker _picker = ImagePicker();

  late AnimationController _pageController;
  late Animation<double> _fadeAnimation;
  late MainBloc mainBloc;

  bool loading = true;
  bool showUpdate = false;
  String? profileImage;
  late bool _isLoading = false;

  final nameController = TextEditingController();
  final staffController = TextEditingController();
  final emailController = TextEditingController();
  final mobileController = TextEditingController();
  final joinController = TextEditingController();
  final addressController = TextEditingController();
  final remoteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    mainBloc = BlocProvider.of<MainBloc>(context);
    _pageController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _pageController, curve: Curves.easeInOut);
    loadProfile();
  }

  Future<void> loadProfile() async {
    final staff = await storage.read(key: "Staff_Code");
    final token = await storage.read(key: "Auth_Token");
    mainBloc.add(GetUserInfoEvents(Staffcode: staff!, token: token!));
  }

  String cleanBase64(String base64String) {
    if (base64String.contains(",")) {
      return base64String.split(",").last;
    }
    return base64String;
  }

  Future<void> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image == null) return;

      CroppedFile? cropped;
      try {
        cropped = await ImageCropper().cropImage(
          sourcePath: image.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Adjust Profile Picture',
              toolbarColor: MyColors.lightBlue,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
            ),
          ],
        );
      } catch (e) {
        debugPrint("Cropper error: $e");
      }

      final filePath = cropped?.path ?? image.path;
      final bytes = await File(filePath).readAsBytes();

      setState(() {
        profileImage = base64Encode(bytes);
        showUpdate = true;
      });
    } catch (e) {
      debugPrint("Image pick error: $e");
    }
  }

  Widget shimmerLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(height: 220, color: Colors.white),
            const SizedBox(height: 80),
            ...List.generate(6, (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              height: 70,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            )),
          ],
        ),
      ),
    );
  }

  Widget glassCard(String title, TextEditingController controller, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(.5)),
            ),
            child: TextField(
              controller: controller,
              enabled: false,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15,color: Colors.black),
              decoration: InputDecoration(
                icon: Icon(icon, color: MyColors.lightBlue, size: 20),
                labelText: title,
                labelStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.w400),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget header() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipPath(
          clipper: HeaderClipper(),
          child: Container(
            height: 240,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [MyColors.lightBlue, MyColors.lightBlue.withOpacity(0.8)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        Positioned(
          left: 10,
          top: 10,
          child: SafeArea(
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.2),
              child: IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Container(
            height: 60,
            alignment: Alignment.center,
            child: const Text(
              "Account Details",
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Positioned(
          bottom: -50,
          left: 0,
          right: 0,
          child: Center(
            child: Hero(
              tag: "profile_avatar",
              child: GestureDetector(
                onTap: pickImage,
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: CircleAvatar(
                        radius: 65,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: profileImage != null
                            ? MemoryImage(base64Decode(cleanBase64(profileImage!)))
                            : const AssetImage("assets/icons/profileicon.png") as ImageProvider,
                      ),
                    ),
                    Positioned(
                      bottom: 5,
                      right: 5,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: MyColors.lightBlue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.edit_rounded, size: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MainBloc, MainState>(
      listener: (context, state) {
        if (state is GetUserinfoLoadedState) {
          final user = state.profileuserinfo.message;
          nameController.text = user?.displayName ?? "";
          staffController.text = user?.staffCode ?? "";
          emailController.text = user?.emailId ?? "";
          mobileController.text = user?.mobileNo ?? "";
          addressController.text = user?.currAddress ?? "";
          remoteController.text = user?.newRemoteLocation ?? "";

          if (user?.createdOn != null) {
            joinController.text = DateFormat('dd MMM yyyy').format(DateTime.parse(user!.createdOn!));
          }
          if (user?.profilePic != null) {
            profileImage = cleanBase64(user!.profilePic!);
          }
          setState(() => loading = false);
          _pageController.forward();
        } else if (state is UpdateUserinfoLoadedState) {
          setState(() => _isLoading = false);
          if (state.updateuserinfo.message == "EmailId is Already Present..") {
            Fluttertoast.showToast(msg: "EmailId already present");
          } else if (state.updateuserinfo.message == "MobileNo is Already Present..") {
            Fluttertoast.showToast(msg: "Mobile Number already present");
          } else if (state.updateuserinfo.message == "Profile Updated Successfully...") {
            Fluttertoast.showToast(msg: "Profile updated successfully!");
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider(
                  create: (context) => MainBloc(webService: WebService()),
                  child: HomeScreen(),
                ),
              ),
            );
          }
        } else if (state is UpdateUserinfoErrorState) {
          setState(() => _isLoading = false);
          Fluttertoast.showToast(msg: "Error in updating profile");
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: loading
            ? shimmerLoader()
            : FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              header(),
              const SizedBox(height: 70),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      glassCard("Full Name", nameController, Icons.person_outline),
                      glassCard("Staff Code", staffController, Icons.badge_outlined),
                      glassCard("Email Address", emailController, Icons.alternate_email),
                      glassCard("Mobile Number", mobileController, Icons.phone_android),
                      glassCard("Joining Date", joinController, Icons.calendar_today_outlined),
                      glassCard("Current Address", addressController, Icons.home_outlined),
                      glassCard("Remote Location", remoteController, Icons.location_on_outlined),
                      const SizedBox(height: 30),
                      if (showUpdate)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: MyColors.lightBlue,
                                elevation: 4,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: _isLoading ? null : () async {
                                final token = await storage.read(key: "Auth_Token");
                                setState(() => _isLoading = true);
                                try {
                                  final updateReq = ProfileUpdateRequest(
                                    staffCode: staffController.text,
                                    profilePic: profileImage.toString(),
                                    email: emailController.text,
                                    mobileNo: mobileController.text,
                                  );
                                  mainBloc.add(UpdateProfileDetailsEvents(
                                    updateuserinfo: updateReq,
                                    token: token!,
                                  ));
                                } catch (e) {
                                  LogFileManager.writeLog('Error: $e');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed: ${e.toString()}')),
                                  );
                                }
                              },
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text("SAVE CHANGES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                            ),
                          ),
                        ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    staffController.dispose();
    emailController.dispose();
    mobileController.dispose();
    joinController.dispose();
    addressController.dispose();
    remoteController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}

/// Custom Clipper for a modern curved header
class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    // Start at the top left
    path.lineTo(0, size.height - 40);

    // Create the curve:
    // control point is at the bottom center, end point is at the bottom right
    path.quadraticBezierTo(
        size.width / 2,
        size.height,
        size.width,
        size.height - 40
    );

    // Line back to top right and close
    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}*/



