import 'dart:async';

import 'package:attendance_system_ios/bloc/main_bloc.dart';
import 'package:attendance_system_ios/bloc/main_event.dart';
import 'package:attendance_system_ios/bloc/main_state.dart';
import 'package:attendance_system_ios/screen/UserListScreen/AddNewStaffScreen.dart';
import 'package:attendance_system_ios/service/WebService.dart';
import 'package:attendance_system_ios/service/menu_rights_service.dart';
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

class _UserListScreenState extends State<UserListScreen> {
  late MainBloc mainBloc;
  final storage = const FlutterSecureStorage();

  String? staffCode = "";
  String? Auth_Token = "";

  late bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  bool isSearchMode = false;
  int pageNumber = 1;
  bool isLastPage = false;
  List<Message> userList = [];
  Timer? _debounce;
  List<Message> filteredUserList = [];
  final TextEditingController searchController = TextEditingController();
  SearchStringClass searchClass = SearchStringClass(searchStr: '');
  int totalUsers = 0;

  @override
  void initState() {
    super.initState();
    mainBloc = BlocProvider.of<MainBloc>(context);
    getData();

    _scrollController.addListener(() {
      if (isSearchMode) return;
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && !isLastPage) {
        pageNumber++;
        mainBloc.add(GetAllUsersListEvent(
          pagenumber: pageNumber.toString(),
          pagesize: "15",
          token: Auth_Token!,
        ));
      }
    });
  }

  Future<void> getData() async {
    staffCode = await storage.read(key: 'Staff_Code');
    Auth_Token = await storage.read(key: 'Auth_Token');
    pageNumber = 1;
    isLastPage = false;
    isSearchMode = false;
    mainBloc.add(GetAllUsersListEvent(
      pagenumber: pageNumber.toString(),
      pagesize: "15",
      token: Auth_Token!,
    ));
  }

  void onSearchTextChanged(String text) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      String sanitizedText = text.trim().replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), '');
      if (sanitizedText.isEmpty) {
        isSearchMode = false;
        pageNumber = 1;
        isLastPage = false;
        mainBloc.add(GetAllUsersListEvent(
          pagenumber: "1",
          pagesize: "15",
          token: Auth_Token!,
        ));
      } else {
        isSearchMode = true;
        mainBloc.add(SearchbyStaffcodeEvents(
          staffcode: sanitizedText,
          token: Auth_Token!,
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: MyColors.lightBlue,
        title: Text(
          "User Directory",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        opacity: 0.3,
        progressIndicator: const CircularProgressIndicator(color: MyColors.lightBlue),
        child: BlocListener<MainBloc, MainState>(
          listener: (context, state) {
            if (state is GetAllUsersListLoadingState || state is SearchbyStaffcodeLoadingPage) {
              setState(() => _isLoading = true);
            } else if (state is GetAllUsersListLoadedState) {
              final newData = state.getAllusersListResponse?.data ?? [];
              setState(() {
                _isLoading = false;
                if (pageNumber == 1) userList.clear();
                userList.addAll(newData);
                totalUsers = state.getAllusersListResponse?.totalcount ?? 0;
                isLastPage = newData.length < 15;
                filteredUserList = List.from(userList);
              });
            } else if (state is SearchbyStaffcodeLoadedPage) {
              setState(() {
                _isLoading = false;
                filteredUserList = state.userResponse?.data.map((e) => Message(
                  staffCode: e.staffCode,
                  displayName: e.displayName,
                  mobileNo: e.mobileNo,
                  emailId: e.emailId,
                  isDeletedFlag: e.isDeletedFlag,
                )).toList() ?? [];
              });
            } else if (state is GetAllUsersListErrorState || state is SearchbyStaffcodeErrorPage) {
              setState(() => _isLoading = false);
              Fluttertoast.showToast(msg: "Error connecting to server");
            }
          },
          child: RefreshIndicator(
            onRefresh: getData,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: const BoxDecoration(
                      color: MyColors.lightBlue,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        SearchBarScreen(
                          searchStrClass: searchClass,
                          controller: searchController,
                          onChanged: onSearchTextChanged,
                        ),
                        const SizedBox(height: 16),
                        _buildTotalUsersCard(),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildUserCard(filteredUserList[index]),
                      childCount: filteredUserList.length,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () => Navigator.of(context).push(MaterialPageRoute(
      //     builder: (_) => BlocProvider(
      //       create: (context) => MainBloc(webService: WebService()),
      //       child:  AddNewStaffScreen(),
      //     ),
      //   )),
      //   backgroundColor: MyColors.appDefaultColorCode,
      //   icon: const Icon(Icons.add, color: Colors.white),
      //   label: Text("Add Staff", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500)),
      // ),
    );
  }

  Widget _buildTotalUsersCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.group, color: Colors.white70, size: 20),
          const SizedBox(width: 8),
          Text(
            "Total Staff: $totalUsers",
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Message user) {
    bool isRemoved = user.isDeletedFlag == "Y";
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => selectOptions(context, user),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: MyColors.appDefaultColorCode.withOpacity(0.1),
                        child: Text(
                          user.displayName?.isNotEmpty == true ? user.displayName![0].toUpperCase() : "?",
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: MyColors.appDefaultColorCode),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName ?? "N/A",
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              "Staff Code: ${user.staffCode ?? "N/A"}",
                              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1),
                  ),
                  Row(
                    children: [
                      _buildInfoItem(Icons.phone_outlined, user.mobileNo ?? "N/A"),
                      const SizedBox(width: 16),
                      _buildInfoItem(Icons.email_outlined, user.emailId ?? "N/A"),
                    ],
                  ),
                ],
              ),
              if (isRemoved)
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => _showRemovedUserDialog(context, user),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            "Removed",
                            style: GoogleFonts.poppins(color: Colors.red.shade700, fontSize: 10, fontWeight: FontWeight.bold),
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
  }

  Widget _buildInfoItem(IconData icon, String value) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade400),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showRemovedUserDialog(BuildContext context, Message user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Removed User", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          "This user has requested to remove their data. Do you want to permanently delete this account?",
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteUser(user);
            },
            child: Text("Delete Permanently", style: GoogleFonts.poppins(color: Colors.white)),
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
          create: (context) => MainBloc(webService: WebService()),
          child: AdminUserProfile(datum: user),
        ),
      ),
    );
  }

  void selectOptions(BuildContext context, Message user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 24),
            Text(
              "Select Option",
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              "Actions for ${user.displayName}",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Center(
                child: Center(
                  child: Center(
                    child: Center(
                      child: Center(
                        child: Center(
                          child: Center(
                            child: Center(
                              child: GridView.count(
                                crossAxisCount: 2,
                                childAspectRatio: 1.5,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                children: [
                                  if (MenuRightsService.isEmployeeProfileAllowed())
                                    _buildOptionCard(context, Icons.person_outline, "Profile", Colors.blue, () {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => BlocProvider(
                                        create: (_) => MainBloc(webService: WebService()),
                                        child: AdminUserProfile(datum: user),
                                      )));
                                    }),
                                  if (MenuRightsService.isEmployeeInOutReportAllowed())
                                    _buildOptionCard(context, Icons.assignment_outlined, "Attendance", Colors.orange, () {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => BlocProvider(
                                        create: (_) => MainBloc(webService: WebService()),
                                        child: AdminAttendanceReport(datum: user),
                                      )));
                                    }),
                                  if (MenuRightsService.isEmployeeVisitReportAllowed())
                                    _buildOptionCard(context, Icons.location_on_outlined, "Visit Track", Colors.green, () {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => BlocProvider(
                                        create: (_) => MainBloc(webService: WebService()),
                                        child: AdminVisitTrackScreen(datum: user),
                                      )));
                                    }),
                                  if (MenuRightsService.isEmployeeExpenseReportAllowed())
                                    _buildOptionCard(context, Icons.receipt_long_outlined, "Expenses", Colors.purple, () {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => BlocProvider(
                                        create: (_) => MainBloc(webService: WebService()),
                                        child: AdminexpenseView(datum: user),
                                      )));
                                    }),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}
