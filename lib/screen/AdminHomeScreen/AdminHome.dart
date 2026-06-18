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
  String? Staffcode;

  final storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    imagePaths = [
      'assets/icons/mtechinnovationsimage1.jpg',
      'assets/icons/mtechinnovationsimage2.jpg',
      'assets/icons/mtechinnovationsimage3.jpg',
    ];
    getStaffCode();
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
                        const SizedBox(height: 10),
                        // if (Staffcode?.toLowerCase() == "mzdl002")
                        //   Row(
                        //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        //     children: [
                        //       _buildCard(
                        //         icon: Icons.person,
                        //         title: 'User Rights',
                        //         onTap: () {
                        //           Navigator.push(
                        //             context,
                        //             MaterialPageRoute(
                        //               builder: (context) => BlocProvider(
                        //                 create: (context) =>
                        //                     MainBloc(webService: WebService()),
                        //                 child: MenuRightsScreen(),
                        //               ),
                        //             ),
                        //           );
                        //         },
                        //       ),
                        //       _buildCard(
                        //         icon: Icons.person,
                        //         title: 'Menu Subcription',
                        //         onTap: () {
                        //           Navigator.push(
                        //             context,
                        //             MaterialPageRoute(
                        //               builder: (context) => BlocProvider(
                        //                 create: (context) =>
                        //                     MainBloc(webService: WebService()),
                        //                 child: MenuSubscriptionScreen(),
                        //               ),
                        //             ),
                        //           );
                        //         },
                        //       ),
                        //     ],
                        //   ),
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

  Future<void> getStaffCode() async {
    Staffcode = await storage.read(key: 'username');
    print("staffcode: $Staffcode");
    setState(() {});
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
