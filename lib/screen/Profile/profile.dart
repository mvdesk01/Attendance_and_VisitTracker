import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

import '../../bloc/main_bloc.dart';
import '../../bloc/main_event.dart';
import '../../bloc/main_state.dart';
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

  Future<void> pickImage() async {

    final XFile? image =
    await _picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: image.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
    );

    if (cropped == null) return;

    final bytes = await File(cropped.path).readAsBytes();

    setState(() {
      profileImage = base64Encode(bytes);
      showUpdate = true;
    });
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
        SafeArea(
          child: Positioned(
            left: 10,
            top: 5,
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
                          onPressed: () {

                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BlocProvider(
                                  create: (_) =>
                                      MainBloc(webService: WebService()),
                                  child: const HomeScreen(),
                                ),
                              ),
                            );
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