import 'dart:async';

import 'package:attendance_system_ios/bloc/main_bloc.dart';
import 'package:attendance_system_ios/bloc/main_event.dart';
import 'package:attendance_system_ios/bloc/main_state.dart';
import 'package:attendance_system_ios/screen/UserListScreen/AddNewStaffScreen.dart';
import 'package:attendance_system_ios/service/WebService.dart';
import 'package:attendance_system_ios/util/MyColor.dart';
import 'package:attendance_system_ios/util/menu_drawer.dart';
import 'package:attendance_system_ios/util/searchString.dart';
import 'package:attendance_system_ios/util/search_bar_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_overlay/loading_overlay.dart';

import '../../model/Expense/ViewexpenseAdmin.dart';
import '../../model/UsersList/GetAllusersListResponse.dart';
import '../AdminExpense/Adminexpenseview.dart';
import '../AdminProfile/Admin_profile.dart';
import '../AdminVisitTracking/AdminVisitTrack.dart';
import '../Home/AdminPunchreport.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

///working fine old ui
class _UserListScreenState extends State<UserListScreen> {
  late MainBloc mainBloc;
  final storage = FlutterSecureStorage();

  String? staffCode = "";
  String? Auth_Token = "";

  late bool _isLoading = false;
  ScrollController UsersRecordController = ScrollController();
  bool isSearchMode = false;
  int pageNumber = 1;
  bool isLastPage = false;
  List<Message> userList = [];
  List<Message> latlongUserList = [];
  Timer? _debounce;
  List<Message> filteredUserList = [];
  List<ViewExpenseModel> filtereduserlisttt =
      []; // List to hold the filtered results
  TextEditingController searchController =
      TextEditingController(); // Controller for search
  String searchClasss = ""; // Search query
  SearchStringClass searchClass = SearchStringClass(searchStr: '');
  int totalUsers = 0;

  // @override
  // void initState() {
  //   super.initState();state.getAllusersListResponse?.data
  //   mainBloc = BlocProvider.of<MainBloc>(context);
  //   getData();
  //
  //   searchController.addListener(() {
  //     onSearchTextChanged(searchController.text);
  //   });
  // }
  @override
  void initState() {
    super.initState();
    mainBloc = BlocProvider.of<MainBloc>(context);

    getData();

    searchController.addListener(() {
      onSearchTextChanged(searchController.text);
    });

    UsersRecordController.addListener(() {
      // ❌ stop pagination during search
      if (isSearchMode) return;

      if (UsersRecordController.position.pixels ==
              UsersRecordController.position.maxScrollExtent &&
          !isLastPage) {
        pageNumber++;

        mainBloc.add(
          GetAllUsersListEvent(
            pagenumber: pageNumber.toString(),
            pagesize: "15",
            token: Auth_Token!,
          ),
        );
      }
    });
  }

  Future<void> getData() async {
    staffCode = await storage.read(key: 'Staff_Code');
    Auth_Token = await storage.read(key: 'Auth_Token');

    pageNumber = 1;
    isLastPage = false;
    isSearchMode = false;

    mainBloc.add(
      GetAllUsersListEvent(
        pagenumber: pageNumber.toString(),
        pagesize: "15",
        token: Auth_Token!,
      ),
    );
  }

  void onSearchTextChanged(String text) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      String sanitizedText =
          text.trim().replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), '');

      if (sanitizedText.isEmpty) {
        // 🔵 BACK TO PAGINATION
        isSearchMode = false;
        pageNumber = 1;
        isLastPage = false;

        mainBloc.add(
          GetAllUsersListEvent(
            pagenumber: "1",
            pagesize: "15",
            token: Auth_Token!,
          ),
        );
      } else {
        // 🟢 SEARCH MODE
        isSearchMode = true;

        mainBloc.add(
          SearchbyStaffcodeEvents(
            staffcode: sanitizedText,
            token: Auth_Token!,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(
            color: Colors.white,
            size: 28,
          ),
          title: const Text("User List"),
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
        body: LoadingOverlay(
          isLoading: _isLoading,
          opacity: 0.5,
          color: Colors.white,
          progressIndicator: CircularProgressIndicator(
            backgroundColor: Color(0xFFCE4A6F),
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
          ),
          child: BlocListener<MainBloc, MainState>(
            listener: (context, state) async {
              if (state is GetAllUsersListLoadingState) {
                setState(() {
                  _isLoading = true;
                });
              } else if (state is GetAllUsersListLoadedState) {
                //final newData = state.getAllusersListResponse?.message ?? [];
                final newData = state.getAllusersListResponse?.data ?? [];
                print("API DATA LENGTH: ${newData.length}");
                print("USER LIST LENGTH: ${userList.length}");
                print("FILTERED LIST LENGTH: ${filteredUserList.length}");
                setState(() {
                  _isLoading = false;

                  if (pageNumber == 1) {
                    userList.clear();
                  }

                  userList.addAll(newData);
                  totalUsers = state.getAllusersListResponse?.totalcount ?? 0;

                  if (newData.length < 15) {
                    isLastPage = true;
                  }

                  // filteredUserList = List.from(userList); //
                  filteredUserList.clear();
                  filteredUserList.addAll(userList); //✅ INSIDE setState
                });
                print("API DATA LENGTH1: ${newData.length}");
                print("USER LIST LENGTH1: ${userList.length}");
                print("FILTERED LIST LENGTH1: ${filteredUserList.length}");
              } else if (state is GetAllUsersListErrorState) {
                setState(() {
                  _isLoading = false;
                });
                Fluttertoast.showToast(
                  msg: "   Failed To Connect Server!   ",
                  toastLength: Toast.LENGTH_SHORT,
                  timeInSecForIosWeb: 1,
                );
              } else if (state is SearchbyStaffcodeLoadingPage) {
                setState(() {
                  _isLoading = true;
                });
              } else if (state is SearchbyStaffcodeLoadedPage) {
                setState(() {
                  _isLoading = false;

                  filteredUserList.clear();

                  filteredUserList.addAll(
                    state.userResponse?.data.map((e) {
                          return Message(
                            staffCode: e.staffCode,
                            displayName: e.displayName,
                            mobileNo: e.mobileNo,
                            emailId: e.emailId,
                            isDeletedFlag: e.isDeletedFlag,
                          );
                        }).toList() ??
                        [],
                  );
                });
              } else if (state is SearchbyStaffcodeErrorPage) {
                setState(() {
                  _isLoading = false;
                  filteredUserList.clear();
                });

                Fluttertoast.showToast(msg: state.message);
              }
            },
            child: CustomScrollView(
              controller: UsersRecordController,
              slivers: [
                // Search Bar before Total Users Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: SearchBarScreen(
                      searchStrClass: searchClass,
                      controller: searchController,
                      onChanged: onSearchTextChanged,
                    ),
                  ),
                ),
                // Sticky Total Users Card
                SliverToBoxAdapter(
                  child: Card(
                    margin: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(width: 1, color: MyColors.lightBlue),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Container(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Total Users  : $totalUsers ",
                            style: TextStyle(
                                color: MyColors.blueColorCode,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // List of Users
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return Card(
                        shape: RoundedRectangleBorder(
                          side: BorderSide(width: 1, color: MyColors.lightBlue),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            selectOptions(context, index);
                          },
                          child: Container(
                            padding: EdgeInsets.only(
                              top: 15,
                              left: 14,
                              right: 14,
                              bottom: 15,
                            ),
                            width: MediaQuery.of(context).size.width,
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                            ),
                            child: Stack(
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 15.0, bottom: 15),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Staff Code",
                                                  style: TextStyle(
                                                    color: MyColors
                                                        .textprofiledetailColorCode,
                                                    fontSize: 18,
                                                  ),
                                                ),
                                                Text(
                                                  filteredUserList[index]
                                                              .staffCode
                                                              .toString() !=
                                                          null
                                                      ? filteredUserList[index]
                                                          .staffCode
                                                          .toString()
                                                      : "0",
                                                  style: TextStyle(
                                                    color:
                                                        MyColors.text5ColorCode,
                                                    fontSize: 18,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Display Name",
                                                  style: TextStyle(
                                                    color: MyColors
                                                        .textprofiledetailColorCode,
                                                    fontSize: 18,
                                                  ),
                                                ),
                                                Text(
                                                  filteredUserList[index]
                                                              .displayName !=
                                                          null
                                                      ? filteredUserList[index]
                                                          .displayName!
                                                      : "",
                                                  textAlign: TextAlign.left,
                                                  style: TextStyle(
                                                    color:
                                                        MyColors.text5ColorCode,
                                                    fontSize: 18,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Mobile No",
                                                style: TextStyle(
                                                  color: MyColors
                                                      .textprofiledetailColorCode,
                                                  fontSize: 18,
                                                ),
                                              ),
                                              Text(
                                                filteredUserList[index]
                                                            .mobileNo !=
                                                        null
                                                    ? filteredUserList[index]
                                                        .mobileNo!
                                                    : "",
                                                textAlign: TextAlign.left,
                                                style: TextStyle(
                                                  color:
                                                      MyColors.text5ColorCode,
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Email ID",
                                                style: TextStyle(
                                                  color: MyColors
                                                      .textprofiledetailColorCode,
                                                  fontSize: 18,
                                                ),
                                              ),
                                              Text(
                                                filteredUserList[index]
                                                            .emailId !=
                                                        null
                                                    ? filteredUserList[index]
                                                        .emailId!
                                                    : "",
                                                style: TextStyle(
                                                  color:
                                                      MyColors.text5ColorCode,
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (filteredUserList[index].isDeletedFlag ==
                                    "Y")
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: () {
                                        _showRemovedUserDialog(
                                            context, filteredUserList[index]);
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade600,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.info_outline,
                                                color: Colors.white, size: 14),
                                            SizedBox(width: 4),
                                            Text(
                                              "Removed",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: filteredUserList.length,
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: MyColors.lightBlue,
          onPressed: () async {
            await Navigator.of(context).push(
              new MaterialPageRoute(
                  builder: (_) => BlocProvider(
                      create: (context) {
                        return MainBloc(webService: WebService());
                      },
                      child: AddNewStaffScreen())),
            );
          },
          child: Icon(Icons.add, color: MyColors.whiteColorCode),
        ),
      ),
    );
  }

  void _showRemovedUserDialog(BuildContext context, Message user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text("Removed User"),
        content: Text(
          "This user is requested to remove their data.\n\nDo you want to permanently delete this user?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteUser(user);
            },
            child: Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _deleteUser(Message user) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => BlocProvider(
              create: (context) {
                return MainBloc(webService: WebService());
              },
              child: AdminUserProfile(datum: user))),
    );

    Fluttertoast.showToast(msg: "Deleted Staff code from here");
    // context.read<MainBloc>().add(
    //   DeleteUserEvent(userId: user.userId),
    // );
  }

  selectOptions(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0), // Rounded corners
          ),
          child: Container(
            height: MediaQuery.of(context).size.height *
                0.6, // Adjust height dynamically
            width: MediaQuery.of(context).size.width - 10,
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: SingleChildScrollView(
                // Add scrolling capability
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      margin:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(width: 1, color: MyColors.lightBlue),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Container(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Center(
                              child: Image.asset(
                                "assets/icons/mtechlogo2.png",
                                width: MediaQuery.of(context).size.width * 0.5,
                                height: 80,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                        padding: const EdgeInsets.only(top: 2.0, bottom: 10),
                        child: Center(
                          child: Text(
                            " Select Options ",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontWeight: FontWeight.w400, fontSize: 17),
                          ),
                        )),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => BlocProvider(
                                          create: (context) {
                                            return MainBloc(
                                                webService: WebService());
                                          },
                                          child: AdminUserProfile(
                                              datum: filteredUserList[index]))),
                                );
                              },
                              child: Card(
                                margin: EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 5),
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                      width: 1, color: MyColors.lightBlue),
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                child: Container(
                                  padding: EdgeInsets.all(6),
                                  height:
                                      MediaQuery.of(context).size.width * 0.2,
                                  width:
                                      MediaQuery.of(context).size.width * 0.2,
                                  child: Center(
                                    child: Image.asset(
                                      "assets/icons/profileeimg.png",
                                      width: MediaQuery.of(context).size.width *
                                          0.1,
                                      height:
                                          MediaQuery.of(context).size.width *
                                              0.1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 2.0, bottom: 10),
                                  child: Text(
                                    "   Profile",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w400,
                                        fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                print("attendance Report Clicked:");
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BlocProvider(
                                        create: (context) {
                                          return MainBloc(
                                              webService: WebService());
                                        },
                                        child: AdminAttendanceReport(
                                            datum: filteredUserList[index])),
                                  ),
                                );
                              },
                              child: Card(
                                margin: EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 5),
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                      width: 1, color: MyColors.lightBlue),
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                child: Container(
                                  padding: EdgeInsets.all(6),
                                  height:
                                      MediaQuery.of(context).size.width * 0.2,
                                  width:
                                      MediaQuery.of(context).size.width * 0.2,
                                  child: Center(
                                    child: Image.asset(
                                      "assets/icons/report.png",
                                      width: MediaQuery.of(context).size.width *
                                          0.2,
                                      height:
                                          MediaQuery.of(context).size.width *
                                              0.2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 2.0, bottom: 10),
                                  child: Text(
                                    "   IN/OUT Report",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w400,
                                        fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                print("Visit Report Clicked:");
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BlocProvider(
                                        create: (context) {
                                          return MainBloc(
                                              webService: WebService());
                                        },
                                        child: AdminVisitTrackScreen(
                                            datum: filteredUserList[index])),
                                  ),
                                );
                              },
                              child: Card(
                                margin: EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 5),
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                      width: 1, color: MyColors.lightBlue),
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                child: Container(
                                  padding: EdgeInsets.all(16),
                                  height:
                                      MediaQuery.of(context).size.width * 0.2,
                                  width:
                                      MediaQuery.of(context).size.width * 0.2,
                                  child: Center(
                                    child: Image.asset(
                                      "assets/icons/visitTrack.png",
                                      width: MediaQuery.of(context).size.width *
                                          0.2,
                                      height:
                                          MediaQuery.of(context).size.width *
                                              0.2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 2.0, bottom: 10),
                                  child: Text(
                                    "   Visit Track ",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w400,
                                        fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                print("Expense Clicked:");
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BlocProvider(
                                        create: (context) {
                                          return MainBloc(
                                              webService: WebService());
                                        },
                                        child: AdminexpenseView(
                                            datum: filteredUserList[index])),
                                  ),
                                );
                              },
                              child: Card(
                                margin: EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 5),
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                      width: 1, color: MyColors.lightBlue),
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                child: Container(
                                  padding: EdgeInsets.all(16),
                                  height:
                                      MediaQuery.of(context).size.width * 0.2,
                                  width:
                                      MediaQuery.of(context).size.width * 0.2,
                                  child: Center(
                                    child: Image.asset(
                                      "assets/icons/expensem.jpg",
                                      width: MediaQuery.of(context).size.width *
                                          0.2,
                                      height:
                                          MediaQuery.of(context).size.width *
                                              0.2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 2.0, bottom: 10),
                                  child: Text(
                                    " Expense Details",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w400,
                                        fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/*

class _UserListScreenState extends State<UserListScreen> {
  late MainBloc mainBloc;
  final storage = FlutterSecureStorage();

  String? staffCode = "";
  String? Auth_Token = "";

  late bool _isLoading = false;
  ScrollController UsersRecordController = ScrollController();
  bool isSearchMode = false;
  int pageNumber = 1;
  bool isLastPage = false;
  List<Message> userList = [];
  List<Message> latlongUserList = [];
  Timer? _debounce;
  List<Message> filteredUserList = [];
  List<ViewExpenseModel> filtereduserlisttt =
      []; // List to hold the filtered results
  TextEditingController searchController =
      TextEditingController(); // Controller for search
  String searchClasss = ""; // Search query
  SearchStringClass searchClass = SearchStringClass(searchStr: '');
  int totalUsers = 0;

  // @override
  // void initState() {
  //   super.initState();
  //   mainBloc = BlocProvider.of<MainBloc>(context);
  //   getData();
  //
  //   searchController.addListener(() {
  //     onSearchTextChanged(searchController.text);
  //   });
  // }
  @override
  void initState() {
    super.initState();
    mainBloc = BlocProvider.of<MainBloc>(context);

    getData();

    searchController.addListener(() {
      onSearchTextChanged(searchController.text);
    });

    UsersRecordController.addListener(() {
      // ❌ stop pagination during search
      if (isSearchMode) return;

      if (UsersRecordController.position.pixels ==
              UsersRecordController.position.maxScrollExtent &&
          !isLastPage) {
        pageNumber++;

        mainBloc.add(
          GetAllUsersListEvent(
            pagenumber: pageNumber.toString(),
            pagesize: "15",
            token: Auth_Token!,
          ),
        );
      }
    });
  }

  Future<void> getData() async {
    staffCode = await storage.read(key: 'Staff_Code');
    Auth_Token = await storage.read(key: 'Auth_Token');

    pageNumber = 1;
    isLastPage = false;
    isSearchMode = false;

    mainBloc.add(
      GetAllUsersListEvent(
        pagenumber: pageNumber.toString(),
        pagesize: "15",
        token: Auth_Token!,
      ),
    );
  }

  void onSearchTextChanged(String text) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      String sanitizedText =
          text.trim().replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), '');

      if (sanitizedText.isEmpty) {
        // 🔵 BACK TO PAGINATION
        isSearchMode = false;
        pageNumber = 1;
        isLastPage = false;

        mainBloc.add(
          GetAllUsersListEvent(
            pagenumber: "1",
            pagesize: "15",
            token: Auth_Token!,
          ),
        );
      } else {
        // 🟢 SEARCH MODE
        isSearchMode = true;

        mainBloc.add(
          SearchbyStaffcodeEvents(
            staffcode: sanitizedText,
            token: Auth_Token!,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(
            color: Colors.white,
            size: 28,
          ),
          title: const Text("User List"),
          backgroundColor: MyColors.lightBlue,
          centerTitle: true,
          elevation: 4,
          titleTextStyle: GoogleFonts.roboto(
            fontWeight: FontWeight.bold,
            fontSize: 22.0,
          ).copyWith(
            color: Colors.white,
          ),
        ),
        drawer: MenuDrawer(),
        backgroundColor: MyColors.backgroundColorCode,
        body: LoadingOverlay(
          isLoading: _isLoading,
          opacity: 0.5,
          color: Colors.white,
          progressIndicator: CircularProgressIndicator(
            backgroundColor: Color(0xFFCE4A6F),
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
          ),
          child: BlocListener<MainBloc, MainState>(
            listener: (context, state) async {
              if (state is GetAllUsersListLoadingState) {
                setState(() {
                  _isLoading = true;
                });
              } else if (state is GetAllUsersListLoadedState) {
                //final newData = state.getAllusersListResponse?.message ?? [];
                final newData = state.getAllusersListResponse?.data ?? [];
                print("API DATA LENGTH: ${newData.length}");
                print("USER LIST LENGTH: ${userList.length}");
                print("FILTERED LIST LENGTH: ${filteredUserList.length}");
                setState(() {
                  _isLoading = false;

                  if (pageNumber == 1) {
                    userList.clear();
                  }

                  userList.addAll(newData);
                  totalUsers = state.getAllusersListResponse?.totalcount ?? 0;

                  if (newData.length < 50) {
                    isLastPage = true;
                  }

                  // filteredUserList = List.from(userList); //
                  filteredUserList.clear();
                  filteredUserList.addAll(userList); //✅ INSIDE setState
                });
                print("API DATA LENGTH1: ${newData.length}");
                print("USER LIST LENGTH1: ${userList.length}");
                print("FILTERED LIST LENGTH1: ${filteredUserList.length}");
              } else if (state is GetAllUsersListErrorState) {
                setState(() {
                  _isLoading = false;
                });
                Fluttertoast.showToast(
                  msg: "   Failed To Connect Server!   ",
                  toastLength: Toast.LENGTH_SHORT,
                  timeInSecForIosWeb: 1,
                );
              } else if (state is SearchbyStaffcodeLoadingPage) {
                setState(() {
                  _isLoading = true;
                });
              } else if (state is SearchbyStaffcodeLoadedPage) {
                setState(() {
                  _isLoading = false;

                  filteredUserList.clear();

                  filteredUserList.addAll(
                    state.userResponse?.data.map((e) {
                          return Message(
                            staffCode: e.staffCode,
                            displayName: e.displayName,
                            mobileNo: e.mobileNo,
                            emailId: e.emailId,
                            isDeletedFlag: e.isDeletedFlag,
                          );
                        }).toList() ??
                        [],
                  );
                });
              } else if (state is SearchbyStaffcodeErrorPage) {
                setState(() {
                  _isLoading = false;
                  filteredUserList.clear();
                });

                Fluttertoast.showToast(msg: state.message);
              }
            },
            child: CustomScrollView(
              controller: UsersRecordController,
              slivers: [
                // Search Bar before Total Users Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: SearchBarScreen(
                        searchStrClass: searchClass,
                        controller: searchController,
                        onChanged: onSearchTextChanged,
                      ),
                    ),
                  ),
                ),
                // Sticky Total Users Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Card(
                      elevation: 4,
                      shadowColor: MyColors.lightBlue.withOpacity(0.3),
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(width: 1.5, color: MyColors.lightBlue),
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              MyColors.lightBlue.withOpacity(0.05),
                            ],
                          ),
                        ),
                        padding:
                            EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_alt_rounded,
                              color: MyColors.lightBlue,
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Text(
                              "Total Users  : $totalUsers ",
                              style: TextStyle(
                                  color: MyColors.blueColorCode,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // List of Users
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Card(
                          elevation: 6,
                          shadowColor: Colors.black26,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                                width: 1,
                                color: MyColors.lightBlue.withOpacity(0.5)),
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          child: GestureDetector(
                            onTap: () {
                              selectOptions(context, index);
                            },
                            child: Container(
                              padding: EdgeInsets.only(
                                top: 18,
                                left: 16,
                                right: 16,
                                bottom: 18,
                              ),
                              width: MediaQuery.of(context).size.width,
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(15)),
                                color: Colors.white,
                              ),
                              child: Stack(
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 16.0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            Expanded(
                                              child: Container(
                                                padding:
                                                    EdgeInsets.only(right: 8),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Icon(Icons.badge,
                                                            size: 16,
                                                            color: MyColors
                                                                .textprofiledetailColorCode),
                                                        SizedBox(width: 6),
                                                        Text(
                                                          "Staff Code",
                                                          style: TextStyle(
                                                            color: MyColors
                                                                .textprofiledetailColorCode,
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(height: 6),
                                                    Text(
                                                      filteredUserList[index]
                                                                  .staffCode
                                                                  .toString() !=
                                                              null
                                                          ? filteredUserList[
                                                                  index]
                                                              .staffCode
                                                              .toString()
                                                          : "0",
                                                      style: TextStyle(
                                                        color: MyColors
                                                            .text5ColorCode,
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Container(
                                                padding:
                                                    EdgeInsets.only(left: 8),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Icon(
                                                            Icons
                                                                .person_outline,
                                                            size: 16,
                                                            color: MyColors
                                                                .textprofiledetailColorCode),
                                                        SizedBox(width: 6),
                                                        Text(
                                                          "Display Name",
                                                          style: TextStyle(
                                                            color: MyColors
                                                                .textprofiledetailColorCode,
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(height: 6),
                                                    Text(
                                                      filteredUserList[index]
                                                                  .displayName !=
                                                              null
                                                          ? filteredUserList[
                                                                  index]
                                                              .displayName!
                                                          : "",
                                                      textAlign: TextAlign.left,
                                                      style: TextStyle(
                                                        color: MyColors
                                                            .text5ColorCode,
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          Expanded(
                                            child: Container(
                                              padding:
                                                  EdgeInsets.only(right: 8),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(Icons.phone_android,
                                                          size: 16,
                                                          color: MyColors
                                                              .textprofiledetailColorCode),
                                                      SizedBox(width: 6),
                                                      Text(
                                                        "Mobile No",
                                                        style: TextStyle(
                                                          color: MyColors
                                                              .textprofiledetailColorCode,
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 6),
                                                  Text(
                                                    filteredUserList[index]
                                                                .mobileNo !=
                                                            null
                                                        ? filteredUserList[
                                                                index]
                                                            .mobileNo!
                                                        : "",
                                                    textAlign: TextAlign.left,
                                                    style: TextStyle(
                                                      color: MyColors
                                                          .text5ColorCode,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Container(
                                              padding: EdgeInsets.only(left: 8),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(Icons.email_outlined,
                                                          size: 16,
                                                          color: MyColors
                                                              .textprofiledetailColorCode),
                                                      SizedBox(width: 6),
                                                      Text(
                                                        "Email ID",
                                                        style: TextStyle(
                                                          color: MyColors
                                                              .textprofiledetailColorCode,
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 6),
                                                  Text(
                                                    filteredUserList[index]
                                                                .emailId !=
                                                            null
                                                        ? filteredUserList[
                                                                index]
                                                            .emailId!
                                                        : "",
                                                    style: TextStyle(
                                                      color: MyColors
                                                          .text5ColorCode,
                                                      fontSize: 14,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (filteredUserList[index].isDeletedFlag ==
                                      "Y")
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: () {
                                          _showRemovedUserDialog(
                                              context, filteredUserList[index]);
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade600,
                                            borderRadius: BorderRadius.only(
                                              bottomLeft: Radius.circular(12),
                                              topRight: Radius.circular(12),
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black26,
                                                blurRadius: 2,
                                                offset: Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.info_outline,
                                                  color: Colors.white,
                                                  size: 14),
                                              SizedBox(width: 4),
                                              Text(
                                                "Removed",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: filteredUserList.length,
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: MyColors.lightBlue,
          onPressed: () async {
            await Navigator.of(context).push(
              new MaterialPageRoute(
                  builder: (_) => BlocProvider(
                      create: (context) {
                        return MainBloc(webService: WebService());
                      },
                      child: AddNewStaffScreen())),
            );
          },
          child: Icon(Icons.add, color: MyColors.whiteColorCode),
        ),
      ),
    );
  }

  void _showRemovedUserDialog(BuildContext context, Message user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text("Removed User"),
        content: Text(
          "This user is requested to remove their data.\n\nDo you want to permanently delete this user?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteUser(user);
            },
            child: Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _deleteUser(Message user) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => BlocProvider(
              create: (context) {
                return MainBloc(webService: WebService());
              },
              child: AdminUserProfile(datum: user))),
    );

    Fluttertoast.showToast(msg: "Deleted Staff code from here");
    // context.read<MainBloc>().add(
    //   DeleteUserEvent(userId: user.userId),
    // );
  }

  selectOptions(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0), // Rounded corners
          ),
          elevation: 16,
          child: Container(
            height: MediaQuery.of(context).size.height *
                0.65, // Adjust height dynamically
            width: MediaQuery.of(context).size.width - 24,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: SingleChildScrollView(
                // Add scrolling capability
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      margin:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(width: 1.5, color: MyColors.lightBlue),
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      elevation: 2,
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Center(
                              child: Image.asset(
                                "assets/icons/mtechlogo2.png",
                                width: MediaQuery.of(context).size.width * 0.5,
                                height: 80,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 16),
                        child: Center(
                          child: Text(
                            " Select Options ",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 20,
                                color: MyColors.lightBlue,
                                letterSpacing: 0.5),
                          ),
                        )),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => BlocProvider(
                                          create: (context) {
                                            return MainBloc(
                                                webService: WebService());
                                          },
                                          child: AdminUserProfile(
                                              datum: filteredUserList[index]))),
                                );
                              },
                              child: Card(
                                margin: EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 5),
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                      width: 1.5, color: MyColors.lightBlue),
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                                elevation: 4,
                                child: Container(
                                  padding: EdgeInsets.all(12),
                                  height:
                                      MediaQuery.of(context).size.width * 0.22,
                                  width:
                                      MediaQuery.of(context).size.width * 0.22,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    color: Colors.white,
                                  ),
                                  child: Center(
                                    child: Image.asset(
                                      "assets/icons/profileeimg.png",
                                      width: MediaQuery.of(context).size.width *
                                          0.12,
                                      height:
                                          MediaQuery.of(context).size.width *
                                              0.12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 8.0, bottom: 10),
                                  child: Text(
                                    "   Profile",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: MyColors.text5ColorCode),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                print("attendance Report Clicked:");
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BlocProvider(
                                        create: (context) {
                                          return MainBloc(
                                              webService: WebService());
                                        },
                                        child: AdminAttendanceReport(
                                            datum: filteredUserList[index])),
                                  ),
                                );
                              },
                              child: Card(
                                margin: EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 5),
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                      width: 1.5, color: MyColors.lightBlue),
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                                elevation: 4,
                                child: Container(
                                  padding: EdgeInsets.all(12),
                                  height:
                                      MediaQuery.of(context).size.width * 0.22,
                                  width:
                                      MediaQuery.of(context).size.width * 0.22,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    color: Colors.white,
                                  ),
                                  child: Center(
                                    child: Image.asset(
                                      "assets/icons/report.png",
                                      width: MediaQuery.of(context).size.width *
                                          0.12,
                                      height:
                                          MediaQuery.of(context).size.width *
                                              0.12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 8.0, bottom: 10),
                                  child: Text(
                                    "   IN/OUT Report",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: MyColors.text5ColorCode),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                print("Visit Report Clicked:");
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BlocProvider(
                                        create: (context) {
                                          return MainBloc(
                                              webService: WebService());
                                        },
                                        child: AdminVisitTrackScreen(
                                            datum: filteredUserList[index])),
                                  ),
                                );
                              },
                              child: Card(
                                margin: EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 5),
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                      width: 1.5, color: MyColors.lightBlue),
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                                elevation: 4,
                                child: Container(
                                  padding: EdgeInsets.all(12),
                                  height:
                                      MediaQuery.of(context).size.width * 0.22,
                                  width:
                                      MediaQuery.of(context).size.width * 0.22,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    color: Colors.white,
                                  ),
                                  child: Center(
                                    child: Image.asset(
                                      "assets/icons/visitTrack.png",
                                      width: MediaQuery.of(context).size.width *
                                          0.12,
                                      height:
                                          MediaQuery.of(context).size.width *
                                              0.12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 8.0, bottom: 10),
                                  child: Text(
                                    "   Visit Track ",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: MyColors.text5ColorCode),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                print("Expense Clicked:");
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BlocProvider(
                                        create: (context) {
                                          return MainBloc(
                                              webService: WebService());
                                        },
                                        child: AdminexpenseView(
                                            datum: filteredUserList[index])),
                                  ),
                                );
                              },
                              child: Card(
                                margin: EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 5),
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                      width: 1.5, color: MyColors.lightBlue),
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                                elevation: 4,
                                child: Container(
                                  padding: EdgeInsets.all(12),
                                  height:
                                      MediaQuery.of(context).size.width * 0.22,
                                  width:
                                      MediaQuery.of(context).size.width * 0.22,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    color: Colors.white,
                                  ),
                                  child: Center(
                                    child: Image.asset(
                                      "assets/icons/expensem.jpg",
                                      width: MediaQuery.of(context).size.width *
                                          0.12,
                                      height:
                                          MediaQuery.of(context).size.width *
                                              0.12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 8.0, bottom: 10),
                                  child: Text(
                                    " Expense Details",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: MyColors.text5ColorCode),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
*/
