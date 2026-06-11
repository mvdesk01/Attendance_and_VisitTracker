import 'package:attendance_system_ios/service/menu_rights_service.dart';
import 'package:attendance_system_ios/util/MyColor.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../bloc/main_bloc.dart';
import '../../service/WebService.dart';
import '../../util/menu_drawer.dart';
import '../Login/login_screen.dart';
import '../Sanction/SanctionScreen.dart';
import '../UserListScreen/UserListScreen.dart';
import '../menurights/menu_rights.dart';
import '../menurights/menu_subscription.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  late List<String> imagePaths;
  String? staffCode;
  String? displayName;
  final storage = const FlutterSecureStorage();
  int _currentCarouselIndex = 0;

  @override
  void initState() {
    super.initState();
    imagePaths = [
      'assets/icons/mtechinnovationsimage1.jpg',
      'assets/icons/mtechinnovationsimage2.jpg',
      'assets/icons/mtechinnovationsimage3.jpg',
    ];
    getUserData();
  }

  Future<void> getUserData() async {
    staffCode = await storage.read(key: 'username');
    displayName = await storage.read(key: 'display_name') ?? "Admin";
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: MyColors.backgroundColorCode,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: MyColors.lightBlue,
        centerTitle: true,
        title: Text(
          "Admin Dashboard",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20.0,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Fluttertoast.showToast(msg: "No new notifications");
            },
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildCarousel(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Quick Actions",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildActionGrid(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildCarousel() {
    return Column(
      children: [
        CarouselSlider(
          items: imagePaths.map((path) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  path,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            );
          }).toList(),
          options: CarouselOptions(
            autoPlay: true,
            aspectRatio: 2.2,
            enlargeCenterPage: true,
            viewportFraction: 0.85,
            autoPlayInterval: const Duration(seconds: 4),
            onPageChanged: (index, _) {
              setState(() => _currentCarouselIndex = index);
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: imagePaths.asMap().entries.map((entry) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _currentCarouselIndex == entry.key ? 24 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: MyColors.appDefaultColorCode.withOpacity(
                  _currentCarouselIndex == entry.key ? 1.0 : 0.2,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionGrid() {
    List<Widget> cards = [
      _buildActionCard(
        icon: Icons.people_alt_rounded,
        title: "User List",
        desc: "Manage staff accounts",
        color: const Color(0xFF4285F4),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlocProvider(
              create: (context) => MainBloc(webService: WebService()),
              child: const UserListScreen(),
            ),
          ),
        ),
      ),
      _buildActionCard(
        icon: Icons.assignment_turned_in_rounded,
        title: "Approvals",
        desc: "Sanction/Reject leaves",
        color: const Color(0xFFFBBC05),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlocProvider(
              create: (context) => MainBloc(webService: WebService()),
              child: const SanctionRequest(),
            ),
          ),
        ),
      ),
    ];

    if (MenuRightsService.isMenuRightsAllowed()) {
      cards.add(
        _buildActionCard(
          icon: Icons.admin_panel_settings_rounded,
          title: "User Rights",
          desc: "Set menu permissions",
          color: const Color(0xFF34A853),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (context) => MainBloc(webService: WebService()),
                child: const MenuRightsScreen(),
              ),
            ),
          ),
        ),
      );
    }

    if (MenuRightsService.isSubscriptionAllowed()) {
      cards.add(
        _buildActionCard(
          icon: Icons.card_membership_rounded,
          title: "Subscription",
          desc: "Manage plan access",
          color: const Color(0xFFEA4335),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (context) => MainBloc(webService: WebService()),
                child: const MenuSubscriptionScreen(),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.95,
        children: cards,
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const Spacer(),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey.shade500,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
