import 'dart:convert';

import 'package:attendance_system_ios/bloc/main_bloc.dart';
import 'package:attendance_system_ios/screen/CancellationRequest/CancellationRequestScreen.dart';
import 'package:attendance_system_ios/screen/Login/login_screen.dart';
import 'package:attendance_system_ios/screen/Sanction/SanctionScreen.dart';
import 'package:attendance_system_ios/screen/UserListScreen/UserListScreen.dart';
import 'package:attendance_system_ios/service/WebService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:attendance_system_ios/util/MyColor.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../screen/AdminHomeScreen/AdminHome.dart';
import '../screen/Profile/ProfileforAdmin.dart';
import '../screen/Profile/profile.dart';
import 'package:http/http.dart' as http;

class MenuDrawer extends StatefulWidget {
  const MenuDrawer({Key? key}) : super(key: key);

  @override
  _MenuDrawerState createState() => _MenuDrawerState();
}

class _MenuDrawerState extends State<MenuDrawer> {
  late int selectedIndex = 0; // Track the selected index
  late FlutterSecureStorage storage;
  String profileImageUrl = "";
  String? profileImageBase64;

  @override
  void initState() {
    super.initState();
    storage = FlutterSecureStorage();
    _fetchProfilePhoto();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            color: MyColors.lightBlue,
            child: Column(
              children: [
                const Padding(padding: EdgeInsets.symmetric(vertical: 8)),
                const Text(
                  "Attendance",
                  style: TextStyle(color: Colors.white, fontSize: 20.0, fontWeight: FontWeight.bold),
                ),
                const Padding(padding: EdgeInsets.symmetric(vertical: 3)),
                GestureDetector(
                  onTap: () async{
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider(
                          create: (context) => MainBloc(webService: WebService()),
                          child: ProfileforAdmin(),
                        ),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 52,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: profileImageBase64 != null
                            ? MemoryImage(base64Decode(profileImageBase64!))  // ✅ Display Base64 Image
                            : const AssetImage("assets/icons/profile.png") as ImageProvider,  // Fallback to default
                      ),
                      const Text(
                        "Admin",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      const Text(
                        "MZDL002",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildMenuItem(0, Icons.home_outlined, 'Home'),
          _buildMenuItem(1, Icons.list_alt_outlined, 'Users List'),
          //_buildMenuItem(2, Icons.book_outlined, 'Sanction/Reject'),
          //_buildMenuItem(3, Icons.cancel_schedule_send_sharp, 'Expense Management'),
          _buildMenuItem(2, Icons.notification_important, 'Notifications'),
          //_buildMenuItem(5, Icons.list_alt_outlined, 'About'),
          _buildMenuItem(3, Icons.logout, 'Logout'),
        ],
      ),
    );
  }

  // Helper function to create menu items
  Widget _buildMenuItem(int index, IconData icon, String title) {
    bool isSelected = selectedIndex == index; // Check if this item is selected

    return Container(
      color: isSelected ? MyColors.blueColorCode.withOpacity(0.1) : Colors.transparent, // Change background color if selected
      child: ListTile(
        selected: isSelected,
        leading: Icon(
          icon,
          color: isSelected ? MyColors.blueColorCode : MyColors.text3greyColorCode, // Change icon color if selected
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? MyColors.blueColorCode : Colors.black, // Change text color if selected
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, // Bold text if selected
          ),
        ),
        onTap: () {
          setState(() {
            selectedIndex = index; // Update the selected index
            print("selectedIndex---->"+selectedIndex.toString());
            if(selectedIndex == 0){
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (context) => MainBloc(webService: WebService()),
                    child: AdminHomeScreen(),
                  ),
                ),
              );
            }
            if(selectedIndex==1)
            {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider(
                      create: (context) {
                        return MainBloc(webService: WebService());
                      },
                      child: UserListScreen()),
                ),
              );
            }
            if(selectedIndex==3)
            {
              print("selectedIndex---->ifff block");

              Navigator.of(context).pop();

              /* SharedPreferences sharedPreferences =
                              await SharedPreferences.getInstance();*/
              // //print(sharedPreferences.getInt("UserID")!);
              showDialog(
                  context: context,
                  builder: (BuildContext context) =>
                      _buildPopupDialogforLogout(
                          context));
            }
            if(selectedIndex==2){
              Fluttertoast.showToast(msg: "No Notification Found!!");
            }

          });
          // Handle navigation here if necessary (e.g., navigate to another screen)
          // Navigator.push(context, MaterialPageRoute(builder: (context) => YourNextScreen()));
        },
      ),
    );
  }

  Widget _buildPopupDialogforLogout(
      BuildContext context) {
    return new AlertDialog(
      // title: const Text('Popup example'),
      content: new Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            "Logout",
            style: TextStyle(
                fontSize: 20,
                color: MyColors.appDefaultColorCode,
                fontWeight: FontWeight.bold),
          ),
          SizedBox(
            height: 20,
          ),
          Text(
            "Are you sure you want to Logout Attendance App?",
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
            clearAllSecureStorage();
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

  Future<void> clearAllSecureStorage() async {
    await storage.deleteAll();  // Clear all stored data
  }

  Future<void> _fetchProfilePhoto() async {
    try {
      String? authToken = await storage.read(key: 'Auth_Token');

      if (authToken != null) {
        var response = await http.get(
          Uri.parse('http://114.143.140.28:8020/Users/GetUserInfoByStaffCode?staffCode=mzdl002'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          var data = json.decode(response.body);

          // ✅ Extract Base64 profile photo
          var profilePicBase64 = data['message']['profilePic'] ?? "";

          if (profilePicBase64.isNotEmpty) {
            setState(() {
              profileImageBase64 = profilePicBase64;
            });
            print("Profile image loaded successfully.");
          } else {
            print("No profile photo found.");
          }
        } else {
          print("Failed to load profile photo. Status code: ${response.statusCode}");
        }
      }
    } catch (e) {
      print("Error fetching profile photo: $e");
    }
  }

  String _cleanBase64(String base64String) {
    if (base64String.contains(",")) {
      return base64String.split(",").last.trim(); // Remove 'data:image/...;base64,' prefix
    }
    return base64String.trim();
  }

}









