import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../bloc/main_bloc.dart';
import '../../bloc/main_event.dart';
import '../../bloc/main_state.dart';
import '../../model/Profile/UpdateUserinfo.dart';
import '../../service/WebService.dart';
import '../../screen/Home/home.dart';
import '../../util/MyColor.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile>
    with SingleTickerProviderStateMixin {

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

  late final token;
  late final staffCode;
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
     staffCode = await storage.read(key: "Staff_Code");
     token = await storage.read(key: "Auth_Token");

    if (staffCode != null && token != null) {
      mainBloc.add(GetUserInfoEvents(Staffcode: staffCode, token: token));
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

      final XFile? image =
      await _picker.pickImage(source: ImageSource.gallery);

      if (image == null) return;

      /// Crop Image
      final cropped = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 90,
      );

      if (cropped == null) return;

      File file = File(cropped.path);

      /// Compress Image
      File compressedFile = await compressImage(file);

      final bytes = await compressedFile.readAsBytes();

      String base64Image = base64Encode(bytes);

      setState(() {
        profileImage = base64Image;
      });

      /// Auto Update Profile
      final updateProfileResponse = ProfileUpdateRequest(
        staffCode: staffController.text,
        profilePic: base64Image,
        email: emailController.text,
        mobileNo: mobileController.text,
      );

      mainBloc.add(
        UpdateProfileDetailsEvents(
          updateuserinfo: updateProfileResponse,
          token: token,
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

    if (compressed == null) {
      return file; // fallback if compression fails
    }

    return File(compressed.path);
  }

  Widget shimmerLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        children: [
          Container(height: 220, color: Colors.white),
          const SizedBox(height: 80),
          ...List.generate(
            5,
                (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget infoCard(String title, TextEditingController controller, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: MyColors.lightBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: MyColors.lightBlue, size: 22),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          controller.text.isEmpty ? "N/A" : controller.text,
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
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
          height: 200,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                MyColors.lightBlue,
                MyColors.lightBlue,
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

        /// App Bar Elements
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  "User Profile",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 48), // Balanced spacing
              ],
            ),
          ),
        ),

        /// Avatar (Centered)
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
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 15,
                            color: Colors.black.withOpacity(0.1),
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: profileImage != null
                            ? MemoryImage(base64Decode(cleanBase64(profileImage!)))
                            : const AssetImage("assets/icons/profileicon.png") as ImageProvider,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: MyColors.lightBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 18,
                        color: Colors.white,
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

          setState(() {
            nameController.text = user?.displayName ?? "";
            staffController.text = user?.staffCode ?? "";
            emailController.text = user?.emailId ?? "";
            mobileController.text = user?.mobileNo ?? "";
            addressController.text = user?.currAddress ?? "";
            remoteController.text = user?.newRemoteLocation ?? "";

            if (user?.createdOn != null) {
              try {
                joinController.text = DateFormat('dd/MM/yyyy')
                    .format(DateTime.parse(user!.createdOn!));
              } catch (e) {
                joinController.text = user!.createdOn!;
              }
            }

            if (user?.profilePic != null && user!.profilePic!.isNotEmpty) {
              profileImage = cleanBase64(user.profilePic!);
            }

            loading = false;
          });
          _pageController.forward();
        }
      },
      child: Scaffold(
        // backgroundColor: Colors.white,
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
                  padding: const EdgeInsets.only(bottom: 30),
                  child: Column(
                    children: [
                      Text(
                        nameController.text,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        "Staff ID: ${staffController.text}",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 25),
                      infoCard("Email Address", emailController, Icons.email_outlined),
                      infoCard("Mobile Number", mobileController, Icons.phone_android_rounded),
                      infoCard("Joining Date", joinController, Icons.calendar_today_rounded),
                      infoCard("Current Address", addressController, Icons.location_on_outlined),
                      if (remoteController.text.isNotEmpty)
                        infoCard("Remote Address", remoteController, Icons.home_work_outlined),

                      const SizedBox(height: 30),

                      if (showUpdate)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: MyColors.lightBlue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BlocProvider(
                                      create: (_) => MainBloc(webService: WebService()),
                                      child: const HomeScreen(),
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                "UPDATE PROFILE",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
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
