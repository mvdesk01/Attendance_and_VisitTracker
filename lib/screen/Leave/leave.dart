import 'package:attendance_system_ios/bloc/main_bloc.dart';
import 'package:attendance_system_ios/bloc/main_event.dart';
import 'package:attendance_system_ios/bloc/main_state.dart';
import 'package:attendance_system_ios/model/Leave/LeavePendingResponse.dart';
import 'package:attendance_system_ios/screen/Home/home.dart';
import 'package:attendance_system_ios/service/WebService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_overlay/loading_overlay.dart';

import '../../model/Leave/CancelLeave.dart';
import '../../service/log_file_manager.dart';
import '../../util/MyColor.dart';
import 'add_leave.dart';
import 'apply_leave.dart';

class PendingLeave extends StatefulWidget {
  const PendingLeave({super.key});

  @override
  State<PendingLeave> createState() => _PendingLeaveState();
}

class _PendingLeaveState extends State<PendingLeave> {
  late bool _isLoading = false;
  bool showtable = false;
  bool isUpdate = true;

  late MainBloc mainBloc;
  final storage = FlutterSecureStorage();

  String? staffCode = "";
  String? Auth_Token = "";
  String ApprovedFlag = "P";
  late List<Message> pendingLeaveList = [];

  ScrollController vendorRecordController = ScrollController();

  @override
  void initState() {
    super.initState();
    mainBloc = BlocProvider.of(context);
    getData();
  }

  Future<void> getData() async {
    staffCode = await storage.read(key: 'Staff_Code');
    Auth_Token = await storage.read(key: 'Auth_Token');

    if (staffCode == null || staffCode!.isEmpty) {
      Fluttertoast.showToast(msg: "Staff code is missing!");
      return;
    }

    if (Auth_Token == null || Auth_Token!.isEmpty) {
      Fluttertoast.showToast(msg: "Auth token is missing!");
      return;
    }

    ApprovedFlag = "P";

    print(
        "StaffCode: 'cd03184', Auth_Token: $Auth_Token, ApprovedFlag: $ApprovedFlag");

    mainBloc.add(GetPendingLeaveEvents(
        StaffCode: staffCode!, token: Auth_Token!, ApprovedFlag: ApprovedFlag));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => (Navigator.canPop(context))
                ? Navigator.pop(context)
                : Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => BlocProvider(
                            create: (context) {
                              return MainBloc(webService: WebService());
                            },
                            child: HomeScreen())))),
        title: const Text(" Leave "),
        backgroundColor: MyColors.lightBlue,
        centerTitle: true,
        titleTextStyle: GoogleFonts.roboto(
          fontWeight: FontWeight.bold,
          fontSize: 18.0,
        ).copyWith(
          color: Colors.white,
        ),
      ),
      body: WillPopScope(
        onWillPop: () async {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            print("Else Navigatorrrrrrrrrrrrr");
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => BlocProvider(
                        create: (context) {
                          return MainBloc(webService: WebService());
                        },
                        child: HomeScreen())));
            return false;
          }
          return true;
        },
        child: _leavescreen(),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: MyColors.lightBlue,
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (context) => MainBloc(webService: WebService()),
                child: AddLeavePage(
                  flag: 1,
                  leaveData: pendingLeaveList.isNotEmpty
                      ? pendingLeaveList.first
                      : null,
                ),
              ),
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  _leavescreen() {
    // SOLUTION 1: Use BlocBuilder instead of BlocListener for UI
    return BlocBuilder<MainBloc, MainState>(
      builder: (context, state) {
        // Handle loading states
        if (state is GetPendingLeaveLoadingStatae) {
          _isLoading = true;
        } else if (state is GetPendingLeaveLoadedState) {
          _isLoading = false;

          // 🔥 ALWAYS RESET FIRST
          pendingLeaveList = [];

          if (state.leavependingresponse.message != null &&
              state.leavependingresponse.message!.isNotEmpty) {
            pendingLeaveList = List.from(state.leavependingresponse.message!);
          }

          print("Updated List Count: ${pendingLeaveList.length}");
        } else if (state is GetPendingLeaveErrorState) {
          _isLoading = false;
          print("GetPendingLeaveErrorState mess: ${state.msg}");
          LogFileManager.writeLog("Error in fetching leave data: ${state.msg}");
        } else if (state is GetCancelLeaveLoadingState) {
          _isLoading = true;
        } else if (state is GetCancelLeaveLoadedState) {
          _isLoading = false;
          Fluttertoast.showToast(msg: "Leave record deleted successfully!");
          pendingLeaveList.clear();
          // Refresh data
          getData();
        } else if (state is GetCancelLeaveErrorState) {
          _isLoading = false;
          Fluttertoast.showToast(
            msg: "Failed to delete leave: ${state.msg}",
            toastLength: Toast.LENGTH_SHORT,
            timeInSecForIosWeb: 1,
          );
        }

        return LoadingOverlay(
          isLoading: _isLoading,
          opacity: 0.5,
          color: Colors.white,
          progressIndicator: CircularProgressIndicator(
            backgroundColor: Color(0xFFCE4A6F),
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
          ),
          child: RefreshIndicator(
            onRefresh: getData,
            child: pendingLeaveList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          "assets/icons/no_data.png",
                          height: 150,
                        ),
                        SizedBox(height: 20),
                        Text(
                          "No Data Available",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    // key: UniqueKey(),
                    // Force rebuild when list changes
                    controller: vendorRecordController,
                    shrinkWrap: true,
                    itemCount: pendingLeaveList.length,
                    itemBuilder: (context, index) {
                      Message leave = pendingLeaveList[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                              width: 1, color: MyColors.textBoxBorderColorCode),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Container(
                          padding: EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("STATUS: PENDING",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: MyColors.greenColorCode)),
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => BlocProvider(
                                                create: (context) => MainBloc(
                                                    webService: WebService()),
                                                child: LeaveDetailsPage(
                                                  flag: 2,
                                                  tokennn: Auth_Token!,
                                                  leaveData:
                                                      pendingLeaveList[index],
                                                ),
                                              ),
                                            ),
                                          );
                                          // Refresh data if update was successful
                                          if (result == true) {
                                            getData();
                                          }
                                        }, // Your gesture detector content
                                        child: Container(
                                          height: 32,
                                          margin:
                                              EdgeInsets.only(top: 7, left: 20),
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 5),
                                          decoration: BoxDecoration(
                                              color: MyColors.blueColorCode,
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(10))),
                                          child: Text(
                                            "EDIT",
                                            style: TextStyle(
                                                color: MyColors.whiteColorCode,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          _showDeleteDialog(context, leave);
                                        },
                                        child: Container(
                                          height: 32,
                                          margin:
                                              EdgeInsets.only(top: 7, left: 20),
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 5),
                                          decoration: BoxDecoration(
                                              color: MyColors.redColorCode,
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                          child: Text(
                                            "DELETE",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: MyColors.whiteColorCode,
                                                fontSize: 12),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),
                              _buildRow("Applied Date",
                                  _formatDate(leave.transactionDate)),
                              _buildRow(
                                  "From Date", _formatDate(leave.startingDate)),
                              _buildRow(
                                  "To Date", _formatDate(leave.endingDate)),
                              _buildRow("Reason", leave.reason ?? "N/A"),
                              _buildRow('Leave', leave.leaveTypeCode!),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: MyColors.black, fontSize: 18)),
          Text(value, style: TextStyle(color: MyColors.black, fontSize: 18)),
        ],
      ),
    );
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return "N/A";
    DateTime parsedDate = DateTime.parse(date);
    return "${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}";
  }

  void _showDeleteDialog(BuildContext context, Message leave) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Delete Leave"),
          content: Text("Are you sure you want to delete this leave record?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("No", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteLeave(context, leave);
              },
              child: Text("Yes", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteLeave(BuildContext context, Message leave) async {
    try {
      CancelLeaveBody request = CancelLeaveBody(
        flag: "C",
        tid: leave.transactionId.toString(),
        rReason: leave.reason ?? "",
        staffcode: staffCode!,
      );

      mainBloc.add(CancelLeaveEvents(
        cancelleavebody: request,
        token: Auth_Token!,
      ));

      LogFileManager.writeLog("delete record $request");
    } catch (e) {
      LogFileManager.writeLog("delete record $e");
      Fluttertoast.showToast(msg: "Failed to delete leave: $e");
    }
  }
}

///new UI
// class _PendingLeaveState extends State<PendingLeave> {
//   late bool _isLoading = false;
//   bool showtable = false;
//   bool isUpdate = true;
//
//   late MainBloc mainBloc;
//   final storage = const FlutterSecureStorage();
//
//   String? staffCode = "";
//   String? Auth_Token = "";
//   String ApprovedFlag = "P";
//   late List<Message> pendingLeaveList = [];
//
//   ScrollController vendorRecordController = ScrollController();
//
//   @override
//   void initState() {
//     super.initState();
//     mainBloc = BlocProvider.of<MainBloc>(context);
//     getData();
//   }
//
//   Future<void> getData() async {
//     staffCode = await storage.read(key: 'Staff_Code');
//     Auth_Token = await storage.read(key: 'Auth_Token');
//
//     if (staffCode == null || staffCode!.isEmpty) {
//       Fluttertoast.showToast(msg: "Staff code is missing!");
//       return;
//     }
//
//     if (Auth_Token == null || Auth_Token!.isEmpty) {
//       Fluttertoast.showToast(msg: "Auth token is missing!");
//       return;
//     }
//
//     ApprovedFlag = "P";
//     mainBloc.add(GetPendingLeaveEvents(
//         StaffCode: staffCode!, token: Auth_Token!, ApprovedFlag: ApprovedFlag));
//   }
//
//   void _navigateToHome() {
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(
//         builder: (_) => BlocProvider(
//           create: (context) => MainBloc(webService: WebService()),
//           child: HomeScreen(),
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF0F2F5), // Soft grey background
//       appBar: AppBar(
//         elevation: 0,
//         toolbarHeight: 70,
//         // Slightly taller for more presence
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios_new_rounded,
//               color: Colors.white, size: 24),
//           onPressed: () => (Navigator.canPop(context))
//               ? Navigator.pop(context)
//               : _navigateToHome(),
//         ),
//         title: Text(
//           "Pending Requests",
//           style: GoogleFonts.poppins(
//               fontWeight: FontWeight.w700,
//               fontSize: 22, // Increased title size
//               color: Colors.white),
//         ),
//         backgroundColor: MyColors.lightBlue,
//         centerTitle: true,
//       ),
//       body: WillPopScope(
//         onWillPop: () async {
//           if (Navigator.canPop(context)) {
//             Navigator.pop(context);
//           } else {
//             _navigateToHome();
//             return false;
//           }
//           return true;
//         },
//         child: _leavescreen(),
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         backgroundColor: MyColors.lightBlue,
//         elevation: 4,
//         icon: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
//         label: Text("NEW REQUEST",
//             style: GoogleFonts.poppins(
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16, // Large clear font
//                 letterSpacing: 1.1)),
//         onPressed: () {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//               builder: (_) => BlocProvider(
//                 create: (context) => MainBloc(webService: WebService()),
//                 child: AddLeavePage(
//                   flag: 1,
//                   leaveData: pendingLeaveList.isNotEmpty
//                       ? pendingLeaveList.first
//                       : null,
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _leavescreen() {
//     return BlocBuilder<MainBloc, MainState>(
//       builder: (context, state) {
//         // --- LOGIC HANDLING (UNCHANGED) ---
//         if (state is GetPendingLeaveLoadingStatae) {
//           _isLoading = true;
//         } else if (state is GetPendingLeaveLoadedState) {
//           _isLoading = false;
//           pendingLeaveList = [];
//           if (state.leavependingresponse.message != null &&
//               state.leavependingresponse.message!.isNotEmpty) {
//             pendingLeaveList = List.from(state.leavependingresponse.message!);
//           }
//         } else if (state is GetCancelLeaveLoadingState) {
//           _isLoading = true;
//         } else if (state is GetCancelLeaveLoadedState) {
//           _isLoading = false;
//           Fluttertoast.showToast(msg: "Success!");
//           getData();
//         }
//
//         return LoadingOverlay(
//           isLoading: _isLoading,
//           opacity: 0.4,
//           color: Colors.white,
//           progressIndicator: const CircularProgressIndicator(),
//           child: RefreshIndicator(
//             onRefresh: getData,
//             child: pendingLeaveList.isEmpty
//                 ? _buildEmptyState()
//                 : _buildListView(),
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildEmptyState() {
//     return ListView(
//       physics: const AlwaysScrollableScrollPhysics(),
//       children: [
//         SizedBox(height: MediaQuery.of(context).size.height * 0.2),
//         Center(
//           child: Column(
//             children: [
//               const Icon(Icons.description_outlined,
//                   size: 100, color: Colors.grey),
//               const SizedBox(height: 20),
//               Text(
//                 "No pending records",
//                 style:
//                     GoogleFonts.poppins(fontSize: 20, color: Colors.grey[700]),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildListView() {
//     return ListView.builder(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
//       controller: vendorRecordController,
//       itemCount: pendingLeaveList.length,
//       itemBuilder: (context, index) {
//         return _buildLeaveCard(pendingLeaveList[index]);
//       },
//     );
//   }
//
//   Widget _buildLeaveCard(Message leave) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           )
//         ],
//       ),
//       child: Column(
//         children: [
//           // Header Row
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 _buildStatusIndicator("PENDING"),
//                 Row(
//                   children: [
//                     _iconAction(Icons.edit_rounded, Colors.blue,
//                         () => _handleEdit(leave)),
//                     const SizedBox(width: 15),
//                     _iconAction(Icons.delete_rounded, Colors.redAccent,
//                         () => _showDeleteDialog(context, leave)),
//                   ],
//                 )
//               ],
//             ),
//           ),
//
//           // Content Block
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 20),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Text(
//                 //   leave.leaveTypeCode ?? "Leave Request",
//                 //   style: GoogleFonts.poppins(
//                 //       fontSize: 20, // Large text
//                 //       fontWeight: FontWeight.bold,
//                 //       color: Colors.black87),
//                 // ),
//                 const SizedBox(height: 15),
//
//                 // Date Range Section
//                 Row(
//                   children: [
//                     _dateElement("START DATE", _formatDate(leave.startingDate)),
//                     Container(width: 1, height: 30, color: Colors.grey[300]),
//                     _dateElement("END DATE", _formatDate(leave.endingDate)),
//                   ],
//                 ),
//
//                 const Divider(height: 30),
//
//                 // Reason Section
//                 Text("REASON",
//                     style: GoogleFonts.poppins(
//                         fontSize: 12,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.grey)),
//                 const SizedBox(height: 4),
//                 Text(
//                   leave.reason ?? "N/A",
//                   style:
//                       GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
//                 ),
//                 const SizedBox(height: 20),
//               ],
//             ),
//           ),
//
//           // Footer
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//             decoration: BoxDecoration(
//                 color: Colors.grey[50],
//                 borderRadius: const BorderRadius.only(
//                     bottomLeft: Radius.circular(16),
//                     bottomRight: Radius.circular(16))),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text("Applied on:",
//                     style: TextStyle(fontSize: 14, color: Colors.grey[600])),
//                 Text(_formatDate(leave.transactionDate),
//                     style: const TextStyle(
//                         fontSize: 14, fontWeight: FontWeight.w600)),
//               ],
//             ),
//           )
//         ],
//       ),
//     );
//   }
//
//   Widget _buildStatusIndicator(String status) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       decoration: BoxDecoration(
//           color: Colors.orange[50],
//           borderRadius: BorderRadius.circular(8),
//           border: Border.all(color: Colors.orange[200]!)),
//       child: Text(
//         status,
//         style: GoogleFonts.poppins(
//             color: Colors.orange[800],
//             fontWeight: FontWeight.bold,
//             fontSize: 13),
//       ),
//     );
//   }
//
//   Widget _dateElement(String label, String date) {
//     return Expanded(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           Text(label,
//               style: GoogleFonts.poppins(
//                   fontSize: 11,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.grey[600])),
//           const SizedBox(height: 4),
//           Text(date,
//               style: GoogleFonts.poppins(
//                   fontSize: 17,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.blueGrey[800])),
//         ],
//       ),
//     );
//   }
//
//   Widget _iconAction(IconData icon, Color color, VoidCallback onTap) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.all(8),
//         decoration: BoxDecoration(
//             color: color.withOpacity(0.1), shape: BoxShape.circle),
//         child: Icon(icon, color: color, size: 24),
//       ),
//     );
//   }
//
//   // --- Logic Methods (Unaltered) ---
//
//   void _handleEdit(Message leave) async {
//     final result = await Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => BlocProvider(
//           create: (context) => MainBloc(webService: WebService()),
//           child:
//               LeaveDetailsPage(flag: 2, tokennn: Auth_Token!, leaveData: leave),
//         ),
//       ),
//     );
//     if (result == true) getData();
//   }
//
//   String _formatDate(String? date) {
//     if (date == null || date.isEmpty) return "N/A";
//     try {
//       DateTime parsedDate = DateTime.parse(date);
//       return "${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}";
//     } catch (_) {
//       return "N/A";
//     }
//   }
//
//   void _showDeleteDialog(BuildContext context, Message leave) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: Text("Delete Request",
//             style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
//         content:
//             const Text("Are you sure you want to remove this leave record?"),
//         actions: [
//           TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text("CANCEL")),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.red,
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8))),
//             onPressed: () {
//               Navigator.pop(context);
//               _deleteLeave(context, leave);
//             },
//             child: const Text("DELETE", style: TextStyle(color: Colors.white)),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _deleteLeave(BuildContext context, Message leave) async {
//     CancelLeaveBody request = CancelLeaveBody(
//       flag: "C",
//       tid: leave.transactionId.toString(),
//       rReason: leave.reason ?? "",
//       staffcode: staffCode!,
//     );
//     mainBloc
//         .add(CancelLeaveEvents(cancelleavebody: request, token: Auth_Token!));
//   }
// }
