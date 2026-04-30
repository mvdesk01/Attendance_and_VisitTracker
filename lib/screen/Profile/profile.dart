import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../bloc/main_bloc.dart';
import '../../bloc/main_event.dart';
import '../../bloc/main_state.dart';
import '../../model/Profile/UpdateUserinfo.dart';
import '../../screen/Home/home.dart';
import '../../service/WebService.dart';
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

  final nameController = TextEditingController();
  final staffController = TextEditingController();
  final emailController = TextEditingController();
  final mobileController = TextEditingController();
  final joinController = TextEditingController();
  final addressController = TextEditingController();
  final remoteController = TextEditingController();

  String? token;
  String? staffCode;

  @override
  void initState() {
    super.initState();
    mainBloc = BlocProvider.of<MainBloc>(context);

    _pageController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));

    _fadeAnimation =
        CurvedAnimation(parent: _pageController, curve: Curves.easeOut);

    loadProfile();
  }

  Future<void> loadProfile() async {
    staffCode = await storage.read(key: "Staff_Code");
    token = await storage.read(key: "Auth_Token");

    if (staffCode != null && token != null) {
      mainBloc.add(GetUserInfoEvents(Staffcode: staffCode!, token: token!));
    }
  }

  String cleanBase64(String base64String) {
    if (base64String.contains(",")) {
      return base64String.split(",").last;
    }
    return base64String;
  }

  Future<void> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final cropped = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Picture',
            toolbarColor: MyColors.lightBlue,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Profile Picture',
          ),
        ],
      );

      if (cropped == null) return;

      File file = File(cropped.path);
      File compressedFile = await compressImage(file);
      final bytes = await compressedFile.readAsBytes();
      String base64Image = base64Encode(bytes);

      setState(() {
        profileImage = base64Image;
      });

      final updateProfileResponse = ProfileUpdateRequest(
        staffCode: staffController.text,
        profilePic: base64Image,
        email: emailController.text,
        mobileNo: mobileController.text,
      );

      mainBloc.add(
        UpdateProfileDetailsEvents(
          updateuserinfo: updateProfileResponse,
          token: token!,
        ),
      );
    } catch (e) {
      debugPrint("Image error: $e");
    }
  }

  Future<File> compressImage(File file) async {
    final targetPath = "${file.path}_compressed.jpg";
    final XFile? compressed = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 60,
      minWidth: 512,
      minHeight: 512,
    );

    return compressed != null ? File(compressed.path) : file;
  }

  Widget shimmerLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(height: 220, color: Colors.white),
            const SizedBox(height: 100),
            ...List.generate(
              6,
              (index) => Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget infoField(
      String title, TextEditingController controller, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        enabled: false,
        style:
            const TextStyle(fontWeight: FontWeight.w500, color: MyColors.black),
        decoration: InputDecoration(
          labelText: title,
          labelStyle:
              const TextStyle(color: MyColors.text3greyColorCode, fontSize: 14),
          prefixIcon: Icon(icon, color: MyColors.lightBlue, size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget header() {
    double topPadding = MediaQuery.of(context).padding.top;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        /// Gradient Header Background
        Container(
          height: 220,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                MyColors.lightBlue,
                Color(0xFF005BC4),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
        ),

        /// Back Button
        Positioned(
          left: 10,
          top: topPadding + 5,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),

        /// Centered Title
        Positioned(
          top: topPadding + 15,
          left: 0,
          right: 0,
          child: const Center(
            child: Text(
              "My Profile",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
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
            child: GestureDetector(
              onTap: pickImage,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 15,
                          color: Colors.black.withOpacity(.15),
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 65,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage:
                          profileImage != null && profileImage!.isNotEmpty
                              ? MemoryImage(
                                  base64Decode(cleanBase64(profileImage!)))
                              : const AssetImage("assets/icons/profileicon.png")
                                  as ImageProvider,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: MyColors.lightBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ],
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
          //mobileController.text = user?.mobileNo ?? "";
          addressController.text = user?.currAddress ?? "";
          //remoteController.text = user?.newRemoteLocation ?? "";

          if (user?.newRemoteLocation == null ||
              user!.newRemoteLocation!.trim().isEmpty ||
              user.newRemoteLocation == "null") {
            remoteController.text = "N/A";
            print("N/A");
          } else {
            print(user.newRemoteLocation);
            remoteController.text = user.newRemoteLocation!;
          }

          if (user?.createdOn != null) {
            try {
              joinController.text = DateFormat('dd MMM yyyy')
                  .format(DateTime.parse(user!.createdOn!));
            } catch (e) {
              joinController.text = user?.createdOn ?? "";
            }
          }
          if (user?.mobileNo == null ||
              user!.mobileNo!.trim().isEmpty ||
              user.mobileNo == "null") {
            mobileController.text = "N/A";
            print("N/A");
          } else {
            print(user.mobileNo);
            mobileController.text = user.mobileNo!;
          }

          if (user?.profilePic != null && user!.profilePic!.isNotEmpty) {
            profileImage = cleanBase64(user.profilePic!);
          }

          setState(() {
            loading = false;
          });
          _pageController.forward();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FE),
        body: loading
            ? shimmerLoader()
            : FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    header(),
                    const SizedBox(height: 80),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 30),
                        child: Column(
                          children: [
                            infoField("Full Name", nameController,
                                Icons.person_outline),
                            infoField("Staff Code", staffController,
                                Icons.badge_outlined),
                            infoField("Email Address", emailController,
                                Icons.email_outlined),
                            infoField("Mobile Number", mobileController,
                                Icons.phone_android_outlined),
                            infoField("Joining Date", joinController,
                                Icons.calendar_today_outlined),
                            infoField("Current Address", addressController,
                                Icons.location_on_outlined),
                            infoField("Remote Location", remoteController,
                                Icons.map_outlined),
                            const SizedBox(height: 30),
                            if (showUpdate)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: MyColors.lightBlue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    onPressed: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => BlocProvider(
                                            create: (_) => MainBloc(
                                                webService: WebService()),
                                            child: const HomeScreen(),
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      "Update Profile",
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ),
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
