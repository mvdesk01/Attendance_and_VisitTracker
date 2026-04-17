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

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  late List<String> imagePaths;

  final storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    imagePaths = [
      'assets/icons/mtechinnovationsimage1.jpg',
      'assets/icons/mtechinnovationsimage2.jpg',
      'assets/icons/mtechinnovationsimage3.jpg',
    ];
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          actions: <Widget>[
            Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: GestureDetector(
                  onTap: () {
                    Fluttertoast.showToast(
                      msg: "No Notification Found",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                    );
                  },
                  child: Icon(Icons.notifications),
                )),
          ],
          iconTheme: const IconThemeData(
            color: Colors.white,
            size: 28,
          ),
          title: const Text("Attendance"),
          backgroundColor: MyColors.lightBlue,
          centerTitle: true,
          titleTextStyle: GoogleFonts.roboto(
            fontWeight: FontWeight.bold,
            fontSize: 20.0,
          ).copyWith(
            color: Colors.white,
          ),
        ),
        drawer: MenuDrawer(),
        backgroundColor: MyColors.backgroundColorCode,
        body: TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [
            // Home Screen Content
            Column(
              children: [
                // Image Slider
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: CarouselSlider(
                    items: imagePaths.map((imagePath) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          imagePath,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      );
                    }).toList(),
                    options: CarouselOptions(
                      autoPlay: true,
                      aspectRatio: 16 / 9,
                      enlargeCenterPage: true,
                      autoPlayInterval: const Duration(seconds: 2),
                    ),
                  ),
                ),

                // Card Views
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildCard(
                              icon: Icons.people_outline,
                              title: 'User List',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BlocProvider(
                                      create: (context) =>
                                          MainBloc(webService: WebService()),
                                      child: UserListScreen(),
                                    ),
                                  ),
                                );
                              },
                            ),
                            _buildCard(
                              icon: Icons.book_outlined,
                              title: 'Sanction/Reject',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BlocProvider(
                                      create: (context) =>
                                          MainBloc(webService: WebService()),
                                      child: SanctionRequest(),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // // Logout Tab
            // Center(
            //   child: GestureDetector(
            //     onTap: () {
            //       showDialog(
            //         context: context,
            //         builder: (BuildContext context) =>
            //             _buildPopupDialogforLogout(context),
            //       );
            //     },
            //     child: Text("Logout"),
            //   ),
            // ),
          ],
        ),
        bottomNavigationBar: Container(
          color: MyColors.whiteColorCode,
          child: TabBar(
            indicatorColor: MyColors.whiteColorCode,
            labelColor: MyColors.appDefaultColorCode,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(
                text: 'Home',
                icon: Icon(Icons.home_outlined, size: 30),
              ),
              GestureDetector(
                onTap: () {
                  print("on click Logout");
                  showDialog(
                      context: context,
                      builder: (BuildContext context) =>
                          _buildPopupDialogforLogout(context));
                },
                child: Tab(
                    text: 'Logout',
                    icon: Icon(
                      Icons.logout,
                      size: 30,
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 5,
        child: Container(
          height: 150,
          width: 150,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 50, color: MyColors.appDefaultColorCode),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopupDialogforLogout(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const <Widget>[
          Text(
            "Logout",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          Text(
            "Are you sure you want to Logout Attendance App?",
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CANCEL'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => BlocProvider(
                  create: (context) => MainBloc(webService: WebService()),
                  child: const LoginScreen(),
                ),
              ),
              (Route<dynamic> route) => false,
            );

            onLogout();
          },
          child: const Text('CONFIRM'),
        ),
      ],
    );
  }

  void onLogout() async {
    // Clear the secure storage
    await clearAllSecureStorage();

    // , navigate the user to the login screen or any other screen
    Navigator.pop(context);

    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => BlocProvider(
              create: (context) {
                return MainBloc(webService: WebService());
              },
              child: LoginScreen()),
        ),
        (Route<dynamic> route) => false);
  }

  // Function to clear specific keys
  Future<void> clearSecureStorage() async {
    await storage.delete(key: 'Auth_Token'); // Delete auth token
    await storage.delete(key: 'Staff_Code'); // Delete staff code
    await storage.delete(key: 'Staff_Name'); // Delete staff name
    await storage.delete(
        key: 'username'); // Delete username (if used for remember me)
    await storage.delete(
        key: 'password'); // Delete password (if used for remember me)
  }

// Or to clear all stored data
  Future<void> clearAllSecureStorage() async {
    await storage.deleteAll(); // Clear all stored data
  }
}

// class _AdminHomeScreenState extends State<AdminHomeScreen> {
//   late List<String> imagePaths;
//   final storage = FlutterSecureStorage();
//
//   @override
//   void initState() {
//     super.initState();
//     imagePaths = [
//       'assets/icons/mtechinnovationsimage1.jpg',
//       'assets/icons/mtechinnovationsimage2.jpg',
//       'assets/icons/mtechinnovationsimage3.jpg',
//     ];
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return DefaultTabController(
//       length: 2,
//       child: Scaffold(
//         backgroundColor: MyColors.backgroundColorCode,
//         appBar: AppBar(
//           elevation: 0,
//           centerTitle: true,
//           backgroundColor: MyColors.lightBlue,
//           title: Text(
//             "Attendance Admin",
//             style: GoogleFonts.poppins(
//               fontWeight: FontWeight.w600,
//               fontSize: 20,
//               color: Colors.white,
//             ),
//           ),
//           actions: [
//             IconButton(
//               icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
//               onPressed: () {
//                 Fluttertoast.showToast(msg: "No Notifications Found");
//               },
//             ),
//             const SizedBox(width: 8),
//           ],
//         ),
//         drawer: const MenuDrawer(),
//         body: TabBarView(
//           physics: const NeverScrollableScrollPhysics(),
//           children: [
//             // Home Screen Content
//             SingleChildScrollView(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const SizedBox(height: 20),
//
//                   // Professional Carousel
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//                     child: CarouselSlider(
//                       items: imagePaths.map((imagePath) {
//                         return Container(
//                           margin: const EdgeInsets.symmetric(horizontal: 5),
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(20),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(0.15),
//                                 blurRadius: 12,
//                                 offset: const Offset(0, 6),
//                               ),
//                             ],
//                           ),
//                           child: ClipRRect(
//                             borderRadius: BorderRadius.circular(20),
//                             child: Image.asset(
//                               imagePath,
//                               fit: BoxFit.cover,
//                               width: double.infinity,
//                             ),
//                           ),
//                         );
//                       }).toList(),
//                       options: CarouselOptions(
//                         autoPlay: true,
//                         height: 220,
//                         enlargeCenterPage: true,
//                         viewportFraction: 0.85,
//                         autoPlayInterval: const Duration(seconds: 4),
//                         pauseAutoPlayOnTouch: true,
//                       ),
//                     ),
//                   ),
//
//                   const SizedBox(height: 32),
//
//                   // Welcome Admin Section
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 20),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Row(
//                           children: [
//                             Icon(
//                               Icons.admin_panel_settings_rounded,
//                               color: MyColors.lightBlue,
//                               size: 28,
//                             ),
//                             const SizedBox(width: 12),
//                             Text(
//                               "Welcome, Admin!",
//                               style: GoogleFonts.poppins(
//                                 fontSize: 24,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.black87,
//                                 letterSpacing: -0.5,
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           "Manage your account and oversee all administrative tasks efficiently",
//                           style: GoogleFonts.poppins(
//                             fontSize: 14,
//                             color: Colors.grey.shade600,
//                             height: 1.4,
//                           ),
//                         ),
//                         const SizedBox(height: 16),
//                         Container(
//                           width: 60,
//                           height: 3,
//                           decoration: BoxDecoration(
//                             color: MyColors.lightBlue,
//                             borderRadius: BorderRadius.circular(2),
//                           ),
//                         ),
//                         const SizedBox(height: 24),
//
//                         // Vertical Card View
//                         Column(
//                           children: [
//                             _buildActionCard(
//                               icon: Icons.group_add_rounded,
//                               title: 'User List',
//                               subtitle: 'Manage Staff Members',
//                               description: 'View, add, edit, or remove staff accounts and manage their permissions.',
//                               color: Colors.blue.shade50,
//                               iconColor: Colors.blue.shade700,
//                               onTap: () => _navigateTo(context, UserListScreen()),
//                             ),
//                             const SizedBox(height: 20),
//                             _buildActionCard(
//                               icon: Icons.assignment_turned_in_rounded,
//                               title: 'Approvals',
//                               subtitle: 'Sanction/Reject Requests',
//                               description: 'Review and process pending leave requests, attendance corrections, and other approvals.',
//                               color: Colors.orange.shade50,
//                               iconColor: Colors.orange.shade700,
//                               onTap: () => _navigateTo(context, SanctionRequest()),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//
//                   const SizedBox(height: 40),
//                 ],
//               ),
//             ),
//             const Center(child: Text("Logout Page Content")),
//           ],
//         ),
//         bottomNavigationBar: Container(
//           decoration: BoxDecoration(
//             color: Colors.white,
//             boxShadow: [
//               BoxShadow(
//                   color: Colors.black.withOpacity(0.08),
//                   blurRadius: 15,
//                   offset: const Offset(0, -3)
//               )
//             ],
//           ),
//           child: TabBar(
//             indicator: UnderlineTabIndicator(
//               borderSide: BorderSide(color: MyColors.lightBlue, width: 3),
//               insets: const EdgeInsets.symmetric(horizontal: 40),
//             ),
//             labelColor: MyColors.lightBlue,
//             unselectedLabelColor: Colors.grey.shade400,
//             labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 12),
//             unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w400, fontSize: 12),
//             tabs: [
//               const Tab(icon: Icon(Icons.dashboard_rounded), text: "Home"),
//               GestureDetector(
//                 behavior: HitTestBehavior.opaque,
//                 onTap: () => _showLogoutDialog(context),
//                 child: const Tab(icon: Icon(Icons.logout_rounded), text: "Logout"),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   // Enhanced Card Builder with Vertical Layout
//   Widget _buildActionCard({
//     required IconData icon,
//     required String title,
//     required String subtitle,
//     required String description,
//     required Color color,
//     required Color iconColor,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: double.infinity,
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(24),
//           border: Border.all(color: Colors.grey.shade100, width: 1.5),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.04),
//               blurRadius: 20,
//               offset: const Offset(0, 8),
//             ),
//             BoxShadow(
//               color: Colors.black.withOpacity(0.02),
//               blurRadius: 4,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Icon Container
//             Container(
//               padding: const EdgeInsets.all(14),
//               decoration: BoxDecoration(
//                 color: color,
//                 borderRadius: BorderRadius.circular(18),
//                 boxShadow: [
//                   BoxShadow(
//                     color: iconColor.withOpacity(0.1),
//                     blurRadius: 8,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: Icon(icon, color: iconColor, size: 32),
//             ),
//             const SizedBox(width: 18),
//
//             // Text Content
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     title,
//                     style: GoogleFonts.poppins(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w700,
//                       color: Colors.black87,
//                       letterSpacing: -0.3,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     subtitle,
//                     style: GoogleFonts.poppins(
//                       fontSize: 13,
//                       fontWeight: FontWeight.w500,
//                       color: iconColor,
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   Text(
//                     description,
//                     style: GoogleFonts.poppins(
//                       fontSize: 12,
//                       color: Colors.grey.shade600,
//                       height: 1.4,
//                     ),
//                   ),
//
//                   // Action Hint
//                   const SizedBox(height: 16),
//                   Row(
//                     children: [
//                       Text(
//                         'Tap to manage →',
//                         style: GoogleFonts.poppins(
//                           fontSize: 11,
//                           fontWeight: FontWeight.w500,
//                           color: iconColor,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // Helper for Clean Navigation
//   void _navigateTo(BuildContext context, Widget screen) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => BlocProvider(
//           create: (context) => MainBloc(webService: WebService()),
//           child: screen,
//         ),
//       ),
//     );
//   }
//
//   void _showLogoutDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
//         title: Text("Confirm Logout", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20)),
//         content: Text("Are you sure you want to exit the Attendance app?", style: GoogleFonts.poppins(fontSize: 14)),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text("CANCEL", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
//           ),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red.shade400,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//             ),
//             onPressed: onLogout,
//             child: const Text("LOGOUT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // --- Logic remains untouched below ---
//   void onLogout() async {
//     await clearAllSecureStorage();
//     if (!mounted) return;
//     Navigator.pushAndRemoveUntil(
//       context,
//       MaterialPageRoute(
//         builder: (context) => BlocProvider(
//           create: (context) => MainBloc(webService: WebService()),
//           child: LoginScreen(),
//         ),
//       ),
//           (route) => false,
//     );
//   }
//
//   Future<void> clearAllSecureStorage() async => await storage.deleteAll();
// }
